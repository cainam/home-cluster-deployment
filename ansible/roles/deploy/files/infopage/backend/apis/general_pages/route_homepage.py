from fastapi import APIRouter
from fastapi import Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

import subprocess
import logging
import functools

import infopage

logging.basicConfig(level = logging.DEBUG)
logger = logging.getLogger(__name__)


def log(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        args_repr = [repr(a) for a in args]
        kwargs_repr = [f"{k}={v!r}" for k, v in kwargs.items()]
        signature = ", ".join(args_repr + kwargs_repr)
        logger.debug(f"function {func.__name__} called with args {signature}")
        try:
            result = func(*args, **kwargs)
            return result
        except Exception as e:
            logger.exception(f"Exception raised in {func.__name__}. exception: {str(e)}")
            raise e
    return wrapper


templates = Jinja2Templates(directory="templates")
general_pages_router = APIRouter()
registry = "https://10.10.10.10:443"
	
loglev = logging.getLogger("uvicorn.access").level
#logging.getLogger("uvicorn.access").setLevel(logging.CRITICAL)
@general_pages_router.get("/")
async def home(request: Request):
	return templates.TemplateResponse("general_pages/homepage.html",{"request":request})

@general_pages_router.get("/check")
#@log
async def check(request: Request):
    return "ok"

#logging.getLogger("uvicorn.access").setLevel(logging.DEBUG)

@general_pages_router.get("/node_status")
#@log
async def node_status(request: Request):
    content = infopage.node_info()
    return templates.TemplateResponse("general_pages/node_info.html",{"request":request, "nodes": content, "name": "node status"})

@general_pages_router.get("/virtual_services")
async def vs(request: Request):
    content = infopage.vs_info()
    return templates.TemplateResponse("general_pages/vs_info.html",{"request":request, "vss": content, "name": "virtual services"})


@general_pages_router.get("/services_status")
#@log
#async def services_status(request: Request):
def services_status(request: Request):
    output={}
    output["registry"] = subprocess.run(["curl","-k","-s","-X","GET","-I",registry+"/v2/_catalog"], capture_output=True).stdout.decode('ascii')
    output["helm"] = subprocess.run(["curl","-k","-s","-X","GET","-I","https://10.10.10.10:9443"], capture_output=True).stdout.decode('ascii')

    # logger.info("response: "+response)
    return templates.TemplateResponse("general_pages/service_status.html",{"request":request, "content": output, "name": "service status" } )

@general_pages_router.post("/delete_image")
async def delete_image(request: Request):
    import requests, hashlib

    payload = await request.json()
    logger.info("/delete_image called, body: "+str(payload ) )

    # header includes digest already, but I went to compute it from the body
    headers = {'Accept': 'application/vnd.docker.distribution.manifest.v2+json,application/vnd.oci.image.manifest.v1+json'}
    manifest = requests.get(registry+"/v2/"+payload["image"]+"/manifests/"+payload["tag"], verify=False, headers=headers)
    hexdigest = hashlib.sha256(manifest.text.encode()).hexdigest()
    logger.info("digest for deletion: "+hexdigest)
    
    del_return = requests.delete(registry+"/v2/"+payload["image"]+"/manifests/sha256:"+hexdigest, verify=False, headers=headers)
    #logger("del_return: "+str(del_return))

    logger.info("status:"+str(del_return.status_code))
    return ""

@general_pages_router.get("/registry_images")
#async def registry_images(request: Request):
def registry_images(request: Request):
  import requests

  serviceaccount = "/var/run/secrets/kubernetes.io/serviceaccount"
  cacert = serviceaccount+"/ca.crt"
  headers = {}

  content = []
  images = requests.get(registry+"/v2/_catalog", verify=False, headers=headers).json()

  images_list = []
  for i in images["repositories"]:
    versions = requests.get(registry+"/v2/"+i+"/tags/list", verify=False, headers=headers).json()
    if versions["tags"] is None:
      images_list.append([i, 'None'])
    else:
      for t in versions["tags"]:
        images_list.append([i, t])

  return templates.TemplateResponse("general_pages/images_list.html",{"request":request, "images_list": images_list, "name": "registry images" } )

@general_pages_router.get("/software")
#async def software(request: Request):
def software(request: Request, name: str | None = None):
    raw, content = infopage.software()
    return templates.TemplateResponse("general_pages/software.html",{"request":request, "content": content, "raw": raw, "name": "software"})

@general_pages_router.get("/soft_ng")
#async def software(request: Request):
def software(request: Request, software: str | None = None):
    raw, content = infopage.soft_ng(software)
    if (software is None ):
      return templates.TemplateResponse("general_pages/soft_ng.html",{"request":request, "content": content, "raw": raw, "name": "soft_ng"})
    else:
      logger.info("software: "+software+" content:"+str(content))
      return templates.TemplateResponse("general_pages/software_versions.html",{"request":request, "content": content, "raw": raw})


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

@general_pages_router.get("/login")
#@log
def login(request: Request):
    bdy = await request.json()

    logger.info("body:"+str(bdy))

    challenge = bdy["challenge"]
    output={}
    output["registry"] = subprocess.run(["curl","-k","-s","-X","GET","-I",registry+"/v2/_catalog"], capture_output=True).stdout.decode('ascii')
    output["helm"] = subprocess.run(["curl","-k","-s","-X","GET","-I","https://10.10.10.10:9443"], capture_output=True).stdout.decode('ascii')

    # logger.info("response: "+response)
    return templates.TemplateResponse("general_pages/login.html",{"request":request, "content": output, "name": "service status" } )

@general_pages_router.get("/consent")
#@log
def consent(request: Request):
    output={}
    output["registry"] = subprocess.run(["curl","-k","-s","-X","GET","-I",registry+"/v2/_catalog"], capture_output=True).stdout.decode('ascii')
    output["helm"] = subprocess.run(["curl","-k","-s","-X","GET","-I","https://10.10.10.10:9443"], capture_output=True).stdout.decode('ascii')

    # logger.info("response: "+response)
    return templates.TemplateResponse("general_pages/consent.html",{"request":request, "content": output, "name": "service status" } )


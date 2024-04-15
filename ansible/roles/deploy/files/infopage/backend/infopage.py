import requests

serviceaccount = "/var/run/secrets/kubernetes.io/serviceaccount"
cacert = serviceaccount+"/ca.crt"
apiserver = "https://kubernetes.default.svc"
token = open(serviceaccount+'/token', 'r').read()
headers = {'Accept': '*/*', 'Authorization': 'Bearer '+token}

def vs_info():
  # list all namespaces
  content = []
  namespaces = requests.get(apiserver+"/api/v1/namespaces/", verify=cacert, headers=headers).json()
  for n in namespaces["items"]:
    namespace = n["metadata"]["name"]
    vss = requests.get(apiserver+"/apis/networking.istio.io/v1beta1/namespaces/"+namespace+"/virtualservices/", verify=cacert, headers=headers).json()
    for vs in vss["items"]:
      #print(vs["metadata"]["name"])
      #print(vs["spec"]["hosts"])
      for s in vs["spec"]["http"]:
        if "name" in s and "uri" in s["match"][0]:
          for host in vs["spec"]["hosts"]:
            content.append( [namespace, host, vs["metadata"]["name"], s["name"], s["match"][0]['uri']['prefix']] )
  return content
  
def node_info():
  # list all nodes
  content=[]
  nodes = requests.get(apiserver+"/api/v1/nodes/", verify=cacert, headers=headers).json()
  for n in nodes["items"]:
    info = "name: "+n["metadata"]["name"]+"\n kernelVersion:"+n["status"]["nodeInfo"]["kernelVersion"]+"\n containerRuntimeVersion:"+n["status"]["nodeInfo"]["containerRuntimeVersion"]
    cond=""
    for c in n["status"]["conditions"]:
        cond += c["type"]+": status:"+c["status"]+" reason:"+c["reason"]+"\n"

    content.append([ info, cond  ] )
  return content

def software():
  import yaml
  import requests
  from packaging.specifiers import SpecifierSet

  software_file = "software"
  with open(software_file, 'r') as file:
    sw = yaml.safe_load(file)

  raw = "" #str(sw)
  content=[]
  for item in sw["software"]:
    raw+="\n"+item+"\n  current version: "+sw["software"][item]["version"]
    content_item=[item,sw["software"][item]["version"]]

    if sw["software"][item]["latest"]["type"] == "github":
      vers = requests.get("https://api.github.com/repos/"+sw["software"][item]["latest"]["params"]["repo"]+"/releases/latest") # | jq .tag_name
      raw += "\n  github version: "+str(vers.json()["tag_name"] )
      content_item.append(vers.json()["tag_name"])

    elif sw["software"][item]["latest"]["type"] == "dockerhub":
      dockerhub_base_url = "https://hub.docker.com/v2/repositories/"
      digest = requests.get(dockerhub_base_url+sw["software"][item]["latest"]["params"]["repo"]+"/tags/latest")
      for image in digest.json()["images"]:
        if image["architecture"] == sw["software"][item]["latest"]["params"]["arch"]:
          digest = image["digest"]
          break
      raw += "\n  latest digest: "+digest
      all_tags = requests.get(dockerhub_base_url+sw["software"][item]["latest"]["params"]["repo"]+"/tags/?page_size=500")
      versions = []
      for tag in all_tags.json()["results"]:
        if tag["name"] == "latest": continue
        for image in tag["images"]:
          if not "digest" in image:
            raw += "\n  no digest for image of tag named "+tag["name"]
            continue
          if image["digest"] == digest:
            versions.append(tag["name"])
      content_item.append(versions)

    elif sw["software"][item]["latest"]["type"] == "quay":
      base_url = "https://quay.io/api/v1/repository/"
      results = requests.get(base_url+sw["software"][item]["latest"]["params"]["repo"]+"/tag/?onlyActiveTags=true")
      vspec = SpecifierSet(">="+sw["software"][item]["version"])
      versions = []
      for v in results.json()["tags"]:
        name = v["name"]
        if name[0:6] != "latest" and name.split("-")[0] in vspec:
          versions.append(name)
      content_item.append(versions)

    else:
      content_item.append("no clue")
    content.append( content_item)
  return raw,content

#!/usr/bin/env python3

import http.server as SimpleHTTPServer
import socketserver as SocketServer
import logging
import sys
import subprocess
#from kubernetes import client, config

logger = logging.getLogger()
fileHandler = logging.FileHandler("/tmp/logfile.log")
streamHandler = logging.StreamHandler(sys.stdout)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
streamHandler.setFormatter(formatter)
fileHandler.setFormatter(formatter)
logger.addHandler(streamHandler)
logger.addHandler(fileHandler)
logger.setLevel(logging.DEBUG)
logger.info("starting")

import argparse

parser = argparse.ArgumentParser(description='none.')
parser.add_argument('--port', dest='port', type=int, default=8080, help="port number")
args = parser.parse_args()

logger.info(args.port)

class GetHandler( SimpleHTTPServer.SimpleHTTPRequestHandler ):
    def do_GET(self):
        logging.info(self.headers)
        externalIP=""
        response='<html><table border=1 align=center style="width:50%"><tr><th>Name</th><th>URL</th></tr>'

        output = subprocess.run(["bash", "/app/get_svc_LB_ports.sh"], capture_output=True)
        for item in output.stdout.decode('ascii').split('\n'):
          logger.info("subprocess output.stdout: "+item)
          if item == "": continue
          if externalIP == "": 
            externalIP=item
            continue
          (name,port,target)=item.split(',')
          name=name.replace('"','')
          response+='<tr><td>'+name+'</td><td><a href="https://'+externalIP+':'+port+'">'+name+'</a></td></tr>'
        response+="</table>"

        output = subprocess.run(["curl","-k","-s","-X","GET","-I","https://10.10.10.10:443/v2/_catalog"], capture_output=True)
        response+="<hr/>registry status<br/><pre>"+output.stdout.decode('ascii')+"</pre>"

        output = subprocess.run(["bash", "/app/my_status.sh"], capture_output=True)
        response+="<hr/>registry content<br/><pre>"+output.stdout.decode('ascii')+"</pre>"

        #for item in output.stdout.decode('ascii').split('\n'):


        response+="</html>"
        logger.info("response: "+response)
        #for item in output.stderr.decode('ascii').split('\n'):
        #  logger.info("subprocess output.stderr: "+item)
        #config.load_incluster_config()
 
        #v1 = client.CoreV1Api()
        #print("Listing pods with their IPs:")
        #ret = v1.list_pod_for_all_namespaces(watch=False)
        #for i in ret.items:
        #  logger.info("%s\t%s\t%s" % (i.status.pod_ip, i.metadata.namespace, i.metadata.name))


        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.send_header("Content-length", len(response))
        self.end_headers()
        self.wfile.write(str.encode(response))



Handler = GetHandler
SocketServer.TCPServer.allow_reuse_address = True
httpd = SocketServer.TCPServer(("", args.port), Handler)
#httpd = SocketServer.TCPServer(("", args.port), Handler, False)
#httpd.allow_reuse_address = True 
#httpd.server_bind()     # Manually bind, to support allow_reuse_address
#httpd.server_activate() # (see above comment)

httpd.serve_forever()

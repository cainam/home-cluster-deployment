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
        logging.info("headers:"+str(self.headers))
        logging.info("path:"+str(self.path)+" type:"+str(type(self.path)))
        if str(self.path) == '/check':
          logging.info("check called")
          self.send_response(200)
          self.send_header("Content-type", "text/html")
          #self.send_header("Content-length", len(response))
          self.end_headers()
          return
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

        output = subprocess.run(["bash", "/app/get_vs.sh"], capture_output=True)
        for item in output.stdout.decode('ascii').split('\n'):
          logger.info("subprocess output.stdout: "+item)
          if item == "": continue
          (name,prefix)=item.split('\t')
          response+='<tr><td>'+name+'</td><td><a href="https://my-lb.adm13'+prefix+'">'+prefix+'</a></td></tr>'
        response+="</table>"

        output = subprocess.run(["curl","-k","-s","-X","GET","-I","https://10.10.10.10:443/v2/_catalog"], capture_output=True)
        response+="<hr/>registry status<br/><pre>"+output.stdout.decode('ascii')+"</pre>"

        output = subprocess.run(["bash", "/app/my_status.sh"], capture_output=True)
        response+="<hr/>registry content<br/><pre>"+output.stdout.decode('ascii')+"</pre>"

        #for item in output.stdout.decode('ascii').split('\n'):


        response+="</html>"
        logger.info("response: "+response)

        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.send_header("Content-length", len(response))
        self.end_headers()
        try:
          self.wfile.write(str.encode(response))
        except Exception as e:
          logger.info("exception caught")
          logger.error(traceback.format_exc())

Handler = GetHandler
SocketServer.TCPServer.allow_reuse_address = True
httpd = SocketServer.TCPServer(("", args.port), Handler)

httpd.serve_forever()

FROM myregistry.adm13:443/tools/mypython:3.10.5-slim 

RUN pip install fastapi uvicorn jinja2 packaging

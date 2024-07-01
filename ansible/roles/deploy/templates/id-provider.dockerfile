FROM docker.io/golang:1.22.4

#RUN apt-get update && apt-get install -y curl jq
#RUN pip install kubernetes fastapi uvicorn jinja2 packaging
ADD oauth2-example-hydra /app
WORKDIR /app
RUN go mod download


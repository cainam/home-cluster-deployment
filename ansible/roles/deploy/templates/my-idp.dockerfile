FROM docker.io/golang:1.22.4-alpine3.20 as build

#RUN apt-get update && apt-get install -y curl jq
#RUN pip install kubernetes fastapi uvicorn jinja2 packaging
ADD id-provider/ /app
WORKDIR /app
RUN go mod download
RUN go build -o my-idp cmd/authc/main.go


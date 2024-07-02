FROM docker.io/golang:1.22.4

#RUN apt-get update && apt-get install -y curl jq
#RUN pip install kubernetes fastapi uvicorn jinja2 packaging
ADD id-provider/ /app
WORKDIR /app
RUN go mod download
RUN go build cmd/authc/main.go

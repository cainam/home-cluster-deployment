FROM python:3.10.5-slim

RUN pip install kubernetes
RUN apt-get update && apt-get install -y curl jq

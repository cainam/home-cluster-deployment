FROM python:3.10.5-slim

RUN apt-get update && apt-get install -y curl jq
RUN pip install kubernetes kopf
CMD kopf run -A /app/kopf.py

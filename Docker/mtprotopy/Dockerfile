FROM python:alpine

ENV PYTHONUNBUFFERED=1

ADD mtprotopy.py /

RUN pip install --no-cache-dir -U uvloop cryptography toml

ENTRYPOINT [ "python3", "mtprotopy.py" ]

# docker build -t brian/sz_sqs_consumer .
# docker run --user $UID -it -v $PWD:/data -e AWS_DEFAULT_REGION -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -e AWS_SESSION_TOKEN -e SENZING_ENGINE_CONFIGURATION_JSON brian/sz_sqs_consumer -q <queue url>

ARG BASE_IMAGE=senzing/senzingsdk-runtime:4.3.2
FROM ${BASE_IMAGE}

LABEL Name="brain/sz_sqs_consumer" \
      Maintainer="brianmacy@gmail.com" \
      Version="DEV"

USER root

RUN apt-get update \
 && apt-get -y install python3 python3-pip python3-boto3 python3-psycopg2 \
 && python3 -mpip install --break-system-packages orjson \
 && apt-get -y remove build-essential python3-pip \
 && apt-get -y autoremove \
 && apt-get -y clean

COPY sz_sqs_consumer.py /app/

ENV PYTHONPATH=/opt/senzing/er/sdk/python:/app

USER 1001

WORKDIR /app
ENTRYPOINT ["/app/sz_sqs_consumer.py"]


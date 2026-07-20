# docker build -t brian/sz_sqs_consumer .
# docker run --user $UID -it -v $PWD:/data -e AWS_DEFAULT_REGION -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -e AWS_SESSION_TOKEN -e SENZING_ENGINE_CONFIGURATION_JSON brian/sz_sqs_consumer -q <queue url>

ARG BASE_IMAGE=senzing/senzingsdk-runtime:4.3.3
FROM ${BASE_IMAGE}

LABEL Name="brain/sz_sqs_consumer" \
      Maintainer="brianmacy@gmail.com" \
      Version="DEV"

USER root

# Version-skew guard (no package changes): the base image ships the senzing STAGING apt repo
# (senzingstagingrepo), whose senzingsdk-* packages track the latest build ACROSS semantic versions
# (e.g. 4.4.0). This image installs no senzing package, but to keep senzingsdk-runtime from being
# floated off the base image's version we (1) pin senzingsdk-* to the base image's SEMANTIC version
# (the X.Y.Z of the installed runtime) allowing only its latest BUILD number (X.Y.Z-*), and
# (2) purge the staging repo so nothing downstream (or a stray apt upgrade) can bump it.
RUN echo "=== Senzing packages present in base image (before apt update): ===" \
 && (dpkg -l | grep -i senzing || echo "  (none found)") \
 && SZ_SEMVER="$(dpkg-query -W -f='${Version}' senzingsdk-runtime | cut -d- -f1)" \
 && echo "=== Holding senzingsdk-* at ${SZ_SEMVER}-* (base image semver, latest build) ===" \
 && printf 'Package: senzingsdk-*\nPin: version %s-*\nPin-Priority: 1001\n' "${SZ_SEMVER}" \
      > /etc/apt/preferences.d/senzing-pin.pref \
 && apt-get update \
 && apt-get -y install python3 python3-pip python3-boto3 python3-psycopg2 \
 && python3 -mpip install --break-system-packages orjson \
 && apt-get -y remove build-essential python3-pip \
 && apt-get -y purge senzingstagingrepo \
 && apt-get -y autoremove \
 && apt-get -y clean \
 && rm -rf /var/lib/apt/lists/*

COPY sz_sqs_consumer.py /app/

ENV PYTHONPATH=/opt/senzing/er/sdk/python:/app

USER 1001

WORKDIR /app
ENTRYPOINT ["/app/sz_sqs_consumer.py"]


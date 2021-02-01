FROM ubuntu:20.04

LABEL maintainer "Richard Regeer" \
      email="rich2309@gmail.com"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -yq --no-install-recommends apt-utils \
  && apt-get install -yq davfs2 ca-certificates unison \
  && apt-get install -y gettext-base \
  && apt-get install -y fuse \
  && mkdir -p /mnt/webdrive \
  && apt-get clean \
  && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

COPY ./docker-entrypoint.sh /bin/entrypoint.sh
COPY ./default.prf /root/.unison/default.prf

ENTRYPOINT [ "/bin/entrypoint.sh" ]
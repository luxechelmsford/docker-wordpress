FROM ubuntu:20.04

LABEL maintainer "Richard Regeer" \
      email="rich2309@gmail.com"

RUN apt-get update \
  && apt-get install -y davfs2 ca-certificates unison \
  && apt-get install gettext-base \
  && mkdir -p /mnt/webdrive \
  && apt-get clean \
  && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

COPY ./docker-entrypoint.sh /bin/entrypoint.sh
COPY ./default.prf /root/.unison/default.prf

ENTRYPOINT [ "/bin/entrypoint.sh" ]
FROM ubuntu:20.04

LABEL maintainer "Richard Regeer" \
      email="rich2309@gmail.com"

RUN apt-get update \
  && apt-get install -y davfs2 ca-certificates unison \
  && apt-get install gettext-base \
  && apt-get clean \
  && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

COPY ./default.prf.template /root/.unison/default.prf.template
COPY docker-entrypoint.sh /bin/entrypoint.sh

ENTRYPOINT [ "entrypoint.sh" ]

#CMD cron -f && bash

FROM ubuntu:20.04

LABEL maintainer "Richard Regeer" \
      email="rich2309@gmail.com"

RUN apt-get update \
  && apt-get install -y davfs2 ca-certificates unison \
  && apt-get install gettext-base \
  && apt-get clean \
  && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* \
  && rm -f /etc/davfs2/secrets # We deleted this file in the image so we know
                               # if the file with correct secrets are copied in entrypoint.sh

COPY docker-entrypoint.sh /bin/entrypoint.sh

ENTRYPOINT [ "entrypoint.sh" ]

#CMD cron -f && bash

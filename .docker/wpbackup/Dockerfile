FROM ubuntu:20.04

RUN apt-get update && \
    apt-get install -y mysql-client cron bzip2 vim sudo gpg curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /bin/entrypoint.sh
COPY backup.sh restore.sh /bin/

ENTRYPOINT [ "entrypoint.sh" ]

CMD cron -f && bash

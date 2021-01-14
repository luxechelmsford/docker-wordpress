FROM ubuntu:20.04

RUN apt-get update && \
    apt-get install -y mysql-client cron bzip2 vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/backups/logs && \
    mkdir -p /var/backups/local

COPY docker-entrypoint.sh /bin/entrypoint.sh
COPY backup.sh restore.sh /bin/

ENTRYPOINT [ "entrypoint.sh" ]

CMD cron -f && bash

FROM ubuntu:20.04

RUN apt-get update && \
    apt-get install -y mysql-client cron bzip2 vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/backups/logs && \
    mkdir -p /var/backups/local

ENV WPBACKUP_TIME 0
ENV WPBACKUP_MYSQL_HOST mysql
ENV WPBACKUP_MYSQL_PORT 3306
ENV WPBACKUP_MYSQL_DATABASE demo
ENV WPBACKUP_MYSQL_USERNAME demo
ENV WPBACKUP_MYSQL_PASSWORD_FILE /run/secrets/demo
ENV WPBACKUP_WEBSITE_NAME demo

COPY docker-entrypoint.sh /bin/entrypoint.sh
COPY backup.sh restore.sh /bin/

ENTRYPOINT [ "entrypoint.sh" ]

CMD cron -f && bash

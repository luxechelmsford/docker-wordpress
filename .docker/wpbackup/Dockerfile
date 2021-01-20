 If base image is changed, please consider the 
FROM ubuntu:20.04

RUN apt-get update \
    && apt-get install -y mysql-client cron bzip2 vim sudo gpg curl unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    #&& groupmod -g 82 www-data # the www-data on this image is 33
    #                           # which cause an issue when file permission of wp-content are changed in this container
    #&& find / -gid 33 ! -type l -exec chgrp 82 {}

COPY docker-entrypoint.sh /bin/entrypoint.sh
COPY backup.sh restore.sh /bin/

ENTRYPOINT [ "entrypoint.sh" ]

CMD cron -f && bash
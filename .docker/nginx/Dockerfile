FROM nginx:1.17-alpine
# Install packages
RUN apk --update --no-cache add certbot certbot-nginx redis bash

RUN mkdir /etc/letsencrypt && mkdir -p /var/www/cache \
    && mkdir -p /etc/nginx/snippets && mkdir -p /var/log/certboot

COPY conf.d   /etc/nginx/conf.d
COPY snippets /etc/nginx/snippets
COPY cron-task.txt /cron-task.txt
COPY docker-entrypoint.sh /bin/entrypoint.sh
COPY redis/redis.conf /etc/redis.conf

RUN usr/bin/crontab /cron-task.txt && rm -f /cron-task.txt

ENTRYPOINT [ "entrypoint.sh" ]
CMD ["nginx", "-g", "daemon off;"]
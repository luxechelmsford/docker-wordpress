FROM nginx:1.17-alpine
# Install packages
RUN apk --update --no-cache add certbot certbot-nginx redis bash

RUN mkdir /etc/letsencrypt && mkdir -p /var/www/cache \
    && mkdir -p /etc/nginx/snippets && mkdir -p /var/log/certboot

COPY ./configs/snippets /etc/nginx/snippets
COPY ./configs/redis.conf /etc/redis.conf
COPY ./docker-entrypoint.sh /bin/entrypoint.sh

#RUN usr/bin/crontab /cron-task.txt && rm -f /cron-task.txt

ENTRYPOINT [ "entrypoint.sh" ]
CMD ["nginx", "-g", "daemon off;"]
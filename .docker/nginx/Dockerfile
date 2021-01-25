FROM nginx:1.17-alpine
# Install packages
RUN apk --update --no-cache add certbot certbot-nginx redis bash

RUN mkdir /etc/letsencrypt && mkdir -p /var/www/cache \
    && mkdir -p /etc/nginx/snippets

COPY ./configs/snippets /etc/nginx/snippets
COPY ./configs/redis.conf /etc
COPY ./configs/templates /etc/nginx/templates/
COPY ./docker-entrypoint.sh /bin/entrypoint.sh

ENTRYPOINT [ "entrypoint.sh" ]
CMD ["nginx", "-g", "daemon off;"]
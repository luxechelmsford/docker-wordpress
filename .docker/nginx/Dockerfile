FROM nginx:1.17-alpine
# Install packages
RUN apk --update --no-cache add certbot certbot-nginx bash

RUN mkdir /etc/letsencrypt

COPY ./conf.d/wordpress.conf.template  /etc/nginx/conf.d/wordpress.conf.template
COPY ./conf.d/phpmyadmin.conf.template /etc/nginx/conf.d/phpmyadmin.conf.template
COPY ./conf.d/certboot.conf.template /etc/nginx/conf.d/certboot.conf.template
COPY docker-entrypoint.sh /bin/entrypoint.sh

ENTRYPOINT [ "entrypoint.sh" ]
CMD ["nginx", "-g", "daemon off;"]
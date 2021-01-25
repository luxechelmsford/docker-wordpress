FROM alpine:3.13.0

RUN apk --update --no-cache add vsftpd bash

COPY ./docker-entrypoint.sh /bin/entrypoint.sh
COPY ./vsftpd.conf /etc/vsftpd/vsftpd.conf

EXPOSE 21 21000-21010

ENTRYPOINT ["/bin/entrypoint.sh"]
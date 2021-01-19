FROM mysql:8.0.22

LABEL maintainer "Pankaj Jain" \
      email="thetekltd@gmail.com"

COPY ./docker-entrypoint.sh /docker-entrypoint-initdb.d
RUN touch /etc/mysql/conf.d/my.cnf && chmod 664 /etc/mysql/conf.d/my.cnf && chown mysql:root /etc/mysql/conf.d/my.cnf
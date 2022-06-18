FROM docker.io/yidigun/ubuntu-build:22.04 AS build

ARG IMG_NAME
ARG IMG_TAG

ENV IMG_NAME=$IMG_NAME
ENV IMG_TAG=$IMG_TAG

# Download source, apply patch and install dependencies.
COPY bind9-dlz-mariadb-module.patch /tmp
RUN apt-get -y update && \
    apt-get -y install libmariadb-dev && \
    (cd /usr/include; ln -s mariadb mysql) && \
    (mkdir -p /tmp/bind9 && \
    cd /tmp/bind9 && \
    apt-get -y source bind9) && \
    (cd `find /tmp/bind9 -type d -name "bind9-*"`/contrib/dlz/modules/mysql && \
    patch -p1 < /tmp/bind9-dlz-mariadb-module.patch && \
    make && \
    make install)

FROM docker.io/yidigun/ubuntu-base:22.04 AS product

ARG IMG_NAME
ARG IMG_TAG

ENV IMG_NAME=$IMG_NAME
ENV IMG_TAG=$IMG_TAG

ENV MYSQL_HOST=localhost
ENV MYSQL_PORT=3306
ENV MYSQL_USERNAME=named
ENV MYSQL_PASSWORD=named
ENV MYSQL_DBNAME=named

RUN apt-get -y update && \
    apt-get -y install libmariadb3 bind9 bind9-libs bind9-utils bind9-dnsutils && \
    apt-get clean
COPY --from=build /usr/lib/bind9 /usr/lib/bind9
COPY entrypoint.sh /entrypoint.sh
COPY named.conf.dlz-mariadb.in /etc/bind/named.conf.dlz-mariadb.in

EXPOSE 53/tcp
EXPOSE 53/udp
VOLUME /var/cache/bind
VOLUME /var/lib/bind

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "run" ]

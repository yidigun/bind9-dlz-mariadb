FROM docker.io/yidigun/ubuntu-build:22.04 AS build

ARG IMG_NAME
ARG IMG_TAG

ENV IMG_NAME=$IMG_NAME
ENV IMG_TAG=$IMG_TAG

# Download source, apply patch and install dependencies.
COPY bind9-dlz-mariadb.patch /tmp
RUN apt-get update && \
    mkdir -p /tmp/bind9 && \
    chown _apt:nogroup /tmp/bind9 && \
    cd /tmp/bind9 && \
    su -s /bin/bash _apt -c ' \
        apt-get -y source bind9 && \
        cd `find /tmp/bind9 -mindepth 1 -maxdepth 1 -type d -name "bind9*"` && \
        patch -p1 </tmp/bind9-dlz-mariadb.patch' && \
    cd `find /tmp/bind9 -mindepth 1 -maxdepth 1 -type d -name "bind9*"` && \
    DEBIAN_FRONTEND=noninteractive \
      apt-get -y --fix-missing install `dpkg-checkbuilddeps 2>&1 | sed -e 's/^.*://' -e 's/([^)]*)//g'` && \
    apt-get clean

# Do build
ENV MYSQL_CONFIG=/usr/bin/mariadb_config
RUN su -s /bin/bash _apt -c ' \
    srcdir=`find /tmp/bind9 -mindepth 1 -maxdepth 1 -type d -name "bind9*" | head -1`;  \
    echo $srcdir; \
    cd $srcdir; \
    dpkg-buildpackage \
      --build=binary \
      -e"Daekyu Lee <dklee@yidigun.com>"'

# Collect packages
RUN mkdir -p /tmp/deb && \
    cp /tmp/bind9/bind9_*.deb \
       /tmp/bind9/bind9-libs_*.deb \
       /tmp/bind9/bind9-utils_*.deb \
       /tmp/bind9/bind9-dnsutils_*.deb \
       /tmp/bind9/bind9-host_*.deb \
       /tmp/deb

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
    DEBIAN_FRONTEND=noninteractive \
      apt-get -y install \
        adduser debconf dns-root-data iproute2 libc6 libcap2 libedit2 libgssapi-krb5-2 libidn2-0 \
        libjson-c5 libkrb5-3 liblmdb0 libmaxminddb0 libnghttp2-14 libssl3 libuv1 libxml2 lsb-base \
        netbase zlib1g libmariadb3 && \
    apt-get clean
COPY --from=build /tmp/deb /tmp/deb
RUN dpkg -i /tmp/deb/*.deb && \
    apt-mark hold bind9 && \
    mkdir -p /run/named && \
    chown bind:bind /run/named && \
    rm -rf /tmp/deb

COPY entrypoint.sh /entrypoint.sh
COPY named.conf.dlz-mariadb.in /etc/bind/named.conf.dlz-mariadb.in

EXPOSE 53/tcp
EXPOSE 53/udp
VOLUME /var/cache/bind
VOLUME /var/lib/bind

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "run" ]

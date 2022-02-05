ARG IMG_NAME
ARG IMG_TAG
ARG LANG=ko_KR.UTF-8
ARG TZ=Asia/Seoul

FROM docker.io/yidigun/ubuntu-build:20.04 AS build

ENV LANG=$LANG
ENV TZ=$TZ

# Download source, apply patch and install dependencies.
COPY bind9-dlz-mariadb.patch /tmp
RUN mkdir -p /tmp/bind9 && \
    chown _apt:nogroup /tmp/bind9 && \
    cd /tmp/bind9 && \
    su -s /bin/bash _apt -c ' \
        apt-get -y source bind9 && \
        cd `find /tmp/bind9 -mindepth 1 -maxdepth 1 -type d -name "bind9*"` && \
        patch -p1 </tmp/bind9-dlz-mariadb.patch' && \
    cd `find /tmp/bind9 -mindepth 1 -maxdepth 1 -type d -name "bind9*"` && \
    DEBIAN_FRONTEND=noninteractive \
      apt-get -y install `dpkg-checkbuilddeps 2>&1 | sed -e 's/^.*://' -e 's/([^)]*)//g'` && \
    apt-get clean

# Do build
RUN cd `find /tmp/bind9 -mindepth 1 -maxdepth 1 -type d -name "bind9*"` && \
    MYSQL_CONFIG=/usr/bin/mariadb_config \
      su -s /bin/bash _apt -c ' \
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

FROM docker.io/yidigun/ubuntu-base:20.04 AS product

ENV IMG_NAME=$IMG_NAME
ENV IMG_TAG=$IMG_TAG
ENV LANG=$LANG
ENV TZ=$TZ
ENV MYSQL_HOST=localhost
ENV MYSQL_PORT=3306
ENV MYSQL_USERNAME=named
ENV MYSQL_PASSWORD=named
ENV MYSQL_DBNAME=named

RUN apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive \
      apt-get -y install \
        dns-root-data iproute2 netbase libmariadb3 libcap2 libjson-c4 liblmdb0 libmaxminddb0 \
        libssl1.1 libxml2 libgssapi-krb5-2 libkrb5-3 libuv1 libedit2 python3-ply && \
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

#!/bin/bash

# try to set locale and timezone
if locale -a 2>/dev/null | grep -q "$LANG"; then
  : do nothing
else
  locale-gen $LANG 2>/dev/null
  update-locale LANG=$LANG 2>/dev/null
fi
if [ -n "$TZ" -a -f /usr/share/zoneinfo/$TZ ]; then
  ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
fi

user=bind

# mysql driver is not thread-safe, so threads must set to 1 !!
# see http://bind-dlz.sourceforge.net/mysql_driver.html
threads=1
bind_opts="-n$threads -u$user -g"

config_dir=/etc/bind

MYSQL_HOST=${MYSQL_HOST:-localhost}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_USERNAME=${MYSQL_USERNAME:-named}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-named}
MYSQL_DBNAME=${MYSQL_DBNAME:-named}

CMD=$1; shift
case $CMD in
  start|run)
    sed \
      -e "s/MYSQL_HOST/$MYSQL_HOST/g" \
      -e "s/MYSQL_PORT/$MYSQL_PORT/g" \
      -e "s/MYSQL_USERNAME/$MYSQL_USERNAME/g" \
      -e "s/MYSQL_PASSWORD/$MYSQL_PASSWORD/g" \
      -e "s/MYSQL_DBNAME/$MYSQL_DBNAME/g" \
      $config_dir/named.conf.dlz-mariadb.in >$config_dir/named.conf.dlz-mariadb
    exec /usr/sbin/named $bind_opts "$@"
    ;;

  rndc|/usr/sbin/rndc)
    exec /usr/sbin/rndc "$@"
    ;;

  sh|bash|/bin/sh|/bin/bash)
    exec /bin/bash "$@"
    ;;

  *)
    echo "usage: $0 { run [ ARGS ... ] | sh [ ARGS ... ] | rndc [ ARGS ... ] }"
    ;;
esac

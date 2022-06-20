#!/bin/sh

# try to set locale and timezone
if locale -a 2>/dev/null | grep -q "$LANG"; then :
else
  locale-gen $LANG 2>/dev/null
  update-locale LANG=$LANG 2>/dev/null
fi
if [ -n "$TZ" ] && [ -f /usr/share/zoneinfo/$TZ ]; then
  ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
fi

user=bind
group=bind
config_dir=/etc/bind

# check runtime dirs
for d in /run/named /var/cache/bind /var/lib/bind; do
  if [ ! -d $d ]; then
    mkdir -p $d
  fi
  if [ ! -w $d ]; then
    chown -R $user:$group $d
  fi
done

MYSQL_HOST=${MYSQL_HOST:-localhost}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_USERNAME=${MYSQL_USERNAME:-named}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-named}
MYSQL_DBNAME=${MYSQL_DBNAME:-named}

# mysql driver is not thread-safe, so threads must set to 1 !!
# see http://bind-dlz.sourceforge.net/mysql_driver.html
# But, mariadb client library is thread-safe by default.
if [ -n "$BIND_THREADS" ]; then
  threads=$BIND_THREADS
else
  cpus=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null)
  threads=$(expr "$cpus" / 2)
fi
bind_opts="-n$threads -u$user -g"

# generate dlz config
if [ ! -f $config_dir/named.conf.dlz-mariadb ]; then
  sed \
    -e "s/MYSQL_HOST/$MYSQL_HOST/g" \
    -e "s/MYSQL_PORT/$MYSQL_PORT/g" \
    -e "s/MYSQL_USERNAME/$MYSQL_USERNAME/g" \
    -e "s/MYSQL_PASSWORD/$(echo "$MYSQL_PASSWORD" | sed -e 's!/!\\\\/!')/g" \
    -e "s/MYSQL_DBNAME/$MYSQL_DBNAME/g" \
    $config_dir/named.conf.dlz-mariadb.in >$config_dir/named.conf.dlz-mariadb
fi
if grep -q 'named.conf.dlz-mariadb' $config_dir/named.conf >/dev/null 2>&1; then :
else
  echo "include \"$config_dir/named.conf.dlz-mariadb\";" >>$config_dir/named.conf
fi

CMD=$1; shift
case $CMD in
  start|run)
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

# BIND9 with DLZ Mariadb plugin

## Bind 9 DLZ License

See http://bind-dlz.sourceforge.net/mysql_driver.html and http://bind-dlz.sourceforge.net/license.html

## Bind 9 License

See https://www.isc.org/bind/ and https://www.mozilla.org/en-US/MPL/2.0/

## Dockerfile License

It's just free. (Public Domain)

See https://github.com/yidigun/bind9-dlz-mariadb

## Changelog

* 2022-06-18 - Upgrade base image 20.04 to 22.04 and ```bind``` upgraded to 9.18.
* 2022-02-18 - Change default locale to en_US.UTF-8, timezone to UTC.
               Locale and timezone is set automatically according to
               ```$LANG``` and ```$TZ``` envoringment variables.

## Use Image

### 1. Prepare Database

See mariadb schema [sql/mariadb-schema.sql](https://github.com/yidigun/bind9-dlz-mariadb/blob/master/sql/mariadb-schema.sql)
and [sql/mariadb-example.sql](https://github.com/yidigun/bind9-dlz-mariadb/blob/master/sql/mariadb-example.sql).

#### ER-Diagram

See [https://www.erdcloud.com/d/ZzZmex5p3cWFo7xpx](https://www.erdcloud.com/d/ZzZmex5p3cWFo7xpx).

![ERD](docs/erd-bind9-dlz-mariadb.png)

### 2. Run Daemon

```shell
docker run -d \
  --name bind9-named \
  -e LANG=ko_KR.UTF-8 \
  -e TZ=Asia/Seoul \
  -e MYSQL_HOST=dbserver \
  -e MYSQL_PORT=3306 \
  -e MYSQL_USERNAME=named \
  -e MYSQL_PASSWORD=dns11 \
  -e MYSQL_DBNAME=domaindb \
  -p 53:53/tcp \
  -p 53:53/udp \
  yidigun/bind9-dlz-mariadb
```

#### docker-compose.yaml

```yaml
version: "3.9"

services:
  bind9:
    container_name: bind9-named
    image: docker.io/yidigun/bind9-dlz-mariadb:latest
    restart: unless-stopped
    ports:
      - "53:53/udp"
      - "53:53/tcp"
    environment:
      - TZ=Asia/Seoul
      - LANG=ko_KR.UTF-8
      - MYSQL_HOST=dbserver
      - MYSQL_PORT=3306
      - MYSQL_USERNAME=named
      - MYSQL_PASSWORD=dns11
      - MYSQL_DBNAME=domaindb
    volumes:
      - ${PWD}/cache:/var/cache/bind
      - ${PWD}/data:/var/lib/bind
```

### 3. rndc utility

```shell
docker exec bind9-named rndc reload
```

### 4. Tuning sql query

You have two choice, that combine to one or split third and fourth query({}).
It's difficult to determine which one is better for database performance.

#### 1. lookup() for all

This one makes query more heavy, but make less queries to db.
A DNS lookup makes 2 queries: ```lookup($zone$, @)``` and ```lookup($zone$, $record$)```.

```
    {/* lookup_all($zone$, $record$) */
     SELECT IFNULL(R.ttl, S.ttl) ttl, R.`type`, R.mx_priority, (CASE R.`type`
            WHEN 'SOA' THEN CONCAT_WS(' ', S.origin, S.email, S.serial, S.refresh, S.retry, S.expire, S.minimum)
            WHEN 'TXT' THEN CONCAT('\"', R.`data`, '\"') ELSE R.`data` END) `data`
       FROM (SELECT S1.ttl, S1.origin, S1.email, S1.refresh, S1.retry, S1.expire, S1.minimum,
                    IFNULL(V1.serial, CAST(CONCAT(DATE_FORMAT(CURDATE(), '%Y%m%d'), '01') AS DECIMAL)) serial
               FROM zone_soa S1 LEFT OUTER JOIN zone_serial V1 ON (S1.`zone` = V1.`zone`)
              WHERE S1.`zone` = '$zone$' AND S1.deleted <> 'Y'
             UNION ALL
             SELECT S2.ttl, S2.origin, S2.email, S2.refresh, S2.retry, S2.expire, S2.minimum,
                    IFNULL(V2.serial, CAST(CONCAT(DATE_FORMAT(CURDATE(), '%Y%m%d'), '01') AS DECIMAL)) serial
               FROM zone_soa S2 LEFT OUTER JOIN zone_serial V2 ON (S2.`zone` = V2.`zone`)
              WHERE S2.`zone` = '*' AND S2.deleted <> 'Y'
                AND NOT EXISTS (SELECT 1 FROM zone_soa WHERE `zone` = '$zone$' AND deleted <> 'Y')) S,
            (SELECT '$zone$' zone, '@' name, 'SOA' type, NULL data, NULL mx_priority, NULL ttl, 1 odr
              WHERE '$record$' = '@'
             UNION ALL
             SELECT R1.`zone`, R1.name, R1.`type`, R1.`data`, R1.mx_priority, R1.ttl, 3 odr
               FROM zone_record R1
              WHERE R1.`zone` = '$zone$' AND R1.name = '$record$' AND R1.deleted <> 'Y'
             UNION ALL
             SELECT '$zone$' `zone`, '$record$' name, 'NS' `type`, R2.`data`, NULL mx_priority, R2.ttl, 2 odr
               FROM zone_record R2
              WHERE '$record$' = '@' AND R2.`zone` = '*' AND R2.name = '@' AND R2.`type` = 'NS' AND R2.deleted <> 'Y'
                AND NOT EXISTS (SELECT 1 FROM zone_record WHERE `zone` = '$zone$'
                                AND name = '@' and `type` = 'NS' AND deleted <> 'Y' LIMIT 1)) R
     ORDER BY R.odr ASC, R.`type`, R.mx_priority, RAND()}
    {}
```

#### 2. split lookup() and authority()

This one makes query light a little bit, but makes more queries to db.

A single DNS lookup makes 3 queries: ```lookup($zone$, @)```, ```authority($zone$)``` and ```lookup($zone$, $record$)```.

```
    {/* lookup($zone$, $record$) */
     SELECT IFNULL(R.ttl, S.ttl) ttl, R.`type`, R.mx_priority, (CASE R.`type`
            WHEN 'TXT' THEN CONCAT('\"', R.`data`, '\"') ELSE R.`data` END) `data`
       FROM (SELECT S1.ttl FROM zone_soa S1 WHERE S1.`zone` = '$zone$' AND S1.deleted <> 'Y'
             UNION ALL
             SELECT S2.ttl FROM zone_soa S2 WHERE S2.`zone` = '*' AND S2.deleted <> 'Y'
                AND NOT EXISTS (SELECT 1 FROM zone_soa WHERE `zone` = '$zone$' AND deleted <> 'Y')) S,
            (SELECT R1.`zone`, R1.name, R1.`type`, R1.`data`, R1.mx_priority, R1.ttl
               FROM zone_record R1
              WHERE R1.`zone` = '$zone$' AND R1.name = '$record$' AND R1.type <> 'NS' AND R1.deleted <> 'Y') R
     ORDER BY R.`type`, R.mx_priority, RAND()}
    {/* authority($zone$) */
     SELECT IFNULL(R.ttl, S.ttl) ttl, R.`type`, NULL mx_priority,
            (CASE R.`type` WHEN 'SOA' THEN S.origin ELSE R.`data` END) `data`,
            (CASE R.`type` WHEN 'SOA' THEN S.email ELSE NULL END) resp_person,
            (CASE R.`type` WHEN 'SOA' THEN S.serial ELSE NULL END) serial,
            (CASE R.`type` WHEN 'SOA' THEN S.refresh ELSE NULL END) refresh,
            (CASE R.`type` WHEN 'SOA' THEN S.retry ELSE NULL END) retry,
            (CASE R.`type` WHEN 'SOA' THEN S.expire ELSE NULL END) expire,
            (CASE R.`type` WHEN 'SOA' THEN S.minimum ELSE NULL END) minimum
       FROM (SELECT S1.ttl, S1.origin, S1.email, S1.refresh, S1.retry, S1.expire, S1.minimum,
                    IFNULL(V1.serial, CAST(CONCAT(DATE_FORMAT(CURDATE(), '%Y%m%d'), '01') AS DECIMAL)) serial
               FROM zone_soa S1 LEFT OUTER JOIN zone_serial V1 ON (S1.`zone` = V1.`zone`)
              WHERE S1.`zone` = '$zone$' AND S1.deleted <> 'Y'
             UNION ALL
             SELECT S2.ttl, S2.origin, S2.email, S2.refresh, S2.retry, S2.expire, S2.minimum,
                    IFNULL(V2.serial, CAST(CONCAT(DATE_FORMAT(CURDATE(), '%Y%m%d'), '01') AS DECIMAL)) serial
               FROM zone_soa S2 LEFT OUTER JOIN zone_serial V2 ON (S2.`zone` = V2.`zone`)
              WHERE S2.`zone` = '*' AND S2.deleted <> 'Y'
                AND NOT EXISTS (SELECT 1 FROM zone_soa WHERE `zone` = '$zone$' AND deleted <> 'Y')) S,
            (SELECT '$zone$' zone, '@' name, 'SOA' type, NULL data, NULL mx_priority, NULL ttl, 1 odr
             UNION ALL
             SELECT R1.`zone`, '@' name, 'NS' `type`, R1.`data`, NULL mx_priority, R1.ttl, 3 odr
               FROM zone_record R1
              WHERE R1.`zone` = '$zone$' AND R1.name = '@' AND R1.`type` = 'NS' AND R1.deleted <> 'Y'
             UNION ALL
             SELECT '$zone$' `zone`, '@' name, 'NS' `type`, R2.`data`, NULL mx_priority, R2.ttl, 2 odr
               FROM zone_record R2
              WHERE R2.`zone` = '*' AND R2.name = '@' AND R2.`type` = 'NS' AND R2.deleted <> 'Y'
                AND NOT EXISTS (SELECT 1 FROM zone_record WHERE `zone` = '$zone$'
                                AND name = '@' and `type` = 'NS' AND deleted <> 'Y' LIMIT 1)) R
     ORDER BY R.odr ASC, R.`type`, R.mx_priority, RAND()}
```

## Build Image

```shell
make test   # build single-arch image using docker build for testing
make TAG=... PUSH={yes|no} # build multi-arch image using docker buildx 
```

DROP TABLE IF EXISTS zone_serial CASCADE;
DROP TABLE IF EXISTS zone_soa CASCADE;
DROP TABLE IF EXISTS zone_stat CASCADE;
DROP TABLE IF EXISTS zone_record CASCADE;
DROP TABLE IF EXISTS zone_authority CASCADE;

CREATE TABLE zone_authority (
    zone            VARCHAR(255) NOT NULL                   COMMENT 'Zone name or "*" (PK)',
    owner_name      VARCHAR(255) NOT NULL                   COMMENT 'Owner of zone (maybe corp. name), not for DNS records',
    admin_name      VARCHAR(255) NOT NULL                   COMMENT 'Admin of zone (maybe tech. officer), not for DNS records',
    admin_email     VARCHAR(255) NOT NULL                   COMMENT 'Email of admin, not for DNS records',
    memo            TEXT,
    create_id       VARCHAR(100) NOT NULL,
    create_dt       DATETIME     NOT NULL,
    update_id       VARCHAR(100) NOT NULL,
    update_dt       DATETIME     NOT NULL,
    deleted         CHAR(1)      NOT NULL DEFAULT 'N',
    delete_id       VARCHAR(100) NULL,
    delete_dt       DATETIME     NULL,
    PRIMARY KEY (zone)
)
COMMENT 'Zone list this nameserver has authority.';

CREATE TABLE zone_serial (
    zone            VARCHAR(255) NOT NULL 	                COMMENT 'Zone name (PK, FK)',
    serial          BIGINT       NOT NULL DEFAULT 1         COMMENT 'Version no. (3rd field of SOA data)',
    create_id       VARCHAR(100) NOT NULL,
    create_dt       DATETIME     NOT NULL,
    update_id       VARCHAR(100) NOT NULL,
    update_dt       DATETIME     NOT NULL,
    PRIMARY KEY (zone),
    CONSTRAINT fk_zone_serial_zone FOREIGN KEY (zone) REFERENCES zone_authority (zone)
        ON DELETE CASCADE ON UPDATE RESTRICT
)
COMMENT 'Zone serial (3rd field of SOA data)';

CREATE TABLE zone_stat (
    zone            VARCHAR(255) NOT NULL 	                COMMENT 'Zone name (PK,FK)',
    date            DATE         NOT NULL                   COMMENT 'Date (PK)',
    count           INT          NOT NULL DEFAULT 0         COMMENT 'Counts of findzone() called',
    PRIMARY KEY (zone, date),
    CONSTRAINT fk_zone_stat_zone FOREIGN KEY (zone) REFERENCES zone_authority (zone)
       ON DELETE CASCADE ON UPDATE RESTRICT
)
COMMENT 'Zone retrieve count statistics';

CREATE TABLE zone_soa (
    zone            VARCHAR(255) NOT NULL                   COMMENT 'Zone name (PK)',
    origin          VARCHAR(255) NOT NULL                   COMMENT 'Primary nameserver (1st field of SOA data)',
    email           VARCHAR(255) NOT NULL                   COMMENT 'Email of the person in charge (2nd field of SOA data)',
    refresh         INT          NOT NULL DEFAULT 3600      COMMENT 'Slave refresh how often, in seconds (4th field of SOA data)',
    retry           INT          NOT NULL DEFAULT 120       COMMENT 'Slave retry how long after transfer failure, in seconds (5th field of SOA data)',
    expire          INT          NOT NULL DEFAULT 604800    COMMENT 'Slave use without update how long before expire it, in seconds (6th field of SOA data)',
    minimum         INT          NOT NULL DEFAULT 60        COMMENT 'Default TTL, in seconds (applied for record not found, 7th field of SOA data)',
    ttl             INT          NOT NULL                   COMMENT 'TTL of SOA record, this assume as default TTL for all records',
    create_id       VARCHAR(100) NOT NULL,
    create_dt       DATETIME     NOT NULL,
    update_id       VARCHAR(100) NOT NULL,
    update_dt       DATETIME     NOT NULL,
    deleted         CHAR(1)      NOT NULL DEFAULT 'N',
    delete_id       VARCHAR(100) NULL,
    delete_dt       DATETIME     NULL,
    PRIMARY KEY (zone)
)
COMMENT 'SOA record data, if not exists then try zone=*';

CREATE TABLE zone_record (
    record_id       BIGINT AUTO_INCREMENT                   COMMENT 'Record id (PK)',
    zone            VARCHAR(255) NOT NULL                   COMMENT 'Zone name (FK)',
    name            VARCHAR(255) NOT NULL                   COMMENT 'Host Name',
    type            VARCHAR(255) NOT NULL                   COMMENT 'Record type',
    data            TEXT         NULL                       COMMENT 'Record data',
    mx_priority     INT          NULL                       COMMENT 'Priority of mail exchanger (MX only)',
    ttl             INT          NULL                       COMMENT 'TTL of this record (default: ttl of SOA)',
    memo            TEXT         NULL,
    create_id       VARCHAR(100) NOT NULL,
    create_dt       DATETIME     NOT NULL,
    update_id       VARCHAR(100) NOT NULL,
    update_dt       DATETIME     NOT NULL,
    deleted         CHAR(1)      NOT NULL DEFAULT 'N',
    delete_id       VARCHAR(100) NULL,
    delete_dt       DATETIME     NULL,
    PRIMARY KEY (record_id),
    KEY ix_zone_record_01 (zone, name, type),
    KEY ix_zone_record_02 (zone, type, name)
)
COMMENT 'All records of Zone (except SOA), if not exists then try zone=* or name=*';

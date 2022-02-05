TRUNCATE TABLE zone_stat;
TRUNCATE TABLE zone_serial;
TRUNCATE TABLE zone_soa;
TRUNCATE TABLE zone_record;
DELETE FROM zone_authority WHERE 1=1;

-- default values
INSERT INTO zone_soa (
    zone, origin, email, refresh, retry, expire, minimum, ttl,
    create_id, create_dt, update_id, update_dt, deleted, delete_id, delete_dt
) VALUES (
    '*', 'ns.example.com.', 'admin.example.com.', 3600, 120, 604800, 60, 3600,
    'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL
);

INSERT INTO zone_record (
    record_id, zone, name, type, data, mx_priority, ttl, memo,
    create_id, create_dt, update_id, update_dt, deleted, delete_id, delete_dt
) VALUES
(NULL, '*', '@', 'NS', 'ns1.example.com.', NULL, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL),
(NULL, '*', '@', 'NS', 'ns2.example.com.', NULL, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
;

-- example.com
INSERT INTO zone_authority (
    zone, owner_name, admin_name, admin_email, memo,
    create_id, create_dt, update_id, update_dt, deleted, delete_id, delete_dt
) VALUES
 ('example.com', 'Example Corp.', 'Mr. Example', 'ex@example.com', NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
,('example.io', 'Example Corp.', 'Mr. Example', 'ex@example.com', NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
;

INSERT INTO zone_serial (zone, serial, create_id, create_dt, update_id, update_dt) VALUES
('example.com', CAST(CONCAT(DATE_FORMAT(CURDATE(), '%Y%m%d'), '01') AS DECIMAL), 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE())
,('example.io', CAST(CONCAT(DATE_FORMAT(CURDATE(), '%Y%m%d'), '01') AS DECIMAL), 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE())
;

INSERT INTO zone_record (
    record_id, zone, name, type, data, mx_priority, ttl, memo,
    create_id, create_dt, update_id, update_dt, deleted, delete_id, delete_dt
) VALUES
 (NULL, 'example.com', '*', 'A', '1.2.3.4', NULL, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
,(NULL, 'example.io', '*', 'A', '1.2.3.4', NULL, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
,(NULL, 'example.com', '@', 'MX', 'aspmx.l.google.com.', 1, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
,(NULL, 'example.com', '@', 'MX', 'alt1.aspmx.l.google.com.', 5, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
,(NULL, 'example.com', '@', 'MX', 'alt2.aspmx.l.google.com.', 5, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
,(NULL, 'example.com', '@', 'MX', 'aspmx2.googlemail.com.', 10, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
,(NULL, 'example.com', '@', 'MX', 'aspmx3.googlemail.com.', 10, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
,(NULL, 'example.com', '@', 'TXT', 'v=spf1 include:_spf.google.com ~all', NULL, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
,(NULL, 'yidigun.com', 'ns1', 'A', '8.8.8.8', NULL, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
,(NULL, 'yidigun.com', 'ns2', 'A', '8.8.4.4', NULL, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
,(NULL, 'yidigun.com', 'ns', 'CNAME', 'ns1.example.com.', NULL, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
,(NULL, 'yidigun.com', '_domain._tcp', 'SRV', '0 50 53 ns1.example.com.', NULL, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
,(NULL, 'yidigun.com', '_domain._tcp', 'SRV', '0 50 53 ns2.example.com.', NULL, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
,(NULL, 'yidigun.com', '_domain._udp', 'SRV', '0 50 53 ns1.example.com.', NULL, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
,(NULL, 'yidigun.com', '_domain._udp', 'SRV', '0 50 53 ns2.example.com.', NULL, NULL, NULL, 'SYSTEM', SYSDATE(), 'SYSTEM', SYSDATE(), 'N', NULL, NULL)
;


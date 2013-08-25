-- Create a lung-logger user and give him grants to insert and select from previous log messages
-- used 'lung-logger' as username because it's harder to guess.
-- @author rajat.banerjee
-- @version 0.1

CREATE USER 'lung-logger'@'localhost' IDENTIFIED BY 'changeme';

-- SET PASSWORD FOR 'lung-logger'@'localhost' = PASSWORD('newpass');

GRANT SELECT ON lung.logs TO 'lung-logger'@'localhost';
GRANT INSERT ON lung.logs to 'lung-logger'@'localhost';

-- Consider - IP range blocking here -- only EC2. Input the US East IP and netmask below.
-- GRANT SELECT ON lung.logs TO 'lung-logger'@'192.58.197.0/255.255.255.0';
-- GRANT UPDATE ON lung.logs TO 'lung-logger'@'192.58.197.0/255.255.255.0';
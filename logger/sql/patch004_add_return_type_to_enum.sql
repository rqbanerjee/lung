-- add return_code to enum for log_level
-- @author rajat.banerjee
-- @version 0.1

-- before using: "use <database_name>;"
-- Raj's is called lung

ALTER TABLE logs CHANGE log_level log_level ENUM('debug','info','warn','error','fatal','return_code') not null;

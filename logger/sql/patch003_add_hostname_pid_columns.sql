-- Add a column to capture hostname-pid from running jobs
-- @author rajat.banerjee
-- @version 0.1

-- before using: "use <database_name>;"
-- Raj's is called lung

alter table logs
  add column hostname varchar(255),
  add column pid int unsigned;

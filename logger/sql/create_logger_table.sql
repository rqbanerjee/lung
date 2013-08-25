-- Create a logging table to receive results from remote processes processing jobs
-- @author rajat.banerjee
-- @version 0.1

-- before using: "use <database_name>;"
-- mine is called lung
use lung;

create table if not exists logs (
  id                  int unsigned auto_increment not null primary key,
  log_level           enum('debug','info','warn','error','fatal') not null,
  entity              varchar(255) DEFAULT 'none',
  message             varchar(255) not null,

  -- what other metadata would be useful ? Q to Ed and Jennifer.

  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
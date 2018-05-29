DROP TABLE IF EXISTS import_log;
CREATE TABLE import_log (
  id       SERIAL,
  new_id   INT,
  old_id   INT,
  lib_name TEXT,
  params   JSON,
  history  JSON
);
DROP FOREIGN TABLE IF EXISTS remote_menupohi;
CREATE FOREIGN TABLE remote_menupohi(

    id INTEGER NOT NULL,
    pad        TEXT      ,
    bar        TEXT      ,
    idx        INTEGER   ,
    properties JSONB,
    status     text
    )
    SERVER db_test
    OPTIONS (SCHEMA_NAME 'ou', TABLE_NAME 'menupohi');


select * from remote_menupohi
ORDER BY id desc limit 100

INSERT into ou.menupohi (pad, bar, idx, properties, status)
select pad, bar, idx, properties, 'active'
from remote_menupohi
where id >= 685
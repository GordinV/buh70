/*
CREATE FOREIGN TABLE remote_toograf (

  id       SERIAL                                         NOT NULL,
  lepingid INTEGER DEFAULT 0                              NOT NULL,
  kuu      INTEGER DEFAULT month(('now' :: TEXT) :: DATE) NOT NULL,
  aasta    INTEGER DEFAULT year(('now' :: TEXT) :: DATE)  NOT NULL,
  muud     TEXT,
  tund     NUMERIC(12, 4) DEFAULT 0
)

SERVER db_narva_ee
OPTIONS (schema_name 'public', table_name 'toograf');
*/

INSERT INTO palk.toograf (lepingid, kuu, aasta, tund, muud)
  SELECT
    i.new_id,
    g.kuu,
    g.aasta,
    g.tund,
    g.muud
  FROM remote_toograf g
    INNER JOIN tooleping t ON t.id = g.lepingid
    INNER JOIN import_log i ON i.old_id = t.id AND i.lib_name = 'TOOLEPING'
  WHERE g.aasta >= 2017
  LIMIT ALL;

DROP FOREIGN TABLE IF EXISTS remote_palk_jaak;

/*
CREATE FOREIGN TABLE remote_palk_jaak (
    id INTEGER NOT NULL,
    lepingid INTEGER DEFAULT 0 NOT NULL,
    kuu SMALLINT DEFAULT 1 NOT NULL,
    aasta SMALLINT DEFAULT year() NOT NULL,
    jaak NUMERIC(12, 4) DEFAULT 0 NOT NULL,
    arvestatud NUMERIC(12, 4) DEFAULT 0 NOT NULL,
    kinni NUMERIC(12, 4) DEFAULT 0 NOT NULL,
    tki NUMERIC(12, 4) DEFAULT 0 NOT NULL,
    tka NUMERIC(12, 4) DEFAULT 0 NOT NULL,
    pm NUMERIC(12, 4) DEFAULT 0 NOT NULL,
    tulumaks NUMERIC(12, 4) DEFAULT 0 NOT NULL,
    sotsmaks NUMERIC(12, 4) DEFAULT 0 NOT NULL,
    muud NUMERIC(12, 4) DEFAULT 0 NOT NULL,
    g31 NUMERIC(12, 4) DEFAULT 0 NOT NULL,
    vanaid INTEGER
    ) SERVER db_narva_ee
    OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'palk_jaak');

*/

DELETE
FROM palk.palk_jaak;
INSERT INTO palk.palk_jaak (lepingid, kuu, aasta, jaak, arvestatud, kinni, tki, tka, pm, tulumaks, sotsmaks, muud, g31)
SELECT i.new_id AS lepingid,
       pj.kuu,
       pj.aasta,
       pj.jaak,
       pj.arvestatud,
       pj.kinni,
       pj.tki,
       pj.tka,
       pj.pm,
       pj.tulumaks,
       pj.sotsmaks,
       pj.muud,
       pj.g31
FROM palk_jaak pj
         INNER JOIN import_log i ON i.old_id = pj.lepingid AND i.lib_name = 'TOOLEPING'
    AND kuu = 12 AND aasta = 2020;

DROP RULE IF EXISTS palk_jaak_2020 ON palk.palk_jaak;
CREATE RULE palk_jaak_2020 AS ON DELETE TO palk.palk_jaak
       WHERE aasta = 2020
              AND kuu = 12
       DO INSTEAD NOTHING ;


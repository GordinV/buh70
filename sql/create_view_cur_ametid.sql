-- View: curametid

DROP VIEW if exists cur_ametid;

CREATE OR REPLACE VIEW cur_ametid AS
  SELECT
    a.id,
    a.nimetus                                          AS amet,
    o.nimetus                                          AS osakond,
    a.rekvid,
    (a.properties :: JSONB ->> 'kogus') :: NUMERIC     AS kogus,
    (a.properties :: JSONB ->> 'vaba') :: NUMERIC      AS vaba,
    (a.properties :: JSONB ->> 'palgamaar') :: INTEGER AS palgamaar
  FROM libs.library a
    JOIN libs.library o ON (a.properties :: JSONB ->> 'osakondid') :: INTEGER = o.id
    where a.status <> 3

GRANT SELECT ON TABLE cur_ametid TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_ametid TO dbkasutaja;
GRANT ALL ON TABLE cur_ametid TO dbadmin;
GRANT SELECT ON TABLE cur_ametid TO dbvaatleja;


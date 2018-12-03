DROP VIEW IF EXISTS com_varad;
DROP VIEW IF EXISTS ladu.com_varad;

CREATE OR REPLACE VIEW ladu.com_varad AS

SELECT *
FROM (SELECT
        0                   AS id,
        NULL :: INTEGER     AS rekvid,
        '' :: VARCHAR(20)   AS kood,
        '' :: VARCHAR(254)  AS nimetus,
        0 :: NUMERIC(14, 2) AS hind,
        0 :: NUMERIC(14, 4) AS kogus,
        0 :: TEXT           AS vat,
        '':: VARCHAR(20)    AS ladu
      UNION
      SELECT
        n.id,
        n.rekvid,
        trim(n.kood)                              AS kood,
        trim(n.nimetus)                           AS nimetus,
        n.hind                                    AS hind,
        coalesce(v.kogus, 0)                      AS kogus,
        (n.properties :: JSONB ->> 'vat') :: TEXT AS vat,
        coalesce(l.kood, '')::VARCHAR(20)          AS ladu
      FROM libs.nomenklatuur n
             LEFT OUTER JOIN (SELECT sum(kogus) AS kogus, vara_id, ladu_id, rekv_id
                              FROM ladu.get_stock(current_date, NULL, NULL,
                                                  NULL)
                              GROUP BY vara_id, ladu_id, rekv_id) v ON n.id = v.vara_id AND n.rekvid = v.rekv_id
             LEFT OUTER JOIN libs.library l ON l.id = v.ladu_id
      WHERE n.status <> 3
        AND dok = 'VARA'
     ) qry
ORDER BY kood;

GRANT SELECT ON TABLE ladu.com_varad TO dbkasutaja;
GRANT SELECT ON TABLE ladu.com_varad TO dbvaatleja;
GRANT SELECT ON TABLE ladu.com_varad TO dbpeakasutaja;


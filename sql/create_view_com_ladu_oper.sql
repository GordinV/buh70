DROP VIEW IF EXISTS com_ladu_oper;

CREATE OR REPLACE VIEW com_ladu_oper AS

  SELECT *
  FROM (SELECT
          0                 AS id,
          '' :: VARCHAR(20) AS kood,
          '' :: VARCHAR(20) AS nimetus,
          NULL :: INTEGER   AS rekvId,
          0 :: INTEGER      AS liik
        UNION
        SELECT
          l.id,
          l.kood,
          l.nimetus,
          l.rekvId,
          l.tun1 as liik
        FROM libs.Library l
        WHERE l.library = 'LADU_OPER'
              AND l.status <> 3
       ) qry
  ORDER BY kood;

GRANT SELECT ON TABLE com_ladu_oper TO dbkasutaja;
GRANT SELECT ON TABLE com_ladu_oper TO dbvaatleja;
GRANT SELECT ON TABLE com_ladu_oper TO dbpeakasutaja;


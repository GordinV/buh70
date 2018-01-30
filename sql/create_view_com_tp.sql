DROP VIEW IF EXISTS com_tp;

CREATE OR REPLACE VIEW com_tp AS

  SELECT *
  FROM (SELECT
          0                 AS id,
          '':: VARCHAR(20) AS kood,
          '':: VARCHAR(20) AS nimetus,
          NULL :: INTEGER   AS rekvId
        UNION
        SELECT
          l.id,
          l.kood,
          l.nimetus,
          l.rekvId
        FROM libs.library l
        WHERE l.library = 'TP'
              AND l.status <> 3
       ) qry
  ORDER BY kood;

GRANT SELECT ON TABLE com_tp TO dbkasutaja;
GRANT SELECT ON TABLE com_tp TO dbvaatleja;
GRANT SELECT ON TABLE com_tp TO dbpeakasutaja;


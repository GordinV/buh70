DROP VIEW IF EXISTS com_vara_gruppid;
DROP VIEW IF EXISTS com_ladu;

CREATE OR REPLACE VIEW com_ladu AS

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
        WHERE l.library = 'LADU'
              AND l.status <> 3
       ) qry
  ORDER BY kood;

GRANT SELECT ON TABLE com_ladu TO dbkasutaja;
GRANT SELECT ON TABLE com_ladu TO dbvaatleja;
GRANT SELECT ON TABLE com_ladu TO dbpeakasutaja;
GRANT SELECT ON TABLE com_ladu TO ladukasutaja;


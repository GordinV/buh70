DROP VIEW IF EXISTS com_ametid;

CREATE OR REPLACE VIEW com_ametid AS

  SELECT *
  FROM (SELECT
          0                 AS id,
          '':: VARCHAR(20) AS kood,
          '':: VARCHAR(20) AS nimetus,
          NULL :: INTEGER   AS rekvId,
          NULL::INTEGER AS osakondId
        UNION
        SELECT
          l.id,
          l.kood,
          l.nimetus,
          l.rekvId,
          (l.properties:: JSONB ->> 'osakondid') :: INTEGER AS osakondId
        FROM libs.library l
        WHERE l.library = 'AMET'
              AND l.status <> 3
       ) qry
  ORDER BY kood;

GRANT SELECT ON TABLE com_ametid TO dbkasutaja;
GRANT SELECT ON TABLE com_ametid TO dbvaatleja;
GRANT SELECT ON TABLE com_ametid TO dbpeakasutaja;


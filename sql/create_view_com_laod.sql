DROP VIEW IF EXISTS com_tahtpaevad;

CREATE OR REPLACE VIEW com_tahtpaevad AS

  SELECT *
  FROM (SELECT
          0                 AS id,
          '' :: VARCHAR(20) AS nimetus,
          NULL :: INTEGER   AS rekvId
        UNION
        SELECT
          l.id,
          l.kood,
          l.nimetus,
          l.rekvId
        FROM libs.Library l
        WHERE l.library = 'LADU'
              AND l.status <> 3
       ) qry
  ORDER BY kood;

GRANT SELECT ON TABLE com_laod TO dbkasutaja;
GRANT SELECT ON TABLE com_laod TO dbvaatleja;
GRANT SELECT ON TABLE com_laod TO dbpeakasutaja;


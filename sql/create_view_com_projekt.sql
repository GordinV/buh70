DROP VIEW IF EXISTS com_projekt;

CREATE OR REPLACE VIEW com_projekt AS

  SELECT *
  FROM (SELECT
          0                 AS id,
          '' :: VARCHAR(20) AS kood,
          '' :: VARCHAR(20) AS nimetus,
          NULL :: INTEGER   AS rekvId
        UNION
        SELECT
          l.id,
          l.kood,
          l.nimetus,
          l.rekvId
        FROM libs.Library l
        WHERE l.library = 'PROJ'
              AND l.status <> 3
       ) qry
  ORDER BY kood;

GRANT SELECT ON TABLE com_projekt TO dbkasutaja;
GRANT SELECT ON TABLE com_projekt TO dbvaatleja;
GRANT SELECT ON TABLE com_projekt TO dbpeakasutaja;


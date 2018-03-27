DROP VIEW IF EXISTS com_osakonnad;

CREATE OR REPLACE VIEW com_osakonnad AS

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
        WHERE l.library = 'OSAKOND'
              AND l.status <> 3
       ) qry
  ORDER BY kood;

GRANT SELECT ON TABLE com_osakonnad TO dbkasutaja;
GRANT SELECT ON TABLE com_osakonnad TO dbvaatleja;
GRANT SELECT ON TABLE com_osakonnad TO dbpeakasutaja;


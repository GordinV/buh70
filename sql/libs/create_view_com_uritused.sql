DROP VIEW IF EXISTS com_uritused;

CREATE OR REPLACE VIEW com_uritused AS

SELECT *
FROM (SELECT 0                AS id,
             '':: VARCHAR(20) AS kood,
             '':: VARCHAR(20) AS nimetus,
             NULL :: INTEGER  AS rekvId,
             NULL::DATE       AS valid

      UNION
      SELECT l.id,
             l.kood,
             l.nimetus,
             l.rekvId,
             (l.properties::JSONB ->> 'valid')::DATE
      FROM libs.library l
      WHERE l.library = 'URITUS'
        AND l.status <> 3
     ) qry
ORDER BY kood;

GRANT SELECT ON TABLE com_uritused TO dbkasutaja;
GRANT SELECT ON TABLE com_uritused TO dbvaatleja;
GRANT SELECT ON TABLE com_uritused TO dbpeakasutaja;


DROP VIEW IF EXISTS com_allikad;

CREATE OR REPLACE VIEW com_allikad AS

SELECT *
FROM (SELECT 0                AS id,
             '':: VARCHAR(20) AS kood,
             '':: VARCHAR(20) AS nimetus,
             0 :: INTEGER     AS rekvId,
             NULL::DATE       AS valid
      UNION
      SELECT l.id,
             l.kood,
             l.nimetus,
             coalesce(l.rekvId, 0) AS rekvid,
             (l.properties::JSONB ->> 'valid')::DATE
      FROM libs.library l
      WHERE l.library = 'ALLIKAD'
        AND l.status <> 3
     ) qry
ORDER BY kood;

GRANT SELECT ON TABLE com_allikad TO dbkasutaja;
GRANT SELECT ON TABLE com_allikad TO dbvaatleja;
GRANT SELECT ON TABLE com_allikad TO dbpeakasutaja;


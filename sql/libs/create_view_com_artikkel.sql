DROP VIEW IF EXISTS com_artikkel;

CREATE OR REPLACE VIEW com_artikkel AS

SELECT *
FROM (SELECT 0                AS id,
             '':: VARCHAR(20) AS kood,
             '':: VARCHAR(20) AS nimetus,
             NULL :: INTEGER  AS rekvId,
             TRUE             AS is_kulud,
             NULL::DATE       AS valid
      UNION
      SELECT l.id,
             l.kood,
             l.nimetus,
             l.rekvId,
             (CASE WHEN l.tun5 = 1 THEN FALSE ELSE TRUE END) AS is_kulud,
             (l.properties::JSONB ->> 'valid')::DATE
      FROM libs.library l
      WHERE l.library = 'TULUDEALLIKAD'
        AND l.status <> 3
     ) qry
ORDER BY kood;

GRANT SELECT ON TABLE com_artikkel TO dbkasutaja;
GRANT SELECT ON TABLE com_artikkel TO dbvaatleja;
GRANT SELECT ON TABLE com_artikkel TO dbpeakasutaja;


DROP VIEW IF EXISTS com_pv_gruppid;
DROP VIEW IF EXISTS com_pv_gruppid;

CREATE OR REPLACE VIEW com_pv_gruppid AS

SELECT *
FROM (SELECT 0                 AS id,
             '':: VARCHAR(20)  AS kood,
             '':: VARCHAR(20)  AS nimetus,
             NULL :: INTEGER   AS rekvId,
             NULL::VARCHAR(20) AS konto,
             NULL::VARCHAR(20) AS kulum_konto,
             NULL::DATE        AS valid
      UNION
      SELECT l.id,
             l.kood,
             l.nimetus,
             l.rekvId,
             (l.properties::JSONB ->> 'konto') :: VARCHAR(20)       AS konto,
             (l.properties::JSONB ->> 'kulum_konto') :: VARCHAR(20) AS kulum_konto,
             (l.properties::JSONB ->> 'valid')::DATE                AS valid
      FROM libs.library l
      WHERE l.library = 'PVGRUPP'
        AND l.status <> 3
     ) qry
ORDER BY kood;

GRANT SELECT ON TABLE com_pv_gruppid TO dbkasutaja;
GRANT SELECT ON TABLE com_pv_gruppid TO dbvaatleja;
GRANT SELECT ON TABLE com_pv_gruppid TO dbpeakasutaja;


DROP VIEW IF EXISTS com_valuuta;

CREATE OR REPLACE VIEW com_valuuta AS

  SELECT *
  FROM (SELECT
          0                 AS id,
          '':: VARCHAR(20) AS kood,
          '':: VARCHAR(20) AS nimetus,
          NULL :: INTEGER   AS rekvId,
          NULL::numeric as kuurs
        UNION
        SELECT
          l.id,
          l.kood,
          l.nimetus,
          l.rekvId,
          coalesce((select v.kuurs from libs.valuuta v where parentid = l.id order by id desc limit 1),0)::numeric as kuurs
        FROM libs.library l
        WHERE l.library = 'VALUUTA'
              AND l.status <> 3
       ) qry
  ORDER BY kood;

GRANT SELECT ON TABLE com_valuuta TO dbkasutaja;
GRANT SELECT ON TABLE com_valuuta TO dbvaatleja;
GRANT SELECT ON TABLE com_valuuta TO dbpeakasutaja;


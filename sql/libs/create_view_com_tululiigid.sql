DROP VIEW IF EXISTS com_tululiigid;

CREATE OR REPLACE VIEW com_tululiigid AS

SELECT *
FROM (SELECT 0                AS id,
             '':: VARCHAR(20) AS kood,
             '':: VARCHAR(20) AS nimetus,
             NULL :: INTEGER  AS rekvId,
             NULL::INTEGER    AS tun1,
             NULL::INTEGER    AS tun2,
             NULL::INTEGER    AS tun3,
             NULL::INTEGER    AS tun4,
             NULL::INTEGER    AS tun5,
             NULL::DATE       AS valid
      UNION
      SELECT l.id,
             l.kood,
             l.nimetus,
             l.rekvId,
             l.tun1,
             l.tun2,
             l.tun3,
             l.tun4,
             l.tun5,
             (l.properties::JSON ->> 'valid')::DATE AS valid
      FROM libs.library l
      WHERE l.library = 'MAKSUKOOD'
        AND l.status <> 3
     ) qry
ORDER BY kood;

GRANT SELECT ON TABLE com_tululiigid TO dbkasutaja;
GRANT SELECT ON TABLE com_tululiigid TO dbvaatleja;
GRANT SELECT ON TABLE com_tululiigid TO dbpeakasutaja;


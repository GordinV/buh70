DROP VIEW IF EXISTS com_tululiigid;

CREATE OR REPLACE VIEW com_tululiigid AS

  SELECT *
  FROM (SELECT
          0                 AS id,
          '':: VARCHAR(20) AS kood,
          '':: VARCHAR(20) AS nimetus,
          NULL :: INTEGER   AS rekvId,
          null::integer as tun1,
          null::integer as tun2,
          null::integer as tun3,
          null::integer as tun4,
          null::integer as tun5
        UNION
        SELECT
          l.id,
          l.kood,
          l.nimetus,
          l.rekvId,
          l.tun1,
          l.tun2,
          l.tun3,
          l.tun4,
          l.tun5
        FROM libs.library l
        WHERE l.library = 'MAKSUKOOD'
              AND l.status <> 3
       ) qry
  ORDER BY kood;

GRANT SELECT ON TABLE com_tululiigid TO dbkasutaja;
GRANT SELECT ON TABLE com_tululiigid TO dbvaatleja;
GRANT SELECT ON TABLE com_tululiigid TO dbpeakasutaja;


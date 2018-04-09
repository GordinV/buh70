DROP VIEW IF EXISTS com_kontoplaan;

CREATE OR REPLACE VIEW com_kontoplaan AS

  SELECT *
  FROM (SELECT
          0                 AS id,
          '' :: VARCHAR(20) AS kood,
          '' :: VARCHAR(20) AS nimetus,
          NULL :: INTEGER   AS rekvId,
          1 :: INTEGER      AS tyyp,
          0 :: INTEGER      AS tun1,
          0 :: INTEGER      AS tun2,
          0 :: INTEGER      AS tun3,
          0 :: INTEGER      AS tun4
        UNION
        SELECT
          l.id,
          l.kood,
          l.nimetus,
          l.rekvId,
          l.tun5 AS tyyp,
          l.tun1,
          l.tun2,
          l.tun3,
          l.tun4
        FROM libs.Library l
        WHERE l.library = 'KONTOD'
              AND l.status <> 3
       ) qry
  ORDER BY kood;

GRANT SELECT ON TABLE com_kontoplaan TO dbkasutaja;
GRANT SELECT ON TABLE com_kontoplaan TO dbvaatleja;
GRANT SELECT ON TABLE com_kontoplaan TO dbpeakasutaja;


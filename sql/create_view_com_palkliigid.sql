DROP VIEW IF EXISTS com_palkliigid;
DROP VIEW IF EXISTS com_palklib;

CREATE OR REPLACE VIEW com_palklib AS

  SELECT *
  FROM (SELECT
          0                 AS id,
          '':: VARCHAR(20) AS kood,
          '':: VARCHAR(20) AS nimetus,
          NULL :: INTEGER   AS rekvId,
          null::integer as liik,
          null::integer as tund,
          null::integer as maks,
          null::integer as asutusest,
          null::integer as palgafond,
          null::integer as sots,
          null::numeric(12,4) as round,
          NULL::varchar(20) as konto
            UNION
        SELECT
          l.id,
          l.kood,
          l.nimetus,
          l.rekvId,
          (l.properties::JSONB ->> 'liik') :: INTEGER as liik,
          (l.properties::JSONB ->> 'tund') :: INTEGER as tund,
          (l.properties::JSONB ->> 'maks') :: INTEGER as maks,
          (l.properties::JSONB ->> 'asutusest') :: INTEGER as asutusest,
          (l.properties::JSONB ->> 'palgafond') :: INTEGER as palgafond,
          (l.properties::JSONB ->> 'sots') :: INTEGER as sots,
          (l.properties::JSONB ->> 'round') :: numeric(12,4) as round,
          (l.properties::JSONB ->> 'konto') :: varchar(20) as konto
        FROM libs.library l
        WHERE l.library = 'PALK'
              AND l.status <> 3
       ) qry
  ORDER BY kood;

GRANT SELECT ON TABLE com_palklib TO dbkasutaja;
GRANT SELECT ON TABLE com_palklib TO dbvaatleja;
GRANT SELECT ON TABLE com_palklib TO dbpeakasutaja;


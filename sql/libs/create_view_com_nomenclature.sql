DROP VIEW IF EXISTS com_nomenclature;

CREATE OR REPLACE VIEW com_nomenclature AS

SELECT *
FROM (SELECT 0                    AS id,
             NULL :: INTEGER      AS rekvid,
             '' :: VARCHAR(20)    AS kood,
             '' :: VARCHAR(20)    AS nimetus,
             'DOK' :: VARCHAR(20) AS DOK,
             0 :: VARCHAR(10)     AS vat,
             0 :: NUMERIC(14, 2)  AS hind,
             'muud':: TEXT        AS uhik,
             0 :: NUMERIC(14, 4)  AS kogus,
             NULL::TEXT           AS tyyp,
             '' :: VARCHAR(20)    AS konto,
             '' :: VARCHAR(20)    AS tegev,
             '' :: VARCHAR(20)    AS allikas,
             '' :: VARCHAR(20)    AS rahavoog,
             '' :: VARCHAR(20)    AS artikkel,
             0 :: INTEGER         AS tunnusId,
             '' :: TEXT           AS formula,
             NULL :: VARCHAR(20)  AS proj,
             'EUR' :: VARCHAR     AS valuuta,
             1                    AS kuurs,
             '':: VARCHAR(20)     AS tunnus,
             FALSE                AS kas_inf3,
             NULL::DATE           AS valid
      UNION
      SELECT n.id,
             n.rekvid,
             trim(n.kood)::VARCHAR(20)                                           AS kood,
             trim(n.nimetus)::VARCHAR(254)                                       AS nimetus,
             trim(n.dok)::VARCHAR(20)                                            AS dok,
             (n.properties :: JSONB ->> 'vat') :: VARCHAR(10)                    AS vat,
             n.hind                                                              AS hind,
             n.uhik::TEXT                                                        AS uhik,
             n.kogus                                                             AS kogus,
             (n.properties :: JSONB ->> 'tyyp')::TEXT                            AS tyyp,
             coalesce((n.properties :: JSONB ->> 'konto') :: VARCHAR(20), '')    AS konto,
             coalesce((n.properties :: JSONB ->> 'tegev') :: VARCHAR(20), '')    AS tegev,
             coalesce((n.properties :: JSONB ->> 'allikas') :: VARCHAR(20), '')  AS allikas,
             coalesce((n.properties :: JSONB ->> 'rahavoog') :: VARCHAR(20), '') AS rahavoog,
             coalesce((n.properties :: JSONB ->> 'artikkel') :: VARCHAR(20), '') AS artikkel,
             coalesce((n.properties :: JSONB ->> 'tunnusId') :: INTEGER, 0)      AS tunnusId,
             coalesce((n.properties :: JSONB ->> 'formula') :: TEXT, '')         AS formula,
             coalesce((n.properties :: JSONB ->> 'projekt') :: TEXT, '')         AS proj,
             'EUR' :: VARCHAR                                                    AS valuuta,
             1 :: NUMERIC                                                        AS kuurs,
             coalesce((n.properties :: JSONB ->> 'tunnus') :: VARCHAR(20), '')   AS tunnus,
             coalesce((n.properties::JSONB ->> 'kas_inf3')::BOOLEAN, FALSE)      AS kas_inf3,
             (n.properties::JSONB ->> 'valid')::DATE                             AS valid
      FROM libs.nomenklatuur n
      WHERE n.status <> 3
     ) qry
ORDER BY kood;

GRANT SELECT ON TABLE com_nomenclature TO dbkasutaja;
GRANT SELECT ON TABLE com_nomenclature TO dbvaatleja;
GRANT SELECT ON TABLE com_nomenclature TO dbpeakasutaja;


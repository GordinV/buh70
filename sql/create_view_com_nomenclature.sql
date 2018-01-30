DROP VIEW IF EXISTS com_nomenclature;

CREATE OR REPLACE VIEW com_nomenclature AS

  SELECT *
  FROM (SELECT
          0                   AS id,
          NULL :: INTEGER     AS rekvid,
          '' :: VARCHAR(20)   AS kood,
          '' :: VARCHAR(20)   AS nimetus,
          'DOK' :: TEXT       AS DOK,
          0 :: TEXT           AS vat,
          1                   AS tyyp,
          0 :: NUMERIC(14, 2) AS hind,
          0 :: NUMERIC(14, 4) AS kogus,
          '' :: VARCHAR(20)   AS konto,
          '' :: VARCHAR(20)   AS tegev,
          '' :: VARCHAR(20)   AS allikas,
          '' :: VARCHAR(20)   AS rahavoog,
          '' :: VARCHAR(20)   AS artikkel,
          0 :: INTEGER        AS tunnusId,
          '' :: TEXT          AS formula,
          'EUR' :: VARCHAR    AS valuuta,
          1                   AS kuurs
        UNION
        SELECT
          n.id,
          n.rekvid,
          trim(n.kood)                                                        AS kood,
          trim(n.nimetus)                                                     AS nimetus,
          trim(n.dok)                                                         AS dok,
          (n.properties :: JSONB ->> 'vat') :: TEXT                           AS vat,
          n.hind                                                              AS hind,
          n.kogus                                                             AS kogus,
          coalesce((n.properties :: JSONB ->> 'tyyp') :: INTEGER, 1)          AS tyyp,
          coalesce((n.properties :: JSONB ->> 'konto') :: VARCHAR(20), '')    AS konto,
          coalesce((n.properties :: JSONB ->> 'tegev') :: VARCHAR(20), '')    AS tegev,
          coalesce((n.properties :: JSONB ->> 'allikas') :: VARCHAR(20), '')  AS allikas,
          coalesce((n.properties :: JSONB ->> 'rahavoog') :: VARCHAR(20), '') AS rahavoog,
          coalesce((n.properties :: JSONB ->> 'artikkel') :: VARCHAR(20), '') AS artikkel,
          coalesce((n.properties :: JSONB ->> 'tunnusId') :: INTEGER, 0)      AS tunnusId,
          coalesce((n.properties :: JSONB ->> 'formula') :: TEXT, '')         AS formula,
          coalesce(d.valuuta, 'EUR') :: VARCHAR                               AS valuuta,
          coalesce(d.kuurs, 1) :: NUMERIC                                     AS kuurs
        FROM libs.nomenklatuur n
          LEFT OUTER JOIN docs.dokvaluuta1 d ON (n.id = d.dokid AND d.dokliik = 17)
        WHERE n.status <> 3
       ) qry
  ORDER BY kood;

GRANT SELECT ON TABLE com_nomenclature TO dbkasutaja;
GRANT SELECT ON TABLE com_nomenclature TO dbvaatleja;
GRANT SELECT ON TABLE com_nomenclature TO dbpeakasutaja;


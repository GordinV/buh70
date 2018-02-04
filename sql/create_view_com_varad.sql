DROP VIEW IF EXISTS com_varad;

CREATE OR REPLACE VIEW com_varad AS

  SELECT *
  FROM (SELECT
          0                   AS id,
          NULL :: INTEGER     AS rekvid,
          '' :: VARCHAR(20)   AS kood,
          '' :: VARCHAR(20)   AS nimetus,
          'LADU' :: TEXT       AS DOK,
          0 :: NUMERIC(14, 2) AS hind,
          0 :: NUMERIC(14, 4) AS kogus,
          0 :: TEXT           AS vat,
          '' :: VARCHAR(20)   AS konto,
          '' :: VARCHAR(20)   AS tegev,
          '' :: VARCHAR(20)   AS allikas,
          '' :: VARCHAR(20)   AS artikkel,
          '' :: VARCHAR(20)   AS tunnus,
          '' :: TEXT          AS formula,
          'EUR' :: VARCHAR    AS valuuta,
          1                   AS kuurs,
          0::integer as status
        UNION
        SELECT
          n.id,
          n.rekvid,
          trim(n.kood)                                                        AS kood,
          trim(n.nimetus)                                                     AS nimetus,
          trim(n.dok)                                                         AS dok,
          n.hind                                                              AS hind,
          n.kogus                                                             AS kogus,
          (n.properties :: JSONB ->> 'vat') :: TEXT                           AS vat,
          coalesce((n.properties :: JSONB ->> 'konto') :: VARCHAR(20), '')    AS konto,
          coalesce((n.properties :: JSONB ->> 'tegev') :: VARCHAR(20), '')    AS tegev,
          coalesce((n.properties :: JSONB ->> 'allikas') :: VARCHAR(20), '')  AS allikas,
          coalesce((n.properties :: JSONB ->> 'artikkel') :: VARCHAR(20), '') AS artikkel,
          coalesce((n.properties :: JSONB ->> 'tunnus') :: VARCHAR(20), '')      AS tunnus,
          coalesce((n.properties :: JSONB ->> 'formula') :: TEXT, '')         AS formula,
          coalesce(d.valuuta, 'EUR') :: VARCHAR                               AS valuuta,
          coalesce(d.kuurs, 1) :: NUMERIC                                     AS kuurs,
          n.status as status
        FROM libs.nomenklatuur n
          LEFT OUTER JOIN docs.dokvaluuta1 d ON (n.id = d.dokid AND d.dokliik = 17)
        WHERE n.status <> 3
        and dok = 'LADU'
       ) qry
  ORDER BY kood;

GRANT SELECT ON TABLE com_varad TO dbkasutaja;
GRANT SELECT ON TABLE com_varad TO dbvaatleja;
GRANT SELECT ON TABLE com_varad TO dbpeakasutaja;


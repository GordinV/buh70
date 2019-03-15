DROP VIEW IF EXISTS cur_pohivara;

CREATE OR REPLACE VIEW cur_pohivara AS
SELECT
  l.id,
  l.kood,
  l.nimetus,
  l.rekvid,
  coalesce(a.nimetus, '') :: VARCHAR(254)                                               AS vastisik,
  (l.properties :: JSONB ->> 'vastisikid') :: INTEGER                                   AS vastisikid,
  (l.properties :: JSONB ->> 'algkulum') :: NUMERIC(12, 2)                              AS algkulum,
  (l.properties :: JSONB ->> 'kulum') :: NUMERIC(12, 2)                                 AS kulum,
  (l.properties :: JSONB ->> 'soetmaks') :: NUMERIC(12, 2)                              AS soetmaks,
  coalesce((l.properties :: JSONB ->> 'parhind') :: NUMERIC(12, 2),
           (l.properties :: JSONB ->> 'soetmaks') :: NUMERIC(12, 2))                    AS parhind,
  coalesce((l.properties :: JSONB ->> 'soetkpv') :: DATE, date(1900, 01, 01))           AS soetkpv,
  coalesce((l.properties :: JSONB ->> 'konto'), '') :: VARCHAR(20)                      AS konto,
  coalesce((l.properties :: JSONB ->> 'tunnus'), '') :: VARCHAR(20)                     AS tunnus,
  (l.properties :: JSONB ->> 'mahakantud') :: DATE                                      AS mahakantud,
  coalesce((l.properties :: JSONB ->> 'rentnik'), '') :: VARCHAR(120)                   AS rentnik,
  (l.properties :: JSONB ->> 'liik') :: VARCHAR(120)                                    AS liik,
  coalesce((l.properties :: JSONB ->> 'selg'), '') :: VARCHAR(120)                      AS selgitus,
  (l.properties :: JSONB ->> 'parent_id') :: INTEGER                                    AS parent_id,
  coalesce((l.properties :: JSONB ->> 'pindala') :: NUMERIC(12, 4), 0):: NUMERIC(12, 4) AS pindala,

  'EUR' :: CHARACTER VARYING                                                            AS valuuta,
  1 :: NUMERIC                                                                          AS kuurs,
  grupp.id                                                                              AS gruppid,
  grupp.nimetus                                                                         AS grupp,
  coalesce(p.kood, '')                                                                  AS parent_kood,
  coalesce(p.nimetus, '')                                                               AS parent_nimetus,
  coalesce((l.properties :: JSONB ->> 'aadress'), ''):: VARCHAR(254)                    AS aadress,
  l.status
FROM libs.library l
       JOIN libs.library grupp ON (l.properties :: JSONB -> 'gruppid') = to_jsonb(grupp.id)
       LEFT JOIN libs.asutus a ON (l.properties :: JSONB -> 'vastisikid') = to_jsonb(a.id)
       LEFT JOIN libs.library p ON (l.properties :: JSONB -> 'parent_id') = to_jsonb(p.id)
WHERE l.status <> 3;

GRANT SELECT ON TABLE cur_pohivara TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_pohivara TO dbkasutaja;
GRANT SELECT ON TABLE cur_pohivara TO dbvaatleja;
GRANT ALL ON TABLE cur_pohivara TO dbadmin;


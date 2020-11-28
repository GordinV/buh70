DROP VIEW IF EXISTS palk.com_palk_kaart;

CREATE VIEW palk.com_palk_kaart AS
SELECT pk.id,
       pk.libid,
       pk.lepingid,
       pk.summa,
       pk.minsots,
       l.kood,
       l.nimetus,
       l.rekvid,
       (l.properties::JSONB ->> 'tegev')                                             AS tegev,
       (l.properties::JSONB ->> 'allikas')                                           AS allikas,
       (l.properties::JSONB ->> 'rahavoog')                                          AS rahavoog,
       (l.properties::JSONB ->> 'artikkel')                                          AS artikkel,
       (l.properties::JSONB ->> 'uritus')                                            AS uritus,
       (l.properties::JSONB ->> 'konto')                                             AS konto,
       (l.properties::JSONB ->> 'proj')                                              AS proj,
       coalesce((l.properties::JSONB ->> 'tunnus'), t.kood)                          AS tunnus,
       (l.properties::JSONB ->> 'liik')::INTEGER                                     AS liik,
       (l.properties::JSONB ->> 'tund')::INTEGER                                     AS tund,
       coalesce((l.properties::JSONB ->> 'percent_')::INTEGER, pk.percent_)::INTEGER AS percent_,
       (l.properties::JSONB ->> 'maks')::INTEGER                                     AS tulumaks,
       (l.properties::JSONB ->> 'asutusest')::INTEGER                                AS asutusest,
       (l.properties::JSONB ->> 'round')::NUMERIC                                    AS round,
       pk.status
FROM libs.library l
         INNER JOIN palk.palk_kaart pk ON pk.libId = l.id
         LEFT OUTER JOIN libs.library t ON (l.properties::JSON ->> 'tunnusid')::INTEGER = t.id

WHERE pk.status <> 3;


GRANT SELECT ON TABLE palk.com_palk_kaart TO dbkasutaja;
GRANT SELECT ON TABLE palk.com_palk_kaart TO dbpeakasutaja;
GRANT SELECT ON TABLE palk.com_palk_kaart TO dbvaatleja;
GRANT ALL ON TABLE palk.com_palk_kaart TO dbadmin;

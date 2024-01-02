DROP VIEW IF EXISTS hooldekodu.com_asutus_hooldekodu;

CREATE VIEW hooldekodu.com_asutus_hooldekodu AS
SELECT isik.id,
       isik.regkood                                                                  AS isikukood,
       (LTRIM(RTRIM(isik.nimetus)) + ',' + LTRIM(RTRIM(isik.regkood)))::VARCHAR(254) AS nimi,
       coalesce(hl.hooldekoduid, 0)                                                  AS hooldekoduid,
       hk.nimetus                                                                    AS hooldekodu,
       hk.tp,
       coalesce(hl.omavalitsusId, 0)                                                 AS omavalitsusId,
       hl.rekvid,
       hl.algkpv,
       hl.loppkpv,
       hl.makse_viis 
FROM libs.asutus isik
         INNER JOIN hooldekodu.hooleping hl ON isik.id = hl.isikid
         INNER JOIN libs.asutus hk ON hk.id = hl.hooldekoduid
WHERE hl.status < 3
and hl.loppkpv > '2022-12-31';


GRANT SELECT ON TABLE hooldekodu.com_asutus_hooldekodu TO hkametnik;
GRANT SELECT ON TABLE hooldekodu.com_asutus_hooldekodu TO soametnik;

/*
SELECT *
FROM hooldekodu.com_asutus_hooldekodu
--WHERE regkood = '11958746'*/
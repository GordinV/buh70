DROP VIEW IF EXISTS hooldekodu.cur_hooTaabel;

CREATE VIEW hooldekodu.cur_hooTaabel AS
SELECT ht.id,
       ht.isikid,
       ht.lepingid,
       ht.kpv,
       date_part('month', ht.kpv)                                                    AS kuu,
       date_part('year', ht.kpv)                                                     AS aasta,
       ht.summa::NUMERIC(12, 2)                                                      AS arv_summa,
       CASE WHEN upper(n.uhik) = 'KUU' THEN n.hind ELSE ht.summa END::NUMERIC(12, 2) AS summa,
       ht.kogus,
       ht.hind,
       ht.arvid,
       ht.sugulane_arv_id,
       left(coalesce(ht.muud, ''), 254)::VARCHAR(254)                                AS selg,
       coalesce(ht.muud, '')                                                         AS muud,
       ht.rekvid,
       coalesce((ht.properties ->> 'umardamine')::NUMERIC, 0)::NUMERIC               AS umardamine,
       n.kood                                                                        AS kood,
       n.nimetus                                                                     AS teenus,
       coalesce(arv.number, '')::VARCHAR(20)                                         AS number,
       coalesce(arv.allikas_85, 0)::NUMERIC(12, 2)                                   AS allikas_85,
       coalesce(arv.allikas_muud, 0)::NUMERIC(12, 2)                                 AS allikas_muud,
       coalesce(arv.allikas_vara, 0)::NUMERIC(12, 2)                                 AS allikas_vara,
       coalesce(arv.omavalitsuse_osa, 0)::NUMERIC(12, 2)                             AS omavalitsuse_osa,
       coalesce(arv.sugulane_osa, 0)::NUMERIC(12, 2)                                 AS sugulane_osa

FROM hooldekodu.hootaabel ht
         INNER JOIN libs.nomenklatuur n ON n.id = ht.nomid
         LEFT OUTER JOIN (
    SELECT d.id,
           a.number,
           sum(coalesce((a1.properties ->> 'allikas_85')::NUMERIC, 0))       AS allikas_85,
           sum(coalesce((a1.properties ->> 'allikas_muud')::NUMERIC, 0))     AS allikas_muud,
           sum(coalesce((a1.properties ->> 'allikas_vara')::NUMERIC, 0))     AS allikas_vara,
           sum(coalesce((a1.properties ->> 'omavalitsuse_osa')::NUMERIC, 0)) AS omavalitsuse_osa,
           sum(coalesce((a1.properties ->> 'sugulane_osa')::NUMERIC, 0))     AS sugulane_osa
    FROM docs.doc d
             INNER JOIN docs.arv a ON d.id = a.parentid
             LEFT JOIN docs.arv1 a1 ON a1.parentid = a.id
    WHERE a.properties ->> 'tyyp' = 'HOOLDEKODU_ISIKU_OSA'
      AND d.status < 3
    GROUP BY d.id, a.number
) arv ON arv.id = ht.arvid

WHERE ht.status < 3;

GRANT SELECT ON TABLE hooldekodu.cur_hooTaabel TO hkametnik;
GRANT SELECT ON TABLE hooldekodu.cur_hooTaabel TO soametnik;


SELECT *
FROM hooldekodu.cur_hooTaabel
WHERE rekvid = 132
--      id = 27



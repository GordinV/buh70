DROP VIEW IF EXISTS cur_eelarve;
DROP VIEW IF EXISTS cur_tulud;

CREATE OR REPLACE VIEW cur_tulud AS
SELECT e.id,
       e.rekvid,
       e.aasta,
       e.summa,
       e.summa_kassa,
       coalesce(e.kood1, '') :: VARCHAR(20)         AS kood1,
       coalesce(e.kood2, '') :: VARCHAR(20)         AS kood2,
       coalesce(e.kood3, '') :: VARCHAR(20)         AS kood3,
       coalesce(e.kood4, '') :: VARCHAR(20)         AS kood4,
       coalesce(e.kood5, '') :: VARCHAR(20)         AS kood5,
       coalesce(e.tunnus, '') :: VARCHAR(20)        AS tunnus,
       r.nimetus :: VARCHAR(254)                    AS asutus,
       r.regkood,
       r.parentid,
       coalesce(parent.nimetus, '') :: VARCHAR(254) AS parasutus,
       coalesce(parent.regkood, '') :: VARCHAR(20)  AS parregkood,
       e.kuu,
       e.kpv,
       e.muud,
       e.is_parandus,
       'EUR' :: CHARACTER VARYING                   AS valuuta,
       1 :: NUMERIC                                 AS kuurs,
       e.is_parandus                                AS tun,
       l.nimetus,
       coalesce(t1.proj, '')                        AS projekt,
       coalesce(t1.objekt, '')                      AS objekt,
       coalesce(t1.kood4, '')                       AS uritus
       
FROM eelarve.tulud e
         JOIN ou.rekv r ON e.rekvid = r.id
         LEFT OUTER JOIN (
    SELECT DISTINCT  id, kood, nimetus
    FROM libs.library l
    WHERE l.library = 'TULUDEALLIKAD'
      AND l.tun5 = 1
      AND l.status <> 3) l
                         ON l.kood = e.kood5
         LEFT OUTER JOIN ou.rekv parent ON parent.id = r.parentid
         LEFT OUTER JOIN eelarve.taotlus1 t1 ON t1.eelarveid = e.id
WHERE e.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted');

GRANT SELECT ON TABLE cur_tulud TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_tulud TO dbkasutaja;
GRANT ALL ON TABLE cur_tulud TO dbadmin;
GRANT SELECT ON TABLE cur_tulud TO dbvaatleja;
GRANT SELECT ON TABLE cur_tulud TO eelaktsepterja;
GRANT SELECT ON TABLE cur_tulud TO eelallkirjastaja;
GRANT SELECT ON TABLE cur_tulud TO eelesitaja;
GRANT SELECT ON TABLE cur_tulud TO eelkoostaja;


/*

select * from cur_tulud
limit 100
 */


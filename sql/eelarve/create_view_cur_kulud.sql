DROP VIEW IF EXISTS cur_eelarve;
DROP VIEW IF EXISTS cur_kulud;

CREATE OR REPLACE VIEW cur_kulud AS
SELECT
  e.id,
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
  l.nimetus
FROM eelarve.kulud e
       JOIN ou.rekv r ON e.rekvid = r.id
       LEFT OUTER JOIN ou.rekv parent ON parent.id = r.parentid
       LEFT OUTER JOIN libs.library l ON l.kood = e.kood5 AND l.library = 'TULUDEALLIKAD' AND l.tun5 = 2

WHERE e.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted');

GRANT SELECT ON TABLE cur_kulud TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_kulud TO dbkasutaja;
GRANT ALL ON TABLE cur_kulud TO dbadmin;
GRANT SELECT ON TABLE cur_kulud TO dbvaatleja;
GRANT SELECT ON TABLE cur_kulud TO eelaktsepterja;
GRANT SELECT ON TABLE cur_kulud TO eelallkirjastaja;
GRANT SELECT ON TABLE cur_kulud TO eelesitaja;
GRANT SELECT ON TABLE cur_kulud TO eelkoostaja;


/*

select * from eelarve.eelarve where rekvid = 63 and aasta = 2018

select * from cur_kulud
 */


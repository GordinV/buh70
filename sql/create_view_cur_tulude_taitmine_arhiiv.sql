DROP VIEW IF EXISTS cur_tulude_taitmine_arhiiv;
DROP VIEW IF EXISTS cur_eelarve_taitmine_arhiiv;

CREATE VIEW cur_eelarve_taitmine_arhiiv AS
  SELECT
    e.kuu        AS kuu,
    e.aasta      AS aasta,

    e.rekvid,
    rekv.nimetus AS asutus,
    rekv.parentid,
    e.tunnus     AS tunnus,
    sum(e.summa)      AS summa,
    e.kood5      AS artikkel,
    e.kood1      AS tegev,
    e.kood2      AS allikas,
    l.nimetus    AS nimetus,
    e.is_kulud
  FROM eelarve.eeltaitmine e
    INNER JOIN ou.rekv rekv ON e.rekvid = rekv.id
    LEFT OUTER JOIN libs.library l ON l.kood = e.kood5 AND l.library = 'ARTIKKEL'

  GROUP BY e.aasta, e.kuu, e.rekvid, rekv.parentid, rekv.nimetus, e.kood1, e.kood5, e.kood2, e.tunnus, l.nimetus, e.is_kulud;


GRANT SELECT ON TABLE cur_eelarve_taitmine_arhiiv TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_eelarve_taitmine_arhiiv TO dbkasutaja;
GRANT ALL ON TABLE cur_eelarve_taitmine_arhiiv TO dbadmin;
GRANT SELECT ON TABLE cur_eelarve_taitmine_arhiiv TO dbvaatleja;
GRANT SELECT ON TABLE cur_eelarve_taitmine_arhiiv TO eelaktsepterja;
GRANT SELECT ON TABLE cur_eelarve_taitmine_arhiiv TO eelallkirjastaja;
GRANT SELECT ON TABLE cur_eelarve_taitmine_arhiiv TO eelesitaja;
GRANT SELECT ON TABLE cur_eelarve_taitmine_arhiiv TO eelkoostaja;


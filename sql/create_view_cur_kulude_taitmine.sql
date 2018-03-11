DROP VIEW IF EXISTS cur_kulude_taitmine;

CREATE VIEW cur_kulude_taitmine AS
  SELECT
    month(j.kpv)                         AS kuu,
    year(j.kpv)                          AS aasta,
    j.rekvid,
    rekv.nimetus                         AS asutus,
    rekv.parentid,
    j1.tunnus                            AS tunnus,
    sum(j1.summa * coalesce(v.kuurs, 1)) AS summa,
    j1.kood5                             AS artikkel,
    j1.kood1                             AS tegev,
    j1.kood2                             AS allikas,
    l.nimetus                            AS nimetus
  FROM docs.journal j
    INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
    INNER JOIN ou.rekv rekv ON j.rekvid = rekv.id
    LEFT OUTER JOIN libs.library l ON l.kood = j1.kood5 AND l.library = 'ARTIKKEL'
    LEFT OUTER JOIN docs.dokvaluuta1 v
      ON v.dokid = j1.id AND v.dokliik = array_position((enum_range(NULL :: DOK_VALUUTA)), 'journal1')
    JOIN faktkulud ON ltrim(rtrim(j1.deebet)) ~~ ltrim(rtrim(faktkulud.kood))

  GROUP BY (year(j.kpv)), (month(j.kpv)), j.rekvid, rekv.parentid, rekv.nimetus, j1.kreedit,
    j1.kood1, j1.kood5, j1.kood2, j1.tunnus, l.nimetus
  ORDER BY (year(j.kpv)), (month(j.kpv)), j.rekvid, rekv.parentid, rekv.nimetus, j1.kreedit,
    j1.kood1, j1.kood5, j1.kood2, j1.tunnus;


GRANT SELECT ON TABLE cur_kulude_taitmine TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_kulude_taitmine TO dbkasutaja;
GRANT ALL ON TABLE cur_kulude_taitmine TO dbadmin;
GRANT SELECT ON TABLE cur_kulude_taitmine TO dbvaatleja;
GRANT SELECT ON TABLE cur_kulude_taitmine TO eelaktsepterja;
GRANT SELECT ON TABLE cur_kulude_taitmine TO eelallkirjastaja;
GRANT SELECT ON TABLE cur_kulude_taitmine TO eelesitaja;
GRANT SELECT ON TABLE cur_kulude_taitmine TO eelkoostaja;


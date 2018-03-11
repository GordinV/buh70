DROP VIEW IF EXISTS cur_tulude_taitmine;

CREATE VIEW cur_tulude_taitmine AS
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
    JOIN fakttulud ON ((ltrim(rtrim((j1.kreedit) :: TEXT)) ~~ ltrim(rtrim((fakttulud.kood) :: TEXT))))
  GROUP BY (year(j.kpv)), (month(j.kpv)), j.rekvid, rekv.parentid, rekv.nimetus, j1.kreedit,
    j1.kood1, j1.kood5, j1.kood2, j1.tunnus, l.nimetus
  ORDER BY (year(j.kpv)), (month(j.kpv)), j.rekvid, rekv.parentid, rekv.nimetus, j1.kreedit,
    j1.kood1, j1.kood5, j1.kood2, j1.tunnus;

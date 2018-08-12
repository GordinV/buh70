DROP VIEW IF EXISTS cur_teenused;

CREATE OR REPLACE VIEW cur_teenused AS
  SELECT
    d.id                                 AS id,
    d.lastupdate,
    a.id                                 AS arv_id,
    trim(a.number)                       AS number,
    a.rekvid,
    a.kpv                                AS kpv,
    a.userid,
    a.asutusid,
    a.journalid,
    a.liik,
    a.operid,
    trim(asutus.nimetus) :: VARCHAR(254) AS asutus,
    asutus.regkood,
    n.kood,
    n.nimetus,
    n.uhik,
    a1.hind,
    a1.kogus,
    a1.summa,
    a1.kbm,
    (a1.summa - a1.kbm)                  AS kbmta,
    n.properties ->> 'vat'               AS kaibemaks,
    coalesce(o.kood, '') :: VARCHAR(20)  AS objekt,
    a1.kood4                             AS uritus,
    a1.proj
  FROM docs.doc d
    INNER JOIN docs.arv a ON a.parentId = d.id
    INNER JOIN docs.arv1 a1 ON a1.parentId = a.id
    INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
    LEFT OUTER JOIN libs.library o ON o.id = a.objektid
    LEFT OUTER JOIN libs.asutus asutus ON a.asutusid = asutus.id
    LEFT OUTER JOIN ou.userid u ON u.id = a.userid
  ORDER BY d.lastupdate DESC;

GRANT SELECT ON TABLE cur_teenused TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_teenused TO dbkasutaja;
GRANT SELECT ON TABLE cur_teenused TO dbvaatleja;
GRANT ALL ON TABLE cur_teenused TO dbadmin;

/*

select * from cur_teenused where rekvid = 1 and liik = 1
 */
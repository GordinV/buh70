-- View: public.cur_ladu_jaak

DROP VIEW IF EXISTS cur_journal;

CREATE OR REPLACE VIEW cur_journal AS
  SELECT
    to_char(d.created, 'DD.MM.YYYY HH:MM')                                                 AS created,
    to_char(d.lastupdate, 'DD.MM.YYYY HH:MM')                                              AS lastupdate,
    s.nimetus                                                                              AS status,
    d.id                                                                                   AS id,
    j.kpv                                                                                  AS kpv,
    jid.number,
    j.id                                                                                   AS journalid,
    j.rekvId,
    j.asutusid,
    month(j.kpv) :: INTEGER                                                                AS kuu,
    year(j.kpv) :: INTEGER                                                                 AS aasta,
    coalesce(j.selg, '') :: VARCHAR(254)                                                   AS selg,
    coalesce(j.dok, '') :: VARCHAR(20)                                                     AS dok,
    coalesce(j.objekt, '') :: VARCHAR(20)                                                  AS objekt,
    j.muud :: CHARACTER VARYING(254)                                                       AS muud,
    j1.deebet,
    coalesce(j1.lisa_d, '') :: VARCHAR(20)                                                 AS lisa_d,
    j1.kreedit,
    coalesce(j1.lisa_k, '') :: VARCHAR(20)                                                 AS lisa_k,
    j1.summa,
    j1.valsumma,
    'EUR' :: VARCHAR(20)                                                                   AS valuuta,
    1 :: NUMERIC(12, 6)                                                                    AS kuurs,
    coalesce(j1.kood1, '') :: VARCHAR(20)                                                  AS kood1,
    coalesce(j1.kood2, '') :: VARCHAR(20)                                                   AS kood2,
    coalesce(j1.kood3, '') :: VARCHAR(20)                                                  AS kood3,
    coalesce(j1.kood4, '') :: VARCHAR(20)                                                  AS kood4,
    coalesce(j1.kood5, '') :: VARCHAR(20)                                                  AS kood5,
    coalesce(j1.proj, '') :: VARCHAR(20)                                                   AS proj,
    coalesce(ltrim(rtrim(a.nimetus)) || ' ' || ltrim(rtrim(a.omvorm)), '') :: VARCHAR(120) AS asutus,
    coalesce(j1.tunnus, '') :: VARCHAR(20)                                                 AS tunnus,
    coalesce(u.ametnik, '') :: VARCHAR(120)                                                AS kasutaja,
    r.nimetus                                                                              AS rekvAsutus
  FROM docs.journal j
    INNER JOIN docs.doc d ON d.id = j.parentid
    INNER JOIN libs.library s ON s.kood = d.status :: TEXT AND s.library = 'STATUS'
    INNER JOIN docs.journalid jid ON j.id = jid.journalid
    INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
    INNER JOIN ou.rekv r ON r.id = j.rekvid
    LEFT JOIN libs.asutus a ON a.id = j.asutusid
    LEFT OUTER JOIN ou.userid u ON u.id = j.userid;

GRANT SELECT ON TABLE cur_journal TO dbkasutaja;
GRANT SELECT ON TABLE cur_journal TO dbvaatleja;
GRANT SELECT ON TABLE cur_journal TO dbpeakasutaja;

/*
select j.*
            from cur_journal j
*/
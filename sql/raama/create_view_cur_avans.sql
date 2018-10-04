DROP VIEW IF EXISTS cur_avans;

CREATE VIEW cur_avans AS
  SELECT
    d.id,
    d.rekvid,
    to_char(d.created, 'DD.MM.YYYY HH:MM' :: TEXT)                AS created,
    to_char(d.lastupdate, 'DD.MM.YYYY HH:MM' :: TEXT)             AS lastupdate,
    a1.userid,
    a1.kpv,
    a1.asutusid,
    a.nimetus                                                     AS isik,
    a1.number,
    a2.konto,
    a2.kood5,
    a2.tunnus,
    a1.dokpropId,
    a2.summa,
    coalesce(Jid.number, 0)                                       AS lausend,
    U.ametnik,
    n.nimetus,
    a2.kood4                                                      AS uritus,
    a2.proj,
    a1.jaak,
    'EUR' :: VARCHAR                                              AS valuuta,
    1 :: NUMERIC                                                  AS kuurs,
    (COALESCE(u.ametnik, '' :: BPCHAR)) :: CHARACTER VARYING(120) AS kasutaja

  FROM docs.doc d
    INNER JOIN docs.avans1 a1 ON d.id = a1.parentid
    INNER JOIN docs.avans2 a2 ON a1.id = a2.parentid
    INNER JOIN libs.asutus a ON a.id = a1.asutusId
    INNER JOIN libs.nomenklatuur n ON a2.nomid = n.id
    LEFT OUTER JOIN ou.userid u ON a1.userid = u.id
    LEFT OUTER JOIN docs.doc dd ON a1.journalid = dd.id
    LEFT OUTER JOIN docs.journal j ON j.parentid = dd.id
    LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id


GRANT SELECT ON TABLE cur_avans TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_avans TO dbkasutaja;
GRANT SELECT ON TABLE cur_avans TO dbvaatleja;
GRANT ALL ON TABLE cur_avans TO dbadmin;

/*
select * from cur_avans

select * from docs.avans1 where parentid = 1276

*/
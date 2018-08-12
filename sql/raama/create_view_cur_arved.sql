DROP VIEW IF EXISTS cur_arved;

CREATE OR REPLACE VIEW cur_arved AS
  SELECT
    d.id                                            AS id,
    a.id                                            AS arv_id,
    trim(a.number)                                  AS number,
    a.rekvid,
    a.kpv                                           AS kpv,
    a.summa,
    a.tahtaeg                                       AS tahtaeg,
    a.jaak,
    a.tasud :: DATE                                 AS tasud,
    a.tasudok,
    a.userid,
    a.asutusid,
    a.journalid,
    a.liik,
    a.operid,
    coalesce(a.objektId, 0)                         AS objektid,
    trim(asutus.nimetus)                            AS asutus,
    coalesce(v.valuuta, 'EUR') :: CHARACTER VARYING AS valuuta,
    coalesce(v.kuurs, 1) :: NUMERIC                 AS kuurs,
    coalesce(a.objekt, '') :: VARCHAR(20)           AS objekt,
    to_char(d.created, 'DD.MM.YYYY HH:MM')          AS created,
    to_char(d.lastupdate, 'DD.MM.YYYY HH:MM')       AS lastupdate,
    trim(s.nimetus)                                 AS status,
    coalesce(u.ametnik, '') :: VARCHAR(120)         AS ametnik,
    jid.number                                      AS lausnr,
    a.muud                                          AS markused
  FROM docs.doc d
    INNER JOIN docs.arv a ON a.parentId = d.id
    INNER JOIN libs.library s ON s.kood = d.status :: TEXT
    LEFT OUTER JOIN libs.asutus asutus ON a.asutusid = asutus.id
    LEFT OUTER JOIN ou.userid u ON u.id = a.userid
    LEFT JOIN docs.dokvaluuta1 v
      ON a.id = v.dokid AND v.dokliik = array_position((enum_range(NULL :: DOK_VALUUTA)), 'arv')
    LEFT OUTER JOIN docs.journal j ON j.parentid = a.journalid
    LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
  ORDER BY d.lastupdate DESC;

GRANT SELECT ON TABLE cur_arved TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_arved TO dbkasutaja;
GRANT SELECT ON TABLE cur_arved TO dbvaatleja;
GRANT ALL ON TABLE cur_arved TO dbadmin;


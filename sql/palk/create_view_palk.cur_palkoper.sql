DROP VIEW IF EXISTS palk.cur_palkoper;

CREATE VIEW palk.cur_palkoper AS
  SELECT
    d.id,
    to_char(d.created, 'DD.MM.YYYY HH:MM' :: TEXT)                                         AS created,
    to_char(d.lastupdate, 'DD.MM.YYYY HH:MM' :: TEXT)                                      AS lastupdate,
    btrim((s.nimetus) :: TEXT)                                                             AS status,
    p.kpv,
    p.summa,
    p.libid,
    p.rekvid,
    p.pensmaks,
    p.sotsmaks,
    p.tulubaas,
    p.tka,
    p.tootumaks,
    p.tulumaks,
    a.regkood                                                                              AS isikukood,
    p.lepingid,
    a.nimetus                                                                              AS isik,
    a.id                                                                                   AS isikid,
    coalesce(jid.number, 0)                                                                AS journalid,
    t.osakondid,
    lib.kood,
    lib.nimetus,
    (enum_range(NULL :: PALK_OPER_LIIK)) [(lib.properties :: JSONB ->> 'liik') :: INTEGER] AS liik,
    (enum_range(NULL :: PALK_TUND_LIIK)) [(lib.properties :: JSONB ->> 'tund') :: INTEGER] AS tund,
    (lib.properties :: JSONB ->> 'asutusest') :: BOOLEAN                                   AS is_asutusest,
    (lib.properties :: JSONB ->> 'maks') :: BOOLEAN                                        AS is_maksustatav,
    (lib.properties :: JSONB ->> 'sost') :: BOOLEAN                                        AS is_sotsmaks

  FROM docs.doc d
    INNER JOIN libs.library s ON (s.kood :: TEXT = d.status :: TEXT AND s.library = 'STATUS')
    INNER JOIN palk.palk_oper p ON p.parentid = d.id
    INNER JOIN libs.library lib ON p.libid = lib.id
    INNER JOIN palk.tooleping t ON p.lepingid = t.id
    INNER JOIN libs.asutus a ON t.parentid = a.id
    LEFT OUTER JOIN docs.doc dd ON p.journalid = dd.id
    LEFT OUTER JOIN docs.journal j ON j.parentid = dd.id
    LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id;
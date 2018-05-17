DROP VIEW IF EXISTS palk.cur_palk_oper_lausend;

CREATE VIEW palk.cur_palk_oper_lausend AS
  SELECT
    d.id,
    d.docs_ids,
    p.parentid,
    p.kpv,
    p.summa,
    p.libid,
    p.rekvid,
    p.lepingid,
    p.doklausid                                                                                 AS dokpropId,
    p.journalid,
    a.regkood                                                                                   AS isikukood,
    a.nimetus                                                                                   AS isik,
    a.id                                                                                        AS isikid,
    a.tp                                                                                        AS isiku_tp,
    coalesce(jid.number, 0)                                                                     AS lausend_nr,
    ((enum_range(NULL :: PALK_LIIK)) [(lib.properties :: JSONB ->> 'liik') :: INTEGER]) :: TEXT AS palk_liik,
    (lib.properties :: JSONB ->> 'korrkonto') :: TEXT                                           AS korr_konto,
    (lib.properties :: JSONB ->> 'asutusest') :: BOOLEAN                                        AS kas_asutusest,
    p.konto,
    p.tp,
    p.kood1,
    p.kood2,
    p.kood3,
    p.kood4,
    p.kood5,
    p.proj,
    p.tunnus,
    p.muud,
    (dp.details :: JSONB ->> 'konto')                                                           AS base_konto,
    NOT empty(dp.registr :: INTEGER)                                                            AS kas_registreerida,
    dp.selg
  FROM docs.doc D
    INNER JOIN palk.palk_oper p ON p.parentid = D.id
    INNER JOIN libs.library lib ON p.libid = lib.id AND lib.library = 'PALK'
    INNER JOIN palk.tooleping t ON p.lepingid = t.id
    INNER JOIN libs.asutus a ON t.parentid = a.id
    LEFT OUTER JOIN libs.dokprop dp ON p.doklausid = dp.id
    LEFT OUTER JOIN docs.doc dd ON p.journalid = dd.id
    LEFT OUTER JOIN docs.journal j ON j.parentid = dd.id
    LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id;

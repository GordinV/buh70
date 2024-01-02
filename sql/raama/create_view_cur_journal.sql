-- View: public.cur_ladu_jaak

--DROP VIEW IF EXISTS cur_journal;
--CASCADE;

CREATE OR REPLACE VIEW cur_journal AS
    WITH doc_type AS (
        SELECT id
        FROM libs.library
        WHERE library = 'DOK'
          AND kood = 'JOURNAL'
    )
    SELECT to_char(d.created, 'DD.MM.YYYY HH:MI')                                                                  AS created,
           to_char(d.lastupdate, 'DD.MM.YYYY HH:MI')                                                               AS lastupdate,
           s.nimetus                                                                                               AS status,
           d.id                                                                                                    AS id,
           j.kpv                                                                                                   AS kpv,
           jid.number,
           j.id                                                                                                    AS journalid,
           j.rekvId,
           j.asutusid,
           month(j.kpv) :: INTEGER                                                                                 AS kuu,
           year(j.kpv) :: INTEGER                                                                                  AS aasta,
           regexp_replace(regexp_replace(coalesce(j.selg, ''), '["/]', ' ', 'g'), '/n/r', '',
                          'g') :: VARCHAR(254)                                                                     AS selg,
           COALESCE(j.dok, '') :: VARCHAR(50)                                                                      AS dok,
           COALESCE(j1.objekt, '') :: VARCHAR(20)                                                                  AS objekt,
           regexp_replace(regexp_replace(replace(coalesce(j.muud, ''), chr(13), ' '), '["/]', ' ', 'g'), '/n/r', '',
                          'g') :: VARCHAR(254)                                                                     AS muud,
--       j.muud :: CHARACTER VARYING(254)                                                                     AS muud,
           j1.deebet,
           COALESCE(j1.lisa_d, '') :: VARCHAR(20)                                                                  AS lisa_d,
           j1.kreedit,
           COALESCE(j1.lisa_k, '') :: VARCHAR(20)                                                                  AS lisa_k,
           j1.summa,
           j1.summa                                                                                                AS valsumma,
           'EUR' :: VARCHAR(20)                                                                                    AS valuuta,
           1 :: NUMERIC(12, 6)                                                                                     AS kuurs,
           COALESCE(j1.kood1, '') :: VARCHAR(20)                                                                   AS kood1,
           COALESCE(j1.kood2, '') :: VARCHAR(20)                                                                   AS kood2,
           COALESCE(j1.kood3, '') :: VARCHAR(20)                                                                   AS kood3,
           COALESCE(j1.kood4, '') :: VARCHAR(20)                                                                   AS kood4,
           COALESCE(j1.kood5, '') :: VARCHAR(20)                                                                   AS kood5,
           COALESCE(j1.proj, '') :: VARCHAR(20)                                                                    AS proj,
           COALESCE(ltrim(rtrim(a.nimetus)) || ' ' || ltrim(rtrim(a.omvorm)),
                    '') :: VARCHAR(120)                                                                            AS asutus,
           COALESCE(j1.tunnus, '') :: VARCHAR(20)                                                                  AS tunnus,
           COALESCE(u.ametnik, '') :: VARCHAR(120)                                                                 AS kasutaja,
           ltrim(rtrim(r.nimetus)):: VARCHAR(254)                                                                  AS rekvAsutus
    FROM docs.journal j
             INNER JOIN docs.doc D ON D.id = j.parentid
             INNER JOIN libs.library S ON S.kood = D.status :: TEXT AND S.library = 'STATUS'
             INNER JOIN docs.journalid jid ON j.id = jid.journalid
             INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
             INNER JOIN ou.rekv r ON r.id = j.rekvid
             LEFT JOIN libs.asutus a ON a.id = j.asutusid
             LEFT OUTER JOIN ou.userid u ON u.id = j.userid
    WHERE D.status <> 3
      AND d.doc_type_id IN (SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'JOURNAL')
;

GRANT SELECT ON TABLE cur_journal TO dbkasutaja;
GRANT SELECT ON TABLE cur_journal TO dbvaatleja;
GRANT SELECT ON TABLE cur_journal TO dbpeakasutaja;

/*

select * from libs.library where library = 'DOK'
select j.*
            from cur_journal j
where rekvid = 132
and kpv >= '2022-01-01'
limit 100
*/
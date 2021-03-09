DROP FUNCTION IF EXISTS docs.sp_kooperi_arv(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_kooperi_arv(user_id INTEGER,
                                               doc_id INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    v_arv          RECORD;
    v_arvread      RECORD;
    l_doc_json     TEXT;
    l_details_json TEXT;
    l_json         TEXT;
    l_doc_id       INTEGER;
BEGIN
    -- paring andmed

    RAISE NOTICE 'start';

    SELECT 0                                                  AS id,
           user_id :: INTEGER                                 AS userid,
           to_char(created, 'DD.MM.YYYY HH:MM:SS') :: TEXT    AS created,
           to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS') :: TEXT AS lastupdate,
           d.bpm,
           trim(l.nimetus)                                    AS doc,
           trim(l.kood)                                       AS doc_type_id,
           trim(s.nimetus)                                    AS status,
           d.status                                           AS doc_status,
           trim(a.number)                                     AS number,
           a.summa,
           a.rekvId,
           coalesce(a.liik, 1) :: INTEGER                     AS liik,
           a.operid,
           current_date                                       AS kpv,
           a.asutusid,
           a.arvId,
           trim(a.lisa)                                       AS lisa,
           a.kbmta,
           a.kbm,
           a.summa,
           a.tasud,
           trim(a.tasudok)                                    AS tasudok,
           a.muud,
           a.jaak,
           a.objektId,
           trim(a.objekt)                                     AS objekt,
           asutus.regkood,
           trim(asutus.nimetus)                               AS asutus,
           a.doklausid,
           a.doklausid,
           dp.selg                                            AS dokprop,
           a.journalid,
           coalesce(jid.number, 0) :: INTEGER                 AS laus_nr
           INTO v_arv
    FROM docs.doc d
             INNER JOIN libs.library l ON l.id = d.doc_type_id
             INNER JOIN docs.arv a ON a.parentId = d.id
             INNER JOIN libs.asutus AS asutus ON asutus.id = a.asutusId
             INNER JOIN ou.userid u ON u.id = user_id :: INTEGER
             LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
             LEFT OUTER JOIN libs.dokprop dp ON dp.id = a.doklausid
             LEFT OUTER JOIN docs.journalid jid ON jid.journalid = a.journalid
    WHERE d.id = doc_id;
    -- salvetsame
    l_doc_json = row_to_json(v_arv) :: TEXT;


    FOR v_arvread IN
        SELECT 0                                                               AS id,
               user_id :: INTEGER                                              AS userid,
               a1.nomid,
               a1.kogus,
               a1.hind,
               a1.kbm,
               a1.kbmta,
               a1.summa,
               trim(n.kood)                                                    AS kood,
               trim(n.nimetus)                                                 AS nimetus,
               a1.soodus,
               a1.kood1,
               a1.kood2,
               a1.kood3,
               a1.kood4,
               a1.kood5,
               a1.tunnus,
               a1.proj,
               a1.konto,
               a1.tp,
               coalesce(v.valuuta, 'EUR') :: VARCHAR(20)                       AS valuuta,
               coalesce(v.kuurs, 1) :: NUMERIC                                 AS kuurs,
               coalesce((n.properties :: JSONB ->> 'vat'), '-') :: VARCHAR(20) AS km
        FROM docs.arv1 AS a1
                 INNER JOIN docs.arv a ON a.id = a1.parentId
                 INNER JOIN libs.nomenklatuur n ON n.id = a1.nomId
                 INNER JOIN ou.userid u ON u.id = user_id :: INTEGER
                 LEFT OUTER JOIN docs.dokvaluuta1 v ON (a.id = v.dokid AND v.dokliik = 2)
        WHERE a.parentid = doc_id
        LOOP
            l_details_json =
                        coalesce(l_details_json, '') :: TEXT || CASE WHEN l_details_json IS NULL THEN '' ELSE ',' END ||
                        row_to_json(v_arvread) :: TEXT;
        END LOOP;

    l_json = ('{"data":' || trim(TRAILING FROM l_doc_json, '}')::TEXT || ',"gridData":[' || l_details_json || ']}}');
    RAISE NOTICE 'l_json %', l_json;

    l_doc_id = docs.sp_salvesta_arv(l_json::JSON, user_id, v_arv.rekvid);

    RETURN l_doc_id;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_kooperi_arv(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_kooperi_arv(INTEGER, INTEGER) TO dbpeakasutaja;


/*
SELECT docs.sp_kooperi_arv(1, 900);

select * from docs.arv where parentid = 913

select * from docs.arv1 where parentid  = 344
*/
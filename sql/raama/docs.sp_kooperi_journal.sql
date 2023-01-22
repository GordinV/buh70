DROP FUNCTION IF EXISTS docs.sp_kooperi_journal(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS docs.sp_kooperi_journal(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION docs.sp_kooperi_journal(user_id INTEGER,
                                                   doc_id INTEGER,
                                                   l_kpv DATE DEFAULT current_date)
    RETURNS INTEGER AS
$BODY$

DECLARE
    v_journal      RECORD;
    v_journal1     RECORD;
    l_doc_json     TEXT;
    l_details_json TEXT;
    l_json         TEXT;
    l_doc_id       INTEGER;
BEGIN
    -- paring andmed

    SELECT 0                                                  AS id,
           user_id :: INTEGER                                 AS userid,
           to_char(created, 'DD.MM.YYYY HH:MM:SS') :: TEXT    AS created,
           to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS') :: TEXT AS lastupdate,
           d.rekvid,
           j.asutusid,
           ''                                                 AS dok,
           l_kpv                                              AS kpv,
           regexp_replace(j.selg, '[/"]', '.', 'g')           AS selg,
           j.muud
    INTO v_journal
    FROM docs.doc d
             INNER JOIN docs.journal j ON j.parentId = d.id
             INNER JOIN ou.userid u ON u.id = user_id :: INTEGER
    WHERE d.id = doc_id;
    -- salvetsame
    l_doc_json = row_to_json(v_journal) :: TEXT;

    FOR v_journal1 IN
        SELECT 0                  AS id,
               user_id :: INTEGER AS userid,
               j1.deebet,
               j1.lisa_d,
               j1.kreedit,
               j1.lisa_k,
               j1.kood1,
               j1.kood2,
               j1.kood3,
               j1.kood4,
               j1.kood5,
               j1.summa,
               j1.tunnus,
               j1.proj,
               j1.muud
        FROM docs.journal1 AS j1
                 INNER JOIN docs.journal j ON j.id = j1.parentId
        WHERE j.parentid = doc_id
        LOOP
            l_details_json = coalesce(l_details_json, '') :: TEXT ||
                             CASE WHEN l_details_json IS NULL THEN '' ELSE ',' END ||
                             row_to_json(v_journal1) :: TEXT;
        END LOOP;

    l_json = ('{"data":' || trim(TRAILING FROM l_doc_json, '}')::TEXT || ',"gridData":[' || l_details_json || ']}}');

    l_doc_id = docs.sp_salvesta_journal(l_json::JSON, user_id, v_journal.rekvid);

    RETURN l_doc_id;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_kooperi_journal(INTEGER, INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_kooperi_journal(INTEGER, INTEGER, DATE) TO dbpeakasutaja;


/*
select docs.sp_kooperi_journal(1::integer, 297419::integer) as result

*/
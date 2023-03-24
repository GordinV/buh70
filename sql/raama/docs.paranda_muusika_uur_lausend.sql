DROP FUNCTION IF EXISTS docs.paranda_muusika_uur_lausend(DATE);

CREATE OR REPLACE FUNCTION docs.paranda_muusika_uur_lausend(
    l_kpv DATE DEFAULT current_date)
    RETURNS INTEGER AS
$BODY$

DECLARE
    v_doc          RECORD;
    v_journal      RECORD;
    v_journal1     RECORD;
    l_doc_json     JSONB;
    l_details_json JSONB   = '[]'::JSONB;
    l_json         TEXT;
    l_doc_id       INTEGER;
    l_kuu          INTEGER = date_part('month', l_kpv);
    l_aasta        INTEGER = date_part('year', l_kpv);
    l_user_id      INTEGER = (SELECT id
                              FROM ou.userid
                              WHERE rekvid = 71
                                AND kasutaja = 'vlad'
                                AND status < 3
                              LIMIT 1);
    l_asutus_id    INTEGER = (SELECT id
                              FROM libs.asutus
                              WHERE regkood = '88888888880'
                                AND staatus < 3
                              LIMIT 1);


BEGIN
    -- paring andmed

    -- аренда, начисленно
    SELECT sum(coalesce(summa_3220, 0)) AS summa_3220,
           sum(coalesce(summa_3233, 0)) AS summa_3223
    INTO v_doc
    FROM (
             SELECT sum(summa) FILTER (WHERE kood5 = '3220') AS summa_3220,
                    sum(summa) FILTER (WHERE kood5 = '3233') AS summa_3233,
                    kood5
             FROM cur_journal
             WHERE rekvid = 71
               AND date_part('month', kpv) = l_kuu
               AND date_part('year', kpv) = l_aasta
               AND deebet = '10300029'
               AND left(kood5, 2) = '32'
               AND kood1 = '09510'
               AND kood2 = '80'
             GROUP BY kood1, kood2, kood5
             UNION ALL
             SELECT -1 * sum(summa) FILTER (WHERE kood5 = '3220') AS summa_3220,
                    -1 * sum(summa) FILTER (WHERE kood5 = '3233') AS summa_3233,
                    kood5
             FROM cur_journal
             WHERE rekvid = 71
               AND date_part('month', kpv) = l_kuu
               AND date_part('year', kpv) = l_aasta
               AND left(deebet, 6) in ('100100', '999999')
               AND left(kood5, 2) = '32'
               AND kood1 = '09510'
               AND kood2 = '80'
             GROUP BY kood5
         ) qry;

    IF v_doc.summa_3223 <= 0
    THEN
        RAISE NOTICE 'Puudub arvestused %', v_doc.summa_3223;
        RETURN 0;
    END IF;

    SELECT 0                      AS id,
           l_user_id :: INTEGER   AS userid,
           71                     AS rekvid,
           l_asutus_id            AS asutusid,
           ''                     AS dok,
           l_kpv                  AS kpv,
           'Muusika uur parandus' AS selg
    INTO v_journal;

    -- salvetsame
    l_doc_json = to_jsonb(v_journal);

    SELECT 0                     AS id,
           '999999'              AS deebet,
           '800402'              AS lisa_d,
           '10300029'            AS kreedit,
           '800699'              AS lisa_k,
           '09510'               AS kood1,
           '80'                  AS kood2,
           '3220'                AS kood5,
           -1 * v_doc.summa_3223 AS summa,
           '0951004'             AS tunnus
    INTO v_journal1;

    l_details_json = l_details_json || to_jsonb(v_journal1);

    SELECT 0                AS id,
           '999999'         AS deebet,
           '800402'         AS lisa_d,
           '10300029'       AS kreedit,
           '800699'         AS lisa_k,
           '09510'          AS kood1,
           '80'             AS kood2,
           '3233'           AS kood5,
           v_doc.summa_3223 AS summa,
           '0951004'        AS tunnus
    INTO v_journal1;

    l_details_json = l_details_json || to_jsonb(v_journal1);

    l_doc_json = jsonb_build_object('id', 0, 'data', (l_doc_json || jsonb_build_object('gridData', l_details_json)));

    RAISE NOTICE 'l_doc_json %',l_doc_json;
    l_doc_id = docs.sp_salvesta_journal(l_doc_json::JSON, l_user_id, 71);

    RETURN l_doc_id;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.paranda_muusika_uur_lausend( DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.paranda_muusika_uur_lausend( DATE) TO dbpeakasutaja;


SELECT docs.paranda_muusika_uur_lausend('2023-02-28'::DATE)

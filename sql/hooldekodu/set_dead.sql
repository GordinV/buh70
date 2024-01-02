DROP FUNCTION IF EXISTS hooldekodu.set_dead(INTEGER, INTEGER, DATE);
-- $2::INTEGER, $1::INTEGER, $3::DATE


CREATE OR REPLACE FUNCTION hooldekodu.set_dead(IN l_isik_id INTEGER, IN user_id INTEGER, IN l_kpv DATE,
                                               OUT result INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    v_hoojaak  RECORD;
    v_journal  RECORD;
    v_journal1 RECORD;
    jsonb_read JSONB   = '[]'::JSONB;
    jsonb_doc  JSONB;
    l_rea      BOOLEAN = FALSE;
    l_rekv_id  INTEGER = (SELECT rekvid
                          FROM ou.userid
                          WHERE id = user_id
                          LIMIT 1);
    l_tunnus   TEXT    = CASE WHEN l_rekv_id = 64 THEN '5003' ELSE '2101' END;

BEGIN
    -- закрываем договора
    UPDATE hooldekodu.hooleping SET loppkpv = l_kpv WHERE isikid = l_isik_id AND status < 3;

    -- set status kinni

    UPDATE libs.asutus SET staatus = 2 WHERE id = l_isik_id;

    SELECT 0                                                         AS id,
           'JOURNAL'                                                 AS doc_type_id,
           l_kpv                                                     AS kpv,
           'Lepingute lõpetamine kliendi surma tõttu'                AS selg,
           l_isik_id                                                 AS asutusid,
           (SELECT rekvid FROM ou.userid WHERE id = user_id LIMIT 1) AS rekv_id
    INTO v_journal;


    /*    5. В случае смерти клиента все средства переводятся на конто 203601
   Deebet            TP             Kreedit            TP             Tunnus    A         TT           Art
20363001   800699    203601       800699       5003     80    10200    2585
*/
    -- leiame jaagirea
    SELECT * INTO v_hoojaak FROM hooldekodu.hoojaak WHERE isikid = l_isik_id LIMIT 1;

    -- allikas 85
    IF v_hoojaak.pension85 <> 0
    THEN
        SELECT 0                   AS id,
               v_hoojaak.pension85 AS summa,
               '20363001'          AS deebet,
               '800699'            AS lisa_d,
               '20363006'          AS kreedit,
               '800699'            AS lisa_k,
               l_tunnus              AS tunnus,
               '10200'             AS kood1,
               '80'                AS kood2,
               '2585'              AS kood5
        INTO v_journal1;

        jsonb_read = jsonb_read || to_jsonb(v_journal1);
        l_rea = TRUE;
    END IF;
    -- allikas 15
    IF v_hoojaak.pension15 <> 0
    THEN

        SELECT 0                   AS id,
               v_hoojaak.pension15 AS summa,
               '20363002'          AS deebet,
               '800699'            AS lisa_d,
               '20363006'          AS kreedit,
               '800699'            AS lisa_k,
               l_tunnus              AS tunnus,
               '10200'             AS kood1,
               '80'                AS kood2,
               '2585'              AS kood5
        INTO v_journal1;

        jsonb_read = jsonb_read || to_jsonb(v_journal1);
        l_rea = TRUE;

    END IF;

    -- allikas toetus
    IF v_hoojaak.toetus <> 0
    THEN
        SELECT 0                AS id,
               v_hoojaak.toetus AS summa,
               '20363003'       AS deebet,
               '800699'         AS lisa_d,
               '20363006'       AS kreedit,
               '800699'         AS lisa_k,
               l_tunnus           AS tunnus,
               '10200'          AS kood1,
               '80'             AS kood2,
               '2585'           AS kood5
        INTO v_journal1;

        jsonb_read = jsonb_read || to_jsonb(v_journal1);
        l_rea = TRUE;

    END IF;

    -- allikas vara
    IF v_hoojaak.vara <> 0
    THEN
        SELECT 0              AS id,
               v_hoojaak.vara AS summa,
               '20363004'     AS deebet,
               '800699'       AS lisa_d,
               '20363006'     AS kreedit,
               '800699'       AS lisa_k,
               l_tunnus         AS tunnus,
               '10200'        AS kood1,
               '80'           AS kood2,
               '2585'         AS kood5
        INTO v_journal1;

        jsonb_read = jsonb_read || to_jsonb(v_journal1);
        l_rea = TRUE;

    END IF;

    -- allikas muud
    IF v_hoojaak.muud <> 0
    THEN
        SELECT 0              AS id,
               v_hoojaak.muud AS summa,
               '20363005'     AS deebet,
               '800699'       AS lisa_d,
               '20363006'     AS kreedit,
               '800699'       AS lisa_k,
               l_tunnus         AS tunnus,
               '10200'        AS kood1,
               '80'           AS kood2,
               '2585'         AS kood5
        INTO v_journal1;

        jsonb_read = jsonb_read || to_jsonb(v_journal1);
        l_rea = TRUE;

    END IF;

    -- salvestan
    SELECT v_journal.id,
           v_journal.rekv_id,
           v_journal.doc_type_id,
           v_journal.kpv,
           v_journal.selg,
           v_journal.asutusid,
           jsonb_read AS "gridData"
    INTO v_journal;

    SELECT to_jsonb(ROW)
    INTO jsonb_doc
    FROM (SELECT 0         AS id,
                 v_journal AS DATA) ROW;
    IF l_rea
    THEN
        result = docs.sp_salvesta_journal(jsonb_doc :: JSON, user_id, v_journal.rekv_id)::INTEGER;
    ELSE
        result = 0::INTEGER;
    END IF;

    PERFORM hooldekodu.sp_calc_hoojaak(l_isik_id);

    RAISE NOTICE 'OK';

    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'Viga';

            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            result = 0::INTEGER;
            RETURN;

END;

$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION hooldekodu.set_dead(INTEGER,INTEGER, DATE) TO hkametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.set_dead(INTEGER,INTEGER, DATE) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.set_dead(INTEGER,INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION hooldekodu.set_dead(INTEGER,INTEGER, DATE) TO dbpeakasutaja;

/*
select hooldekodu.sp_calc_hoojaak(13346)
 */
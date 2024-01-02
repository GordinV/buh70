DROP FUNCTION IF EXISTS hooldekodu.sp_koosta_hooettemaks(INTEGER, JSONB);

CREATE FUNCTION hooldekodu.sp_koosta_hooettemaks(IN user_id INTEGER, IN params JSONB, OUT result INTEGER,
                                                 OUT error_code INTEGER, OUT error_message TEXT)
    RETURNS RECORD

    LANGUAGE plpgsql
AS
$$
DECLARE
    lausend_id  INTEGER = params ->> 'id';
    l_liik      INTEGER = coalesce((params ->> 'liik') :: INTEGER, 1);
    l_id        INTEGER = 0;
    v_journal   RECORD;
    v_ettemaks  RECORD;
    json_params JSONB;
    is_import   BOOLEAN = coalesce((params ->> 'import') :: BOOLEAN, FALSE);
    l_allikas   TEXT    = 'PENSION85';
BEGIN

    IF l_liik = 1
    THEN
        -- journal
        FOR v_journal IN
            SELECT j.parentid AS id,
                   j1.id      AS journal1Id,
                   j.rekvid,
                   j.kpv,
                   j.asutusid,
                   j.selg,
                   j1.summa,
                   jid.number,
                   j1.deebet,
                   j1.kreedit
            FROM docs.journal j
                     JOIN docs.journal1 j1 ON j.id = j1.parentid
                     JOIN docs.journalid jid ON j.id = jid.journalid
            WHERE j.parentid = lausend_id
            LOOP

                -- опредлеляем источник
                l_allikas = CASE
                                WHEN left(v_journal.deebet, 6) = '100100' AND
                                     v_journal.kreedit IN ('203630', '20363001') THEN
                                    'PENSION85'
                                WHEN left(v_journal.deebet, 6) = '100100' AND
                                     v_journal.kreedit IN ('20363002') THEN
                                    'PENSION15'
                                WHEN left(v_journal.deebet, 6) = '100100' AND
                                     v_journal.kreedit IN ('20363003') THEN
                                    'TOETUS'
                                WHEN left(v_journal.deebet, 6) = '100100' AND
                                     v_journal.kreedit IN ('20363004') THEN
                                    'VARA'
                                WHEN left(v_journal.deebet, 6) = '100100' AND
                                     v_journal.kreedit IN ('20363005') THEN
                                    'MUUD'
                                ELSE
                                    'PENSION85'
                    END;

                -- kontrollime kas ettemaks juba koostatud
                SELECT coalesce(e.id, 0)
                INTO l_id
                FROM hooldekodu.hooettemaksud e
                WHERE dokid = v_journal.journal1Id;

                SELECT coalesce(l_id, 0)      AS id,
                       v_journal.asutusId,
                       v_journal.id           AS dokid,
                       v_journal.kpv          AS kpv,
                       'LAUSEND'              AS doktyyp,
                       v_journal.summa        AS summa,
                       v_journal.selg :: TEXT AS selg,
                       v_journal.rekvid,
                       l_allikas              AS allikas,
                       is_import              AS import
                INTO v_ettemaks;

                SELECT row_to_json(row)
                INTO json_params
                FROM (SELECT coalesce(l_id, 0) AS id, row_to_json(v_ettemaks) AS data) row;

                result = hooldekodu.sp_salvesta_hooettemaks(json_params, user_id, v_journal.rekvid);

            END LOOP;
        RETURN;
    END IF;
EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_code = 1;
            error_message = SQLERRM;
            result = 0;
            RETURN;

END ;
$$;


GRANT EXECUTE ON FUNCTION hooldekodu.sp_koosta_hooettemaks(INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_koosta_hooettemaks(INTEGER, JSONB) TO dbpeakasutaja;

/*
select * from hooldekodu.sp_koosta_hooettemaks(3196, '{"id":2308955,"import":false}')

 select * from cur_journal
where rekvid = 64
order by id desc limit 10


 */
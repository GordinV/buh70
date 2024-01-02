DROP FUNCTION IF EXISTS hooldekodu.sp_koosta_hootehing(INTEGER, JSONB);

CREATE FUNCTION hooldekodu.sp_koosta_hootehing(IN user_id INTEGER, IN params JSONB, OUT result INTEGER,
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
    v_tehing    RECORD;
    json_params JSONB;
    is_import   BOOLEAN = coalesce((params ->> 'import') :: BOOLEAN, FALSE);
    l_allikas   TEXT    = 'PENSION85';
    l_tyyp      TEXT    = 'TULUD';
BEGIN

    -- проверка на договор
    IF NOT exists(SELECT id
                  FROM hooldekodu.hooleping hl
                  WHERE hl.isikid IN (
                      SELECT asutusid
                      FROM docs.journal
                      WHERE parentid = lausend_id
                  )
                    AND hl.status < 3)
    THEN
        error_message = 'Puudub leping';
        RETURN;

    END IF;

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
              AND (left(deebet, 6) IN ('203630', '203560') OR left(kreedit, 6) IN ('203630', '203560'))
--              AND (left(deebet, 6) <> '999999' AND left(kreedit, 6) <> '999999')
            LOOP
                IF left(v_journal.deebet, 6) = '100100' OR left(v_journal.deebet, 6) = '100000' OR left(v_journal.deebet, 6) = '999999'
                THEN
                    l_tyyp = 'TULUD';
                ELSIF left(v_journal.deebet, 6) = '203630'
                THEN
                    l_tyyp = 'KULUD';
                ELSIF v_journal.kreedit = '20356001'
                THEN
                    l_tyyp = 'TULUD';
                ELSIF left(v_journal.deebet, 6) = '20356001'
                THEN
                    -- выплата карманных
                    l_tyyp = 'KULUD';
                ELSE
                    l_tyyp = 'KULUD';
                END IF;


                -- опредлеляем источник
                l_allikas = CASE
                                WHEN (left(v_journal.deebet, 6) = '100100' AND
                                      v_journal.kreedit IN ('203630', '20363001') OR
                                      v_journal.deebet IN ('203630', '20363001')) THEN
                                    'PENSION85'
                                WHEN (left(v_journal.deebet, 6) = '100100' AND
                                      v_journal.kreedit IN ('20363002') OR
                                      v_journal.deebet IN ('20363002')) THEN
                                    'PENSION15'
                                WHEN (left(v_journal.deebet, 6) = '100100' AND
                                      v_journal.kreedit IN ('20363003') OR
                                      v_journal.deebet IN ('20363003')) THEN
                                    'TOETUS'
                                WHEN (left(v_journal.deebet, 6) = '100100' AND
                                      v_journal.kreedit IN ('20363004') OR
                                      v_journal.deebet IN ('20363004')) THEN
                                    'VARA'
                                WHEN (left(v_journal.deebet, 6) = '100100' AND
                                      v_journal.kreedit IN ('20363005') OR
                                      v_journal.deebet IN ('20363005')) THEN
                                    'MUUD'
                                WHEN (v_journal.kreedit IN ('20356001') OR v_journal.deebet IN ('20356001')) THEN
                                    'TASKURAHA'
                                ELSE
                                    'PENSION85'
                    END;

                -- kontrollime kas ettemaks juba koostatud
                SELECT coalesce(e.id, 0)
                INTO l_id
                FROM hooldekodu.hootehingud e
                WHERE dokid = v_journal.journal1Id
                  AND status < 3;

                SELECT coalesce(l_id, 0)                                               AS id,
                       v_journal.asutusId                                              AS isikid,
                       v_journal.journal1Id                                            AS dokid,
                       v_journal.id                                                    AS journalid,
                       v_journal.kpv                                                   AS kpv,
                       'LAUSEND'                                                       AS doktyyp,
                       l_tyyp                                                          AS tyyp,
                       CASE WHEN l_tyyp = 'KULUD' THEN -1 ELSE 1 END * v_journal.summa AS summa,
                       v_journal.selg :: TEXT                                          AS muud,
                       v_journal.rekvid,
                       l_allikas                                                       AS allikas,
                       is_import                                                       AS import
                INTO v_tehing;


                SELECT row_to_json(row)
                INTO json_params
                FROM (SELECT coalesce(l_id, 0) AS id, row_to_json(v_tehing) AS data) row;

                result = hooldekodu.sp_salvesta_hootehing(json_params, user_id, v_journal.rekvid);


            END LOOP;

        -- удалим те операции, которых нет в этой проводке
        DELETE
        FROM hooldekodu.hootehingud
        WHERE isikid = v_journal.asutusId
          AND journalid = lausend_id
          AND dokid NOT IN (SELECT j1.id
                            FROM docs.journal j
                                     INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                            WHERE j.parentid = lausend_id)
          AND status < 3;

        PERFORM hooldekodu.sp_calc_hoojaak(v_journal.asutusId);
        RETURN;
    END IF;
END ;
$$;


GRANT EXECUTE ON FUNCTION hooldekodu.sp_koosta_hootehing(INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_koosta_hootehing(INTEGER, JSONB) TO dbpeakasutaja;

/*
select * from hooldekodu.sp_koosta_hootehing(5175, '{"id":5293464,"import":false}')

 select * from public.cur_journal
where rekvid = 64
order by id desc limit 10


 */
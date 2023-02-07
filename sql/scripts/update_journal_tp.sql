DROP FUNCTION IF EXISTS eelarve.update_journal_tp();

CREATE FUNCTION eelarve.update_journal_tp()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_j1    RECORD;
    v_row RECORD;
    l_count INTEGER = 0;
BEGIN
    FOR v_j1 IN
        SELECT j1.*, j.rekvid
        FROM remote_journal1 j1
                 INNER JOIN docs.journal j ON j.id = j1.parentid
        WHERE (lisa_d = '800301' OR lisa_k = '800301')
        and kpv >= '2022-01-01'
        and j1.id in (select id from docs.journal1 where (lisa_d = '800399' or lisa_k = '800399'))
    LOOP
        insert into ou.logs (rekvid, user_id, doc_id, timestamp, propertis, changes)
        values (v_j1.rekvid, 0, v_j1.id, now(),jsonb_build_object('table', 'journal1'), jsonb_build_object('lisa_d', v_j1.lisa_d, 'lisa_k', v_j1.lisa_k));

        update docs.journal1 set lisa_d = v_j1.lisa_d, lisa_k = v_j1.lisa_k where id = v_j1.id;

    END LOOP;


    RETURN l_count;

END;
$$;

SELECT eelarve.update_journal_tp();

DROP FUNCTION IF EXISTS eelarve.update_journal_tp();

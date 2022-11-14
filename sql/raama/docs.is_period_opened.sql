-- FUNCTION: docs.is_period_opened(integer)

-- DROP FUNCTION docs.is_period_opened(integer);

CREATE OR REPLACE FUNCTION docs.is_period_opened(
    doc_id INTEGER)
    RETURNS BOOLEAN
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
DECLARE
    l_table_name  TEXT;
    lcSqlString   TEXT;
    l_kpv         DATE;
    l_doc_type_id TEXT;
    l_status      INTEGER = 0;
    l_rekv_id     INTEGER;
BEGIN
    -- поиск типа документа
    SELECT l.kood, d.rekvid INTO l_doc_type_id, l_rekv_id
    FROM libs.library l
             INNER JOIN docs.doc d ON d.doc_type_id = l.id
    WHERE d.id = doc_id;

    IF l_doc_type_id IS NULL
    THEN
        -- документ не найден или его тип
        RETURN TRUE;
    END IF;
    -- поиск даты
    CASE
        WHEN l_doc_type_id = 'ARV'
            THEN
                l_table_name = 'docs.arv';
        WHEN l_doc_type_id = 'SORDER' OR l_doc_type_id = 'VORDER'
            THEN
                l_table_name = 'docs.korder1';
        WHEN l_doc_type_id = 'MK' OR l_doc_type_id = 'SMK' OR l_doc_type_id = 'VMK'
            THEN
                l_table_name = 'docs.mk';
        WHEN l_doc_type_id = 'TAOTLUS'
            THEN
                l_table_name = 'eelarve.taotlus';
        WHEN l_doc_type_id = 'JOURNAL'
            THEN
                l_table_name = 'docs.journal';
        WHEN l_doc_type_id = 'AVANS'
            THEN
                l_table_name = 'docs.journal';
        WHEN l_doc_type_id = 'PV_OPER'
            THEN
                l_table_name = 'docs.pv_oper';
        WHEN l_doc_type_id = 'PALK_OPER'
            THEN
                l_table_name = 'docs.pv_oper';
        ELSE
            RETURN TRUE;
        END CASE;

    IF l_table_name IS NULL
    THEN
        RETURN TRUE;
    END IF;

    lcSqlString = 'select kpv from docs.doc d inner join '
        || l_table_name || ' tbl on d.id = tbl.parentid and d.status <> 3 '
        || ' where d.id = $1::integer';

    EXECUTE lcSqlString
        INTO l_kpv
        USING doc_id;

    IF l_kpv IS NULL
    THEN
        RETURN TRUE;
    END IF;

    -- period

    SELECT kinni INTO l_status
    FROM ou.aasta a
    WHERE rekvid = l_rekv_id
      AND aasta = date_part('year',l_kpv)
      AND kuu = date_part('month',l_kpv)
    LIMIT 1;

    IF l_status IS NULL OR l_status = 0
    THEN
        RETURN TRUE;
    ELSE
        -- period closed
        RETURN FALSE;
    END IF;
END;
$BODY$;

ALTER FUNCTION docs.is_period_opened(INTEGER)
    OWNER TO vlad;

GRANT EXECUTE ON FUNCTION docs.is_period_opened(INTEGER) TO arvestaja;

GRANT EXECUTE ON FUNCTION docs.is_period_opened(INTEGER) TO dbkasutaja;

GRANT EXECUTE ON FUNCTION docs.is_period_opened(INTEGER) TO dbpeakasutaja;

GRANT EXECUTE ON FUNCTION docs.is_period_opened(INTEGER) TO vlad;

GRANT EXECUTE ON FUNCTION docs.is_period_opened(INTEGER) TO PUBLIC;


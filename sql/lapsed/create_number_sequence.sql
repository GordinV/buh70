DROP FUNCTION IF EXISTS docs.create_number_sequence(INTEGER, TEXT);
DROP FUNCTION IF EXISTS docs.create_number_sequence(INTEGER, TEXT, BOOLEAN);

CREATE FUNCTION docs.create_number_sequence(l_rekvid INTEGER, l_dok TEXT, l_found_last_num BOOLEAN DEFAULT TRUE)
    RETURNS TEXT
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_sequence_name TEXT = lower(l_dok) || '_' || l_rekvid::TEXT || '_number';
    l_sql           TEXT;
    l_number        TEXT;
    l_result        INTEGER;
    l_last_id       INTEGER;
BEGIN
    -- sequence name
    -- check if exists sequencetbl
    IF NOT EXISTS(
            SELECT 1 FROM pg_class WHERE relname = l_sequence_name
        )
    THEN
        -- IF NOT then sql for create sequence

        -- get last doc number
        IF l_found_last_num
        THEN

            l_sql = 'select (max(SUBSTRING(''0'' || coalesce(tbl.number,''0''), ' || quote_literal('Y*[0-9]\d+') ||
                    ')::bigint) ::bigint) from docs.' || l_dok || ' tbl where rekvid = $1 ' ||
                    CASE WHEN l_dok = 'ARV' THEN ' and liik = 0' ELSE '' END;
            EXECUTE l_sql INTO l_number USING l_rekvid;

            IF len(l_number) > 6
            THEN
                l_number = '1';
            END IF;
        ELSE
            l_number = '1';
        END IF;

        l_sql = 'CREATE SEQUENCE ' || l_sequence_name || ' AS integer;' ||
                'GRANT ALL ON SEQUENCE ' || l_sequence_name || ' TO public;';

        IF l_number IS NOT NULL AND l_number::INTEGER > 0
        THEN
            -- will store last value
            l_sql = l_sql || 'select setval(' || quote_literal(l_sequence_name) || ',' || l_number || ');';

        END IF;

        -- execute sequnce
        EXECUTE l_sql;
    ELSE
        l_sql = 'GRANT ALL ON SEQUENCE ' || l_sequence_name || ' TO public;';

        IF l_number IS NOT NULL AND l_number::INTEGER > 0
        THEN
            -- will store last value
            l_sql = l_sql || 'select setval(' || quote_literal(l_sequence_name) || ',0);';

        END IF;

        -- execute sequnce
        EXECUTE l_sql;
    END IF;

    -- return name of sequence

    RETURN l_sequence_name;
END;
$$;

GRANT EXECUTE ON FUNCTION docs.create_number_sequence(INTEGER, TEXT, BOOLEAN) TO arvestaja;
GRANT EXECUTE ON FUNCTION docs.create_number_sequence(INTEGER, TEXT, BOOLEAN) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.create_number_sequence(INTEGER, TEXT, BOOLEAN) TO dbpeakasutaja;

/*
select docs.create_number_sequence(63, 'ARV')
DROP SEQUENCE ARV_63_number
ALTER SEQUENCE arv_63_number START  WITH 43
SELECT * FROM pg_class WHERE relname = 'arv_63_number'

select setval('arv_63_number', 43)
select currval('arv_' || 63::text || '_number')

SELECT * FROM DOCS.ARV
select (max(SUBSTRING('0' || coalesce(tbl.number,'0'), E'Y*[0-9]\\d+')::bigint) ::bigint) from docs.ARV tbl where rekvid = 63
 */
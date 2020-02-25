-- управление правами в зависимости от статуса

DROP FUNCTION IF EXISTS docs.trigIU_doc_before_aasta() CASCADE;
DROP FUNCTION IF EXISTS trigIU_doc_before_aasta() CASCADE;

CREATE FUNCTION docs.trigIU_doc_before_aasta()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
DECLARE

BEGIN

    -- 0 = открыт
    -- 1 закрыт
    IF NOT docs.is_period_opened(new.id)
    THEN
        RAISE EXCEPTION 'Period on suletatud';
    END IF;
    RETURN new;
END;
$$;


DROP TRIGGER IF EXISTS trigIU_doc_before_aasta
    ON docs.doc;

CREATE TRIGGER trigIU_doc_before_aasta
    BEFORE UPDATE OR INSERT
    ON docs.doc
    FOR EACH ROW
EXECUTE PROCEDURE docs.trigIU_doc_before_aasta();



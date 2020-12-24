-- управление правами в зависимости от статуса

DROP FUNCTION IF EXISTS docs.trigI_doc_before_chield() CASCADE;

CREATE FUNCTION docs.trigI_doc_before_chield()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
DECLARE

BEGIN
    raise notice 'trig start insert %', new.id;
    IF (year(date()) = 2020)
    THEN
        raise notice 'insert %', new.id;
        INSERT INTO docs.doc_2020 SELECT new.*;
    END IF;

    RETURN new;
END;
$$;


DROP TRIGGER IF EXISTS trigI_doc_before_chield
    ON docs.doc CASCADE;

CREATE TRIGGER trigI_doc_before_chield
    BEFORE INSERT
    ON docs.doc
    FOR EACH ROW
EXECUTE PROCEDURE docs.trigI_doc_before_chield();



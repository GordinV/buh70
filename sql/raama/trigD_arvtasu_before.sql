DROP TRIGGER IF EXISTS trigD_arvtasu_before
    ON docs.arvtasu CASCADE;

DROP FUNCTION IF EXISTS docs.trigD_arvtasu_before();

CREATE FUNCTION docs.trigD_arvtasu_before()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
BEGIN
    IF old.properties ->> 'ebatoenaolised_tagastamine_id' IS NOT NULL AND exists
        (SELECT id FROM cur_journal WHERE id = (old.properties ->> 'ebatoenaolised_tagastamine_id')::INTEGER)
    THEN
        RAISE EXCEPTION 'Viga: ei saa kustuta tasu ümber jaotamine';
    END IF;

    RETURN old;

END;
$$;

CREATE TRIGGER trigD_arvtasu_before
    AFTER DELETE
    ON docs.arvtasu
    FOR EACH ROW
EXECUTE PROCEDURE docs.trigD_arvtasu_before();

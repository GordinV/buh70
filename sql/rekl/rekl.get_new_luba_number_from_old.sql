DROP FUNCTION IF EXISTS rekl.get_new_luba_number_from_old(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION rekl.get_new_luba_number_from_old(old_number TEXT)
    RETURNS VARCHAR(20)
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_number    VARCHAR(20);
    l_kuu       TEXT;
    l_aasta     TEXT;
    l_klient_id TEXT;
BEGIN
    l_kuu = left(old_number, position('/' IN old_number) - 1);
    l_aasta = substring(old_number FROM position('/' IN old_number) + 1 FOR 4);
    l_klient_id = ltrim(rtrim(substring(old_number FROM position('-' IN old_number) + 1)));
    if empty(l_klient_id) THEN
        l_klient_id = '00000';
    END IF;

    IF (length(l_kuu) > 2)
    THEN
        -- uus format
        l_number = old_number;
    ELSE
        -- Антон, новый формат
        l_number = coalesce(l_klient_id, '0001') || '/' || l_aasta::TEXT || '-' || l_kuu::TEXT;

    END IF;
    RETURN l_number;
END;
$$;

SELECT rekl.get_new_luba_number_from_old('460/2020-08')

/*


update rekl.luba set number = rekl.get_new_luba_number_from_old(number)

select rekl.get_new_luba_number_from_old(number), number, staatus from rekl.luba
order by id desc


*/
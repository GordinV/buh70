DROP FUNCTION IF EXISTS update_saldoandmik();

CREATE FUNCTION update_saldoandmik()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_saldoandmik RECORD;
    l_nimetus text;
BEGIN
    FOR v_saldoandmik IN
        SELECT id, konto, nimetus
        FROM eelarve.saldoandmik s
        WHERE aasta < 2021
        and ltrim(rtrim(nimetus)) not in (select ltrim(rtrim(nimetus)) from libs.library where library.library = 'KONTOD' and kood = s.konto)
        LOOP
            l_nimetus = (select nimetus from libs.library where kood = v_saldoandmik.konto and library.library = 'KONTOD' and status < 3 ORDER BY id desc limit 1);
            raise notice 'konto % id % uus %', v_saldoandmik.konto, v_saldoandmik.id, l_nimetus;
            if l_nimetus is not null then
                update eelarve.saldoandmik set nimetus = l_nimetus where id = v_saldoandmik.id;
            END IF;
        END LOOP;
    RETURN 1;

END;
$$;

SELECT update_saldoandmik();

DROP FUNCTION IF EXISTS update_saldoandmik();



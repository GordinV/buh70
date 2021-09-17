DROP FUNCTION IF EXISTS update_aa();

CREATE FUNCTION update_aa()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_aa   RECORD;
    v_rekv RECORD;
BEGIN
    FOR v_aa IN
        SELECT * FROM ou.aa WHERE parentid = 66
        LOOP
            raise notice 'checking %', v_aa.arve;
            FOR v_rekv IN
                SELECT * FROM ou.rekv WHERE parentid = 119
                                        AND id not in (66, 67)
                LOOP
                    IF (SELECT count(id)
                        FROM ou.aa
                        WHERE parentid = v_rekv.id
                          AND upper(ltrim(rtrim(arve))) = upper(ltrim(rtrim(v_aa.arve)))
                          AND kassa = v_aa.kassa)
                    THEN
                        raise notice 'updating %', v_rekv.id;

                        -- exists
                        UPDATE ou.aa
                        SET nimetus  = v_aa.nimetus,
                            default_ = v_aa.default_,
                            pank     = v_aa.pank,
                            konto    = v_aa.konto,
                            tp       = v_aa.tp
                        WHERE parentid = v_rekv.id
                          AND upper(ltrim(rtrim(arve))) = upper(ltrim(rtrim(v_aa.arve)))
                          AND kassa = v_aa.kassa;
                    ELSE
                        raise notice 'inserting %', v_rekv.id;

                        INSERT INTO ou.aa (parentid, arve, nimetus, default_, kassa, pank, konto, muud, tp)
                        VALUES (v_rekv.id, v_aa.arve, v_aa.nimetus, v_aa.default_, v_aa.kassa, v_aa.pank, v_aa.konto,
                                v_aa.muud, v_aa.tp);
                    END IF;

                END LOOP;

        END LOOP;
return 1;
END;

$$;

SELECT update_aa();

DROP FUNCTION IF EXISTS update_aa();


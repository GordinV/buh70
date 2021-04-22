DROP FUNCTION IF EXISTS lapsed.mode_aa_to_vanem_arveldus();

CREATE FUNCTION lapsed.mode_aa_to_vanem_arveldus()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_vanem RECORD;
BEGIN
    FOR v_vanem IN
        SELECT *,
               v.properties ->> 'pank' AS pank,
               v.properties ->> 'iban' AS iban
        FROM lapsed.vanemad v
        WHERE (properties -> 'kas_earve') IS NOT NULL
          AND (properties ->> 'kas_earve')::BOOLEAN
        LOOP
            -- update
            UPDATE lapsed.vanem_arveldus
            SET properties = json_build_object('kas_earve', TRUE, 'pank', v_vanem.pank, 'iban', v_vanem.iban)
            WHERE parentid = v_vanem.parentid
              AND asutusid = v_vanem.asutusid;
        END LOOP;
    RETURN 1;

END;
$$;

SELECT lapsed.mode_aa_to_vanem_arveldus();

DROP FUNCTION IF EXISTS lapsed.mode_aa_to_vanem_arveldus();



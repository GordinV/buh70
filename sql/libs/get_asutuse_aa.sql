DROP FUNCTION IF EXISTS libs.get_asutuse_aa(INTEGER, TEXT);

CREATE FUNCTION libs.get_asutuse_aa(IN asutus_id INTEGER, IN module TEXT, OUT aa TEXT)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_aa      RECORD;
    l_aa      TEXT;
    l_aa_tyyp TEXT = CASE
                         WHEN module IS NULL THEN NULL
                         WHEN module = 'PALK' THEN 'kas_palk'
                         WHEN module = 'ÕPPETASU' THEN 'kas_oppetasu'
                         WHEN module = 'RAAMATUPIDAMINE' THEN 'kas_raamatupidamine'
        END ;

BEGIN

    FOR v_aa IN
        SELECT (e.element ->> 'aa') :: VARCHAR(20)       AS aa,
               (e.element ->> 'kas_palk') :: BOOLEAN     AS kas_palk,
               (e.element ->> 'kas_raama') :: BOOLEAN    AS kas_raama,
               (e.element ->> 'kas_oppetasu') :: BOOLEAN AS kas_oppetasu,
               row_number() OVER ()                      AS id,
               count(*) OVER ()                          AS kokku
        FROM libs.asutus a,
             json_array_elements(CASE
                                     WHEN (a.properties ->> 'asutus_aa') IS NULL THEN '[]'::JSON
                                     WHEN (a.properties ->> 'asutus_aa') = '' THEN '[]'::JSON
                                     ELSE (a.properties -> 'asutus_aa') :: JSON END) AS e (element)
        WHERE a.id = asutus_id
          AND ltrim(rtrim(coalesce((e.element ->> 'aa'), ''))) <> ''
        LOOP
            CASE
                WHEN module IS NULL THEN
                    aa = v_aa.aa;
                    EXIT;
                WHEN module = 'PALK' AND v_aa.kas_palk THEN
                    aa = v_aa.aa;
                    EXIT;
                WHEN module = 'ÕPPETASU' OR module = 'OPPE' AND v_aa.kas_oppetasu THEN
                    aa = v_aa.aa;
                    EXIT;
                WHEN module = 'RAAMATUPIDAMINE' OR module = 'RAAMA' AND v_aa.kas_raama THEN
                    aa = v_aa.aa;
                    EXIT;
                ELSE
                    aa = v_aa.aa;
                END CASE;
        END LOOP;

    RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION libs.get_asutuse_aa(INTEGER, TEXT) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION libs.get_asutuse_aa(INTEGER, TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.get_asutuse_aa(INTEGER, TEXT) TO dbpeakasutaja;


/*
SELECT libs.get_asutuse_aa(30984, 'PALK'::TEXT);

select * from ou.aa where id = 269
-- EE502200221011482108
*/
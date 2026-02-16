DROP FUNCTION IF EXISTS libs.get_konto_laiendus(TEXT);

CREATE FUNCTION libs.get_konto_laiendus(l_konto TEXT)
    RETURNS JSONB
    LANGUAGE plpgsql
AS
$$
DECLARE
    tulemus      JSONB = '{}'::JSONB;
    v_konto_tyyp record;
BEGIN

    IF l_konto IS NOT NULL
    THEN
        select
            exists
            (
                select
                    1
                from
                    palk.palk_kulu_kontod pk
                where
                    l_konto in (
                                   select unnest(pk.puhkused_kontod)
                               )
            ) as puhkuse_konto,
            exists
            (
                select
                    1
                from
                    palk.palk_kulu_kontod pk
                where
                    l_konto in (
                                   select unnest(pk.koolitus_kontod)
                               )
            ) as koolituse_konto,
            exists
            (
                select
                    1
                from
                    palk.palk_kulu_kontod pk
                where
                    l_konto in (
                                   select unnest(pk.huvitised_kontod)

                               )
            ) as haiguse_konto
        into v_konto_tyyp;

        tulemus = to_jsonb(v_konto_tyyp);

    END IF;
    RETURN tulemus;
END;

$$;

GRANT EXECUTE ON FUNCTION libs.get_konto_laiendus(TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.get_konto_laiendus(TEXT) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION libs.get_konto_laiendus(TEXT) TO dbpeakasutaja;

select
    (konto_tyyp ->> 'puhkuse_konto')::boolean   as kas_puhkuse_konto,
    (konto_tyyp ->> 'koolituse_konto')::boolean as kas_koolituse_konto,
    (konto_tyyp ->> 'haiguse_konto')::boolean as kas_haiguse_konto

from
    libs.get_konto_laiendus('50010003'::text) as konto_tyyp


/*



*/


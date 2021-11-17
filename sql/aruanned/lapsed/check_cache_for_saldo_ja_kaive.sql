DROP FUNCTION IF EXISTS lapsed.check_cache_for_saldo_ja_kaive(DATE);
DROP FUNCTION IF EXISTS lapsed.check_cache_for_saldo_ja_kaive();

CREATE FUNCTION lapsed.check_cache_for_saldo_ja_kaive(l_kpv DATE DEFAULT NULL)
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_periods RECORD;
    l_params  JSONB;
BEGIN

    FOR v_periods IN
        SELECT rekvid, max(lastupdate) AS lastupdate, kuu, aasta
        FROM (
                 SELECT d.rekvid, max(d.lastupdate) AS lastupdate, month(arv.kpv) AS kuu, year(arv.kpv) AS aasta
                 FROM docs.doc d
                          INNER JOIN docs.arv arv ON arv.parentid = d.id
                 WHERE d.lastupdate::DATE BETWEEN current_date - 1 AND current_date
                   AND (l_kpv IS NULL OR (month(arv.kpv) = month(l_kpv) AND year(arv.kpv) = year(l_kpv)))
                 GROUP BY d.rekvid, month(arv.kpv), year(arv.kpv)
                 UNION ALL
                 SELECT d.rekvid, max(d.lastupdate), month(mk.maksepaev) AS kuu, year(mk.maksepaev) AS aasta
                 FROM docs.doc d
                          INNER JOIN docs.mk mk ON mk.parentid = d.id
                 WHERE d.lastupdate::DATE BETWEEN current_date - 1 AND current_date
                   AND (l_kpv IS NULL OR (month(mk.maksepaev) = month(l_kpv) AND year(mk.maksepaev) = year(l_kpv)))
                 GROUP BY d.rekvid, month(mk.maksepaev), year(mk.maksepaev)
             ) qry
        GROUP BY rekvid, kuu, aasta
        LOOP
            l_params = jsonb_build_object('kpv_start', make_date(v_periods.aasta, v_periods.kuu, 1)::DATE, 'kpv_end',
                                          (gomonth(make_date(v_periods.aasta, v_periods.kuu, 1), 1) - 1) ::DATE);
            IF NOT exists(SELECT q.id
                          FROM lapsed.saldo_ja_kaive q
                          WHERE q.params @> l_params
                            AND q.created > v_periods.lastupdate
                            AND q.rekvid = v_periods.rekvid
                )

            THEN
                RAISE NOTICE 'start cashe % , %', v_periods.rekvid, l_params;
                PERFORM
                FROM lapsed.create_cache_for_saldo_ja_kaive(v_periods.rekvid, l_params::JSONB);
            END IF;
        END LOOP;
    RETURN 1;
END
$$;

GRANT EXECUTE ON FUNCTION lapsed.check_cache_for_saldo_ja_kaive(DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.check_cache_for_saldo_ja_kaive(DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.check_cache_for_saldo_ja_kaive(DATE) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.check_cache_for_saldo_ja_kaive(DATE) TO dbvaatleja;


/*
SELECT *
FROM lapsed.check_cache_for_saldo_ja_kaive('2021-01-31'::date);

 */
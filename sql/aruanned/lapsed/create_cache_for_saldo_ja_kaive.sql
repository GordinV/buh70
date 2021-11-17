DROP FUNCTION IF EXISTS lapsed.create_cache_for_saldo_ja_kaive(INTEGER, JSONB);

CREATE FUNCTION lapsed.create_cache_for_saldo_ja_kaive(l_rekvid INTEGER, l_params JSONB)
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_start DATE = coalesce((l_params ->> 'kpv_start')::DATE, make_date(year(current_date), 1, 1))::DATE;
    l_end   DATE = coalesce((l_params ->> 'kpv_end')::DATE, current_date)::DATE;
    v_periods record;
BEGIN
    SELECT rekvid, max(lastupdate), kuu, aasta
    from (
             SELECT d.rekvid, max(d.lastupdate) AS lastupdate, month(arv.kpv) AS kuu, year(arv.kpv) AS aasta
             FROM docs.doc d
                      INNER JOIN docs.arv arv ON arv.parentid = d.id
             WHERE d.lastupdate::DATE BETWEEN current_date - 1 AND current_date
             GROUP BY d.rekvid, month(arv.kpv), year(arv.kpv)
             UNION ALL
             SELECT d.rekvid, max(d.lastupdate), month(mk.maksepaev) AS kuu, year(mk.maksepaev) AS aasta
             FROM docs.doc d
                      INNER JOIN docs.mk mk ON mk.parentid = d.id
             WHERE d.lastupdate::DATE BETWEEN current_date - 1 AND current_date
             GROUP BY d.rekvid, month(mk.maksepaev), year(mk.maksepaev)
         ) qry
    GROUP BY rekvid, kuu, aasta

    -- удаляем отчет из кеша
    DELETE
    FROM lapsed.saldo_ja_kaive
    WHERE rekvid IN (SELECT rekv_id
                     FROM get_asutuse_struktuur(l_rekvid)
    )
      AND params @> l_params;

    -- создаем отчет
    INSERT INTO lapsed.saldo_ja_kaive (id, period, kulastatavus, lapse_nimi, lapse_isikukood, yksus, viitenumber,
                                       alg_saldo, arvestatud, soodustus, laekumised, mahakantud, tagastused, jaak,
                                       rekvid, created, params)

    SELECT q.id,
           q.period,
           q.kulastatavus::TEXT,
           q.lapse_nimi ::TEXT,
           q.lapse_isikukood ::TEXT,
           q.yksus ::TEXT,
           q.viitenumber ::TEXT,
           q.alg_saldo ::NUMERIC(14, 4),
           q.arvestatud ::NUMERIC(14, 4),
           q.soodustus ::NUMERIC(14, 4),
           q.laekumised ::NUMERIC(14, 4),
           q.mahakantud ::NUMERIC(14, 4),
           q.tagastused ::NUMERIC(14, 4),
           q.jaak ::NUMERIC(14, 4),
           q.rekvid,
           now(),
           l_params
    FROM lapsed.saldo_ja_kaive(l_rekvid,
                               l_start::DATE,
                               l_end:: DATE) q;
    RETURN 1;
END
$$;

GRANT EXECUTE ON FUNCTION  lapsed.create_cache_for_saldo_ja_kaive(INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.create_cache_for_saldo_ja_kaive(INTEGER, JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.create_cache_for_saldo_ja_kaive(INTEGER, JSONB) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.create_cache_for_saldo_ja_kaive(INTEGER, JSONB) TO dbvaatleja;


/*
SELECT *
FROM lapsed.create_cache_for_saldo_ja_kaive(71,'{"kpv_start": "2021-01-01", "kpv_end": "2021-01-31"}'::JSONB);

 */
DROP FUNCTION IF EXISTS lapsed.get_saldo_ja_kaive_from_cache(JSONB);
DROP FUNCTION IF EXISTS lapsed.get_saldo_ja_kaive_from_cache(INTEGER, JSONB);

CREATE FUNCTION lapsed.get_saldo_ja_kaive_from_cache(l_rekvid INTEGER, l_params JSONB)
    RETURNS TABLE (
        id              BIGINT,
        period          DATE,
        kulastatavus    TEXT,
        lapse_nimi      TEXT,
        lapse_isikukood TEXT,
        yksus           TEXT,
        viitenumber     TEXT,
        alg_saldo       NUMERIC(14, 4),
        arvestatud      NUMERIC(14, 4),
        soodustus       NUMERIC(14, 4),
        laekumised      NUMERIC(14, 4),
        mahakantud      NUMERIC(14, 4),
        tagastused      NUMERIC(14, 4),
        jaak            NUMERIC(14, 4),
        rekvid          INTEGER
    )
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_start         DATE = coalesce((l_params ->> 'kpv_start')::DATE, make_date(year(current_date), 1, 1))::DATE;
    l_end           DATE = coalesce((l_params ->> 'kpv_end')::DATE, current_date)::DATE;
    l_timestamp     TIMESTAMP;
    l_max_timestamp TIMESTAMP;
BEGIN
    IF l_params ->> 'kpv_end' IS NULL
    THEN
        RETURN QUERY
            SELECT NULL:: DATE,
                   NULL:: TEXT,
                   NULL:: TEXT,
                   NULL:: TEXT,
                   NULL:: TEXT,
                   NULL:: TEXT,
                   0:: NUMERIC(14, 4),
                   0:: NUMERIC(14, 4),
                   0:: NUMERIC(14, 4),
                   0:: NUMERIC(14, 4),
                   0:: NUMERIC(14, 4),
                   0:: NUMERIC(14, 4),
                   0:: NUMERIC(14, 4),
                   NULL:: INTEGER;
    END IF;

    -- последний отчет
    l_max_timestamp = (SELECT max(created)
                       FROM lapsed.saldo_ja_kaive q
                       WHERE (q.params ->> 'kpv_start')::DATE = l_start
                         AND (q.params ->> 'kpv_end')::DATE = l_end
                         AND q.rekvid = l_rekvid
    );


    -- ищем в дату изменения документов
    l_timestamp = (SELECT max(d.lastupdate) AS lastupdate
                   FROM docs.doc d
                            INNER JOIN docs.mk mk ON mk.parentid = d.id
                   WHERE mk.maksepaev <= l_end
                     AND d.status < 3
                     AND d.rekvid IN (SELECT rekv_id
                                      FROM get_asutuse_struktuur(l_rekvid))
                   UNION ALL
                   SELECT max(d.lastupdate) AS lastupdate
                   FROM docs.doc d
                            INNER JOIN docs.arv ON arv.parentid = d.id
                   WHERE arv.kpv <= l_end
                     AND d.rekvid IN (SELECT rekv_id
                                      FROM get_asutuse_struktuur(l_rekvid)
                   )
                     AND d.status < 3
                   ORDER BY lastupdate DESC
                   LIMIT 1);

    -- ищев в кеше

    IF NOT exists(SELECT q.id
                  FROM lapsed.saldo_ja_kaive q
                  WHERE (q.params ->> 'kpv_start')::DATE = l_start
                    AND (q.params ->> 'kpv_end')::DATE = l_end
                    AND q.created > l_timestamp
                    AND q.rekvid = l_rekvid
        )
    THEN
        IF (l_params ->> 'kpv_end') IS NULL
        THEN
            l_params = jsonb_build_object('kpv_start', l_start, 'kpv_end', l_end);
        END IF;

        PERFORM
        FROM lapsed.create_cache_for_saldo_ja_kaive(l_rekvid, l_params::JSONB);
    END IF;

    RETURN QUERY
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
               q.rekvid
        FROM lapsed.saldo_ja_kaive q
        WHERE q.rekvid IN (SELECT rekv_id
                           FROM get_asutuse_struktuur(l_rekvid))
          AND created = l_max_timestamp
          AND (q.params ->> 'kpv_start')::DATE = l_start
          AND (q.params ->> 'kpv_end')::DATE = l_end;
END
$$;

GRANT EXECUTE ON FUNCTION lapsed.get_saldo_ja_kaive_from_cache(INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_saldo_ja_kaive_from_cache(INTEGER, JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_saldo_ja_kaive_from_cache(INTEGER, JSONB) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.get_saldo_ja_kaive_from_cache(INTEGER, JSONB) TO dbvaatleja;


/*
    SELECT  *
    FROM lapsed.get_saldo_ja_kaive_from_cache(71,'{"kpv_start": "2021-01-01", "kpv_end": "2021-01-31"}'::JSONB)
*/
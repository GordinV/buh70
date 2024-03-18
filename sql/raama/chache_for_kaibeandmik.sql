DROP FUNCTION IF EXISTS docs.cache_for_kaibeandmik(DATE, BOOLEAN);

CREATE FUNCTION docs.cache_for_kaibeandmik(l_kpv DATE, l_force BOOLEAN DEFAULT FALSE)
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_kpv_alg            DATE    = make_date(year(l_kpv), 01, 01);
    l_kpv_lopp           DATE    = make_date(year(l_kpv), month(l_kpv), 01) + INTERVAL '1 month' - INTERVAL '1 day';
    v_rekv               RECORD;
    l_rahandus_amet_id   INTEGER = 63;
    l_last_doc_timestamp TIMESTAMP;
    DOC_TYPE_JOURNAL     INTEGER = 57; -- тип проводки
BEGIN
    -- проверяем наличие таблицы
    IF NOT exists(SELECT 1
                  FROM pg_class
                  WHERE relname = 'cache_kaibeandmik'
        )
    THEN
        CREATE TABLE cache_kaibeandmik (
            rekv_id   INT,
            alg_saldo NUMERIC(14, 2),
            deebet    NUMERIC(14, 2),
            kreedit   NUMERIC(14, 2),
            konto     VARCHAR(20),
            alg_kpv   DATE,
            lopp_kpv  DATE,
            timestamp TIMESTAMP DEFAULT now()
        );

    END IF;

    -- проверяем наличие и необходимость расчета
    SELECT max(d.lastupdate) AS last_update
    INTO l_last_doc_timestamp
    FROM docs.journal j
             INNER JOIN docs.doc d ON d.id = j.parentid
    WHERE j.kpv <= l_kpv_lopp
      AND d.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rahandus_amet_id));

    IF NOT exists(SELECT 1
                  FROM cache_kaibeandmik
                  WHERE timestamp < l_last_doc_timestamp
                    AND lopp_kpv = l_kpv_lopp) OR l_force
    THEN

        -- удаляем старый расчет
        DELETE
        FROM cache_kaibeandmik
        WHERE lopp_kpv >= l_kpv_lopp;
        -- делаем расчет оборотки
        FOR v_rekv IN
            SELECT rekv_id
            FROM get_asutuse_struktuur(l_rahandus_amet_id)
            LOOP
                RAISE NOTICE 'Arvestan  v_rekv.rekv_id %, l_kpv_alg %, l_kpv_lopp %', v_rekv.rekv_id, l_kpv_alg, l_kpv_lopp;

                INSERT INTO cache_kaibeandmik (rekv_id, alg_saldo, deebet, kreedit, konto, alg_kpv, lopp_kpv)
                SELECT v_rekv.rekv_id,
                       report.alg_saldo,
                       report.deebet,
                       report.kreedit,
                       report.konto,
                       l_kpv_alg,
                       l_kpv_lopp
                FROM docs.kaibeandmik(l_kpv_alg:: DATE, l_kpv_lopp:: DATE, v_rekv.rekv_id, 0, NULL::TEXT,
                                      NULL::JSONB) report;
            END LOOP;
    END IF;

    RETURN 1;
END
$$;

GRANT EXECUTE ON FUNCTION docs.cache_for_kaibeandmik(DATE, BOOLEAN) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.cache_for_kaibeandmik(DATE, BOOLEAN) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.cache_for_kaibeandmik(DATE, BOOLEAN) TO dbvaatleja;


/*
SELECT *
FROM docs.cache_for_kaibeandmik('2022-12-31');

 */
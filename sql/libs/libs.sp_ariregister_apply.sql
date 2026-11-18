-- Атомарное применение данных из libs.ariregister_stage в libs.ariregister и обновление libs.ariregister_meta.
CREATE OR REPLACE FUNCTION libs.sp_ariregister_apply(
    p_file_date DATE,
    p_min_rows  INTEGER
)
    RETURNS JSON AS
$BODY$
DECLARE
    v_stage_count INTEGER;
    v_inserted    INTEGER := 0;
    v_updated     INTEGER := 0;
    v_deleted     INTEGER := 0;
    v_total       INTEGER := 0;
    v_min_rows    INTEGER := COALESCE(p_min_rows, 0);
    v_now         TIMESTAMPTZ := clock_timestamp();
    v_file_date   DATE;
BEGIN
    SELECT count(DISTINCT s.regkood)
    INTO v_stage_count
    FROM libs.ariregister_stage s
    WHERE s.regkood IS NOT NULL
      AND s.nimi IS NOT NULL;

    IF v_stage_count < v_min_rows THEN
        RAISE EXCEPTION 'libs.ariregister_stage valid row count (%) is less than minimum required (%)',
            v_stage_count, v_min_rows;
    END IF;

    v_file_date := p_file_date;
    IF v_file_date IS NULL THEN
        SELECT max(s.file_date)
        INTO v_file_date
        FROM libs.ariregister_stage s
        WHERE s.regkood IS NOT NULL
          AND s.nimi IS NOT NULL;
    END IF;

    WITH upserted AS (
        INSERT INTO libs.ariregister (
            regkood,
            nimi,
            oiguslik_vorm,
            oigusliku_vormi_alaliik,
            kmkr_nr,
            staatus,
            staatus_tekst,
            esmakande_kpv,
            aadress,
            asukoht,
            ehak_kood,
            ehak_tekst,
            indeks,
            ads_adr_id,
            ads_ads_oid,
            taisaadress,
            link,
            file_date,
            loaded_at,
            deleted_at
        )
        SELECT DISTINCT ON (s.regkood)
            s.regkood,
            s.nimi,
            s.oiguslik_vorm,
            s.oigusliku_vormi_alaliik,
            s.kmkr_nr,
            s.staatus,
            s.staatus_tekst,
            s.esmakande_kpv,
            s.aadress,
            s.asukoht,
            s.ehak_kood,
            s.ehak_tekst,
            s.indeks,
            s.ads_adr_id,
            s.ads_ads_oid,
            s.taisaadress,
            s.link,
            COALESCE(v_file_date, s.file_date),
            v_now,
            NULL
        FROM libs.ariregister_stage s
        WHERE s.regkood IS NOT NULL
          AND s.nimi IS NOT NULL
        ORDER BY s.regkood
        ON CONFLICT (regkood) DO UPDATE
            SET nimi                    = EXCLUDED.nimi,
                oiguslik_vorm           = EXCLUDED.oiguslik_vorm,
                oigusliku_vormi_alaliik = EXCLUDED.oigusliku_vormi_alaliik,
                kmkr_nr                 = EXCLUDED.kmkr_nr,
                staatus                 = EXCLUDED.staatus,
                staatus_tekst           = EXCLUDED.staatus_tekst,
                esmakande_kpv           = EXCLUDED.esmakande_kpv,
                aadress                 = EXCLUDED.aadress,
                asukoht                 = EXCLUDED.asukoht,
                ehak_kood               = EXCLUDED.ehak_kood,
                ehak_tekst              = EXCLUDED.ehak_tekst,
                indeks                  = EXCLUDED.indeks,
                ads_adr_id              = EXCLUDED.ads_adr_id,
                ads_ads_oid             = EXCLUDED.ads_ads_oid,
                taisaadress             = EXCLUDED.taisaadress,
                link                    = EXCLUDED.link,
                file_date               = EXCLUDED.file_date,
                loaded_at               = EXCLUDED.loaded_at,
                deleted_at              = NULL
            WHERE (
                libs.ariregister.nimi,
                libs.ariregister.oiguslik_vorm,
                libs.ariregister.oigusliku_vormi_alaliik,
                libs.ariregister.kmkr_nr,
                libs.ariregister.staatus,
                libs.ariregister.staatus_tekst,
                libs.ariregister.esmakande_kpv,
                libs.ariregister.aadress,
                libs.ariregister.asukoht,
                libs.ariregister.ehak_kood,
                libs.ariregister.ehak_tekst,
                libs.ariregister.indeks,
                libs.ariregister.ads_adr_id,
                libs.ariregister.ads_ads_oid,
                libs.ariregister.taisaadress,
                libs.ariregister.link,
                libs.ariregister.deleted_at
            ) IS DISTINCT FROM (
                EXCLUDED.nimi,
                EXCLUDED.oiguslik_vorm,
                EXCLUDED.oigusliku_vormi_alaliik,
                EXCLUDED.kmkr_nr,
                EXCLUDED.staatus,
                EXCLUDED.staatus_tekst,
                EXCLUDED.esmakande_kpv,
                EXCLUDED.aadress,
                EXCLUDED.asukoht,
                EXCLUDED.ehak_kood,
                EXCLUDED.ehak_tekst,
                EXCLUDED.indeks,
                EXCLUDED.ads_adr_id,
                EXCLUDED.ads_ads_oid,
                EXCLUDED.taisaadress,
                EXCLUDED.link,
                NULL
            )
        RETURNING (xmax = 0) AS is_inserted
    )
    SELECT
        count(*) FILTER (WHERE is_inserted),
        count(*) FILTER (WHERE NOT is_inserted)
    INTO v_inserted, v_updated
    FROM upserted;

    UPDATE libs.ariregister a
    SET deleted_at    = v_now,
        staatus       = 'K',
        staatus_tekst = 'Kustutatud'
    WHERE a.deleted_at IS NULL
      AND NOT EXISTS (
          SELECT 1
          FROM libs.ariregister_stage s
          WHERE s.regkood = a.regkood
            AND s.nimi IS NOT NULL
      );

    GET DIAGNOSTICS v_deleted = ROW_COUNT;

    SELECT count(*)
    INTO v_total
    FROM libs.ariregister
    WHERE deleted_at IS NULL;

    INSERT INTO libs.ariregister_meta (id, file_date, applied_at, rows_total)
    VALUES (1, v_file_date, v_now, COALESCE(v_total, 0))
    ON CONFLICT (id) DO UPDATE
        SET file_date  = EXCLUDED.file_date,
            applied_at = EXCLUDED.applied_at,
            rows_total = EXCLUDED.rows_total;

    RETURN json_build_object(
        'inserted',  COALESCE(v_inserted, 0),
        'updated',   COALESCE(v_updated, 0),
        'deleted',   COALESCE(v_deleted, 0),
        'total',     COALESCE(v_total, 0),
        'file_date', v_file_date
    );
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_ariregister_apply(DATE, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_ariregister_apply(DATE, INTEGER) TO dbpeakasutaja;

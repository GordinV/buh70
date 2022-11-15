DROP FUNCTION IF EXISTS lapsed.update_taabelid_soodustus();

CREATE FUNCTION lapsed.update_taabelid_soodustus()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_tabelid RECORD;
    v_rea     RECORD;
    l_kokku   INTEGER = 0;
BEGIN
    FOR v_tabelid IN
        SELECT lt.id,
               CASE
                   WHEN (lk.properties ->> 'sooduse_alg')::DATE < make_date(lt.aasta, lt.kuu, 1)
                       AND (lk.properties ->> 'sooduse_lopp')::DATE >= make_date(lt.aasta, lt.kuu, 1)
                       THEN 1
                   ELSE 0 END                                       AS sooduse_kehtivus,
               (lk.properties ->> 'sooduse_alg')::DATE              AS sooduse_alg,
               (lk.properties ->> 'sooduse_lopp')::DATE             AS sooduse_lopp,
               lk.hind                                              AS alus_hind,
               (CASE
                    WHEN lk.properties ->> 'soodus' IS NOT NULL THEN coalesce((lk.properties ->> 'soodus')::NUMERIC, 0)
                    ELSE 0 END) ::NUMERIC * CASE
                                                WHEN (lk.properties ->> 'kas_protsent')::BOOLEAN THEN (0.01 * lk.hind)
                                                ELSE 1 END::NUMERIC AS alus_soodustus
        FROM lapsed.lapse_taabel lt
                 INNER JOIN lapsed.lapse_kaart lk ON lk.id = lt.lapse_kaart_id
                 INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
        WHERE lt.properties ->> 'sooduse_alg' IS NOT NULL
          AND lt.staatus < 3
--          AND lt.rekvid = 63
        LOOP
            UPDATE lapsed.lapse_taabel
            SET properties = properties ||
                             jsonb_build_object('alus_soodustus', v_tabelid.alus_soodustus)
            WHERE id = v_tabelid.id;
        END LOOP;
    RETURN l_kokku;

END;
$$;

SELECT lapsed.update_taabelid_soodustus();

DROP FUNCTION IF EXISTS lapsed.update_taabelid_soodustus();


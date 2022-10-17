DROP FUNCTION IF EXISTS lapsed.update_taabelid();

CREATE FUNCTION lapsed.update_taabelid()
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
        SELECT id
        FROM lapsed.lapse_taabel lt
        WHERE  staatus < 3
        LOOP
            SELECT lt.id,
                   lt.parentid,
                   lt.rekvid,
                   lt.nomid,
                   lt.kuu::INTEGER,
                   lt.aasta::INTEGER,
                   lt.kogus::NUMERIC(12, 4),
                   lt.hind::NUMERIC(12, 2),
                   lt.uhik,
                   CASE WHEN lt.umberarvestus THEN 'Jah' ELSE 'Ei' END::TEXT                    AS umberarvestus,
                   (CASE
                        WHEN lt.kas_protsent THEN (lt.hind * lt.kogus)::NUMERIC(12, 2) *
                                                  ((lt.soodustus * lt.sooduse_kehtivus) / 100)
                        ELSE lt.soodustus * lt.kogus * lt.sooduse_kehtivus END)::NUMERIC(12, 2) AS soodustus,
                   ((lt.hind * lt.kogus - (CASE
                                               WHEN lt.kas_protsent THEN (lt.hind * lt.kogus)::NUMERIC(12, 2) *
                                                                         ((lt.soodustus * lt.sooduse_kehtivus) / 100)
                                               ELSE lt.soodustus * lt.kogus * lt.sooduse_kehtivus *
                                                    (CASE WHEN lt.tyyp IS NOT NULL AND lt.tyyp = 'SOODUSTUS' THEN 0 ELSE 1 END)
                       END)))::NUMERIC(12, 2)                                                   AS summa,
                   lt.isikukood,
                   lt.nimi,
                   lt.kood,
                   lt.teenus,
                   (coalesce(lt.yksus, '') ||
                    CASE WHEN lt.all_yksus IS NULL THEN '' ELSE '-' || lt.all_yksus END)        AS yksus,
                   lt.viitenr,
                   lt.muud,
                   lt.kulastused,
                   lt.too_paevad,
                   lt.kovid,
                   lt.vahe::NUMERIC
            INTO v_rea
            FROM lapsed.cur_lapse_taabel lt
            WHERE lt.id = v_tabelid.id;

            UPDATE lapsed.lapse_taabel
            SET /*hind      = coalesce(v_rea.hind, 0),
                soodustus = coalesce(v_rea.soodustus, 0),
                summa     = coalesce(v_rea.summa, 0),
                */
                vahe      = v_rea.vahe
            WHERE id = v_tabelid.id;
        END LOOP;
    RETURN l_kokku;

END;
$$;

SELECT lapsed.update_taabelid();

DROP FUNCTION IF EXISTS lapsed.update_taabelid();


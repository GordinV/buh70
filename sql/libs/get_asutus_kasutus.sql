DROP FUNCTION IF EXISTS get_asutus_kasutus(INTEGER, DATE, INTEGER);

CREATE FUNCTION get_asutus_kasutus(l_lib_id INTEGER, l_kpv DATE, l_rekv_id INTEGER)
    RETURNS JSONB
    LANGUAGE plpgsql
AS
$$
DECLARE
    tulemus       JSONB = '[]'::JSONB;
    v_docs        RECORD;
    l_asutus_kood TEXT  = (SELECT ltrim(rtrim(regkood)) AS kood
                           FROM libs.asutus
                           WHERE id = l_lib_id);
BEGIN

    IF l_lib_id IS NOT NULL
    THEN
        FOR v_docs IN
            SELECT 'Dok. rekl.luba nr.:' || ltrim(rtrim(l.number)) AS dok_nr
            FROM rekl.luba l
                     INNER JOIN rekl.luba1 l1 ON l.id = l1.parentid
            WHERE l.rekvid = l_rekv_id
              AND l.loppkpv > l_kpv
              AND l.asutusid = l_lib_id
            UNION
            SELECT 'Dok. arve nr.:' || ltrim(rtrim(a.number)) AS dok_nr
            FROM docs.arv a
                     INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
            WHERE a.rekvid = l_rekv_id
              AND a.kpv > l_kpv
              AND a.asutusid = l_lib_id
            UNION
            SELECT 'Dok. MK nr.:' || ltrim(rtrim(m.number)) AS dok_nr
            FROM docs.mk m
                     INNER JOIN docs.mk1 m1 ON m.id = m1.parentid
            WHERE m.rekvid = l_rekv_id
              AND m.kpv > l_kpv
              AND m1.asutusid = l_lib_id
            UNION
            SELECT 'Dok. kassa order nr.:' || ltrim(rtrim(m.number)) AS dok_nr
            FROM docs.korder1 m
                     INNER JOIN docs.korder2 m1 ON m.id = m1.parentid
            WHERE m.rekvid = l_rekv_id
              AND m.kpv > l_kpv
              AND m.asutusid = l_lib_id
            UNION
            SELECT 'Dok avans nr.:' || ltrim(rtrim(m.number)) AS dok_nr
            FROM docs.avans1 m
                     INNER JOIN docs.avans2 m1 ON m.id = m1.parentid
            WHERE m.rekvid = l_rekv_id
              AND m.kpv > l_kpv
              AND m.asutusid = l_lib_id
            UNION
            SELECT 'Dok PV operatsioon inv.nr.:' || ltrim(rtrim(p.kood)) AS dok_nr
            FROM docs.pv_oper o
                     INNER JOIN cur_pohivara p ON o.parentid = p.id
            WHERE o.kpv > l_kpv
              AND o.asutusid = l_lib_id
            UNION ALL
            SELECT DISTINCT 'Dok lausend nr.:' || ltrim(rtrim(m.number::TEXT)) || ' (' || ltrim(rtrim(r.nimetus)) ||
                            ')' AS dok_nr
            FROM cur_journal m
                     INNER JOIN ou.rekv r ON m.rekvid = r.id
            WHERE m.kpv > l_kpv
              AND m.asutusid = l_lib_id
            UNION ALL
            SELECT DISTINCT 'Dok tööleping :' || ' (' || ltrim(rtrim(r.nimetus)) ||
                            ')' AS dok_nr
            FROM palk.tooleping m
                     INNER JOIN ou.rekv r ON m.rekvid = r.id
            WHERE (m.algab > l_kpv OR m.lopp IS NULL OR m.lopp > l_kpv)
              AND m.parentid = l_lib_id

            LOOP
                tulemus = tulemus || to_jsonb(row)
                          FROM (SELECT 'Asutus regkood ' || ltrim(rtrim(l_asutus_kood)) || ' kasutusel, ' ||
                                       ltrim(rtrim(v_docs.dok_nr)) AS error_message,
                                       1                           AS error_code) row;
            END LOOP;

    END IF;
    RETURN tulemus;
END;

$$;

GRANT EXECUTE ON FUNCTION get_asutus_kasutus(INTEGER, DATE, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION get_asutus_kasutus(INTEGER, DATE, INTEGER) TO dbpeakasutaja;


/*

-- Koolituskulud -> NOM
-- TUNNUS ->>test 3


SELECT *
FROM jsonb_to_recordset(get_nom_kasutus(17848, '2020-11-09'::DATE, 63))
         AS x (error_message TEXT, error_code integer);


*/


DROP FUNCTION IF EXISTS docs.dokumendid(INTEGER);

CREATE OR REPLACE FUNCTION docs.dokumendid(l_asutus_id INTEGER)
    RETURNS TABLE (
        omanik   VARCHAR(254),
        dok_nimi VARCHAR(254),
        kogus    INTEGER
    ) AS
$BODY$
WITH qry_docs AS (
    SELECT ltrim(rtrim(r.nimetus))::VARCHAR(254) AS omanik,
           ltrim(rtrim(l.nimetus))::VARCHAR(254) AS dok_nimi,
           count(d.id)::INTEGER                  AS kogus
    FROM docs.doc d
             INNER JOIN libs.library l ON l.id = d.doc_type_id
             INNER JOIN ou.rekv r ON r.id = d.rekvid
    WHERE d.status <> 3
      AND d.id IN (
        SELECT parentid
        FROM docs.arv
        WHERE asutusid = l_asutus_id
        UNION ALL
        SELECT parentid
        FROM docs.journal
        WHERE asutusid = l_asutus_id
        UNION ALL
        SELECT mk.parentid
        FROM docs.mk1 mk1
                 INNER JOIN docs.mk mk ON mk.id = mk1.parentid
        WHERE asutusid = l_asutus_id
        UNION ALL
        SELECT parentid
        FROM docs.korder1
        WHERE asutusid = l_asutus_id
        UNION ALL
        SELECT parentid
        FROM docs.avans1
        WHERE asutusid = l_asutus_id
        UNION ALL
        SELECT parentid
        FROM rekl.luba
        WHERE asutusid = l_asutus_id
          AND staatus > 0
        UNION ALL
        SELECT parentid
        FROM docs.pv_oper
        WHERE asutusid = l_asutus_id
        UNION ALL
        SELECT po.parentid
        FROM palk.palk_oper po
                 INNER JOIN palk.tooleping t ON po.lepingid = t.id
        WHERE t.parentid = l_asutus_id
    )
    GROUP BY r.nimetus, l.nimetus
)
SELECT *
FROM qry_docs
UNION ALL
SELECT '' AS omanik, '' AS dok_nimi, 0 AS kogus
WHERE NOT exists(SELECT 1 FROM qry_docs)

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.dokumendid(INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.dokumendid(INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.dokumendid(INTEGER) TO dbkasutaja;


/*
select * from libs.asutus where nimetus like '%DATEL%'

select * from docs.dokumendid(3022499)


*/
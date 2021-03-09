DROP FUNCTION IF EXISTS lapsed.get_last_maksja(INTEGER[]);

CREATE OR REPLACE FUNCTION lapsed.get_last_maksja(IN docs_ids INTEGER[], OUT asutus_id INTEGER)
AS
$BODY$
BEGIN
    asutus_id = (
        SELECT asutusid
        FROM (
                 SELECT a.asutusid, a.kpv
                 FROM docs.arv a
                 WHERE parentid IN (SELECT unnest(docs_ids))
                     UNION ALL
                     SELECT mk1.asutusid
                     , mk.kpv
                     FROM docs.mk mk
                     INNER JOIN docs.mk1 mk1 ON mk.id = mk1.parentid
                     WHERE mk.parentid IN (SELECT unnest(docs_ids))
             ) qry
        WHERE qry.asutusid IS NOT NULL
          AND qry.asutusid <> 0
            ORDER BY kpv
            LIMIT 1
    );
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.get_last_maksja(INTEGER[]) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_last_maksja(INTEGER[]) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_last_maksja(INTEGER[]) TO arvestaja;


SELECT lapsed.get_last_maksja(docs_ids)
FROM lapsed.lapse_saldod('2020-09-01'::DATE)
WHERE laps_id = 6933
  AND rekv_id = 69


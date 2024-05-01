DROP FUNCTION IF EXISTS public.get_asutuse_struktuur(INTEGER, DATE);

CREATE OR REPLACE FUNCTION public.get_asutuse_struktuur(INTEGER,
                                                        DATE DEFAULT CURRENT_DATE)
    RETURNS TABLE (
        rekv_id   INTEGER,
        parent_id INTEGER,
        tase      INTEGER
    )
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS
$BODY$

WITH RECURSIVE chield_rekv(id, parentid) AS (
    SELECT id,
           CASE
               WHEN $2::DATE <= '2020-12-31'::DATE AND rekv.parentid >= 9999 AND
                    rekv.id IN (90) THEN 119
               ELSE rekv.parentid END AS parentid,
           1 as tase
    FROM ou.rekv
    WHERE id = $1
    UNION
    SELECT rekv.id,
           rekv.parentid,
           tase + 1 as tase 
    FROM chield_rekv,
         ou.rekv rekv
    WHERE CASE
              WHEN $2::DATE <= '2020-12-31'::DATE AND rekv.parentid >= 9999 AND
                   rekv.id IN (90) THEN 119
              ELSE rekv.parentid END = chield_rekv.id
)
SELECT id,
       parentid,
       tase
FROM chield_rekv;

$BODY$;


GRANT EXECUTE ON FUNCTION public.get_asutuse_struktuur(INTEGER, DATE) TO dbadmin;

GRANT EXECUTE ON FUNCTION public.get_asutuse_struktuur(INTEGER, DATE) TO dbkasutaja;

GRANT EXECUTE ON FUNCTION public.get_asutuse_struktuur(INTEGER, DATE) TO dbpeakasutaja;

GRANT EXECUTE ON FUNCTION public.get_asutuse_struktuur(INTEGER, DATE) TO dbvaatleja;

GRANT EXECUTE ON FUNCTION public.get_asutuse_struktuur(INTEGER, DATE) TO eelaktsepterja;

GRANT EXECUTE ON FUNCTION public.get_asutuse_struktuur(INTEGER, DATE) TO eelallkirjastaja;

GRANT EXECUTE ON FUNCTION public.get_asutuse_struktuur(INTEGER, DATE) TO eelesitaja;

GRANT EXECUTE ON FUNCTION public.get_asutuse_struktuur(INTEGER, DATE) TO eelkoostaja;


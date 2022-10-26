DROP FUNCTION IF EXISTS lapsed.get_differ_from_algoritm(NUMERIC,NUMERIC,NUMERIC);

CREATE OR REPLACE FUNCTION lapsed.get_differ_from_algoritm(l_hind NUMERIC, l_soodustus NUMERIC, l_kogus NUMERIC)
    RETURNS NUMERIC AS
$BODY$

DECLARE
    l_tapne_summa NUMERIC = 0;
    l_umardatud_summa NUMERIC(14,2) = 0;
    l_differ        NUMERIC = 0;
BEGIN
    IF l_soodustus > 0
    THEN
        l_tapne_summa =  l_hind * l_kogus - l_soodustus * l_kogus;
        l_umardatud_summa = round(l_hind * l_kogus,2) - round(l_soodustus * l_kogus,2);
        l_differ =  round(l_tapne_summa - l_umardatud_summa,2);
    END IF;

    RETURN l_differ;

END;

$BODY$
    LANGUAGE plpgsql
    IMMUTABLE
    COST 100;



GRANT EXECUTE ON FUNCTION lapsed.get_differ_from_algoritm(NUMERIC,NUMERIC,NUMERIC) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_differ_from_algoritm(NUMERIC,NUMERIC,NUMERIC) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.get_differ_from_algoritm(NUMERIC,NUMERIC,NUMERIC) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_differ_from_algoritm(NUMERIC,NUMERIC,NUMERIC) TO arvestaja;

/*SELECT 8.76 * 0.9048, 2.19 * 0.9048, (8.76 * 0.9048 - 2.19 * 0.9048) as summa,
       (round(8.76 * 0.9048,2) - round(2.19 * 0.9048,2)) as arv_summa,
       lapsed.get_differ_from_algoritm(8.76,  2.09, 0.9048);

select * from lapsed.lapse_taabel where id = 89475
*/
  select  lapsed.get_differ_from_algoritm(8.76,  2.19, 0.7619)

select * from lapsed.lapse_taabel where id = 89162

select * from lapsed.lapse_kaart where id = 39945
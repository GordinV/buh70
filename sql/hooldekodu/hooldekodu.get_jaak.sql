DROP FUNCTION IF EXISTS hooldekodu.get_jaak(INTEGER, INTEGER, DATE);

CREATE FUNCTION hooldekodu.get_jaak(IN l_rekv_id INTEGER, IN l_isik_id INTEGER, IN l_kpv DATE DEFAULT current_date,
                                    OUT pension_85 NUMERIC, OUT pension_15 NUMERIC, OUT toetus NUMERIC,
                                    OUT vara NUMERIC, OUT muud NUMERIC)
    LANGUAGE plpgsql
AS
$$
DECLARE
BEGIN
    -- leiame jaagirea
    SELECT coalesce(sum(summa) FILTER ( WHERE ltrim(rtrim(ht.allikas)) = 'PENSION85'), 0) AS pension_85,
           coalesce(sum(summa) FILTER ( WHERE ltrim(rtrim(ht.allikas)) = 'PENSION15'), 0) AS pension_15,
           coalesce(sum(summa) FILTER ( WHERE ltrim(rtrim(ht.allikas)) = 'TOETUS'), 0)    AS toetus,
           coalesce(sum(summa) FILTER ( WHERE ltrim(rtrim(ht.allikas)) = 'VARA'), 0)      AS vara,
           coalesce(sum(summa) FILTER ( WHERE ltrim(rtrim(ht.allikas)) = 'MUUD'), 0)      AS muud
    INTO pension_85, pension_15, toetus, vara, muud
    FROM hooldekodu.hootehingud ht
    WHERE isikid = l_isik_id
      AND kpv < l_kpv
      AND rekvid = l_rekv_id
      AND status < 3;
    RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION hooldekodu.get_jaak(INTEGER, INTEGER, DATE) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION hooldekodu.get_jaak(INTEGER, INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION hooldekodu.get_jaak(INTEGER, INTEGER, DATE) TO dbpeakasutaja;


/*
select * from cur_journal where rekvid = 132 and kpv > '2023-09-01'
-- 29296
select * from hooldekodu.get_jaak(132, 26944, DATE(2023,01,31))

*/
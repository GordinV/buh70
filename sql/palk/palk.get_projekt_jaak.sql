DROP FUNCTION IF EXISTS palk.get_projekt_jaak(INTEGER, DATE, TEXT);

CREATE FUNCTION palk.get_projekt_jaak(IN l_leping_id INTEGER, IN l_kpv DATE, l_proj TEXT, OUT l_jaak NUMERIC)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_palk_jaak RECORD;
BEGIN
    IF (l_leping_id IS NULL OR l_kpv IS NULL)
    THEN
        l_jaak = 0;
        RETURN;
    END IF;

    SELECT sum(po.summa)
           FILTER (WHERE po.palk_liik = 'ARVESTUSED')          AS arvestatud,
           sum(coalesce(po.summa, 0))
           FILTER (WHERE po.palk_liik = 'ARVESTUSED' AND po.tululiik =
                                                         '22') AS tulud_pm,
           sum(COALESCE(po.summa, 0))
           FILTER ( WHERE po.palk_liik = 'KINNIPIDAMISED')     AS kinni,
           sum(COALESCE(po.summa, 0))
           FILTER ( WHERE po.palk_liik = 'TULUMAKS')           AS tm,
           sum(COALESCE(po.summa, 0))
           FILTER ( WHERE po.palk_liik = 'TASU')               AS tasu,
           sum(COALESCE(po.summa, 0))
           FILTER ( WHERE po.palk_liik = 'TÖÖTUSKINDLUSTUSMAKS' AND
                          NOT po.is_asutusest)                 AS tki,
           sum(COALESCE(po.summa, 0))
           FILTER ( WHERE po.palk_liik = 'PENSIONIMAKS')       AS pm

    INTO v_palk_jaak
    FROM (SELECT p.summa,
                 ((enum_range(NULL :: PALK_LIIK))[(lib.properties :: JSONB ->> 'liik') :: INTEGER]) :: TEXT AS palk_liik,
                 (lib.properties :: JSONB ->> 'asutusest') :: BOOLEAN                                       AS is_asutusest,
                 (lib.properties :: JSONB ->> 'tululiik') :: TEXT                                           AS tululiik,
                 p.tulubaas
          FROM docs.doc d
                   INNER JOIN palk.palk_oper p ON p.parentid = d.id
                   INNER JOIN libs.library lib ON p.libid = lib.id AND lib.library = 'PALK'
          WHERE d.doc_type_id IN (SELECT id FROM libs.library l WHERE l.library = 'DOK' AND l.kood = 'PALK_OPER')
            AND p.kpv <= l_kpv
            AND p.lepingId = l_leping_id
            AND (l_proj IS NULL OR p.proj ILIKE l_proj || '%')
            AND D.status <> 3
         ) po;
    -- поправка в сальдо за счет 3 пенсионной ступени

    IF coalesce(v_palk_jaak.tulud_pm, 0) > 0
    THEN
        v_palk_jaak.arvestatud = coalesce(v_palk_jaak.arvestatud, 0) - coalesce(v_palk_jaak.tulud_pm, 0);
    END IF;

    -- ищем запись текущего периода

    -- расчет сальдо
    l_jaak = coalesce(v_palk_jaak.arvestatud, 0) - coalesce(v_palk_jaak.kinni, 0) -
             coalesce(v_palk_jaak.tki, 0) - coalesce(v_palk_jaak.pm, 0) -
             coalesce(v_palk_jaak.tasu, 0) - coalesce(v_palk_jaak.tm, 0);

    RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION palk.get_projekt_jaak(INTEGER, DATE, TEXT) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.get_projekt_jaak(INTEGER, DATE, TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_projekt_jaak(INTEGER, DATE, TEXT) TO dbpeakasutaja;


/*
id
35412
36557

SELECT  palk.get_projekt_jaak(35412, DATE(2023,03,31), '23001'::TEXT);


*/
-- Function: docs.sp_salvesta_mk(json, integer, integer)

DROP FUNCTION IF EXISTS docs.sp_loe_tagasimakse(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_loe_tagasimakse(IN l_tasu_id INTEGER, IN l_user_id INTEGER,
                                                   OUT error_code INTEGER,
                                                   OUT result INTEGER,
                                                   OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_tasu_jaak NUMERIC; -- остаток оплаты
    l_tasu      NUMERIC; -- сумма оплаты
    v_arv       RECORD;
    v_mk        RECORD;
    v_tasu      RECORD;
    l_laps_id   INTEGER;
BEGIN
    -- расчет сальдо платежа
    l_tasu_jaak = docs.sp_update_mk_jaak(l_tasu_id);

    IF coalesce(l_tasu_jaak, 0) <> 0
    THEN

        -- load tasu data
        SELECT mk.id,
               d.rekvid,
               (regexp_replace(viitenr, '[^0-9]', ''))::TEXT                    AS viitenr,
               (SELECT sum(summa) FROM docs.mk1 mk1 WHERE mk1.parentid = mk.id) AS summa,
               jaak,
               CASE WHEN mk.opt = 1 THEN 'VM' ELSE 'SM' END                     AS liik,
               mk.maksepaev,
               l.parentid                                                       AS laps_id
        INTO v_tasu
        FROM docs.doc D
                 INNER JOIN docs.mk mk ON mk.parentid = D.id
                 INNER JOIN lapsed.liidestamine l ON l.docid = d.id
        WHERE d.id = l_tasu_id;

        IF v_tasu IS NULL
        THEN
            -- нет связи, вызодим
            result = 0;
            error_message = 'laps ei leidnud';
            RETURN;
        END IF;

        -- ищем предоплаты
        FOR v_mk IN
            SELECT mk.jaak AS ettemaks, id
            FROM lapsed.cur_lapsed_mk mk
            WHERE mk.rekvid = v_tasu.rekvid
              AND mk.laps_id = v_tasu.laps_id
              AND jaak > 0      -- только предоплаты
              AND mk.deebet > 0 -- только поступления
            ORDER BY CASE WHEN mk.maksepaev <= v_tasu.maksepaev THEN 0 ELSE 1 END, mk.maksepaev DESC, mk.id DESC
            LOOP

                IF (v_mk.ettemaks + (CASE WHEN v_tasu.liik = 'VM' THEN -1 ELSE 1 END * l_tasu_jaak) > 0)
                THEN
                    -- в оплату пошел остаток платежа
                    l_tasu = l_tasu_jaak;
                ELSE
                    --в оплату пошел сальдо счета
                    l_tasu = -1 * v_mk.ettemaks;
                END IF;

                -- вызывает оплату
                result = docs.sp_ulekanne_ettemaks(l_tasu_id, v_mk.id, l_user_id, l_tasu);
                IF result IS NOT NULL AND result > 0
                THEN
--                    perform docs.sp_update_mk_jaak(l_tasu_id);
                    PERFORM docs.sp_update_mk_jaak(v_mk.id);

                    -- минусуем сумму оплаты
                    l_tasu_jaak = l_tasu_jaak - l_tasu;
                END IF;

                IF l_tasu_jaak = 0
                THEN
                    -- если оплата выбрана, то выходим
                    EXIT;
                END IF;

            END LOOP;

        IF l_tasu_jaak = 0
        THEN
            RETURN;

        END IF;


        -- ищем оплаченные счета
        FOR v_arv IN
            SELECT a.id,
                   a.jaak,
                   a.rekvid,
                   a.asutusid,
                   a.asutus         AS maksja,
                   a.summa - a.jaak AS tagastamata_osa
            FROM lapsed.cur_laste_arved a
                     INNER JOIN docs.arv arv ON a.id = arv.parentid
            WHERE a.rekvid = v_tasu.rekvid
              AND ltrim(rtrim((regexp_replace(a.viitenr, '[^0-9]', ''))))::TEXT =
                  ltrim(rtrim((regexp_replace(v_tasu.viitenr, '[^0-9]', ''))))::TEXT
              AND a.jaak < a.summa
              AND (arv.properties ->> 'ettemaksu_period' IS NULL OR
                   arv.properties ->> 'tyyp' = 'ETTEMAKS') -- только обычные счета или предоплаты
              AND liik = 0                                 -- при только исходящие счета (снимаем оплату при возвратах
            ORDER BY
--                     case when a.kpv <= v_tasu.maksepaev then 0 else 1 end,
a.kpv DESC, a.id DESC
            LOOP

                RAISE NOTICE 'v_arv.id %, v_arv.tagastamata_osa % ', v_arv.id, v_arv.tagastamata_osa;
                -- списываем в оплату сальдо счета (только остаток счета)
                IF (v_arv.tagastamata_osa + (CASE WHEN v_tasu.liik = 'VM' THEN -1 ELSE 1 END * l_tasu_jaak) > 0)
                THEN
                    -- в оплату пошел остаток платежа
                    l_tasu = l_tasu_jaak;
                ELSE
                    --в оплату пошел сальдо счета
                    l_tasu = -1 * v_arv.tagastamata_osa;
                END IF;

                -- вызывает оплату
                result = docs.sp_tasu_arv(l_tasu_id, v_arv.id, l_user_id, l_tasu);

                IF result IS NOT NULL AND result > 0
                THEN

                    -- минусуем сумму оплаты
                    l_tasu_jaak = l_tasu_jaak - l_tasu;
                END IF;


                IF l_tasu_jaak = 0
                THEN
                    -- если оплата выбрана, то выходим
                    EXIT;
                END IF;
            END LOOP;

    END IF;
END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_loe_tagasimakse(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_loe_tagasimakse(INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_loe_tagasimakse(INTEGER, INTEGER) TO arvestaja;

COMMENT ON FUNCTION docs.sp_loe_tagasimakse(INTEGER, INTEGER) IS 'производит поиск оплаченных счетов и вызывает процедуру снятия их оплаты';

/*
SELECT *
FROM docs.sp_loe_tagasimakse_(5525088, 5410)


DELETE
select *
from docs.arvtasu where doc_tasu_id = 5525088

select * from ou.userid where id = 70

select * from lapsed.cur_lapsed_mk where id = 5586691

select * from docs.doc where
--created = '2023-04-03 15:44:57.740032'
--and doc_type_id = 55
id = 5583933


*/


DROP FUNCTION IF EXISTS docs.ulekanne_saldo(INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.ulekanne_saldo(IN user_id INTEGER,
                                               IN params JSONB,
                                               OUT error_code INTEGER,
                                               OUT result INTEGER,
                                               OUT doc_type_id TEXT,
                                               OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_laps_id       INTEGER = params ->> 'laps_id'; -- на ком переплата
    l_kpv           DATE    = params ->> 'kpv'; -- переплата на дату
    l_viitenumber   TEXT    = params ->> 'viitenumber'; -- кому переплата переносится
    l_jaak          NUMERIC = 0; -- сумма переплаты в учреждении
    doc_id_kreedit  INTEGER;
    doc_id_new      INTEGER;

    l_rekvId        INTEGER = (SELECT rekvid
                               FROM ou.userid
                               WHERE id = user_id); -- ид учреждения, откуда списываем переплата


    json_object     JSONB;

BEGIN

    doc_type_id = 'ARV';

    IF l_laps_id IS NULL OR l_rekvid IS NULL
    THEN
        result = 0;
        error_message = 'Laps ei leidnud';
        error_code = 1;
        RAISE EXCEPTION '%', error_message;

    END IF;

    -- считаем сумму переплаты

    SELECT -1 * qry.jaak
    INTO l_jaak
    FROM lapsed.kaive_aruanne(l_rekvId, l_kpv, l_kpv) qry
    WHERE viitenumber = lapsed.get_viitenumber(l_rekvId, l_laps_id)
      AND jaak < 0; -- только минус (переплата)

    RAISE NOTICE 'l_jaak %, l_rekvId %, l_kpv %, l_laps_id %, user_id %', l_jaak, l_rekvId, l_kpv,l_laps_id, user_id;

    IF (coalesce(l_jaak, 0)) = 0
    THEN
        -- выходим
        error_code = 0;
        error_message = 'Jääk = 0';
        result = 0;
        RETURN;
    END IF;

    -- ищем документ - основу
    SELECT id
    INTO doc_id_kreedit
    FROM lapsed.cur_lapsed_mk mk
    WHERE mk.rekvid = l_rekvId
      AND mk.laps_id = l_laps_id
      AND mk.jaak > 0
    ORDER BY kpv DESC
    LIMIT 1;

    IF doc_id_kreedit IS NULL
    THEN
        -- выходим
        error_code = 0;
        error_message = 'Puudub MK, kus jääk > 0';
        result = 0;
        RETURN;

    END IF;

    -- делаем перенос платежа
    json_object =
            jsonb_build_object('mk_id', doc_id_kreedit, 'maksepaev', l_kpv, 'viitenumber', l_viitenumber, 'kogus',
                               l_jaak, 'tyyp', 'jaak_ulekandmine');

    doc_id_new = (SELECT um.result FROM docs.ulekanne_makse(user_id, json_object) um);

    IF coalesce(doc_id_new, 0) = 0
    THEN
        -- платеж не создан, ошибка
        error_code = 0;
        error_message = 'Uus MK salvestamine ebaõnnestus, viga';
        result = 0;
        RAISE EXCEPTION 'Viga: %', error_message;
    END IF;


    -- списываем долг у просроченных счетов
    result = doc_id_new;
    RETURN;
END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.ulekanne_saldo(INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.ulekanne_saldo(INTEGER, JSONB) TO dbpeakasutaja;


/*
SELECT docs.ulekanne_saldo(5411, '{"laps_id":8440, "kpv":"20240531","viitenumber":"0830084403"}')
*/
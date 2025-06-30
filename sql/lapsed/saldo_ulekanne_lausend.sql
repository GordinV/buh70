DROP FUNCTION IF EXISTS docs.saldo_ulekanne_lausend(INTEGER, INTEGER, INTEGER, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.saldo_ulekanne_lausend(INTEGER, INTEGER, INTEGER, DATE, INTEGER, numeric);

CREATE OR REPLACE FUNCTION docs.saldo_ulekanne_lausend(IN user_Id INTEGER,
                                                       IN asutus_id_from INTEGER,
                                                       IN asutus_id_to INTEGER,
                                                       IN l_kpv DATE,
                                                       IN l_laps_id INTEGER,
                                                       in l_saldo numeric default 0,
                                                       OUT error_code INTEGER,
                                                       OUT result INTEGER[],
                                                       OUT error_message TEXT)
AS
$BODY$
DECLARE
    lcSelg         TEXT    = 'õppetasu. Saldo üleviimine teise vastutava isiku nimele';
    l_json         TEXT;
    l_json_details JSONB   = '[]';
    v_saldo        RECORD;
    l_rekv_id      INTEGER = (SELECT rekvid
                              FROM ou.userid
                              WHERE id = user_Id
                              LIMIT 1);
    l_vn           TEXT    = lapsed.get_viitenumber(l_rekv_id, l_laps_id);
    l_konto        TEXT    = '10300029';
    l_art          text    = '3220'; -- artikkel
    l_tegev        text    = '09110'; -- tegevusalla
    l_tunnus       TEXT    = (SELECT left(nimetus, 7) AS tunnus
                              FROM ou.rekv
                              WHERE id = l_rekv_id
                              LIMIT 1);
    l_journal_id   INTEGER;
    v_arv          record;
    json_props     jsonb   = jsonb_build_object('laps_id', jsonb_build_object ('laps_id', array[l_laps_id]));
BEGIN
    IF (coalesce(asutus_id_from, 0) = coalesce(asutus_id_to, 0))
    THEN
        -- одно и то же лицо, не надо
        RETURN;
    END IF;
    -- проверим наличие признака
    IF NOT exists
        (SELECT id FROM libs.library WHERE kood = l_tunnus AND library.library = 'TUNNUS')
    THEN
        l_tunnus = '';
    END IF;

    FOR v_saldo IN
        -- получаем сальдо
        SELECT (rep.alg_saldo + deebet - kreedit) AS lopp_saldo,
               rep.asutus_id,
               a.tp
        FROM docs.kaibeasutusandmik(l_konto, asutus_id_from, l_kpv, l_kpv, l_rekv_id, '%', 0, json_props) rep
                 INNER JOIN libs.asutus a ON a.id = rep.asutus_id
        LOOP
            -- уточняем артикел и вид. деятельности
            select a1.kood1 as tegev,
                   a1.kood5 as artikkel
            into v_arv
            from docs.arv a
                     inner join docs.arv1 a1 on a.id = a1.parentid
            where a.asutusid = v_saldo.asutus_id
              and a.rekvid = l_rekv_id
              and a.liik = 0
              and a.summa >= 0
            order by a.id desc
            limit 1;

            if v_arv.artikkel is not null then
                l_art = v_arv.artikkel;
                l_tegev = v_arv.tegev;
            end if;

            -- parametrid,
            -- снимаем сальдо
            l_json_details =
                    json_build_object('id', 0, 'summa', (-1 * v_saldo.lopp_saldo), 'valuuta', 'EUR', 'kuurs', 1,
                                      'deebet',
                                      l_konto, 'lisa_d', v_saldo.tp,
                                      'kreedit', '888888', 'lisa_k', '', 'tunnus', l_tunnus, 'kood1', l_tegev,
                                      'kood2', '80', 'kood5', l_art);

            l_json = json_build_object('doc_type_id', 'JOURNAL', 'kpv', l_kpv, 'selg', lcSelg, 'asutusid',
                                       asutus_id_from, 'dok', l_vn, 'vn',l_vn,  'gridData', '[]'::JSONB || l_json_details);

            l_journal_id =
                    docs.sp_salvesta_journal(json_build_object('id', 0, 'data', l_json) :: JSON, user_Id, l_rekv_id);
            result = array_append(result, l_journal_id);

            -- ставим сальдо

            l_json_details =
                    json_build_object('id', 0, 'summa', (-1 * v_saldo.lopp_saldo), 'valuuta', 'EUR', 'kuurs', 1,
                                      'kreedit',
                                      l_konto, 'lisa_k', v_saldo.tp,
                                      'deebet', '888888', 'lisa_d', '', 'tunnus', l_tunnus, 'kood1', l_tegev,
                                      'kood2', '80', 'kood5', l_art);

            l_json = json_build_object('doc_type_id', 'JOURNAL', 'kpv', l_kpv, 'selg', lcSelg, 'asutusid',
                                       asutus_id_to, 'dok', l_vn, 'vn', l_vn, 'gridData', '[]'::JSONB || l_json_details);

            l_journal_id =
                    docs.sp_salvesta_journal(json_build_object('id', 0, 'data', l_json) :: JSON, user_Id, l_rekv_id);
            result = array_append(result, l_journal_id);
        END LOOP;


END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.saldo_ulekanne_lausend(INTEGER, INTEGER, INTEGER, DATE, INTEGER, numeric) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.saldo_ulekanne_lausend(INTEGER, INTEGER, INTEGER, DATE, INTEGER, numeric) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.saldo_ulekanne_lausend(INTEGER, INTEGER, INTEGER, DATE, INTEGER, numeric) TO arvestaja;

/*
select docs.saldo_ulekanne_lausend(2477::INTEGER, 63::INTEGER, 28639::INTEGER, current_date, 3::INTEGER)

*/


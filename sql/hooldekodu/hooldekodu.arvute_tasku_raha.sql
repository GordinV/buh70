-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS hooldekodu.arvuta_tasku_raha(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION hooldekodu.arvuta_tasku_raha(IN user_id INTEGER,
                                                        IN l_isik_id INTEGER,
                                                        IN l_kpv DATE DEFAULT current_date,
                                                        OUT error_code INTEGER,
                                                        OUT result INTEGER,
                                                        OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid     INTEGER        = (SELECT rekvid
                                   FROM ou.userid u
                                   WHERE id = user_id
                                   LIMIT 1);

    v_isik       RECORD;
    v_journal    RECORD;
    v_leping     RECORD;
    l_json       JSONB          = '{}'::JSONB;
    l_json_rea   JSONB          = '[]'::JSONB;
    l_lausend_id INTEGER;
    l_kuu        INTEGER        = date_part('month', l_kpv);
    l_aasta      INTEGER        = date_part('year', l_kpv);
    l_selg       TEXT           = 'KOV taskuraha kohustis';
    l_summa      NUMERIC(16, 2) = 0;
    DB           TEXT           =  '413110'; -- Поправлено 24.05.24 В.Б , 18.07.2024  '413110,413800,413899';
    KR           TEXT           = '20356001';
    TUNNUS       TEXT           = CASE WHEN l_rekvid = 64 THEN '4023' ELSE '2101' END;
    ALLIKAS      TEXT           = 'LE-P';
    TEGEV        TEXT           = '10200';
    ARTIKKEL     TEXT           = '4131';-- -- Поправлено 24.05.24 В.Б , 18.07.2024 '4131, 4138';
    URITUS       TEXT           = 'Taskuraha';
    v_hk         RECORD;
    v_kp         RECORD;
    v_pm         RECORD;

BEGIN

    IF l_isik_id IS NULL
    THEN
        -- контр-анет не найден, выходим
        result = 0;
        error_message = 'Puudub kontragent';
        error_code = 1;
        RETURN;
    END IF;

    -- инициализируем справочники
    SELECT *
    INTO v_hk
    FROM hooldekodu.hoo_config hc
    WHERE hc.library = 'RIIGI_TOETUS'
      AND hc.kpv >= l_kpv
      AND hc.status < 3
    ORDER BY hc.id DESC
    LIMIT 1;

    SELECT hc.*
    INTO v_kp
    FROM hooldekodu.hoo_config hc
    WHERE library = 'KESK_PENSION'
      AND kpv >= l_kpv
      AND status < 3
    LIMIT 1;

    SELECT hc.*
    INTO v_pm
    FROM hooldekodu.hoo_config hc
    WHERE library = 'KOV_PIIRIMAAR'
      AND kpv >= l_kpv
      AND status < 3
    LIMIT 1;

    SELECT a.regkood                AS isikukood,
           a.nimetus                AS nimi,
           coalesce(a.tp, '800699') AS tp
    FROM libs.asutus a
    WHERE a.id = l_isik_id
    INTO v_isik;

    -- расчет суммы

    WITH data AS (
        SELECT hl.bruttosissetulek,
               hl.netosissetulek,
               hl.summa                                                AS Kohamaksumus,
               (hl.netosissetulek * coalesce(hl.tasku_raha, 0) * 0.01) AS tasku_raha,
               CASE
                   WHEN coalesce(hl.hoolduskulud, 0) = 0 THEN v_hk.summa
                   ELSE hl.hoolduskulud END                            AS Hoolduskulu,
               (hl.summa - (CASE
                                WHEN coalesce(hl.hoolduskulud, 0) = 0 THEN v_hk.summa
                                ELSE hl.hoolduskulud END))             AS isiku_poolt_kulud,
               v_kp.summa                                              AS kesk_pension,
               v_pm.summa                                              AS piirimaar,
               coalesce(j.pension15, 0)                                AS pension15,
               hl.tunnus
        FROM hooldekodu.hooleping hl
                 LEFT OUTER JOIN hooldekodu.hoojaak j ON j.isikid = hl.isikid
        WHERE hl.isikid = l_isik_id
          AND hl.algkpv <= l_kpv
          AND (hl.loppkpv IS NULL OR hl.loppkpv >= l_kpv)
          AND hl.status < 3
          AND hl.rekvid = l_rekvid
        ORDER BY hl.id DESC
        LIMIT 1),
         prev_data AS (
             SELECT pd.Kohamaksumus,
                    pd.Hoolduskulu,
                    pd.isiku_poolt_kulud,
                    pd.piirimaar,
                    pd.tasku_raha,
                    pd.kesk_pension,
                    pd.pension15,
                    pd.TUNNUS,
                    CASE
                        WHEN pd.Hoolduskulu < pd.piirimaar THEN pd.Hoolduskulu
                        ELSE pd.piirimaar END       AS hoolduskulu_huvitis,
                    pd.bruttosissetulek,
                    pd.netosissetulek,
                    CASE
                        WHEN pd.bruttosissetulek >= pd.kesk_pension THEN 0
                        WHEN (pd.isiku_poolt_kulud - pd.bruttosissetulek) >= (pd.kesk_pension - pd.bruttosissetulek)
                            THEN (pd.isiku_poolt_kulud - pd.bruttosissetulek)
                        WHEN (pd.kesk_pension - pd.bruttosissetulek) > (pd.isiku_poolt_kulud - pd.bruttosissetulek)
                            THEN (pd.kesk_pension - pd.bruttosissetulek)
                        ELSE 0 END                  AS vaiksema_sissetuleku_huvitis,
                    (pd.Hoolduskulu - pd.piirimaar) AS isiku_tasutav_hoolduskulu
             FROM data pd)
    SELECT d.*,
           d.hoolduskulu_huvitis + d.vaiksema_sissetuleku_huvitis                    AS tasutav_hoolduskulu_huvitis,
           d.Kohamaksumus - (d.hoolduskulu_huvitis + d.vaiksema_sissetuleku_huvitis) AS jaab_tasuda,
           ROUND(d.tasku_raha, 2) - ROUND(CASE
                                              WHEN (d.netosissetulek - d.isiku_poolt_kulud) > 0
                                                  THEN (d.netosissetulek - d.isiku_poolt_kulud)
                                              ELSE 0 END, 2)                         AS kov_tasku_raha
    INTO v_leping
    FROM prev_data d;

    IF v_leping IS NULL OR v_leping.kov_tasku_raha <= 0
    THEN
        -- вернем ответ, что расчет = 0
        error_message = 'Isikukood: ' || v_isik.isikukood || ', Nimi:' || v_isik.nimi || ',' ||
                        'Tulemus: Puudub leping või tasku raha ´0';
        error_code = 1;

        RETURN;
    END IF;

    SELECT j.id
    INTO l_lausend_id
    FROM cur_journal j
    WHERE month(kpv) = month(l_kpv)
      AND year(kpv) = year(kpv)
      AND rekvid = l_rekvid
      AND j.deebet = DB
      AND j.kreedit = KR
      AND j.asutusid = l_isik_id
    LIMIT 1;

    l_json_rea = '[]'::JSONB || jsonb_build_object('id', 0,
                                                   'summa', v_leping.kov_tasku_raha,
                                                   'deebet', DB,
                                                   'kreedit', KR,
                                                   'lisa_d', coalesce(v_isik.tp, '800699'),
                                                   'lisa_k', coalesce(v_isik.tp, '800699'),
                                                   'tunnus', TUNNUS,
                                                   'kood1', TEGEV,
                                                   'kood2', ALLIKAS,
                                                   'kood5', ARTIKKEL,
                                                   'kood4', URITUS
        );

    l_json = jsonb_build_object('id', coalesce(l_lausend_id, 0),
                                'doc_type_id', 'JOURNAL',
                                'kpv', l_kpv,
                                'selg', l_selg,
                                'muud', 'Tasku (KOV) arvutus',
                                'asutusid', l_isik_id,
                                'gridData', l_json_rea
        );

    l_json = jsonb_build_object('id', coalesce(l_lausend_id, 0), 'data', l_json);

    result = docs.sp_salvesta_journal(l_json :: JSON, user_id, l_rekvid);

    IF result IS NOT NULL AND result > 0
    THEN
        error_message = 'Isikukood: ' || v_isik.isikukood || ', Nimi:' || v_isik.nimi;
    ELSE
        error_code = 1;
        error_message = 'Dokumendi koostamise viga,  Isikukood: ' || v_isik.isikukood || ', Nimi:' || v_isik.nimi;
    END IF;

    RETURN;

END ;
$BODY$ LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION hooldekodu.arvuta_tasku_raha(INTEGER, INTEGER, DATE) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.arvuta_tasku_raha(INTEGER, INTEGER, DATE) TO hkametnik;


/*

select * from libs.asutus where regkood = '43506213740'

SELECT hooldekodu.arvuta_tasku_raha_(5175, 31679, '2023-07-31')

SELECT * FROM hooldekodu.hooleping where isikid in (42397, 43192)

select * from ou.userid where kasutaja = 'vlad' and rekvid = 132

 */


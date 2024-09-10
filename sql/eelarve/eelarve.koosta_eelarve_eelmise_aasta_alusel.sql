DROP FUNCTION IF EXISTS eelarve.koosta_eelarve_eelmise_aasta_alusel(INTEGER, JSONB);

CREATE OR REPLACE FUNCTION eelarve.koosta_eelarve_eelmise_aasta_alusel(IN user_id INTEGER, IN params JSONB, OUT result INTEGER)
    RETURNS INTEGER
AS
$BODY$

DECLARE
    l_aasta        INTEGER = (params ->> 'aasta')::INTEGER;
    l_kond         INTEGER = (params ->> 'kond')::INTEGER;
    l_tapsestatud  INTEGER = coalesce((params ->> 'tapsestatud')::INTEGER, 0)::INTEGER;
    l_kpv          DATE    = coalesce((params ->> 'kpv')::DATE, current_date);
    l_tulud        INTEGER = coalesce((params ->> 'tulud')::INTEGER, 1)::INTEGER;
    l_kulud        INTEGER = coalesce((params ->> 'kulud')::INTEGER, 1)::INTEGER;

    v_taotlus      RECORD;
    v_taotlus1     RECORD;
    v_rekv         RECORD;
    l_doc_json     TEXT;
    l_details_json TEXT;
    l_jsonb jsonb = '[]'::jsonb;
    l_jsonb_doc json;
    l_json         TEXT;
    l_user_id      INTEGER; -- ид пользователя в искомой бд
    l_rekvid       INTEGER = (SELECT rekvid
                              FROM ou.userid
                              WHERE id = user_id
                              LIMIT 1);
    l_count        INTEGER = 0;


BEGIN

    RAISE NOTICE 'start';
    -- kontrol
    IF coalesce(l_aasta, 0) < 2022
    THEN
        RAISE EXCEPTION 'Viga: puudub või vale eelarve aasta';
    END IF;

    FOR v_rekv IN
        SELECT r.rekv_id
        FROM get_asutuse_struktuur(l_rekvid) r
        WHERE rekv_id = CASE
                            WHEN l_kond = 1
                                -- kond
                                THEN rekv_id
                            ELSE l_rekvid END
          AND exists(SELECT id FROM eelarve.taotlus t WHERE t.rekvid = r.rekv_id)
        LOOP
            SELECT u.id
            INTO l_user_id
            FROM ou.userid u
            WHERE rekvid = v_rekv.rekv_id
              AND kasutaja IN (
                SELECT kasutaja
                FROM ou.userid
                WHERE id = user_id
                  AND status < 3
            )
              AND (u.roles ->> 'is_eel_koostaja') IS NOT NULL
              AND (u.roles ->> 'is_eel_koostaja')::BOOLEAN;

            IF l_user_id IS NULL
            THEN
                RAISE EXCEPTION 'Viga: kasutajal puudub vajaliku õigused %', v_rekv.rekv_id;
            END IF;

            l_json = NULL;
            l_count = 0;
            RAISE NOTICE 'l_kpv %, v_rekv.rekv_id %', l_kpv, v_rekv.rekv_id;

            -- paring andmed
            SELECT 0                                 AS id,
                   l_user_id :: INTEGER              AS userid,
                   l_kpv                             AS kpv,
                   v_rekv.rekv_id                    AS rekvid,
                   l_user_id                         AS koostajaid,
                   l_aasta                           AS aasta,
                   0                                 AS status,
                   l_aasta::TEXT || '. aasta eelnou' AS muud
            INTO v_taotlus;
            -- salvetsame
            l_doc_json = row_to_json(v_taotlus) :: TEXT;
            l_details_json = '[]';
            l_jsonb = '[]'::jsonb;


            FOR v_taotlus1 IN
                SELECT *
                FROM (
                         WITH qryTuluArtikklid AS (
                             SELECT l.kood
                             FROM libs.library l
                             WHERE l.tun5 = 1 --tulud
                               AND l.status <> 3
                               AND l.library = 'TULUDEALLIKAD'
                         ),
                              qryKuluArtikklid AS (
                                  SELECT l.kood
                                  FROM libs.library l
                                  WHERE l.tun5 <> 1 --kulud
                                    AND l.status <> 3
                                    AND l.library = 'TULUDEALLIKAD'
                              )
-- tulud
                         SELECT 0                    AS id,
                                l_user_id :: INTEGER AS userid,
                                sum(t1.summa)        AS summa,
                                sum(t1.summa_kassa)  AS summa_kassa,
                                t1.tunnus,
                                t1.proj,
                                t1.kood1,
                                t1.kood2,
                                t1.kood3,
                                t1.kood4,
                                t1.kood5,
                                t1.objekt,
                                t1.selg              AS selg
                         FROM eelarve.taotlus1 AS t1
                                  INNER JOIN eelarve.taotlus t ON t.id = t1.parentId
                         WHERE t.status = 3
                           AND t.aasta = l_aasta - 1
                           AND t.rekvid = v_rekv.rekv_id
                           AND t.tunnus <= l_tapsestatud
                           AND t1.kood5 IN (SELECT kood FROM qryTuluArtikklid)
                           AND coalesce(l_tulud, 0) > 0
                         GROUP BY t1.tunnus,
                                  t1.proj,
                                  t1.kood1,
                                  t1.kood2,
                                  t1.kood3,
                                  t1.kood4,
                                  t1.kood5,
                                  t1.objekt,
                                  t1.selg
                         UNION ALL
                         -- kulud
                         SELECT 0                    AS id,
                                l_user_id :: INTEGER AS userid,
                                sum(t1.summa)        AS summa,
                                sum(t1.summa_kassa)  AS summa_kassa,
                                t1.tunnus,
                                t1.proj,
                                t1.kood1,
                                t1.kood2,
                                t1.kood3,
                                t1.kood4,
                                t1.kood5,
                                t1.objekt,
                                t1.selg              AS selg
                         FROM eelarve.taotlus1 AS t1
                                  INNER JOIN eelarve.taotlus t ON t.id = t1.parentId
                         WHERE t.status = 3
                           AND t.aasta = l_aasta - 1
                           AND t.rekvid = v_rekv.rekv_id
                           AND t.tunnus <= l_tapsestatud
                           AND t1.kood5 IN (SELECT kood FROM qryKuluArtikklid)
                           AND coalesce(l_kulud, 0) > 0
                         GROUP BY t1.tunnus,
                                  t1.proj,
                                  t1.kood1,
                                  t1.kood2,
                                  t1.kood3,
                                  t1.kood4,
                                  t1.kood5,
                                  t1.objekt,
                                  t1.selg
                     ) qry

                LOOP
                    l_count = l_count + 1;
                    RAISE NOTICE 'v_taotlus1 %', v_taotlus1.kood5;
                    l_jsonb = l_jsonb::jsonb || to_jsonb(v_taotlus1);
                    l_details_json = (l_details_json::jsonb ||  to_jsonb(v_taotlus1)) :: TEXT;
                END LOOP;

            l_json = ('{"id":0,"data":' || trim(TRAILING FROM l_doc_json, '}')::TEXT || ',"gridData":[' ||
                      l_details_json ||
                      ']}}');
            l_jsonb_doc = to_jsonb(v_taotlus);
            l_jsonb_doc = l_jsonb_doc::jsonb || jsonb_build_object('gridData',l_jsonb);
            l_jsonb_doc = jsonb_build_object( 'id',0,'data',l_jsonb_doc::jsonb);

            RAISE NOTICE 'salvestan %', l_jsonb_doc;

            IF l_count > 0
            THEN
--                result = eelarve.sp_salvesta_taotlus(l_jsonb_doc::JSON, l_user_id, v_rekv.rekv_id);
                result = 1;
            END IF;
            RAISE NOTICE 'result %, v_rekv.rekv_id %, l_count %', result, v_rekv.rekv_id, l_count;

            l_details_json = NULL;
            l_json = NULL;
            l_doc_json = NULL;
            v_taotlus = NULL;
            l_count = 0;

        END LOOP;

    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION eelarve.koosta_eelarve_eelmise_aasta_alusel(INTEGER, JSONB) TO eelkoostaja;

/*

select eelarve.koosta_eelarve_eelmise_aasta_alusel(INTEGER, INTEGER, INTEGER ,INTEGER, date)

select * from eelarve.taotlus order by id desc limit 10

select eelarve.sp_kooperi_taotlus(70, 1613390)

select * from eelarve.taotlus where parentid = 1613406

*/
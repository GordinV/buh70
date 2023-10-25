/*DROP TABLE IF EXISTS tmp_ebat;
CREATE TABLE IF NOT EXISTS tmp_ebat (number integer, asutus text);

INSERT INTO tmp_ebat(number, asutus)
SELECT t.f[1]::integer   AS number, t.f[2]::text as asutus
FROM (
         SELECT regexp_split_to_array(l, ',') AS f
         FROM regexp_split_to_table(
                      $$10447,0820201 Kultuurimaja Rugodiv
10450,0820201 Kultuurimaja Rugodiv
10455,0820201 Kultuurimaja Rugodiv
10459,0820201 Kultuurimaja Rugodiv
3477,0810202 Narva Spordikeskus
3478,0810202 Narva Spordikeskus
3479,0810202 Narva Spordikeskus
3480,0810202 Narva Spordikeskus
3481,0810202 Narva Spordikeskus
3482,0810202 Narva Spordikeskus
3483,0810202 Narva Spordikeskus
5603,0820101 Narva Keskraamatukogu
13930,0911034 Narva Lasteaed Kirsike
12066,0911033 Narva Lasteaed Pingviin
13695,0911027 Narva Lasteaed Pongerjas
14891,0951004 Narva Muusikakool
5481,0951002 Narva Kunstikool
8387,0911036 Narva Lasteaed Vikerkaar
10476,0911032 Narva Lasteaed Sademeke
14142,0911031 Narva Lasteaed Sipsik
13689,0911037 Narva Lasteaed Cipollino
5466,0911007 Narva Lasteaed Tuluke
13983,0911010 Narva Lasteaed Potsataja
7319,0911030 Narva Lasteaed Tareke
12044,0911021 Narva Lasteaed Paikene
19505,0810203 Narva Paemurru Spordikool
2731,0911008 Narva Lasteaed Karikakar
168,0911012 Narva Lasteaed Kaseke
12859,0911038 Narva Lasteaed Kaoke
22371,0810204 Narva Spordikool Energia
6653,0911006 Narva Lasteaed Paasuke
8948,0911018 Narva Lasteaed Punamutsike$$, '\n') AS l) t;
*/


DROP FUNCTION IF EXISTS lapsed.delete_ebatoenaolised();

CREATE FUNCTION lapsed.delete_ebatoenaolised()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_journal      RECORD;
    l_count        INTEGER = 0;
    l_kokku        INTEGER = 0;
    l_user_id      INTEGER;
    l_json         JSONB;
    l_json_details JSONB   = '[]'::JSONB;
    v_params       RECORD;
    l_journal_id   INTEGER;

BEGIN
    /*    FOR v_journal IN (
            SELECT id, number, rekvasutus, rekvid, summa
            FROM cur_journal
            WHERE rekvid IN (SELECT id FROM ou.rekv WHERE parentid = 119 OR id = 119)
              AND deebet = '605030'
              AND kreedit = '103009'
              AND kpv >= '2023-10-01'
    --          AND kpv < '2023-10-01'
        )
            LOOP
                l_kokku = l_kokku + 1;
                RAISE NOTICE 'delete ... v_journal.number %, rekvasutus %, id %', v_journal.number, v_journal.rekvasutus, v_journal.id;

                IF exists(SELECT *
                          FROM tmp_ebat
                          WHERE number = v_journal.number AND left(asutus, 7) = left(v_journal.rekvasutus, 7))
                THEN
                    RAISE NOTICE 'in list, keelatud';
                    l_count = l_count + 1;
                ELSE
                    l_user_id = (SELECT id FROM ou.userid WHERE rekvid = v_journal.rekvid AND kasutaja = 'vlad' LIMIT 1);
                    PERFORM docs.sp_delete_journal(l_user_id, v_journal.id);
                END IF;
            END LOOP;
    */
/*    FOR v_journal IN (
        SELECT id, number, rekvasutus, rekvid, summa, selg
        FROM cur_journal
        WHERE rekvid IN (SELECT id FROM ou.rekv WHERE parentid = 119 OR id = 119)
          AND deebet = '103009'
          AND kreedit = '10300029'
          AND kpv >= '2023-09-01'
          AND kpv < '2023-10-01'
    )
        LOOP
            l_kokku = l_kokku + 1;
            RAISE NOTICE 'delete ... v_journal.number %, rekvasutus %, id %', v_journal.number, v_journal.rekvasutus, v_journal.id;

            IF exists(SELECT *
                      FROM tmp_ebat
                      WHERE number = v_journal.number AND left(asutus, 7) = left(v_journal.rekvasutus, 7))
            THEN
                RAISE NOTICE 'in list, keelatud';
                l_count = l_count + 1;
            ELSE
                l_user_id = (SELECT id FROM ou.userid WHERE rekvid = v_journal.rekvid AND kasutaja = 'vlad' LIMIT 1);
                PERFORM docs.sp_delete_journal(l_user_id, v_journal.id);
            END IF;
        END LOOP;
*/

    FOR v_journal IN (
        SELECT id,
               number,
               rekvasutus,
               rekvid,
               summa,
               kood1,
               kood2,
               kood5,
               tunnus,
               lisa_d,
               lisa_k,
               asutusid,
               selg,
               dok
        FROM cur_journal
        WHERE rekvid IN (SELECT id FROM ou.rekv WHERE parentid = 119 OR id = 119)
          AND deebet = '605030'
          AND kreedit = '103009'
          AND kpv >= '2023-07-01'
          AND kpv < '2023-08-01'
    )
        LOOP

            l_user_id = (SELECT id FROM ou.userid WHERE rekvid = v_journal.rekvid AND kasutaja = 'vlad' LIMIT 1);

            l_json_details = '[]'::jsonb || to_jsonb(row)
                             FROM (SELECT 0                    AS id,
                                          -1 * v_journal.summa AS summa, -- 50% от требования
                                          '605030'             AS deebet,
                                          '103009'             AS kreedit,
                                          v_journal.kood1      AS kood1,
                                          v_journal.kood2      AS kood2,
                                          v_journal.kood5,
                                          v_journal.tunnus,
                                          v_journal.lisa_d     AS lisa_d,
                                          v_journal.lisa_k     AS lisa_k
                                  ) row;

            SELECT 0                  AS id,
                   'JOURNAL'          AS doc_type_id,
                   '2023-09-01'::DATE AS kpv,
                   v_journal.selg     AS selg,
                   v_journal.Asutusid,
                   v_journal.dok      AS dok,
                   l_json_details     AS "gridData"
            INTO v_params;

            l_json = to_json(row)
                     FROM (SELECT 0        AS id,
                                  v_params AS data) row;

            l_journal_id = docs.sp_salvesta_journal(l_json :: JSON, l_user_id, v_journal.rekvId);

            UPDATE docs.journal
            SET properties = coalesce(properties, '{}'::JSONB) ||
                             jsonb_build_object('kreedit_lausend_id', l_journal_id)
            WHERE parentid = v_journal.id;

            RAISE NOTICE 'originaal lausend_id %, kreedit l_journal_id %', v_journal.id, l_journal_id;
            l_kokku = l_kokku + 1;

        END LOOP;

    RAISE NOTICE 'l_kokku %', l_kokku;
    RETURN l_count;

END ;

$$;

SELECT *
FROM lapsed.delete_ebatoenaolised();

DROP FUNCTION IF EXISTS lapsed.delete_ebatoenaolised();


/*
drop table if exists tmp_viitenr;
create table if not EXISTS tmp_viitenr (vn text,  ik text, asutus text);

insert into  tmp_viitenr(ik)
SELECT
    t.f[1]::text AS ik
FROM (
         SELECT regexp_split_to_array(l, ';') AS f
         FROM regexp_split_to_table(
                      $$61010183729
50707167055
60104243724
60906193754
60402063714
50810013717
51005063718
60112043717
50704103740
60612203738
50404273742
51102093727
51103233757
51305190022
50809083730
50305093724
60801093731
39809193715
60501113738
50107213728
60902013716
60302113715
51212073742
61509150250
50704303724
51310070208
60405213728
51308230176
39508253756
51406170085
60301193744
60605073720
50501200843
51107143712
61204043717
39912083718
61310130059
61005127087
50909057145
60301293728
51006103711
50005143752
50102223732
39805263713
50711163738
50709083727
50303013713
51511180049
51009120017
61412290261
60503263712
61409200044
51202080057
39004293727
60611093733
60612283749
60806093734
60612163720
50205183716
51304230156
50203053716
60105243729
61210153736
60701073725
50206273724
50103203734
39910283716
50210043710
60708173722
60510253738
50302123710
61104263729
50602023713
60707243713
60607313750
60409013747
51203073732
60507063731
60704063711
49811293719
51202143712
51211253713
60703243715
60905053737
50904033717
51110243720
61201013714
60707313711
50711293710
61001073728
60703123728
60712123716
60003022726
60701083743
49811033720
60904143711
49808313722
60805273727
60706173712
60211075240
50511253720
51008033712
60606043737
49010133719
60402163712
50202133725
60309203738
60308223769
51001203712
50911033728
50907183718
49911153721
50906193742
39908043749
50608193710
60907243720
38904133715
51111300124
60406023739
60105103750
60409072214
51104273713
50909023713
50903243720
60006163728
61009133713
60302063722
49905243714
50507022237
60208083719
51304130030
51311190137
60803173733
61203053719
60203183744
60810263710
50007083718
50201093712
49409093711
50904267063
60906123727
60707263738
50710023721
60108273743
60305133733
50607123744
60702253739
60710153727
49906303730
39202273731
61203143718
61307160187
49302253743
50606173719
60611083711
50307033714
50712053730
50701133713
60908283720
51111300124
60601143729
50912293710
61107152789
51109063719
51204080092
50602210248
50902233741
50909183739
50309043716
51407140305
61001293732
49907223710
50602033720
61306280310
61210263716
61201133712
61210043712
61310290030
60801147015
60903273731
60807163746
50608043713
61402200020
51110063711
51504300027
51105153710
60808223718
50808093721
60706303720
60911053710
60708083712
50204243737
$$, '\n') AS l) t;
*/
DROP FUNCTION IF EXISTS lapsed.restore_teenused();

CREATE FUNCTION lapsed.restore_teenused()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_vn      RECORD;
    v_lk      RECORD;
    l_count   INTEGER = 0;
    l_rekv_id INTEGER;
    l_kokku   INTEGER = 0;
    l_vn      TEXT;
    l_ik      TEXT;
    l_viitenr TEXT;
    l_laps_id INTEGER;
BEGIN
    -- Эти VN необходимо присвоить только имеющим слуги детям в своих учреждениях.
-- Если ребенка в указанном учрежд. нет, то такого надо игнорировать и не сохранять его нигде в базе не создавая мусора.
-- Если ребенок есть (имеет услуги), то присваиваем ему старый ВН
-- Если ребенок есть (имеет услуги) и имеет какой-то, ранее присвоенный ВН, то просто добавляем ему еще один ВН

    FOR v_vn IN
        SELECT regexp_replace(ik, E'(^[\\n\\r]+)|([\\n\\r]+$)', '', 'g') AS ik
        FROM tmp_viitenr
        WHERE ik IS NOT NULL
        LOOP
            RAISE NOTICE ' ik %', v_vn.ik;
            l_rekv_id = 66;

            l_laps_id = (SELECT id FROM lapsed.laps WHERE isikukood = v_vn.ik ORDER BY id DESC LIMIT 1);

--            в Паемуру этим детям услуги с датой окончания позднее 31.12.2021, установи дату окончания действия этих услуг 31.12.2021.
            UPDATE lapsed.lapse_kaart
            SET properties = properties || '{
              "lopp_kpv": "2021-12-31"
            }'::JSONB
            WHERE parentid = l_laps_id
              AND rekvid = l_rekv_id
              AND (properties ->> 'lopp_kpv')::DATE > '2021-12-31'
              AND staatus < 3;
        END LOOP;


    --После этого всем услугам,  где не присвоен старый VN, установи его (если он один в карточке)

    FOR v_lk IN
        SELECT l.isikukood, lk.*
        FROM lapsed.lapse_kaart lk
                 INNER JOIN lapsed.laps l ON l.id = lk.parentid

        WHERE lk.staatus < 3
          AND rekvid = 66
          AND ((lk.properties ->> 'viitenr') IS NULL OR empty(lk.properties ->> 'viitenr') OR
               (lk.properties ->> 'viitenr') = l.isikukood)
        LOOP
            -- otsime VN
            l_viitenr = (SELECT v.viitenumber
                         FROM lapsed.viitenr v
                         WHERE v.isikukood = v_lk.isikukood
                           AND v.rekv_id = 66
                         ORDER BY id DESC
                         LIMIT 1);

            IF l_viitenr IS NOT NULL
            THEN
                UPDATE lapsed.lapse_kaart
                SET properties = properties || jsonb_build_object('viitenr', l_viitenr)
                WHERE id = v_lk.id;
            END IF;

        END LOOP;

    RETURN l_count;

END;
$$;

SELECT lapsed.restore_teenused();

DROP FUNCTION IF EXISTS lapsed.restore_teenused();
--DROP TABLE IF EXISTS tmp_viitenr;
/*
 select trim(replace(vn,E'\n',''),'"'), vn, ik, asutus from tmp_viitenr_kustuta

SELECT id FROM ou.rekv WHERE left(nimetus, 10) = left(trim('"0911027 Narva Lasteaed Pongerjas T"','"'), 10) LIMIT 1

          FROM lapsed.viitenr
            WHERE isikukood = v_vn.ik
              AND rekv_id = l_rekv_id
              AND viitenumber = trim(replace(v_vn.vn,E'\n',''),'"');

select * from tmp_viitenr_kustuta
 where vn = '9366554'

 */

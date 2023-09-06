/*DROP TABLE IF EXISTS tmp_isikud;
CREATE TABLE IF NOT EXISTS tmp_isikud (
    ik TEXT
);

INSERT INTO tmp_isikud(ik)
SELECT t.f[1]::TEXT AS ik
FROM (
         SELECT regexp_split_to_array(l, ';') AS f
         FROM regexp_split_to_table(
                      $$37209162752
37401023736
37405023734
37607213711
37612053717
37905103719
37907143713
38002112210
38403242210
44906133729
45307102232
46004192240
46105263711
46507157018
46508012213
46702243742
47106203718
47112183730
47205042223
47209233713
47303073724
47306230351
47410062211
47412090030
47503153711
47505273724
47505273730
47507174219
47508062261
47511113710
47601053720
47603192734
47605193719
47608203710
47610073722
47704153722
47709083740
47710133714
47802022234
47805293720
47807144240
47807213729
47811170062
47907212212
47907213743
47907302222
47909012221
48005093719
48006233716
48008202229
48009283722
48012033710
48106243715
48109083713
48111103715
48112312241
48203083725
48203313710
48204222218
48207107013
48209042245
48210143726
48211013719
48211153720
48302197010
48302272246
48303222253
48305312236
48309283720
48310222238
48310263711
48405172214
48405263744
48406153736
48409282214
48502173722
48507043719
48507213744
48511213729
48601033719
48603053732
48604163728
48604183742
48604262225
48605313710
48606270041
48609053718
48701122234
48701222218
48702283719
48703022216
48707123718
48709132226
48711083728
48712273716
48801070043
48811243715
48811303726
48904153726
48904203734
48908237011
48909123734
48912233716
49002153717
49003283716
49008302215
49009043728
49101233729
49104243740
49106253713
49107162254
49108053711
49110183713
49205053743
49301293711
49306023719
49311072714
49402123719
49405233736
49507103711
49609077014$$, '\n') AS l) t;

*/
DROP TABLE IF EXISTS tmp_maksjad;

CREATE TEMPORARY TABLE IF NOT EXISTS tmp_maksjad (
    ik                TEXT,
    nimi              TEXT,
    viimane_laekumise DATE,
    asutus            TEXT,
    lapse_nimi        TEXT
);


DROP FUNCTION IF EXISTS lapsed.lisa_info;

CREATE FUNCTION lapsed.lisa_info()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_ik      RECORD;
    l_count   INTEGER = 0;
    v_pank_vv RECORD;
    v_laps    RECORD;
BEGIN
    raise notice 'start';

    FOR v_ik IN
        SELECT * FROM tmp_isikud
--        where left(ik,11)::text = '49106253713'::text
        LOOP

            SELECT *
            INTO v_pank_vv
            FROM lapsed.pank_vv
            WHERE left(ltrim(rtrim(isikukood)),11) = left(ltrim(rtrim(v_ik.ik)),11)
            ORDER BY kpv DESC
            LIMIT 1;

            raise notice 'v_ik %, v_pank_vv %', v_ik.ik, v_pank_vv;


            IF v_pank_vv.isikukood IS NOT NULL
            THEN

                raise notice 'found v_ik %',v_ik.ik;

                SELECT laps.nimi, r.nimetus AS asutus
                INTO v_laps
                FROM lapsed.laps laps
                         INNER JOIN lapsed.liidestamine l ON l.parentid = laps.id
                         INNER JOIN docs.doc d ON d.id = l.docid
                         INNER JOIN ou.rekv r ON r.id = d.rekvid
                WHERE l.docid = v_pank_vv.doc_id
                ORDER BY d.id DESC
                LIMIT 1;

                INSERT INTO tmp_maksjad (ik, nimi, viimane_laekumise, asutus, lapse_nimi)
                VALUES (v_pank_vv.isikukood, v_pank_vv.maksja, v_pank_vv.kpv, v_laps.asutus, v_laps.nimi);

                l_count = l_count + 1;


            END IF;


        END LOOP;

    RETURN l_count;

END;
$$;

select lapsed.lisa_info();

DROP FUNCTION IF EXISTS lapsed.lisa_info;

select * from tmp_maksjad;

/*
drop table if exists tmp_arved;
create table if not EXISTS tmp_arved (ik text, summa numeric);

insert into  tmp_arved (ik, summa)
SELECT
    t.f[1]::text AS ik
        ,abs(replace(t.f[2],',','.') ::NUMERIC) AS summa
FROM (
         SELECT regexp_split_to_array(l, ';') AS f
         FROM regexp_split_to_table(
                      $$45001163722;-362,49
43710163749;-1154,97
43708183722;-566,47
33908063718;-1385,31
35405132223;-108,41
36010092239;-1404,28
45601202217;-223,15
44612183750;-871,12
35205303717;-1249,46
35204283735;-1781,95
45606242215;-661,76
43609263738;-520,49
44907043735;-1782,59
45209240044;-209,62
35402223738;-554,36
43812083737;-113,82
45307123711;-899,34
44702142212;-157,60
44611023730;-1135,25
43912013746;-185,87
45202133712;-1023,10
44602083729;-390,12
45412223721;-906,57
36404103730;-1772,65
44810073711;-194,01
33209213712;-771,90
35012263736;-340,63
45312153711;-625,47
43104103738;-81,82$$, '\n') AS l) t;
*/
DROP FUNCTION IF EXISTS algsaldo_nstk();

CREATE FUNCTION algsaldo_nstk()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_arv    RECORD;
    l_rekvid INTEGER;
    l_tunnus TEXT;
    tmp_arv  RECORD;
    l_asutus_id INTEGER;
BEGIN
    FOR v_arv IN
        SELECT *
        FROM tmp_arved
        WHERE ik IS NOT NULL
        LOOP

            l_asutus_id = (select id from libs.asutus where ltrim(rtrim(regkood)) = ltrim(rtrim(v_arv.ik)));

            raise notice 'l_asutus_id %, v_arv.ik %, v_arv.summa %', l_asutus_id, v_arv.ik, v_arv.summa;

            update hooldekodu.hootehingud set status = 3 where  kpv < '2022-12-31' and isikid = l_asutus_id and status < 3;

            insert into hooldekodu.hootehingud (isikid, ettemaksid, journalid, dokid, doktyyp, kpv, summa, allikas, tyyp, jaak, muud, properties, status, rekvid)
            VALUES (l_asutus_id, null, null, null, 'ALGSALDO', '2022-12-31',v_arv.summa, 'TOETUS', 'TULUD', 0, 'ALG.SALDO 2023', null, 1, 132);

            perform hooldekodu.sp_calc_hoojaak(l_asutus_id);

        END LOOP;

    RETURN 0;

END;
$$;

SELECT algsaldo_nstk();

--DROP FUNCTION IF EXISTS paranda_lausend_arv();



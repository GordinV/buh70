/*drop table if exists tmp_libs;
create table if not EXISTS tmp_libs (kood text,  nimetus text);

insert into  tmp_libs (kood, nimetus)
SELECT
    t.f[1]::text AS kood
        ,t.f[2]::text AS nimetus
FROM (
         SELECT regexp_split_to_array(l, ';') AS f
         FROM regexp_split_to_table(
                      $$AJ;Ametnikud - Juhid
ATS;Ametnikud - Tippspetsialistid
AKS;Ametnikud - Keskastme spetsialistid
ANS;Ametnikud - Nooremspetsialistid
TJ(A);Juhid - töölepingu alusel linna ametiasutustes
TTS(A);Tippspetsialistid - töölepingu alusel linna ametiasutustes
TKS(A);Keskastme spetsialistid - töölepingu alusel linna ametiasutustes
TNS(A);Nooremspetsialistid - töölepingu alusel linna ametiasutustes
TT(A);Töötajad töölepingu alusel linna ametiasutustes
TJ1;Juhid I alagrupp - töölepingu alusel
TJ2;Juhid II alagrupp - töölepingu alusel
TTS;Tippspetsialistid - töölepingu alusel
TKS;Keskastme spetsialistid - töölepingu alusel
TNS;Nooremspetsialistid - töölepingu alusel
TT;Töötajad - töölepingu alusel
LJ2V;Lasteaedade juhid (direktor) nõuetele vastav
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav
LJ2MV;Lasteaedade juhid (direktor) nõuetele mittevastav
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav
LMV;Lasteaedade õpetaja magistrikraadiga nõuetele vastav
LBV;Lasteaedade õpetaja bakalaureusekraadiga nõuetele vastav
LMMV;Lasteaedade õpetaja magistrikraadiga nõuetele mittevastav
LBMV;Lasteaedade õpetaja bakalaureusekraadiga nõuetele mittevastav
KJ2-RE-JAH;Koolide nõuetele vastavad juhid (direktor), riigieelarve vahendid RE-HKJ
KJ2-RE-EI;Koolide nõuetele mittevastavad juhid (direktor), riigieelarve vahendid RE-HKJ
KJ2-LE-JAH;Koolide nõuetele vastavad juhid (direktor), linna põhieelarve vahendid LE-P
KJ2-LE-EI;Koolide nõuetele mittevastavad juhid (direktor), linna põhieelarve vahendid LE-P
KJ1-RE-JAH;Koolide nõuetele vastavad juhid (õppealajuhataja), riigieelarve vahendid RE-HKJ
KJ1-RE-EI;Koolide nõuetele mittevastavad juhid (õppealajuhataja), riigieelarve vahendid RE-HKJ
KJ1-LE-JAH;Koolide nõuetele vastavad juhid (õppealajuhataja), linna põhieelarve vahendid LE-P
KJ1-LE-EI;Koolide nõuetele mittevastavad juhid (õppealajuhataja), linna põhieelarve vahendid LE-P
KJ1-LE;Koolide juhid (õppealajuhataja), linna põhieelarve vahendid LE-P
HKP-JAH;Koolide põhikooliastme õpetajad nõuetele vastavad, riigieelarve vahendid RE-HKP
HKP-EI;Koolide põhikooliastme õpetajad nõuetele mittevastavad, riigieelarve vahendid RE-HKP
HKG-JAH;Koolide  gümnaasiumi astme õpetajad nõuetele vastavad, riigieelarve vahendid RE-HKG
HKG-EI;Koolide gümnaasiumi õpetajad nõuetele mittevastavad, riigieelarve vahendid RE-HKG
LEP-JAH;Koolide põhikooliastme õpetajad nõuetele vastavad, linna põhielarve vahendid LE-P
LEP-EI;Koolide põhikooliastme õpetajad nõuetele mittevastavad, linna põhielarve vahendid LE-P
LEG-JAH;Koolide  gümnaasiumi astme õpetajad nõuetele vastavad, linna põhielarve vahendid LE-P
LEG-EI;Koolide gümnaasiumi õpetajad nõuetele mittevastavad, linna põhielarve vahendid LE-P
TSRHKU-JAH;Koolide tugispetsialistid nõuetele vastavad, riigieelarve vahendid RE-HKU
TSRHKU-EI;Koolide tugispetsialistid nõuetele mittevastavad, riigieelarve vahendid RE-HKU
TSRHKP-JAH;Koolide tugispetsialistid nõuetele vastavad, riigieelarve vahendid RE-HKP
TSRHKP-EI;Koolide tugispetsialistid nõuetele mittevastavad, riigieelarve vahendid RE-HKP
TSRHKG-JAH;Koolide tugispetsialistid nõuetele vastavad, riigieelarve vahendid RE-HKG
TSRHKG-EI;Koolide põhikooliastme õpetajad nõuetele mittevastavad, riigieelarve vahendid RE-HKG
TS-JAH;Koolide tugispetsialistid nõuetele vastavad, linna põhieelarve vahendid LE-P
TS-EI;Koolide tugispetsialistid nõuetele mittevastavad, linna põhieelarve vahendid LE-P
KK;Koolide keskharidusega huvijuhid, ringijuhid ja kasvatajad, linna põhielarve vahendid LE-P
KKE;Koolide keskeriharidusega huvijuhid, ringijuhid ja kasvatajad, linna põhielarve vahendid LE-P
KB;Koolide bakalaureusekraadiga huvijuhid, ringijuhid ja kasvatajad, linna põhielarve vahendid LE-P
KM;Koolide magistrikraadiga huvijuhid, ringijuhid ja kasvatajad, linna põhielarve vahendid LE-P
HJ2V;Huvikoolide juhid (direktor) nõuetele vastav
HJ1V;Huvikoolide juhid (õppealajuhataja) nõuetele vastav
HJ2MV;Huvikoolide juhid (direktor) nõuetele mittevastav
HJ1MV;Huvikoolide juhid (õppealajuhataja) nõuetele mittevastav
HK;Huvikoolide keskharidusega õpetajad
HKE;Huvikoolide keskeriharidusega õpetajad
HB;Huvikoolide bakalaureusekraadiga õpetajad
HM;Huvikoolide magistrikraadiga õpetajad
HK3;Spordikoolide treenirid keskharidusega, kutsetase 3
HK4;Spordikoolide treenirid keskharidusega, kutsetase 4
HK5;Spordikoolide treenirid keskharidusega, kutsetase 5
HK6;Spordikoolide treenirid keskharidusega, kutsetase 6
HK7;Spordikoolide treenirid keskharidusega, kutsetase 7
HKE3;Spordikoolide treenirid keskeriharidusega, kutsetase 3
HKE4;Spordikoolide treenirid keskeriharidusega, kutsetase 4
HKE5;Spordikoolide treenirid keskeriharidusega, kutsetase 5
HKE6;Spordikoolide treenirid keskeriharidusega, kutsetase 6
HKE7;Spordikoolide treenirid keskeriharidusega, kutsetase 7
HB3;Spordikoolide treenirid bakalaureusekraadiga, kutsetase 3
HB4;Spordikoolide treenirid bakalaureusekraadiga, kutsetase 4
HB5;Spordikoolide treenirid bakalaureusekraadiga, kutsetase 5
HB6;Spordikoolide treenirid bakalaureusekraadiga, kutsetase 6
HB7;Spordikoolide treenirid bakalaureusekraadiga, kutsetase 7
HM3;Spordikoolide treenirid magistrikraadiga, kutsetase 3
HM4;Spordikoolide treenirid magistrikraadiga, kutsetase 4
HM5;Spordikoolide treenirid magistrikraadiga, kutsetase 5
HM6;Spordikoolide treenirid magistrikraadiga, kutsetase 6
HM7;Spordikoolide treenirid magistrikraadiga, kutsetase 7
$$, '\n') AS l) t;
*/
DROP FUNCTION IF EXISTS libs.import_ameti_klassifikaatorid();

CREATE FUNCTION libs.import_ameti_klassifikaatorid()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_ak    RECORD;
    l_count INTEGER = 0;
BEGIN

    FOR v_ak IN
        SELECT
            kood,
            nimetus
        FROM
            tmp_libs
        where nimetus is not null
        LOOP
            if not exists
            (
                select id
                from libs.library
                where library = 'AMETI_KLASSIF'
                and ltrim(rtrim(kood)) = ltrim(rtrim(v_ak.kood))
            ) then
                insert into libs.library (rekvid, kood, nimetus, library)
                values (63,v_ak.kood, v_ak.nimetus, 'AMETI_KLASSIF');
                l_count = l_count + 1;
            end if;
        END LOOP;
    RETURN l_count;

END;
$$;

SELECT libs.import_ameti_klassifikaatorid();

DROP FUNCTION IF EXISTS libs.import_ameti_klassifikaatorid();
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

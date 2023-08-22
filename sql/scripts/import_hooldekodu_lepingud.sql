/*

drop table if exists tmp_hoolepingud;

create table if not EXISTS tmp_hoolepingud (eesnimi text, perenimi text, ik text, kohamaksumus numeric,
hoolduskulu numeric, kov_piirimaar numeric, brutto numeric, netto numeric,
taskuraha numeric, hooldekodu_regkood text);

insert into  tmp_hoolepingud(eesnimi, perenimi, ik , kohamaksumus, hoolduskulu, kov_piirimaar, brutto, netto, taskuraha)
SELECT
    t.f[1]::text AS eesnimi
        ,t.f[2]::text AS perenimi
        ,t.f[3]::text AS ik
        ,rtrim(regexp_replace(overlay( t.f[4] placing '' from 2 for 1),'[,]','.'))::numeric AS kohamaksumus
        ,rtrim(regexp_replace(regexp_replace( t.f[5],'[ ]',''),'[,]','.'))::numeric AS hoolduskulu
        ,rtrim(regexp_replace(regexp_replace( t.f[6],'[ ]',''),'[,]','.'))::numeric AS kov_piirimaar
        ,rtrim(regexp_replace(case when position(' ' in t.f[8]) > 0 then overlay( t.f[3] placing '' from 2 for 1) else regexp_replace( t.f[8],'[ ]','') end ,'[,]','.'))::numeric AS brutto
        ,rtrim(regexp_replace(regexp_replace( t.f[9],'[ ]',''),'[,]','.'))::numeric AS netto
        ,t.f[11]::numeric AS taskuraha
FROM (
         SELECT regexp_split_to_array(l, ';') AS f
         FROM regexp_split_to_table(
                      $$AELITA;TIMOFEEVA;43804272228;1 150,00   ;541;700,00   ;541,00   ;745,59   ;737,27   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;01.01.2022;31.12.2032
ALEXANDER ;SERGEEV;36005083731;1 150,00   ;541;700,00   ;541,00   ;558,00   ;558,00   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
ANATOLY;STEPANOV;34901213728;1 150,00   ;541;700,00   ;541,00   ;1 032,55   ;966,84   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
ANNA;SHUMENKOVA;43401143716;1 150,00   ;541;700,00   ;541,00   ;701,07   ;701,07   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
ANNA;SOKOLOVA;43702223722;1 150,00   ;541;700,00   ;541,00   ;691,33   ;691,33   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
BOLESLOVAS;ZINKEVICIUS;33107282228;1 150,00   ;541;700,00   ;541,00   ;725,83   ;721,46   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
DMITRY ;LUKIN;37503293711;1 050,00   ;541;700,00   ;541,00   ;558,00   ;558,00   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
EDUARD;MALÕŠEVSKI;33912100296;1 050,00   ;541;700,00   ;541,00   ;774,78   ;760,62   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
EKATERINA;EYDEMILLER;44109213723;1 150,00   ;541;700,00   ;541,00   ;738,36   ;731,49   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
ELENA;PINCHUK;46611033728;1 150,00   ;541;700,00   ;541,00   ;558,00   ;558,00   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
GALINA;MIKHAILOVA;43210160068;1 150,00   ;541;700,00   ;541,00   ;336,39   ;336,39   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
GALINA;ŠTŠENNIKOVA;43606253727;1 150,00   ;541;700,00   ;541,00   ;630,54   ;630,54   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
GALINA;KAMLEVA;43703193715;1 150,00   ;541;700,00   ;541,00   ;660,94   ;660,94   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
GALINA;KAZANOVA;43806033729;1 150,00   ;541;700,00   ;541,00   ;700,55   ;700,55   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
GALINA;JERŠOVA;43902043719;1 050,00   ;541;700,00   ;541,00   ;682,65   ;682,65   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
GALINA;VASSINA;43904053714;1 150,00   ;541;700,00   ;541,00   ;823,86   ;799,89   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
IRAIDA;PAUMAN;43007053713;1 150,00   ;541;700,00   ;541,00   ;713,04   ;711,23   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
IRINA;ŠLÕPKINA;44203153718;1 150,00   ;541;700,00   ;541,00   ;978,87   ;923,90   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
JEKATERINA;GRIBOVA;43412013720;1 150,00   ;541;700,00   ;541,00   ;760,80   ;749,44   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
JEVGENI;STEPANOV;36402283716;1 150,00   ;541;700,00   ;541,00   ;578,44   ;578,44   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
JEVGENIA ;RABTSEVITŠ;43506213740;1 150,00   ;541;700,00   ;541,00   ;708,70   ;707,76   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
KIIRA;MARKINA;44002203711;1 150,00   ;541;700,00   ;541,00   ;728,19   ;723,35   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
LARISA;SEMENOVA;43107093722;1 150,00   ;541;700,00   ;541,00   ;678,31   ;678,31   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
LEIDA;BRENNER;43508073736;1 150,00   ;541;700,00   ;541,00   ;626,29   ;626,29   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
LIDIA;MAKSIMOVITŠ;43605263729;1 150,00   ;541;700,00   ;541,00   ;669,91   ;669,91   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
LILIYA;ISAEVA;43008153724;1 150,00   ;541;700,00   ;541,00   ;587,12   ;587,12   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
LIUDMILA;BOGDANOVA;43410063712;1 150,00   ;541;700,00   ;541,00   ;626,61   ;626,61   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
LIUDMILA;KUVAKINA;43907013712;1 150,00   ;541;700,00   ;541,00   ;749,31   ;740,25   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
LIUDMILA;TOKAREVA;45304283711;1 050,00   ;541;700,00   ;541,00   ;688,73   ;688,73   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
LIYA;SAMODELKINA;44009063710;1 150,00   ;541;700,00   ;541,00   ;695,67   ;695,67   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
MARGARITA;BOJETSKAJA;43502272218;1 150,00   ;541;700,00   ;541,00   ;708,70   ;707,76   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
MARGARITA;KRASSILNIKOVA;44005033713;1 050,00   ;541;700,00   ;541,00   ;718,54   ;715,63   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
MARIA;MATSAKOVA;42704043710;1 150,00   ;541;700,00   ;541,00   ;708,70   ;707,76   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
MARIA;ZAVJALOVA;43301313715;1 150,00   ;541;700,00   ;541,00   ;717,53   ;714,82   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
MARIA;ŽILTSOVA;43607273713;1 150,00   ;541;700,00   ;541,00   ;686,99   ;686,99   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
MARIA;PETROVA;44209203719;1 150,00   ;541;700,00   ;541,00   ;736,57   ;730,06   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
MARINA;SMIRNOVA;44701083716;1 050,00   ;541;700,00   ;541,00   ;571,62   ;571,62   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
MARINA;PETROVA;46211113721;1 150,00   ;541;700,00   ;541,00   ;558,00   ;558,00   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
MIHHAIL;MIHHALTŠENKO;34003163718;1 150,00   ;541;700,00   ;541,00   ;847,57   ;818,86   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
MILVI;SIIG;43603163713;1 050,00   ;541;700,00   ;541,00   ;708,70   ;707,76   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
NADEZHDA;FEDOTOVA;45608053732;1 150,00   ;541;700,00   ;541,00   ;554,31   ;554,31   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
NADEZHDA;DOBRODEY;44810173728;1 150,00   ;541;700,00   ;541,00   ;480,28   ;480,28   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
NADEZHDA ;ANTONOVA;44904103720;1 150,00   ;541;700,00   ;541,00   ;605,88   ;605,88   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
NATALJA;SOMOVA;45605103718;1 050,00   ;541;700,00   ;541,00   ;691,25   ;691,25   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
NIINA;SALL;42709192223;1 150,00   ;541;700,00   ;541,00   ;825,93   ;801,54   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
NIINA;KUZMINA;43301013741;1 150,00   ;541;700,00   ;541,00   ;708,70   ;707,76   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
NIKOLAI;LEEMAN;35905073725;1 050,00   ;541;700,00   ;541,00   ;558,00   ;558,00   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
NIKOLAY;GOLOVKOV;35402223727;1 150,00   ;541;700,00   ;541,00   ;667,53   ;667,53   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
NINA;SERGEEVA;45008143765;1 050,00   ;541;700,00   ;541,00   ;574,24   ;574,24   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
NINA;VASILIEVA;45107103713;1 050,00   ;541;700,00   ;541,00   ;678,67   ;678,67   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
OLEG;SUPEROV;35111283737;1 050,00   ;541;700,00   ;541,00   ;626,90   ;626,90   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
PETR;KISELEV;33409122221;1 050,00   ;541;700,00   ;541,00   ;677,76   ;677,76   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
RAISA;LEGOTKINA;44907292233;1 150,00   ;541;700,00   ;541,00   ;700,91   ;700,91   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
SALMA;MUONI;42901173717;1 050,00   ;541;700,00   ;541,00   ;665,28   ;665,28   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
SERGEY;NIKISHOV;35403122261;1 150,00   ;541;700,00   ;541,00   ;696,15   ;696,15   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
SIRJE;MÜRK;45001273713;1 050,00   ;541;700,00   ;541,00   ;678,90   ;678,90   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
ZINAIDA;MÜRSEP;43405293711;1 050,00   ;541;700,00   ;541,00   ;678,31   ;678,31   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
TAMARA;EFIMOVA;43504112215;1 150,00   ;541;700,00   ;541,00   ;639,23   ;639,23   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
TAMARA;SKASYRSKAYA;43708203716;1 150,00   ;541;700,00   ;541,00   ;700,02   ;700,02   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
TATIANA;AVVAKUMOVA;43310173722;1 150,00   ;541;700,00   ;541,00   ;769,49   ;756,39   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
TATJANA;TKATŠENKOVA;46205163717;1 050,00   ;541;700,00   ;541,00   ;558,00   ;558,00   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
VALENTINA;SHABUNOVA;43105152214;1 150,00   ;541;700,00   ;541,00   ;747,78   ;739,02   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
VALERI;DUPLENKOV;35405143717;1 150,00   ;541;700,00   ;541,00   ;578,44   ;578,44   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
VALERIY;TATARCHENKO;34107183711;1 050,00   ;541;700,00   ;541,00   ;854,49   ;824,39   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
VASILY;KORZANOV;32605093724;1 150,00   ;541;700,00   ;541,00   ;811,81   ;790,25   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
VASSILI;PONOMARJOV;35004052236;1 150,00   ;541;700,00   ;541,00   ;711,41   ;709,93   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
VEERA;GEORGIEVA;43605253722;1 150,00   ;541;700,00   ;541,00   ;695,98   ;695,98   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
VEERA;ARTJUŠKINA;43609182215;1 050,00   ;541;700,00   ;541,00   ;723,71   ;719,77   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
VEERA;TIMONINA;45101083733;1 150,00   ;541;700,00   ;541,00   ;658,29   ;658,29   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
VICTOR;SHAROFOST;35008143720;1 050,00   ;541;700,00   ;541,00   ;686,49   ;686,49   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
VICTOR ;SEMENOV;34906163727;1 050,00   ;541;700,00   ;541,00   ;705,08   ;704,86   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
VIKTOR;KALININ;35303253728;1 150,00   ;541;700,00   ;541,00   ;687,25   ;687,25   ;;0;;;Narva Sotsiaaltöökeskus;75038078;;;
VLADIMIR;ANDREJEV;34702153716;1 150,00   ;541;700,00   ;541,00   ;814,77   ;792,62   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
VLADIMIR;ANTONOV;34702067019;1 150,00   ;541;700,00   ;541,00   ;626,90   ;626,90   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
VLADIMIR;BAŠUROV;34807255243;1 150,00   ;541;700,00   ;541,00   ;975,62   ;859,62   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
VLADIMIR;IVANOV;35110293717;1 050,00   ;541;700,00   ;541,00   ;521,36   ;521,36   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
VYACHESLAV ;SHISHOV;34401242225;1 150,00   ;541;700,00   ;541,00   ;847,15   ;818,52   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
VYACHESLAV ;PERETOCHKIN;34007083724;1 150,00   ;541;700,00   ;541,00   ;674,74   ;674,74   ;;0;;;Narva Sotsiaaltöökeskus;75038078;;;
YULIA;SAVINA;43312013717;1 150,00   ;541;700,00   ;541,00   ;717,38   ;714,70   ;;15;;;Narva Sotsiaaltöökeskus;75038078;;;
YURI;SAVIN;34506293720;1 050,00   ;541;700,00   ;541,00   ;698,82;698,82;;0;;;Narva Sotsiaaltöökeskus;75038079;;;$$, '\n') AS l) t;
*/
DROP FUNCTION IF EXISTS hooldekodu.import_hooldekodu_lepingud();

CREATE FUNCTION hooldekodu.import_hooldekodu_lepingud()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_lep           RECORD;
    l_count         INTEGER = 0;
    l_rekv_id       INTEGER;
    l_isik_id       INTEGER;
    l_jsonb         JSONB;
    l_user_id       INTEGER = (SELECT id
                               FROM ou.userid
                                   WHERE kasutaja = 'vlad'
                                        AND rekvid = 132
                                   LIMIT 1);
    l_leping_id     INTEGER;
    l_hooldekodu_id INTEGER = (SELECT id
                               FROM libs.asutus WHERE regkood = '75038078' ORDER BY id DESC LIMIT 1);
    l_kov_id        INTEGER = (SELECT id
                               FROM libs.asutus WHERE regkood = '75009148' ORDER BY id DESC LIMIT 1);
    l_grid_json     JSONB   = '[]';
    l_nom_id INTEGER = (SELECT id
                               FROM libs.nomenklatuur
                                   WHERE kood = '3Ööpäev'
                                        AND rekvid = 132 LIMIT 1);

BEGIN
    FOR v_lep IN
        SELECT * FROM tmp_hoolepingud
        LOOP
            --1 ищем контрагента, если нет то дополняем
            l_isik_id = (SELECT id
                         FROM libs.asutus
                             WHERE ltrim(rtrim(regkood)) = ltrim(rtrim(v_lep.ik))
                                  AND staatus < 3
                             LIMIT 1);

            IF l_isik_id IS NULL
            THEN
                -- подготавливаем параметры для сохранения
                -- в справочнике контр-агентов

                l_jsonb = jsonb_build_object('id', 0, 'regkood', ltrim(rtrim(v_lep.ik)), 'nimetus',
                                             (ltrim(rtrim(v_lep.eesnimi)) || ' ' || ltrim(rtrim(v_lep.perenimi))),
                                             'omvorm', 'ISIK');

                l_jsonb = jsonb_build_object('id', 0, 'data', l_jsonb);

                l_isik_id = libs.sp_salvesta_asutus(l_jsonb :: JSON, l_user_id, 132);

                IF coalesce(l_isik_id, 0) = 0
                THEN
                    RAISE EXCEPTION 'Viga, %', v_lep;
                END IF;

            END IF;


            -- 2 ищем договор, если нет то создаем

            l_leping_id = (SELECT id
                           FROM hooldekodu.hooleping hl WHERE isikid = l_isik_id and status < 3 ORDER BY id DESC LIMIT 1);

            IF l_leping_id IS NULL
            THEN
                -- услуги

                l_grid_json = '[]'::jsonb ||  jsonb_build_object('id', 0, 'nomid', l_nom_id,
                                                 'hind', v_lep.kohamaksumus, 'muud', 'import');

                l_jsonb = jsonb_build_object('id', 0, 'isikid', l_isik_id, 'hooldekoduid', l_hooldekodu_id,
                                             'omavalitsusid', l_kov_id,
                                             'algkpv', '2022-01-01', 'loppkpv', '2033-12-31', 'number',
                                             (docs.sp_get_number(132, 'HOOLEPING', year(date()), NULL)),
                                             'summa', v_lep.kohamaksumus, 'osa', (100 - v_lep.taskuraha),
                                             'bruttosissetulek', v_lep.brutto, 'netosissetulek', v_lep.netto,
                                             'hoolduskulud', v_lep.hoolduskulu, 'makse_viis', 3, 'muud','import',
                                             'gridData', l_grid_json);

                l_leping_id =
                        hooldekodu.sp_salvesta_hooleping((jsonb_build_object('id', 0, 'data', l_jsonb)), l_user_id,
                                                         132);

            END IF;
            RAISE NOTICE 'v_lep %, l_isik_id %, l_leping_id %', v_lep, l_isik_id, l_leping_id;


        END LOOP;

    RETURN l_count;

END;
$$;

SELECT hooldekodu.import_hooldekodu_lepingud();

DROP FUNCTION IF EXISTS hooldekodu.import_hooldekodu_lepingud();
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

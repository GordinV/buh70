/*
drop table if exists tmp_lib;
create table if not EXISTS tmp_lib (kpv text, asutus text, kasutaja text, tekke text, kassa text, oodatav text, tunnus text, allikas text,
artikkel text, tegev text, uritus text, projekt text, objekt text, rea_selg text, markused text);

insert into  tmp_lib(kpv, asutus, kasutaja, tekke, kassa, oodatav, tunnus, allikas,
artikkel, tegev, uritus, projekt, objekt, rea_selg, markused)
SELECT
    t.f[2]::text AS kpv
    ,t.f[3]::text AS asutus
    ,t.f[4]::text AS kasutaja
    ,t.f[5]::text AS tekke
    ,t.f[6]::text AS kassa
    ,t.f[7]::text AS oodatav
    ,t.f[8]::text AS tunnus
    ,t.f[9]::text AS allikas
    ,t.f[10]::text AS artikkel
    ,t.f[11]::text AS tegev
    ,t.f[12]::text AS uritus
    ,t.f[13]::text AS projekt
    ,t.f[14]::text AS objekt
    ,t.f[15]::text AS rea_selg
    ,t.f[16]::text AS markused

FROM (
         SELECT regexp_split_to_array(l, ';') AS f
         FROM regexp_split_to_table(
                      $$;30.09.2025;0810203 Narva Paemurru Spordikool;Svetlana Guljajeva;;379;;0810203;60;3500;08102;;00001;Sotsiaalkindlustusamet riik;Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0810203 Narva Paemurru Spordikool;Svetlana Guljajeva;72;72;;0810203;60;3500;08102;;25076;Eesti Töötukassa avalik;0810203 Eesti keele B2-taseme eksamiks ettevalmistamisele suunatud täienduskoolitus;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0810204 Narva Spordikool Energia;Svetlana Guljajeva;230;230;;0810204;60;3500;08102;;25041;FÜÜSILISED ISIKUD isik;0810204 Narva Spordikooli Energia treeningute labiviimine motospordi huvialal;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0810204 Narva Spordikool Energia;Svetlana Guljajeva;6992;6992;;0810204;60;3500;08102;;25040;Eesti Töötukassa avalik;0810204 Eesti keele B1 taseme eksamiks ettevalmisttav kursus (4 in.);Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0810204 Narva Spordikool Energia;Svetlana Guljajeva;15945;15945;;0810204;60;3500;08102;;25038;Eesti Töötukassa avalik;0810204 Eesti keele A2 taseme eksamiks ettevalmisttav kursus (9 in.);Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0810204 Narva Spordikool Energia;Svetlana Guljajeva;1271;1271;;0810204;60;3500;08102;;25043;Eesti Töötukassa avalik;0810204 Eesti keele A2 taseme eksamiks ettevalmisttav kursus (1 in.);Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0810204 Narva Spordikool Energia;Svetlana Guljajeva;4481;4481;;0810204;60;3500;08102;;25039;Eesti Töötukassa avalik;0810204 Eesti keele A2 taseme eksamiks ettevalmisttav kursus (3 in.);Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0810204 Narva Spordikool Energia;Svetlana Guljajeva;180;180;;0810204;60;3500;08102;;25041;Narva Motoklub MTU;0810204 Narva Spordikooli Energia treeningute labiviimine motospordi huvialal;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0810204 Narva Spordikool Energia;Svetlana Guljajeva;;68;;0810204;60;3500;08102;;00001;Sotsiaalkindlustusamet riik;Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0951004 Narva Muusikakool;Svetlana Guljajeva;;214;;0951004;60;3500;09510;;00001;Sotsiaalkindlustusamet riik;Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;;211;;0951005;60;3500;09510;;00001;Sotsiaalkindlustusamet riik;Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;2907;2907;;0951005;60;3500;09510;;24063;Kliimaministeerium riik;0951005 Taaskasutus;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;2440;2440;;0951005;21;3500;09510;;25071;Regionaal- ja Põllumajandusministeerium riik;0951005 Loodus kõneleb…;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;5316;5316;;0951005;39;3500;09510;;25046;YOUTH4YOUTH-GIOVANI IN MOVIMEN mitteresident;0951005 MyMusicAlley;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;300;300;;0951005;60;3500;09510;;25077;Eesti Kultuurkapital avalik;0951005 Male sokolaaditurniiride korraldamine;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0810799 Narva Noortekeskus;Svetlana Guljajeva;500;500;;0810799;60;3500;08107;;25053;Eesti Noorteühenduste Liit MTU;0810799 Oleviku Otsustajad;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0810799 Narva Noortekeskus;Svetlana Guljajeva;2000;2000;;0810799;60;3500;08107;;25078;Eesti Noorteühenduste Liit MTU;0810799 Minu linn – minu valik;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0820101 Narva Keskraamatukogu;Svetlana Guljajeva;4246;4246;;0820101;60;3500;08201;;25066;OÜ Vestifex OU;0820101 Õpiränded konsortsiumi liikmega;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0820101 Narva Keskraamatukogu;Svetlana Guljajeva;;182;;0820101;60;3500;08201;;00001;Sotsiaalkindlustusamet riik;Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0820201 Narva Kultuurimaja Rugodiv;Svetlana Guljajeva;1749;1749;;0820201;60;3500;08202;;25017;Eesti Rahvakultuuri Keskus riik;0820201 Toetuse eraldamine eelarvevahenditestLaulu- ja tantsupeoliikumises osalevate kollektiivide juhendajate tööjõukulu 2025aasta;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0820201 Narva Kultuurimaja Rugodiv;Svetlana Guljajeva;;646;;0820201;60;3500;08202;;00001;Sotsiaalkindlustusamet riik;Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0911010 Narva Lasteaed Potsataja;Svetlana Guljajeva;340;340;;0911010;60;3500;09110;;21112;Põllumajanduse Registrite Ja Informatsiooni Amet riik;0911010 PRIA puvilja- ja koogiviljatoetus;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0911010 Narva Lasteaed Potsataja;Svetlana Guljajeva;4832;4832;;0911010;39;3500;09110;;25075;Kedainiai kindergarten Vaikyste mitteresident;0911010 Eco-Tech Explorers;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;122;122;;0911027;60;3500;09110;;25068;Sotsiaalministeerium riik;0911027 Lapse tervis;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;;63;;0911027;60;3500;09110;;00001;Sotsiaalkindlustusamet riik;Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0911031 Narva Lasteaed Sipsik;Svetlana Guljajeva;679;679;;0911031;60;3500;09110;;24127;Eesti Töötukassa avalik;0911031 Koolitustoetuse maksmine (B1);Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0911032 Narva Lasteaed Sademeke;Svetlana Guljajeva;255;255;;0911032;60;3500;09110;;22100;Põllumajanduse Registrite Ja Informatsiooni Amet riik;0911032 PRIA puvilja- ja koogiviljatoetus;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0911033 Narva Lasteaed Pingviin;Svetlana Guljajeva;;98;;0911033;60;3500;09110;;00001;Sotsiaalkindlustusamet riik;Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0911034 Narva Lasteaed Kirsike;Svetlana Guljajeva;243;243;;0911034;60;3500;09110;;25065;Sotsiaalministeerium riik;0911034 Lapse tervis;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0911034 Narva Lasteaed Kirsike;Svetlana Guljajeva;522;522;;0911034;21;3500;09110;;25013;Põllumajanduse Registrite Ja Informatsiooni Amet riik;0911034 Ise kasvatame, ise valmistame, ise sööme;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0911037 Narva Lasteaed Cipollino;Svetlana Guljajeva;82;82;;0911037;60;3500;09110;;24119;Eesti Töötukassa avalik;0911037 Eesti keele B2 taseme eksamiks ettevalmisttav kursus (1 in.);Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0911037 Narva Lasteaed Cipollino;Svetlana Guljajeva;408;408;;0911037;60;3500;09110;;22017;Põllumajanduse Registrite Ja Informatsiooni Amet riik;0911037 PRIA puvilja- ja koogiviljatoetus;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0911038 Narva Lasteaed Kaoke;Svetlana Guljajeva;;342;;0911038;60;3500;09110;;00001;Sotsiaalkindlustusamet riik;Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0911038 Narva Lasteaed Kaoke;Svetlana Guljajeva;300;300;;0911038;60;3500;09110;;21113;Põllumajanduse Registrite Ja Informatsiooni Amet riik;0911038 PRIA puvilja- ja koogiviljatoetus;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;6360;6360;;0921201;60;3500;09212;;25012;Eesti Töötukassa avalik;0921201 A2-taseme eesti keele eksamiks ettevalmistav kursus (11 in.);Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;6072;6072;;0921201;60;3500;09601;;22120;Põllumajanduse Registrite Ja Informatsiooni Amet riik;09212 Mahe koolitoidu toetus;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;;366;;0921201;60;3500;09212;;00001;Sotsiaalkindlustusamet riik;Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0921204 Narva Kreenholmi Kool;Svetlana Guljajeva;3775;3775;;0921204;60;3500;09601;;22120;Põllumajanduse Registrite Ja Informatsiooni Amet riik;09212 Mahe koolitoidu toetus;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0921204 Narva Kreenholmi Kool;Svetlana Guljajeva;;654;;0921204;60;3500;09212;;00001;Sotsiaalkindlustusamet riik;Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0921210 Narva Paju Kool;Svetlana Guljajeva;;711;;0921210;60;3500;10403;;00001;Sotsiaalkindlustusamet riik;Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0921214 Narva Keeltelutseum;Svetlana Guljajeva;213;213;;0921214;60;3500;09212;;23060;Kliimaministeerium riik;0921214 Jalgratturi koolitus;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0921214 Narva Keeltelutseum;Svetlana Guljajeva;5214;5214;;0921214;60;3500;09601;;22120;Põllumajanduse Registrite Ja Informatsiooni Amet riik;09212 Mahe koolitoidu toetus;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0860001 Kultuuriosakond;Svetlana Guljajeva;2639;2639;;0810901;60;3500;08109;;25067;Ida-Virumaa Omavalitsuste Liit MTU;Laulu-ja tantsupeo transpordikompensatsioon 2025. Narva linna kollektiivid;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0860001 Kultuuriosakond;Svetlana Guljajeva;2000;2000;;0911065;21;3500;09110;;25069;Regionaal- ja Põllumajandusministeerium riik;0860001 Teadusnädal Narvas;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0860001 Kultuuriosakond;Svetlana Guljajeva;4000;4000;;0921285;21;3500;09212;;25069;Regionaal- ja Põllumajandusministeerium riik;0860001 Teadusnädal Narvas;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;175;175;;0921211;60;3500;09212;;23049;Kliimaministeerium riik;0921211 Jalgratturite koolituse koostooleping;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;664;664;;0921211;60;3500;09212;;25022;Eesti Töötukassa avalik;0921211 Eesti keele C1-taseme eksamiks ettevalmistav kursus;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;2950;2950;;0921211;60;3500;09212;;25018;Eesti Töötukassa avalik;0921211 Eesti keele B2-taseme eksamiks ettevalmistav kursus;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;5755;5755;;0921211;60;3500;09601;;22120;Põllumajanduse Registrite Ja Informatsiooni Amet riik;09212 Mahe koolitoidu toetus;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;2500;2500;;0921211;60;3500;09212;;25064;Eesti Töötukassa avalik;0921211 B1-taseme eesti keele eksamiks ettevalmistav kursus (1 in.);Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;2500;2500;;0921211;60;3500;09212;;24109;Eesti Töötukassa avalik;0921211 B2-taseme eesti keele eksamiks ettevalmistav kursus (2 in.);Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN
;30.09.2025;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;5606;5606;;0921211;39;3500;09212;;25036;Het Palet Hapert Primary School mitteresident;0921211 Art in inclusive education;Narva Linnavalitsuse Kultuuriosakonna PP.11.2025 taotlus nr 9.1-19-NNNNN$$, '\n') AS l) t;
*/
DROP FUNCTION IF EXISTS import_taotlused;

CREATE FUNCTION import_taotlused()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_asutus  RECORD;
    v_taotlus record;
    l_count   INTEGER = 0;
    l_json    jsonb   = '[]';
    l_user_id integer;
    l_rekv_id integer;
    l_doc_id  integer;
BEGIN
    for v_asutus in
        select distinct
            s.asutus
        from
            tmp_lib s
        where
            asutus is not null
        loop
            raise notice 'asutus %, l_json %', v_asutus.asutus, l_json;
            l_rekv_id = (
                            select id from ou.rekv where nimetus ilike ltrim(rtrim(v_asutus.asutus)) || '%' limit 1
                        );
            l_user_id = (
                            select id from ou.userid where rekvid = l_rekv_id and kasutaja = 'svetlana.guljajeva' limit 1
                        );
            if l_rekv_id is null or l_user_id is null then
                raise exception 'Puudub kasutaja voi asutus l_rekv_id %, l_user_id %', l_rekv_id, l_user_id;
            end if;
            for v_taotlus in
                select *
                from
                    tmp_lib t
                where
                    t.asutus = v_asutus.asutus
                loop
                    l_json = l_json ||
                             jsonb_build_object('id', 0, 'kood1', v_taotlus.tegev, 'kood2', v_taotlus.allikas, 'kood4',
                                                v_taotlus.uritus,
                                                'kood5', v_taotlus.artikkel, 'selg', v_taotlus.rea_selg, 'proj',
                                                v_taotlus.projekt,
                                                'tunnus', v_taotlus.tunnus,
                                                'summa', case when empty(v_taotlus.tekke) then '0' else replace (replace(v_taotlus.tekke , ',', '.'),' ','')   end,
                                                'summa_kassa', case when empty(v_taotlus.kassa) then '0' else  replace ( replace(v_taotlus.kassa , ',', '.'),' ','') end);
                    l_count = l_count + 1;
                end loop;
            l_json =  jsonb_build_object('id', 0,'koostajaid',l_user_id, 'tunnus',1, 'aasta', 2025, 'kpv', '2025-09-30', 'gridData', l_json);
            l_json =  jsonb_build_object('id', 0, 'data', l_json);
            l_doc_id = eelarve.sp_salvesta_taotlus(l_json::json, l_user_id, l_rekv_id);
            if coalesce(l_doc_id, 0) = 0 then
                raise exception 'Viga %', l_json;
            end if;

            l_json = '[]'::jsonb;

        end loop;
    raise notice 'kokku l_count %', l_count;

    RETURN l_count;

END;
$$;

SELECT import_taotlused();

--DROP FUNCTION IF EXISTS import_taotlused;
--DROP TABLE IF EXISTS tmp_viitenr;
/*
select * from eelarve.taotlus order by id desc limit 10

select * from eelarve.taotlus1 where parentid = 30006

 */

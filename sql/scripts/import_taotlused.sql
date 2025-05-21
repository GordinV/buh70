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
                      $$;30.04.2025;0810203 Narva Paemurru Spordikool;Svetlana Guljajeva;;54,00;;0810203;60;3500;08102;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0810203 Narva Paemurru Spordikool;Svetlana Guljajeva;;30,00;;0810203;60;3500;08102;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0810204 Narva Spordikool Energia;Svetlana Guljajeva;;488,00;;0810204;60;3500;08102;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0810204 Narva Spordikool Energia;Svetlana Guljajeva;;60,00;;0810204;60;3500;08102;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0810799 Narva Noortekeskus;Svetlana Guljajeva;;400,00;;0810799;60;3500;08107;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0820101 Narva Keskraamatukogu;Svetlana Guljajeva;;90,00;;0820101;60;3500;08201;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0820101 Narva Keskraamatukogu;Svetlana Guljajeva;;24,00;;0820101;60;3500;08201;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0911010 Narva Lasteaed Potsataja;Svetlana Guljajeva;;27,00;;0911010;60;3500;09110;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0911010 Narva Lasteaed Potsataja;Svetlana Guljajeva;;26,00;;0911010;60;3500;09110;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0911018 Narva Vanalinna Lasteaed;Svetlana Guljajeva;;78,00;;0911018;60;3500;09110;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;;15,00;;0911027;60;3500;09110;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0911031 Narva Lasteaed Sipsik;Svetlana Guljajeva;;151,00;;0911031;60;3500;09110;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0911032 Narva Lasteaed Sademeke;Svetlana Guljajeva;;42,00;;0911032;60;3500;09110;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0911032 Narva Lasteaed Sademeke;Svetlana Guljajeva;;15,00;;0911032;60;3500;09110;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0911032 Narva Lasteaed Sademeke;Svetlana Guljajeva;;15,00;;0911032;60;3500;09110;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0911033 Narva Lasteaed Pingviin;Svetlana Guljajeva;;221,00;;0911033;60;3500;09110;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0911033 Narva Lasteaed Pingviin;Svetlana Guljajeva;;54,00;;0911033;60;3500;09110;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0911033 Narva Lasteaed Pingviin;Svetlana Guljajeva;;107,00;;0911033;60;3500;09110;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0911037 Narva Lasteaed Cipollino;Svetlana Guljajeva;;28,00;;0911037;60;3500;09110;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0911038 Narva Lasteaed Kaoke;Svetlana Guljajeva;;365,00;;0911038;60;3500;09110;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0911038 Narva Lasteaed Kaoke;Svetlana Guljajeva;;84,00;;0911038;60;3500;09110;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921206 Narva 6. Kool;Svetlana Guljajeva;;253,00;;0921206;60;3500;09212;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921204 Narva Kreenholmi Kool;Svetlana Guljajeva;;404,00;;0921204;60;3500;09212;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921204 Narva Kreenholmi Kool;Svetlana Guljajeva;;82,00;;0921204;60;3500;09212;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921204 Narva Kreenholmi Kool;Svetlana Guljajeva;;142,00;;0921204;60;3500;09212;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921210 Narva Paju Kool;Svetlana Guljajeva;;29,00;;0921210;60;3500;09212;;00001;;Sotsiaalkindlustusamet. Hallatavate asutuste töötajate puhkusetasu ja palga hüvitise nõuded;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0820201 Narva Kultuurimaja Rugodiv;Svetlana Guljajeva;800,00;800,00;;0820201;60;3500;08202;;25007;;Eesti Kultuurkapital. Kooliteatrite festivali Kuldkalake 2025 läbiviimine;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0860001 Kultuuriosakond;Svetlana Guljajeva;286344,00;286344,00;;0921285;60;3500;09212;;25008;;Haridus- ja Teadusministeerium. 09212 Toetus munitsipaalkoolide pidajatele valmisoleku tagamiseks tasemetööde ja eksamite läbiviimiseks testide andmekogus;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0860001 Kultuuriosakond;Svetlana Guljajeva;114120,00;114120,00;;0921285;60;3500;09212;;25009;;Haridus- ja Teadusministeerium. 09212 Toetus liikumisõpetuse ja loodusainete praktilise õppe läbiviimiseks;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0823601 Narva Linna Sumfooniaorkester;Svetlana Guljajeva;28500,00;28500,00;;0823601;60;352;08236;;25010;;Kultuuriministeerium. Toetus Sumfooniaorkestri kontserttegevuseks 2025;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921210 Narva Paju Kool;Svetlana Guljajeva;48000,00;48000,00;;0921210;21;3500;09212;;25011;;Haridus- ja Teadusministeerium. AI - as an assistant in working with children with special needs;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;2255,00;2255,00;;0921201;60;3500;09212;;25012;;Eesti Töötukassa. A2-taseme eesti keele eksamiks ettevalmistav kursus (11 in.);Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;4269,00;4269,00;;0921201;60;3500;09212;;25012;;Eesti Töötukassa. A2-taseme eesti keele eksamiks ettevalmistav kursus (11 in.);Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0820201 Narva Kultuurimaja Rugodiv;Svetlana Guljajeva;1138,00;1138,00;;0820201;60;3500;08202;;25017;;Eesti Rahvakultuuri Keskus. Toetuse eraldamine eelarvevahenditestLaulu- ja tantsupeoliikumises osalevate kollektiivide juhendajate tööjõukulu 2025aasta;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0820201 Narva Kultuurimaja Rugodiv;Svetlana Guljajeva;612,00;612,00;;0820201;60;3500;08202;;25017;;Eesti Rahvakultuuri Keskus. Toetuse eraldamine eelarvevahenditestLaulu- ja tantsupeoliikumises osalevate kollektiivide juhendajate tööjõukulu 2025aasta;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;48000,00;48000,00;;0921201;21;3500;09212;;25019;;Haridus- ja Teadusministeerium. Meaningful Language Mastery;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;320,00;320,00;;0951005;60;3500;09510;;25020;;Kultuuriministeerium. Pitsifestival;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0911032 Narva Lasteaed Sademeke;Svetlana Guljajeva;10000,00;10000,00;;0911032;60;3500;09110;;25021;;Haridus- ja Teadusministeerium. Keeleoppe metoodikakeskus;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;350,00;350,00;;0951005;60;3500;09510;;25023;;Eesti Kultuurkapital. Raadio teel juhitavate lennumudelite õhuvõitluse korraldamine;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;488,00;488,00;;0921201;60;3500;09212;;25024;;Eesti Olumpiaakadeemia MTÜ. Narva Kesklinna Kooli kooliolümpiamängude korraldamine;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0810204 Narva Spordikool Energia;Svetlana Guljajeva;2267,00;2267,00;;0810204;60;3500;08102;;25025;;NARVA SÕUDEKLUBI ENERGIA MTÜ. Narva Spordikooli Energia sõudmise huviala toetus;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921214 Narva Keeltelutseum;Svetlana Guljajeva;700,00;700,00;;0921214;60;352;09212;;25026;;Kaitseressursside Amet. Riigikaitseõpetuse 2025: välilaagri transport, õppekäik;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921214 Narva Keeltelutseum;Svetlana Guljajeva;2100,00;2100,00;;0921214;60;352;09212;;25026;;Kaitseressursside Amet. Riigikaitseõpetuse 2025: välilaagri transport, õppekäik;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921206 Narva 6. Kool;Svetlana Guljajeva;7200,00;7200,00;;0921206;60;3500;09212;;25027;;Haridus- ja Teadusministeerium. Uussisserändaja toetus põhikoolile ja gümnaasiumile;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;7800,00;7800,00;;0921201;60;3500;09212;;25027;;Haridus- ja Teadusministeerium. Uussisserändaja toetus põhikoolile ja gümnaasiumile;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921204 Narva Kreenholmi Kool;Svetlana Guljajeva;15600,00;15600,00;;0921204;60;3500;09212;;25027;;Haridus- ja Teadusministeerium. Uussisserändaja toetus põhikoolile ja gümnaasiumile;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921210 Narva Paju Kool;Svetlana Guljajeva;3000,00;3000,00;;0921210;60;3500;09212;;25027;;Haridus- ja Teadusministeerium. Uussisserändaja toetus põhikoolile ja gümnaasiumile;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0921214 Narva Keeltelutseum;Svetlana Guljajeva;13200,00;13200,00;;0921214;60;3500;09212;;25027;;Haridus- ja Teadusministeerium. Uussisserändaja toetus põhikoolile ja gümnaasiumile;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0823601 Narva Linna Sumfooniaorkester;Svetlana Guljajeva;1200,00;1200,00;;0823601;60;3500;08236;;25028;;Eesti Kultuurkapital. Kontsert - etenduse Kogu pere ja orkestriga esineva etleja jaoks;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0823601 Narva Linna Sumfooniaorkester;Svetlana Guljajeva;1500,00;1500,00;;0823601;60;3500;08236;;25029;;Eesti Kultuurkapital. Johann Sebastian Bachi ja Georg Friedrich Händeli 340. sünniaastapäeva kontsertide korraldamine;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0951004 Narva Muusikakool;Svetlana Guljajeva;1500,00;1500,00;;0951004;60;3500;09510;;25030;;Eesti Kultuurkapital. Noorte segakoori Vaimustus ja poistekoori osalemine ESTO 2025 üritusel;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;780,00;780,00;;0951005;60;3500;09510;;25032;;Eesti Kultuurkapital. Pitsifestivali korraldamisele;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;3500,00;3500,00;;0951005;60;3500;09510;;25033;;Eesti Kultuurkapital. Narva Laste Loomemaja tantsurühmale rahvarõivakomplektide õmblemine;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0951002 Narva Kunstikool;Svetlana Guljajeva;2000,00;2000,00;;0951002;60;3500;09510;;25034;;Eesti Rahvakultuuri Keskus. Virumaa pärandi hoidmine ja tulevikule suunamine kunsti kaudu;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0820201 Narva Kultuurimaja Rugodiv;Svetlana Guljajeva;446,00;446,00;;0820201;60;3500;08202;;25035;;Eesti Rahvakultuuri Keskus. Kadrina khk otsiktanude valmistamise õpituba Narva rahvatantsuansamblile Jun-Ost;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0951004 Narva Muusikakool;Svetlana Guljajeva;2600,00;2600,00;;0951004;60;3500;09510;;25037;;Eesti Kultuurkapital. Noorte segakoori Vaimustus ja poistekoori osalemine ESTO 2025 üritusel;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN
;30.04.2025;0810204 Narva Spordikool Energia;Svetlana Guljajeva;150,00;150,00;;0810204;60;3500;08102;;25041;;Narva Motoklub MTÜ. Narva Spordikooli Energia treeningute laiviimine motospordi huvialal;Narva Linnavalitsuse Kultuuriosakonna PP.04.2025 taotlus nr 9.1-19-NNNN$$, '\n') AS l) t;
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
                            select id from ou.userid where rekvid = l_rekv_id and kasutaja = 'margarita.tolkova' limit 1
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
                                                'summa', case when empty(v_taotlus.tekke) then '0' else replace(v_taotlus.tekke , ',', '.') end,
                                                'summa_kassa', case when empty(v_taotlus.kassa) then '0' else replace(v_taotlus.kassa , ',', '.') end);
                    l_count = l_count + 1;
                end loop;
            l_json =  jsonb_build_object('id', 0,'koostajaid',l_user_id, 'tunnus',1, 'aasta', 2025, 'kpv', '2025-04-30', 'gridData', l_json);
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

DROP FUNCTION IF EXISTS import_taotlused;
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

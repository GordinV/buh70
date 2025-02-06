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
                      $$;31.12.2024;0810202 Narva Spordikeskus;Svetlana Guljajeva;;86,00;;0810202;60;3500;08102;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0810203 Narva Paemurru Spordikool;Svetlana Guljajeva;;1282,00;;0810203;60;3500;08102;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0810204 Narva Spordikool Energia;Svetlana Guljajeva;;436,00;;0810204;60;3500;08102;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0820101 Narva Keskraamatukogu;Svetlana Guljajeva;;222,00;;0820101;60;3500;08201;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0820201 Narva Kultuurimaja Rugodiv;Svetlana Guljajeva;;1224,00;;0820201;60;3500;08202;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911009 Narva Lasteaed Muinasjutt;Svetlana Guljajeva;;47,00;;0911009;60;3500;09110;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911010 Narva Lasteaed Potsataja;Svetlana Guljajeva;;144,00;;0911010;60;3500;09110;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911018 Narva Vanalinna Lasteaed;Svetlana Guljajeva;;23,00;;0911018;60;3500;09110;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911021 Narva Lasteaed Paikene;Svetlana Guljajeva;;247,00;;0911021;60;3500;09110;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;;353,00;;0911027;60;3500;09110;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911031 Narva Lasteaed Sipsik;Svetlana Guljajeva;;-118,00;;0911031;60;3500;09110;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911032 Narva Lasteaed Sademeke;Svetlana Guljajeva;;342,00;;0911032;60;3500;09110;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911033 Narva Lasteaed Pingviin;Svetlana Guljajeva;;362,00;;0911033;60;3500;09110;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911037 Narva Lasteaed Cipollino;Svetlana Guljajeva;;322,00;;0911037;60;3500;09110;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911038 Narva Lasteaed Kaoke;Svetlana Guljajeva;;657,00;;0911038;60;3500;09110;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;;1303,00;;0921201;60;3500;09212;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921204 Narva Kreenholmi Kool;Svetlana Guljajeva;;1141,00;;0921204;60;3500;09212;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921206 Narva 6. Kool;Svetlana Guljajeva;;-15,00;;0921206;60;3500;09212;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921210 Narva Paju Kool;Svetlana Guljajeva;;1339,00;;0921210;60;3500;09212;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;;285,00;;0921211;60;3500;09212;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921217 Narva Taiskasvanute Kool;Svetlana Guljajeva;;634,00;;0921217;60;3500;09212;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951004 Narva Muusikakool;Svetlana Guljajeva;;488,00;;0951004;60;3500;09510;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;;532,00;;0951005;60;3500;09510;;00001;;Sotsiaalkindlustusamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0810203 Narva Paemurru Spordikool;Svetlana Guljajeva;3000,00;3000,00;;0810203;60;3500;08102;;20006;;Jäähokiklubi Narva PSK MTU;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911018 Narva Vanalinna Lasteaed;Svetlana Guljajeva;66,00;66,00;;0911018;60;3500;09110;;21018;;Pollumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911021 Narva Lasteaed Paikene;Svetlana Guljajeva;593,00;593,00;;0911021;60;3500;09110;;21019;;Pollumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;261,00;261,00;;0911027;60;3500;09110;;21020;;Pollumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911034 Narva Lasteaed Kirsike;Svetlana Guljajeva;632,00;632,00;;0911034;60;3500;09110;;21089;;Pollumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911009 Narva Lasteaed Muinasjutt;Svetlana Guljajeva;93,00;93,00;;0911009;60;3500;09110;;21091;;Pollumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;119,00;119,00;;0911027;60;3500;09110;;21091;;Pollumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911031 Narva Lasteaed Sipsik;Svetlana Guljajeva;243,00;243,00;;0911031;60;3500;09110;;21111;;Pollumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911010 Narva Lasteaed Potsataja;Svetlana Guljajeva;650,00;650,00;;0911010;60;3500;09110;;21112;;Pollumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911038 Narva Lasteaed Kaoke;Svetlana Guljajeva;697,00;697,00;;0911038;60;3500;09110;;21113;;Pollumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;3149,00;3149,00;;0921211;39;3500;09212;;21116;;Fermat Science mitteresident;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;3236,00;3236,00;;0921211;39;3500;09212;;21120;;YUZUPULSE SARL mitteresident;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911037 Narva Lasteaed Cipollino;Svetlana Guljajeva;841,00;841,00;;0911037;60;3500;09110;;22017;;Pollumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911033 Narva Lasteaed Pingviin;Svetlana Guljajeva;247,00;247,00;;0911033;60;3500;09110;;22029;;Pollumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911032 Narva Lasteaed Sademeke;Svetlana Guljajeva;136,00;136,00;;0911032;60;3500;09110;;22042;;Pollumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911036 Narva Lasteaed Vikerkaar;Svetlana Guljajeva;150,00;150,00;;0911036;60;3500;09110;;22042;;Pollumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;213,00;213,00;;0921201;21;3500;09212;;22084;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;12000,00;12000,00;;0921201;21;3500;09212;;22084;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911032 Narva Lasteaed Sademeke;Svetlana Guljajeva;561,00;561,00;;0911032;60;3500;09110;;22100;;Pollumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;6250,00;6250,00;;0921201;39;3500;09212;;22114;;Vantaan Kaupunki mitteresident;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;3714,00;3714,00;;0921201;60;3500;09212;;22120;;Põllumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921204 Narva Kreenholmi Kool;Svetlana Guljajeva;7689,00;7689,00;;0921204;60;3500;09212;;22120;;Põllumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;3815,00;3815,00;;0921211;60;3500;09212;;22120;;Põllumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0860001 Kultuuriosakond;Svetlana Guljajeva;2711,00;2711,00;;0921213;60;3500;09212;;22120;;Põllumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921214 Narva Keeltelutseum;Svetlana Guljajeva;9452,00;9452,00;;0921214;60;3500;09212;;22120;;Põllumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911006 Narva Lasteaed Paasuke;Svetlana Guljajeva;140,00;140,00;;0911006;60;3500;09110;;22134;;Pollumajanduse Registrite Ja Informatsiooni Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0860001 Kultuuriosakond;Svetlana Guljajeva;820,00;820,00;;0860001;60;3500;08600;;23037;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;588,00;588,00;;0921211;60;3500;09212;;23049;;Kliimaministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921214 Narva Keeltelutseum;Svetlana Guljajeva;20178,00;20178,00;;0921214;39;3500;09212;;23050;;VENTSPILS VPI VENTSPILS IZGLITIBAS PARVALDE mitteresident;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;150,00;150,00;;0921201;60;3500;09212;;23057;;Kliimaministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921214 Narva Keeltelutseum;Svetlana Guljajeva;475,00;475,00;;0921214;60;3500;09212;;23060;;Kliimaministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;4000,00;4000,00;;0921211;39;3500;09212;;23066;;LICEO SCIENTIFICO STATALE C. COLOMBO MAR mitteresident;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;30,00;30,00;;0921211;60;3500;09212;;23067;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;530,00;530,00;;0911027;60;3500;09110;;23074;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;19943,00;19943,00;;0921201;21;3500;09212;;23083;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0860001 Kultuuriosakond;Svetlana Guljajeva;739,00;739,00;;0921213;60;3500;09212;;23092;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;130,00;130,00;;0921211;60;3500;09212;;23097;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;296,00;296,00;;0921211;60;3500;09212;;23103;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921214 Narva Keeltelutseum;Svetlana Guljajeva;3798,00;3798,00;;0921214;60;3500;09212;;23105;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921214 Narva Keeltelutseum;Svetlana Guljajeva;531,00;531,00;;0921214;60;3500;09212;;23112;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;674,00;674,00;;0911027;60;3500;09110;;23113;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0810203 Narva Paemurru Spordikool;Svetlana Guljajeva;95,00;95,00;;0810203;60;3500;08102;;23118;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911021 Narva Lasteaed Paikene;Svetlana Guljajeva;401,00;401,00;;0911021;60;3500;09110;;23125;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;410,00;410,00;;0921211;60;3500;09212;;23127;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911009 Narva Lasteaed Muinasjutt;Svetlana Guljajeva;-1796,00;-1796,00;;0911009;60;3500;09110;;24001;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911018 Narva Vanalinna Lasteaed;Svetlana Guljajeva;30,00;30,00;;0911018;60;3500;09110;;24001;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;294,00;294,00;;0911027;60;3500;09110;;24001;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911031 Narva Lasteaed Sipsik;Svetlana Guljajeva;-2879,00;-2879,00;;0911031;60;3500;09110;;24001;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911032 Narva Lasteaed Sademeke;Svetlana Guljajeva;-6834,00;-6834,00;;0911032;60;3500;09110;;24001;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911034 Narva Lasteaed Kirsike;Svetlana Guljajeva;-3865,00;-3865,00;;0911034;60;3500;09110;;24001;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911036 Narva Lasteaed Vikerkaar;Svetlana Guljajeva;-10577,00;-10577,00;;0911036;60;3500;09110;;24001;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911038 Narva Lasteaed Kaoke;Svetlana Guljajeva;270,00;270,00;;0911038;60;3500;09110;;24001;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911009 Narva Lasteaed Muinasjutt;Svetlana Guljajeva;-400,00;-400,00;;0911009;60;352;09110;;24003;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;400,00;400,00;;0911027;60;352;09110;;24003;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911032 Narva Lasteaed Sademeke;Svetlana Guljajeva;400,00;400,00;;0911032;60;352;09110;;24003;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911036 Narva Lasteaed Vikerkaar;Svetlana Guljajeva;-400,00;-400,00;;0911036;60;352;09110;;24003;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0810203 Narva Paemurru Spordikool;Svetlana Guljajeva;-1611,00;-1611,00;;0810203;60;3500;08102;;24004;;Spordikoolituse ja -Teabe Sihtasutus SA;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;1080,00;1080,00;;0921211;60;3500;09212;;24008;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911018 Narva Vanalinna Lasteaed;Svetlana Guljajeva;3699,00;3699,00;;0911018;60;3500;09110;;24014;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911009 Narva Lasteaed Muinasjutt;Svetlana Guljajeva;-686,00;-686,00;;0911009;60;3500;09110;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911010 Narva Lasteaed Potsataja;Svetlana Guljajeva;-3284,00;-3284,00;;0911010;60;3500;09110;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911018 Narva Vanalinna Lasteaed;Svetlana Guljajeva;-5916,00;-5916,00;;0911018;60;3500;09110;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911021 Narva Lasteaed Paikene;Svetlana Guljajeva;-5086,00;-5086,00;;0911021;60;3500;09110;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;-9151,00;-9151,00;;0911027;60;3500;09110;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911031 Narva Lasteaed Sipsik;Svetlana Guljajeva;-6551,00;-6551,00;;0911031;60;3500;09110;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911032 Narva Lasteaed Sademeke;Svetlana Guljajeva;-3941,00;-3941,00;;0911032;60;3500;09110;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911033 Narva Lasteaed Pingviin;Svetlana Guljajeva;-2657,00;-2657,00;;0911033;60;3500;09110;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911034 Narva Lasteaed Kirsike;Svetlana Guljajeva;-3317,00;-3317,00;;0911034;60;3500;09110;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911036 Narva Lasteaed Vikerkaar;Svetlana Guljajeva;-4277,00;-4277,00;;0911036;60;3500;09110;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911037 Narva Lasteaed Cipollino;Svetlana Guljajeva;-2362,00;-2362,00;;0911037;60;3500;09110;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911038 Narva Lasteaed Kaoke;Svetlana Guljajeva;-2684,00;-2684,00;;0911038;60;3500;09110;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;-19729,00;-19729,00;;0921201;60;3500;09212;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921204 Narva Kreenholmi Kool;Svetlana Guljajeva;-20645,00;-20645,00;;0921204;60;3500;09212;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921206 Narva 6. Kool;Svetlana Guljajeva;-1284,00;-1284,00;;0921206;60;3500;09212;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921210 Narva Paju Kool;Svetlana Guljajeva;-2959,00;-2959,00;;0921210;60;3500;09212;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;-6463,00;-6463,00;;0921211;60;3500;09212;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0860001 Kultuuriosakond;Svetlana Guljajeva;-1463,00;-1463,00;;0921213;60;3500;09212;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921214 Narva Keeltelutseum;Svetlana Guljajeva;-16439,00;-16439,00;;0921214;60;3500;09212;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921217 Narva Taiskasvanute Kool;Svetlana Guljajeva;-3665,00;-3665,00;;0921217;60;3500;09212;;24015;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921217 Narva Taiskasvanute Kool;Svetlana Guljajeva;-1098,00;-1098,00;;0921217;21;3500;09212;;24016;;Elpis Association mitteresident;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911009 Narva Lasteaed Muinasjutt;Svetlana Guljajeva;-5467,00;-5467,00;;0911009;60;3500;09110;;24017;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;5467,00;5467,00;;0911027;60;3500;09110;;24017;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911032 Narva Lasteaed Sademeke;Svetlana Guljajeva;2847,00;2847,00;;0911032;60;3500;09110;;24017;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911036 Narva Lasteaed Vikerkaar;Svetlana Guljajeva;-2847,00;-2847,00;;0911036;60;3500;09110;;24017;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;2305,00;2305,00;;0951005;60;3500;09510;;24019;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951004 Narva Muusikakool;Svetlana Guljajeva;5580,00;5580,00;;0951004;60;3500;09510;;24020;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951004 Narva Muusikakool;Svetlana Guljajeva;8654,00;8654,00;;0951004;60;3500;09510;;24023;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911037 Narva Lasteaed Cipollino;Svetlana Guljajeva;729,00;729,00;;0911037;60;3500;09110;;24024;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911037 Narva Lasteaed Cipollino;Svetlana Guljajeva;3839,00;3839,00;;0911037;60;3500;09110;;24028;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911031 Narva Lasteaed Sipsik;Svetlana Guljajeva;1357,00;1357,00;;0911031;60;3500;09110;;24029;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911031 Narva Lasteaed Sipsik;Svetlana Guljajeva;2616,00;2616,00;;0911031;60;3500;09110;;24030;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921214 Narva Keeltelutseum;Svetlana Guljajeva;-571,00;-571,00;;0921214;60;352;09212;;24031;;Kaitseressursside Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0820201 Narva Kultuurimaja Rugodiv;Svetlana Guljajeva;22238,00;22238,00;;0820201;60;3500;08202;;24037;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0820201 Narva Kultuurimaja Rugodiv;Svetlana Guljajeva;28788,00;28788,00;;0820201;60;3500;08202;;24038;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0820201 Narva Kultuurimaja Rugodiv;Svetlana Guljajeva;3387,00;3387,00;;0820201;60;3500;08202;;24039;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0820201 Narva Kultuurimaja Rugodiv;Svetlana Guljajeva;985,00;985,00;;0820201;60;3500;08202;;24040;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0820201 Narva Kultuurimaja Rugodiv;Svetlana Guljajeva;1427,00;1427,00;;0820201;60;3500;08202;;24041;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921211 Narva Pahklimae Kool;Svetlana Guljajeva;965,00;965,00;;0921211;60;3500;09212;;24051;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911032 Narva Lasteaed Sademeke;Svetlana Guljajeva;9000,00;9000,00;;0911032;60;3500;09110;;24061;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0810204 Narva Spordikool Energia;Svetlana Guljajeva;1201,00;1201,00;;0810204;60;3500;08102;;24062;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;2906,00;2906,00;;0951005;60;3500;09510;;24063;;Kliimaministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921210 Narva Paju Kool;Svetlana Guljajeva;2380,00;2380,00;;0921210;60;3500;09212;;24064;;Kliimaministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921214 Narva Keeltelutseum;Svetlana Guljajeva;5440,00;5440,00;;0921214;60;3500;09212;;24065;;Kliimaministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921204 Narva Kreenholmi Kool;Svetlana Guljajeva;2550,00;2550,00;;0921204;60;3500;09212;;24066;;Kliimaministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0810203 Narva Paemurru Spordikool;Svetlana Guljajeva;36778,00;36778,00;;0810203;39;3500;08102;;24067;;International Ice Hockey Federation mitteresident;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0810203 Narva Paemurru Spordikool;Svetlana Guljajeva;4554,00;4554,00;;0810203;39;3500;08102;;24068;;International Ice Hockey Federation mitteresident;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;601,00;601,00;;0951005;39;3500;09510;;24069;;Nuorisokeskus Piispala mitteresident;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;300,00;300,00;;0951005;60;3500;09510;;24070;;Eesti Kultuurkapital avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;528,00;528,00;;0951005;60;3500;09510;;24071;;Kultuuriministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0820101 Narva Keskraamatukogu;Svetlana Guljajeva;47040,00;47040,00;;0820101;39;3500;08201;;24072;;US DISBURSING OFFICER SYM 8769 mitteresident;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0823601 Narva Linna Sumfooniaorkester;Svetlana Guljajeva;1000,00;1000,00;;0823601;60;3500;08236;;24073;;Eesti Kultuurkapital avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0823601 Narva Linna Sumfooniaorkester;Svetlana Guljajeva;1000,00;1000,00;;0823601;60;3500;08236;;24074;;Eesti Kultuurkapital avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0823601 Narva Linna Sumfooniaorkester;Svetlana Guljajeva;1000,00;1000,00;;0823601;60;3500;08236;;24075;;Eesti Kultuurkapital avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0860001 Kultuuriosakond;Svetlana Guljajeva;680,00;680,00;;0860001;60;3500;08600;;24077;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911034 Narva Lasteaed Kirsike;Svetlana Guljajeva;2112,00;2112,00;;0911034;60;3500;09110;;24078;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911034 Narva Lasteaed Kirsike;Svetlana Guljajeva;3242,00;3242,00;;0911034;60;3500;09110;;24079;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0810204 Narva Spordikool Energia;Svetlana Guljajeva;1081,00;1081,00;;0810204;60;3500;08102;;24080;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921204 Narva Kreenholmi Kool;Svetlana Guljajeva;8290,00;8290,00;;0921204;60;3500;09212;;24081;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911038 Narva Lasteaed Kaoke;Svetlana Guljajeva;860,00;860,00;;0911038;60;3500;09110;;24083;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;2162,00;2162,00;;0911027;60;3500;09110;;24084;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;2112,00;2112,00;;0911027;60;3500;09110;;24085;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;90,00;90,00;;0911027;60;3500;09110;;24086;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;7210,00;7210,00;;0911027;60;3500;09110;;24087;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911027 Narva Lasteaed Pongerjas;Svetlana Guljajeva;4756,00;4756,00;;0911027;60;3500;09110;;24088;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921204 Narva Kreenholmi Kool;Svetlana Guljajeva;6120,00;6120,00;;0921204;60;3500;09212;;24089;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911010 Narva Lasteaed Potsataja;Svetlana Guljajeva;3271,00;3271,00;;0911010;60;3500;09110;;24090;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911010 Narva Lasteaed Potsataja;Svetlana Guljajeva;1477,00;1477,00;;0911010;60;3500;09110;;24091;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911010 Narva Lasteaed Potsataja;Svetlana Guljajeva;3844,00;3844,00;;0911010;60;3500;09110;;24092;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;13702,00;13702,00;;0921201;21;3500;09212;;24094;;Haridus- ja Teadusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0823601 Narva Linna Sumfooniaorkester;Svetlana Guljajeva;1500,00;1500,00;;0823601;60;3500;08236;;24095;;Eesti Kultuurkapital avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0810799 Narva Noortekeskus;Svetlana Guljajeva;600,00;600,00;;0810799;60;3500;08107;;24096;;Pohjamaade Ministrite Noukogu esindus Eestis mitteresident;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951004 Narva Muusikakool;Svetlana Guljajeva;319,00;319,00;;0951004;60;3500;09510;;24097;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951004 Narva Muusikakool;Svetlana Guljajeva;363,00;363,00;;0951004;60;3500;09510;;24098;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951004 Narva Muusikakool;Svetlana Guljajeva;2178,00;2178,00;;0951004;60;3500;09510;;24099;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951004 Narva Muusikakool;Svetlana Guljajeva;860,00;860,00;;0951004;60;3500;09510;;24100;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951004 Narva Muusikakool;Svetlana Guljajeva;726,00;726,00;;0951004;60;3500;09510;;24101;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951004 Narva Muusikakool;Svetlana Guljajeva;319,00;319,00;;0951004;60;3500;09510;;24102;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921210 Narva Paju Kool;Svetlana Guljajeva;5634,00;5634,00;;0921210;60;3500;09212;;24103;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0810799 Narva Noortekeskus;Svetlana Guljajeva;7420,00;7420,00;;0810799;60;3500;08107;;24105;;Haridus- ja Noorteamet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921214 Narva Keeltelutseum;Svetlana Guljajeva;477,00;477,00;;0921214;60;352;09212;;24106;;Kaitseressursside Amet riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921201 Narva Kesklinna Kool;Svetlana Guljajeva;1042,00;1042,00;;0921201;60;3500;09212;;24107;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911038 Narva Lasteaed Kaoke;Svetlana Guljajeva;2098,00;2098,00;;0911038;60;3500;09110;;24108;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921210 Narva Paju Kool;Svetlana Guljajeva;947,00;947,00;;0921210;60;3500;09212;;24110;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921210 Narva Paju Kool;Svetlana Guljajeva;525,00;525,00;;0921210;60;3500;09212;;24112;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921210 Narva Paju Kool;Svetlana Guljajeva;308,00;308,00;;0921210;60;3500;09212;;24113;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0860001 Kultuuriosakond;Svetlana Guljajeva;3000,00;3000,00;;0911065;21;3500;09110;;24114;;Regionaal- ja Põllumajandusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0860001 Kultuuriosakond;Svetlana Guljajeva;7000,00;7000,00;;0921285;21;3500;09212;;24114;;Regionaal- ja Põllumajandusministeerium riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;500,00;500,00;;0951005;60;3500;09510;;24115;;Fortaco Estonia OU;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0820201 Narva Kultuurimaja Rugodiv;Svetlana Guljajeva;821,00;821,00;;0820201;60;3500;08202;;24116;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0823601 Narva Linna Sumfooniaorkester;Svetlana Guljajeva;534,00;534,00;;0823601;60;3500;08236;;24117;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911037 Narva Lasteaed Cipollino;Svetlana Guljajeva;640,00;640,00;;0911037;60;3500;09110;;24118;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911037 Narva Lasteaed Cipollino;Svetlana Guljajeva;847,00;847,00;;0911037;60;3500;09110;;24119;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911021 Narva Lasteaed Paikene;Svetlana Guljajeva;811,00;811,00;;0911021;60;3500;09110;;24120;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911034 Narva Lasteaed Kirsike;Svetlana Guljajeva;786,00;786,00;;0911034;60;3500;09110;;24121;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911034 Narva Lasteaed Kirsike;Svetlana Guljajeva;811,00;811,00;;0911034;60;3500;09110;;24122;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0820201 Narva Kultuurimaja Rugodiv;Svetlana Guljajeva;221,00;221,00;;0820201;60;3500;08202;;24126;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0911031 Narva Lasteaed Sipsik;Svetlana Guljajeva;679,00;679,00;;0911031;60;3500;09110;;24127;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921206 Narva 6. Kool;Svetlana Guljajeva;947,00;947,00;;0921206;60;3500;09212;;24128;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921206 Narva 6. Kool;Svetlana Guljajeva;2548,00;2548,00;;0921206;60;3500;09212;;24129;;Eesti Töötukassa avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951004 Narva Muusikakool;Svetlana Guljajeva;2747,00;2747,00;;0951004;60;3500;09510;;24130;;Eesti Laulu- ja Tantsupeo Sihtasutus SA;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0921210 Narva Paju Kool;Svetlana Guljajeva;1022,00;1022,00;;0921210;60;3500;09212;;24132;;Eesti Rahvakultuuri Keskus riik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;300,00;300,00;;0951005;60;3500;09510;;24133;;Eesti Kultuurkapital avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;300,00;300,00;;0951005;60;3500;09510;;24134;;Eesti Kultuurkapital avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0951005 Narva Laste Loomemaja;Svetlana Guljajeva;250,00;250,00;;0951005;60;3500;09510;;24135;;Eesti Kultuurkapital avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN
;31.12.2024;0820101 Narva Keskraamatukogu;Svetlana Guljajeva;800,00;800,00;;0820101;60;3500;08201;;24136;;Eesti Kultuurkapital avalik;Narva Linnavalitsuse Kultuuriosakonna PP.01.2025 taotlus nr 9.1-19-NNN$$, '\n') AS l) t;
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
            l_json =  jsonb_build_object('id', 0,'koostajaid',l_user_id, 'tunnus',1, 'aasta', 2024, 'kpv', '2024-12-31', 'gridData', l_json);
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

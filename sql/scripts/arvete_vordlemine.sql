/*DROP TABLE IF EXISTS tmp_arved;
CREATE TABLE IF NOT EXISTS tmp_arved (
    asutus          TEXT,
    vn              TEXT,
    ik              TEXT,
    nimi            TEXT,
    maksja_ik       TEXT,
    maksja          TEXT,
    alg_salod       TEXT,
    arvestatud      TEXT,
    soodustus       TEXT,
    umberarvestatud TEXT,
    arv_kokku       TEXT,
    laekumised      TEXT,
    tagastatud      TEXT,
    lopp_saldo      TEXT
);

INSERT INTO tmp_arved(asutus, vn, ik, nimi, maksja_ik, maksja, alg_salod, arvestatud, soodustus, umberarvestatud,
                      arv_kokku, laekumised, tagastatud, lopp_saldo)
SELECT t.f[1]::TEXT  AS asutus,
       t.f[2]::TEXT  AS vn,
       t.f[3]::TEXT  AS ik,
       t.f[4]::TEXT  AS nimi,
       t.f[5]::TEXT  AS maksja_ik,
       t.f[6]::TEXT  AS maksja,
       t.f[7]::TEXT  AS alg_salod,
       t.f[8]::TEXT  AS arvestatud,
       t.f[9]::TEXT  AS soodustus,
       t.f[10]::TEXT AS umberarvestatud,
       t.f[11]::TEXT AS arv_kokku,
       t.f[12]::TEXT AS laekumised,
       t.f[13]::TEXT AS tagastatud,
       t.f[15]::TEXT AS lopp_saldo

FROM (
         SELECT regexp_split_to_array(l, ';') AS f
         FROM regexp_split_to_table(
                      $$Narva Muusikakool;8100119;60102133712;Ovdeitšuk Esfir;60102133712;Ovdeitšuk Esfir;0;;;;0;;;;0
Narva Muusikakool;8100216;50911303714;Streff Erik ;48002212217;Streff Julia;75;;;;0;;;;75
Narva Muusikakool;8100313;50710303714;Stulov Ivan;47309103733;Teplova Tatiana;36;43;;;43;36;;;43
Narva Muusikakool;8100410;60210163763;Kudukis Anastassija;46502093726;Kudukis Albina;-25;;;;0;;;;-25
Narva Muusikakool;8100517;61310040173;Petrištševa Maria;48001023716;Petrištševa Jelena;30;36;;;36;30;;;36
Narva Muusikakool;8100614;51104213715;Frolov Viktor;47403292723;Karina Anna;15;36;;;36;15;;;36
Narva Muusikakool;8100711;51303290138;Bartšukov Roman;49011173730;Bartšukova Viktoria;-3,73;;;;0;;;;-3,73
Narva Muusikakool;8100818;51511290149;Belozor Tikhon;38603293716;Belozor Nikolai;60;36;;;36;60;;;36
Narva Muusikakool;8100915;51705230140;Tõsjatov Egor;49006282211;Tõsjatova Kristina;9;11;;;11;;;;20
Narva Muusikakool;8101011;61608240095;Vasilieva Anastasia;48401152213;Vasileva Erika;0;29;;;29;;;;29
Narva Muusikakool;8101118;60412143732;Lugina Alina;48002163711;Slepova Daria;0;;;;0;;;;0
Narva Muusikakool;8101215;50606303748;Žitkovski Jegor;36905013735;Žitkovski Vladimir;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8101312;60108223724;Oganesjan Nelli;35912033741;Oganesjan Ruben;0;;;;0;;;;0
Narva Muusikakool;8101419;60108223724;Oganesjan Nelli;35912033741;Oganesjan Ruben;0;;;;0;;;;0
Narva Muusikakool;8101516;60405053733;Savosto Jaanika;47106263727;Asson Olga;0;;;;0;;;;0
Narva Muusikakool;8101613;60710010289;Jegorova Margarita;45806093731;Egorova Alla;-7,9;;;;0;;;;-7,9
Narva Muusikakool;8101710;51608240072;Verguljanets Tom;38411092216;Verguljanets  Daniil;20;;;;0;;;;20
Narva Muusikakool;8101817;60105173722;Sevastjanova Maria;46501212223;Pšelintseva Ella;-0,02;;;;0;;;;-0,02
Narva Muusikakool;8101914;61603090027;Dambina Amelia;48612073712;Dambina Olga;24;29;;;29;;;;53
Narva Muusikakool;8102010;51611010226;Pulkin Matvei;48708113716;Pulkina Dina;0;;;;0;;;;0
Narva Muusikakool;8102117;50912163716;Kuznetsov Leonid;47707243725;Smirnova Natalja;0;;;;0;;;;0
Narva Muusikakool;8102214;50106123788;Kinko Saveli;46705072213;Kinko Jelena;-16;;;;0;;;;-16
Narva Muusikakool;8102311;60307113751;Gavrilova Jelizaveta;46612042211;Gavrilova Tatjana;0;;;;0;;;;0
Narva Muusikakool;8102418;61603280185;Goldman Diana;48305083710;Goldman Tatjana;-11,43;;;;0;;;;-11,43
Narva Muusikakool;8102515;61508120170;Capecchi Sofia;48101272257;Lopatina  Ekaterina;0;;;;0;;;;0
Narva Muusikakool;8102612;51502190068;Kuzmin Maksim;49006083719;Kuzmina Aleksandra;0;;;;0;;;;0
Narva Muusikakool;8102719;61407070016;Kulikovskaja Alisa;48308263712;Kulikovskaja Kristina;30;36;;;36;30;;;36
Narva Muusikakool;8102816;61202070269;Sova Linda;48508092229;Sova Natalja;0;;;;0;;;;0
Narva Muusikakool;8102913;50504223710;Tatatšenko Makar;37405202256;Tatartšenko Anton;0;;;;0;;;;0
Narva Muusikakool;8103019;60512143724;Võssotskaja Anneli;47911063718;Võssotskaja Svetlana;0;;;;0;;;;0
Narva Muusikakool;8103116;61403120099;Damelgart Nika;49212313733;Damelgart Jekaterina;0;;;;0;;;;0
Narva Muusikakool;8103213;60010313712;Smirnova Ljudmila;60010313712;Smirnova Ljudmila;0;;;;0;;;;0
Narva Muusikakool;8103310;60801307108;Sokolova Maia;37506082264;Sokolov Aleksei;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8103417;61402210136;Nagornaya Nicoletta;48005313769;Nagornaya Natalia;0;;;;0;;;;0
Narva Muusikakool;8103514;61005243717;Šilina Alisa;37808283716;Šilin Andrei;60;43;;;43;60;;;43
Narva Muusikakool;8103611;51301280078;Trofimov Nikita;47408292214;Kirikmäe Inga;0;;;;0;;;;0
Narva Muusikakool;8103718;51011023729;Rudnitski Albert;47706172738;Rudnitskaja Natalja;36;43;;;43;;;;79
Narva Muusikakool;8103815;60406143737;Volkova Aissel;48703182253;Volkova Bazhena;0;;;;0;;;;0
Narva Muusikakool;8103912;51802020088;Živolunov Mihhail;37805133715;Živolunov Aleksandr;0;;;;0;;;;0
Narva Muusikakool;8104018;61610020153;Terehhova Polina;47902272752;Terehhova Olesja;0;36;-36;;0;;;;0
Narva Muusikakool;8104115;60502033740;Baikova Anna;48204053714;Baikova Olga;-30;;;;0;;;;-30
Narva Muusikakool;8104212;51306150196;Kruhlov Diemid;47811040111;Kruhlova Olena;0;;;;0;;;;0
Narva Muusikakool;8104319;60911053710; Sheverda Polina;48101242236;Sheverda Nadežda;6;11;;;11;6;;;11
Narva Muusikakool;8104416;51703260140;Tykhostup Yaroslav;48811290149;Tykhostup Alona;0;;;;0;;;;0
Narva Muusikakool;8104513;50407053716;Mateyko Ivan;48012183729;Mateyko Ekaterina;0;36;-36;;0;;;;0
Narva Muusikakool;8104610;51212043732;Silašin Zahar;48709263729;Silašina Tatjana;30;36;;;36;;;;66
Narva Muusikakool;8104717;51708110015;Nikonov Maksim;48908013716;Ponomarjova Jekaterina;7;;;;0;;;;7
Narva Muusikakool;8104814;50704233712;Kossorotov Vladislav;48112113727;Kossorotova Nadezda;72;43;;;43;;;;115
Narva Muusikakool;8104911;61010110189;Briliantova Anna;48203030105;Briliantova Olena;0;36;;-36;0;;;;0
Narva Muusikakool;8105017;50710143730;Aletko Ariel;48208263712;Aletko Jelizaveta;60;36;;;36;30;;;66
Narva Muusikakool;8105114;51207160117;Aletko Daniel;48208263712;Aletko Jelizaveta;72;43;;;43;36;;;79
Narva Muusikakool;8105211;60704257105;Allik Valeria;48206060326;Saveljeva Tatjana;0;;;;0;;;;0
Narva Muusikakool;8105318;51601030084;Asson Nikita;48309012259;Kodošigova Natalja;30;36;;;36;30;;;36
Narva Muusikakool;8105415;51511270179;Babi Veniamin;49407153721;Babi Jelena;40;36;-36;;0;;;;40
Narva Muusikakool;8105512;61506290073;Baranova Alina;49003113716;Babi Inna;30;36;;;36;30;;;36
Narva Muusikakool;8105619;61312230107;Belanova Marika;38107213742;Belanov Andrei;25;;;;0;;;;25
Narva Muusikakool;8105716;50707063714;Cheremisinov Artem;47510293712;Cheremisinova Alla;0;36;-36;;0;;;;0
Narva Muusikakool;8105813;61609150024;Derkach Daniella;49405213711;Derkach  Olesia;60;36;;-36;0;60;;;0
Narva Muusikakool;8105910;60612123713;Druzhishcheva Dominika;48112223718;Druzhishcheva Elena;30;36;;;36;;;;66
Narva Muusikakool;8106016;51212043710;Getalov Matvei;47902153718;Solovjova Oksana;30;36;;;36;30;;;36
Narva Muusikakool;8106113;60611153738;Gordejeva Lilija;38403303752;Gordejev Sergei;63;43;;;43;;;;106
Narva Muusikakool;8106210;51204283712;Hütt Mark;48507272233;Hütt Tatjana;0;43;;;43;;;;43
Narva Muusikakool;8106317;51408230081;Ivanov Aleksandr;38512102255;Look Evgeny;30;36;;;36;;;;66
Narva Muusikakool;8106414;51403140155;Ivanov Ruslan;48411263717;Ivanova Elvira;15;36;;;36;15;;;36
Narva Muusikakool;8106511;50702273719;Ivanov Juri;48411263717;Ivanova Elvira;30;43;;;43;;;;73
Narva Muusikakool;8106618;51301020166;Ivanov Artur;48411263717;Ivanova Elvira;-97,96;36;;;36;;;;-61,96
Narva Muusikakool;8106715;61406110183;Jakimuš Olesja;47912222275;Nikolaeva Ekaterina;0;;;;0;;;;0
Narva Muusikakool;8106812;51212063724;Kalinin Andrei;48808190076;Kalinina Svetlana;30;36;;;36;30;;;36
Narva Muusikakool;8106919;60403133759;Komoshilova Anastasia;48401203726;Komoshilova Tatiana;72;43;;;43;36;;;79
Narva Muusikakool;8107015;61511130200;Ksenofontova Kira;48212150102;Ksenofontova Kateryna;0;36;;-36;0;;;;0
Narva Muusikakool;8107112;51508040231;Kudryavtsev Artjom;48705163714;Litvinova Marina;30;36;;;36;;;;66
Narva Muusikakool;8107219;51601090027;Kutuzov Gleb;49006203719;Kutuzova Irina;30;36;;;36;30;;;36
Narva Muusikakool;8107316;51805070061;Kutuzov Gordey;49006203719;Kutuzova Irina;9;11;;;11;9;;;11
Narva Muusikakool;8107413;51505270151;Laukonen Adrian;47807243717;Tabakova Irina;30;36;;;36;;;;66
Narva Muusikakool;8107510;60803013718;Luik  Karina;47508123726;Luik Maria;36;43;;;43;80;;;-1
Narva Muusikakool;8107617;60911190067;Lukach Kateryna;47501010132;Lukach Larisa;0;36;;-36;0;;;;0
Narva Muusikakool;8107714;50706073727;Manuškin  Aleksandr;48403123722;Manuškina Julia;0;;;;0;;;;0
Narva Muusikakool;8107811;60708283713;Nazarova Evelina;48209273710;Nazarova Ekaterina;0;43;-43;;0;;;;0
Narva Muusikakool;8107918;61605190119;Nechaeva Ksenia;48412310256;Bogovskaja Marina;30;36;;;36;30;;;36
Narva Muusikakool;8108014;61704070054;Nikandrova Veronika;49401193720;Nikandrova Kristina;9;11;;;11;9;;;11
Narva Muusikakool;8108111;51201093714;Nikitin Manuil-Mihhei;48301252216;Nukitina Maria;-5;36;;;36;;;;31
Narva Muusikakool;8108218;48301252216;Nikitin Martin-Mikael;48301252216;Nukitina Maria;35;36;;;36;;;;71
Narva Muusikakool;8108315;61611220181;Pedari Milena;38811013725;Pedari Aleksandr;60;36;;;36;60;;;36
Narva Muusikakool;8108412;61601190078;Persidskaja Stefania;48401192241;Vladoiu-Predi Svetlana;0;36;-36;;0;;;;0
Narva Muusikakool;8108519;61612010123;Petrova Elina;48305272261;Petrova Elena;15,1;36;;;36;15,1;;;36
Narva Muusikakool;8108616;61510020052;Peussa Aleksandra;48105283738;Peussa Ljudmila;30;36;;;36;30;;;36
Narva Muusikakool;8108713;61103233769;Peussa Vasilisa;48105283738;Peussa Ljudmila;30;36;;;36;30;;;36
Narva Muusikakool;8108810;60810083723;Pirk Olivia;48010163716;Pirk Olga;24;29;;;29;24;;;29
Narva Muusikakool;8108917;60705253721;Pogodina Dominika;48401192241;Vladoiu-Predi Svetlana;-25;36;-36;;0;;;;-25
Narva Muusikakool;8109013;61606220114;Poltoruhho Sofja;48302113736;Poltoruhho Anna;0;36;;;36;35;;;1
Narva Muusikakool;8109110;51103270140;Pomaznev Andrei;47503250018;Pomazneva Galina;30;36;;;36;30;;;36
Narva Muusikakool;8109217;61708090077;Prohhorenko Jelizaveta;47712273725;Prohhorenko Olga;-156,23;36;-36;;0;;;;-156,23
Narva Muusikakool;8109314;50906113719;Prosvetov Miron;46403053711;Prosvetova Jelena;23;43;;;43;43;;;23
Narva Muusikakool;8109411;60511100842;Puusta Elina;48305243716;Tšotšis Lia;30;36;;;36;;;;66
Narva Muusikakool;8109518;60502023755;Raud Angelina;46904213748;Raud Svetlana;0;;;;0;;;;0
Narva Muusikakool;8109615;61012213735;Romanova Olga;47610223721;Romanova Galina;30;36;;;36;30;;;36
Narva Muusikakool;8109712;60803173733;Rõženkova  Maria;48409013717;Rõženkova Marina;72;43;;;43;72;;;43
Narva Muusikakool;8109819;51506070013;Šatskih Saveli;37803302253;Šatskih Ivan;90;36;;;36;90;;;36
Narva Muusikakool;8109916;51704030101;Savvatjev Fjodor;48401172249;Savvatjeva Olga;30;36;;;36;30;;;36
Narva Muusikakool;8110015;61604210185;Semenova Miloslava;49304233728;Ots Marika;35;36;;;36;30;;;41
Narva Muusikakool;8110112;60401283735;Setško Anastassija;47210282210;Setško Jelena;0;;;;0;;;;0
Narva Muusikakool;8110219;61605220218;Shcherbaniuk Oleksandra;48807050102;Shcherbaniuk Yuliia;0;36;;-36;0;;;;0
Narva Muusikakool;8110316;50904083727;Shkuro Arseni;48302223720;Zahharova Natalja;30;36;;;36;30;;;36
Narva Muusikakool;8110413;51504280284;Smirnov Fjodor;47503232257;Smirnova Yulia;115;36;;;36;;;;151
Narva Muusikakool;8110510;51305120202;Snisarenko Mikhailo;37202090128;Snisarenko Oleksandr;0;36;;-36;0;;;;0
Narva Muusikakool;8110617;60611293730;Sokolova Sofia;47901123714;Talik Katerina;60;36;;;36;120;;;-24
Narva Muusikakool;8110714;60605233737;ŠTŠEPOTJEVA KRISTINA;47005272217;Štšepotjeva Irina;0;;;;0;;;;0
Narva Muusikakool;8110811;61102163746;Tamvilius Varvara;46409083718;Tamvilius Olga;30;36;;;36;30;;;36
Narva Muusikakool;8110918;60804133721;Titova Alina;47306172214;Titova Natalia;18;43;;;43;30;;;31
Narva Muusikakool;8111014;51509170089;Tšurbakov Martin;48603073713;Tšurbakova Veronika;27,5;36;-36;;0;27,5;;;0
Narva Muusikakool;8111111;61804210158;Tšurbakova Olivia;48603073713;Tšurbakova Veronika;30;36;-36;;0;30;;;0
Narva Muusikakool;8111218;51409180050;Vassiljev Aleksandr;48805033712;Vassiljeva Jekaterina;30;36;;;36;30;;;36
Narva Muusikakool;8111315;51602190256;Vedernikov Mark;48310280133;Medvedeva Mariia;30;36;;;36;30;;;36
Narva Muusikakool;8111412;51608240072;Verguljanets Tom;38411092216;Verguljanets  Daniil;30;36;;;36;30;;;36
Narva Muusikakool;8111519;51602250191;Verguljanets Semjon;49209293715;Verguljanets Marina;0;36;-36;;0;;;;0
Narva Muusikakool;8111616;61706270065;Veselko Evnika;48107103728;Veselko Irina;60;36;-36;;0;;;;60
Narva Muusikakool;8111713;51401220213;Zhelnov Arseni;48303073737;Zhelnova Mayya;-50;36;;;36;;;;-14
Narva Muusikakool;8111810;61701040160;Tsernõsova Mari anna;48310273738;Tsernõsova Valentina;9;36;;;36;9;;;36
Narva Muusikakool;8111917;61604060120;Andreeva Uljana;49404273737;Tširkova Julia;24;29;;;29;24;;;29
Narva Muusikakool;8112013;50807270026;Azimov Denis;48304280127;Azimova Natalia;9;;;;0;;;;9
Narva Muusikakool;8112110;61801170179;Babi Amelia;49407153721;Babi Jelena;9;11;;;11;12;;;8
Narva Muusikakool;8112217;51806160098;Belin Andrei;46701023711;Belina Tatjana;-9;11;;;11;9;;;-7
Narva Muusikakool;8112314;51501050051;Bõkov  Kirill;47911282235;Bõkova Larissa;24;29;;;29;24;;;29
Narva Muusikakool;8112411;50708133726;Drozdov Viktor;48704283718;Shevtsova Olga;9;11;;;11;;;;20
Narva Muusikakool;8112518;61806150081;Dymova Alice;48403153710;Dymova Dina;9;11;;;11;9;;;11
Narva Muusikakool;8112615;51805170143;Emajõe  Miron;49204233736;Emajõe  Martha;0;11;;;11;;;;11
Narva Muusikakool;8112712;61403060088;Ermakova Darja;49207053720;Ermakova Elena;0;29;-29;;0;;;;0
Narva Muusikakool;8112819;60411163730;Eroshkina Marija;47406223725;Solovjova Jelena;28,5;34,5;;;34,5;28,5;;;34,5
Narva Muusikakool;8112916;51704050300;Fedorov Nikita;48105287018;Fedorova Julia;9;11;;;11;;;;20
Narva Muusikakool;8113012;61409070081;Frolova Kira;48511043727;Frolova Ksenija;24;29;;;29;;;;53
Narva Muusikakool;8113119;60407303715;Golubeva Polina;37401233744;Golubev  Roman;0;;;;0;;;;0
Narva Muusikakool;8113216;51803210141;Efimov Nikita;48604170080;Efimova Juliia;0;11;;;11;;;;11
Narva Muusikakool;8113313;60804273733;Ivanova Anastasia;48307193722;Ivanova Svetlana;9;11;;;11;9;;;11
Narva Muusikakool;8113410;50112063727;Jegorov Igor;47605022711;Sergejeva Svetlana;36;43;;;43;;;;79
Narva Muusikakool;8113517;61706210089;Kärmann Sofia;48507103713;Kärmann Olga;9;11;;;11;9;;;11
Narva Muusikakool;8113614;60811043722;Krylova Ksenia;46011223717;Krylova Elena;27;11;;;11;;;;38
Narva Muusikakool;8113711;61508180255;Kudriashova Viktoriia;47206113722;Kudriashova Olga;0;29;-29;;0;;;;0
Narva Muusikakool;8113818;51009073712;Kuhharenkov Matvei;48609053718;Kukharenkova Erika;36;43;;;43;;;;79
Narva Muusikakool;8113915;60403023735;Milovidova Alissa;47908213759;Milovidova Jelena;36;43;;;43;36;;;43
Narva Muusikakool;8114011;51611150086;Mišin Albert;36109123716;Mišin Vladimir;24;29;;;29;24;;;29
Narva Muusikakool;8114118;61806140020;Nazarova Mia;48804223712;Nazarova Ekaterina;0;11;;;11;;;;11
Narva Muusikakool;8114215;60507227039;Nazarova Maria;45507182217;Nazarova Liidia;24;29;;;29;24;;;29
Narva Muusikakool;8114312;61412100150;Panteleeva Veronika;48507250073;Panteleeva Marina;0;29;-29;;0;;;;0
Narva Muusikakool;8114419;61412100160;Panteleeva Eva;48507250073;Panteleeva Marina;0;29;-29;;0;;;;0
Narva Muusikakool;8114516;51807290173;Penner Emil;49405123712;Penner Anžela;0;11;;;11;;;;11
Narva Muusikakool;8114613;50805063729;Porošin Arseni;47610053719;Matsijanskaite Virginia;11;11;;;11;9;;;13
Narva Muusikakool;8114710;60708263710;Püdja Elisabet;47406063713;Püdja Irina;9;11;;;11;9;;;11
Narva Muusikakool;8114817;61408200181;Pulkina Kira;48708113716;Pulkina Dina;48;29;;;29;;;;77
Narva Muusikakool;8114914;61806140128;Raudsepp Teya;48705022215;Raudsepp Maria;9;11;;;11;9;;;11
Narva Muusikakool;8115010;60410033713;Reinsalu Sille;47704043731;Reinsalu Jelena;28,5;34,5;;;34,5;;;;63
Narva Muusikakool;8115117;50904083727;Shkuro Arseni;48302223720;Zahharova Natalja;34;11;;;11;34;;;11
Narva Muusikakool;8115214;60507032724;Surgutšova Anastassia;47206232723;Kornilova Ilona;72;43;;;43;;;;115
Narva Muusikakool;8115311;61601130101;Šurmina Marina;47402053741;Tupikina Julia;24;29;;;29;24;;;29
Narva Muusikakool;8115418;51804290136;Tanin Nikita;48704012214;Tanina Maria;9;11;;;11;9;;;11
Narva Muusikakool;8115515;61301140198;Timofejeva Arina;48610022213;Timofejeva  Maria;11;11;;;11;11;;;11
Narva Muusikakool;8115612;61803240141;Toropina Varvara;48409233721;Toropina Anastasia;9;11;;;11;9;;;11
Narva Muusikakool;8115719;60412083721;Treinbuk Kristel Viiri;37204283722;Treinbuk Virgo;48;29;;;29;48;;;29
Narva Muusikakool;8115816;49703033723;Adamova Viktoria;36701172253;Adamov Jevgeni;0;;;;0;;;;0
Narva Muusikakool;8115913;50707203728;Ude Albert;47805193725;Ude Jelena;9;11;;;11;9;;;11
Narva Muusikakool;8116019;61803140200;Varvaševitš Nelli;49501053721;Varvaševitš  Karina;0;11;;;11;;;;11
Narva Muusikakool;8116116;51310030085;Vasilev Igor;48401152213;Vasileva Erika;0;29;;;29;;;;29
Narva Muusikakool;8116213;61808020075;Vasileva Polianna;48401152213;Vasileva Erika;0;11;;;11;;;;11
Narva Muusikakool;8116310;61304160052;Verguljanets Polina;49209293715;Verguljanets Marina;0;29;-29;;0;;;;0
Narva Muusikakool;8116417;61806070285;Vivcharchuk Olha;48712150183;Vivcharchuk Olena;0;11;;-11;0;;;;0
Narva Muusikakool;8116514;61503140192;Vivcharchuk Oksana;48712150183;Vivcharchuk Olena;0;29;;-29;0;;;;0
Narva Muusikakool;8116611;51206160145;Vivcharchuk Volodymyr;48712150183;Vivcharchuk Olena;0;29;;-29;0;;;;0
Narva Muusikakool;8116718;51004300078;Vivcharchuk Vitalii;48712150183;Vivcharchuk Olena;0;29;;-29;0;;;;0
Narva Muusikakool;8116815;61807210162;Võhma Anastassia;48508280142;Vohma Olena;0;11;;;11;;;;11
Narva Muusikakool;8116912;50803163725;Volkov  Artjom;48509033712;Kippari Natalja;9;11;;;11;;;;20
Narva Muusikakool;8117018;60607313739;Zholudova Anna;46206103724;Zholudova Vera;9;11;;;11;9;;;11
Narva Muusikakool;8117115;51406280149;Zolotukhin Devid;47403293720;Zolotukhina Evgenia;0;29;;;29;;;;29
Narva Muusikakool;8117212;51704230059;Rezvukhin Radmir;48212062217;Rezvukhina Elina;0;29;-29;;0;;;;0
Narva Muusikakool;8117319;51410240269;Staroverov Alexander;48508023744;Tsvetkova Jelena;24;29;;;29;24;;;29
Narva Muusikakool;8117416;61412070017;Krutikova Mikaela;48402012217;Krutikova Jekaterina;24;29;;;29;24;;;29
Narva Muusikakool;8117513;60612073731;Gubaydullina Azalia;48512253718;Gubaydullina Irina;9;11;;;11;;;;20
Narva Muusikakool;8117610;61005043754;Gordejeva Anita;38205092215;Gordejev Roman;0;36;;;36;;;;36
Narva Muusikakool;8117717;49912193732;Sergejeva Ksenia;46001133714;Sergejeva Jelena;30;36;;;36;30;;;36
Narva Muusikakool;8117814;51812200166;Siika Oskar;49011113710;Siika Ksenia;9;11;;;11;9;;;11
Narva Muusikakool;8117911;50612213722;Leonov Aleksandr;47306033711;Leonova Tatjana;9;11;;;11;;;;20
Narva Muusikakool;8118017;50612213725;Leonov Aleksandr;47306033711;Leonova Tatjana;30;36;;;36;;;;66
Narva Muusikakool;8118114;50906097174;Kruptsev Kasyan;47401173723;Chistodelova Anna;60;36;;;36;60;;;36
Narva Muusikakool;8118211;50211213749;Afanasjev David;46809133712;Afanasjeva Žanna;0;36;;;36;;;;36
Narva Muusikakool;8118318;50504173728;Grigorjev Vladislav;37911193711;Grigorjev Maksim;36;43;;;43;36;;;43
Narva Muusikakool;8118415;51008283715;Mets Juri;48902083724;Mihhailova Kristina;30;36;;;36;30;;;36
Narva Muusikakool;8118512;61307090016;Krivonoi Kira;48302132267;Krivonoy Polina;60;36;;;36;30;;;66
Narva Muusikakool;8118619;50501113726;Nikitin Mark-Maksim;48301252216;Nukitina Maria;30;36;;;36;;;;66
Narva Muusikakool;8118716;50410307029;Polezhaev Yugan;50410307029;Polezhaev Yugan;18;11;;;11;;;;29
Narva Muusikakool;8118813;61801070013;Lohmatova Amelia;37708073738;Lohmatov Dmitri;9;11;;;11;9;;;11
Narva Muusikakool;8118910;60712213748;Gorškova Lija;48706293713;Gorškova Anastassia;9;11;;;11;;;;20
Narva Muusikakool;8119016;60310270842;Keller Anastasiia;60310270842;Keller Anastasiia;24;29;;;29;;;;53
Narva Muusikakool;8119113;51202043728;Drangovsky Timofey;49008102214;Drangovskaya Tatiana;0;11;;;11;;;;11
Narva Muusikakool;8119210;60804097015;Eremina Tereza;47201030039;Eremina Irina;0;36;;;36;;;;36
Narva Muusikakool;8119317;50910063755;Jakovlev Makar;47111093715;Jakovleva Anžela;0;29;;;29;;;;29
Narva Muusikakool;8119414;60809223745;Toropina Alina;48409233721;Toropina Anastasia;0;11;;;11;;;;11
Narva Muusikakool;8123918;60207283726;Kilina  Serafima;38212153713;Kilin Eduard;-14;;;;0;;;;-14
Narva Muusikakool;8124218;60102033728;Urbans Elženija;37110133728;Urbans Igor;0;;;;0;;;;0
Narva Muusikakool;8125217;50210223733;Prohhorenko  Kirill;37909193725;Prohhorenko Roman;-15;;;;0;;;;-15
Narva Muusikakool;8130613;60411063724;Smirnova Marija;47503232257;Smirnova Yulia;0;;;;0;;;;0
Narva Muusikakool;8132912;60206033718;Stepanova Glafira;46508012224;Stepanova Veera;0;;;;0;;;;0
Narva Muusikakool;8133319;50503143746;Giblov Georgy;47106143733;Shemyakina Svetlana;-62,9;;;;0;;;;-62,9
Narva Muusikakool;8133814;60611183728;Ljauman  Zoja;46011272210;Ljauman Ljudmila;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8134114;60510083725;Oganesjan Lidia;35912033741;Oganesjan Ruben;0;;;;0;;;;0
Narva Muusikakool;8136918;60611213729;Ohrimenko Julia;48409123719;Kuznetsova Natalja;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8137111;60602133716;Stupnikova Viktoria;45904193728;Stupnikova Natalia;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8137218;60411063724;Smirnova Marija;47503232257;Smirnova Yulia;0;;;;0;;;;0
Narva Muusikakool;8137917;50510113747;Misnik Rodion;47409099513;Misnik Julia;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8139012;50709057019;Kuznetšikov Ivan;46201032216;Rego Galina;0;;;;0;;;;0
Narva Muusikakool;8139119;60601037029;Kuznetšikova Valeria;46201032216;Rego Galina;-16,23;;;;0;;;;-16,23
Narva Muusikakool;8140412;50604083732;Bobryshev Aleksandr;47812093719;Suup Regina;0;;;;0;;;;0
Narva Muusikakool;8140917;60608213727;Smirnova Polina;47503232257;Smirnova Yulia;-62,5;36;-36;;0;;;;-62,5
Narva Muusikakool;8142313;60611153738;Gordejeva Lilija;38403303752;Gordejev Sergei;-178,33;;;;0;;;;-178,33
Narva Muusikakool;8142517;60501142762;Ivleva Polina;47209147016;Ivleva Oksana;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8142915;60701213717;Prohhorenko Jana;47712273725;Prohhorenko Olga;0;;;;0;;;;0
Narva Muusikakool;8143914;60802093714;Levanidova Evilina;47107282226;Levanidova  Julia;30;36;-36;;0;30;;;0
Narva Muusikakool;8144311;60806113739;Vasilchenko Valentina;46506192243;Vasilchenko Anna;-25,56;;;;0;;;;-25,56
Narva Muusikakool;8144418;61611230188;Ahu Emilia;47410103717;Kalaud Natalja;24;29;;;29;24;;;29
Narva Muusikakool;8144515;51204293719;Aktšurin Damir;48202102210;Aktšurina  Nelli;24;29;;;29;24;;;29
Narva Muusikakool;8144612;51405110090;Babi Leonel;49407153721;Babi Jelena;-0,83;36;-36;;0;;;;-0,83
Narva Muusikakool;8144719;51602140047;Baranov Ilja;47602262213;Ušanova Tatjana;-7;;;;0;;;;-7
Narva Muusikakool;8144816;60912257051;Bystrova Milana;47806093746;Bystrova Tatiana;0;;;;0;;;;0
Narva Muusikakool;8144913;60610233727;Tšupina Anna;47506293716;Nestrueva Yulia;0;;;;0;;;;0
Narva Muusikakool;8145019;50601283740;Dmitrijev Timofei;46912093731;Dmitrijeva Natalja;8;11;;;11;8;;;11
Narva Muusikakool;8145116;61403060120;Egorova Polina;47702133711;Fedossenko Diana;30;36;;;36;30;;;36
Narva Muusikakool;8145213;50804097058;Eremin Makar;47201030039;Eremina Irina;-4,3;;;;0;;;;-4,3
Narva Muusikakool;8145310;61309200106;Fomina Ella;48606303729;Fomina Juliana;-65,83;36;;;36;;;;-29,83
Narva Muusikakool;8145417;60407303715;Golubeva Polina;48107073730; Golubeba Jelena;0;;;;0;;;;0
Narva Muusikakool;8145514;60606293718;Hussainova Sofia;47504032218;Hussainova Zoja;0;;;;0;;;;0
Narva Muusikakool;8145611;60606293718;Hussainova Sofia;47504032218;Hussainova Zoja;0;;;;0;;;;0
Narva Muusikakool;8145718;61404060071;Ilina Taissija;49406213716;Ilina Janika;32;43;;;43;24;;;51
Narva Muusikakool;8145815;51403120032;Ivanen Pjotr;48410183720;Ivanen Maria;-12,67;;;;0;;;;-12,67
Narva Muusikakool;8145912;61605300254;Kapranova  Viveja;48010053714;Kapranova Natalja;0;;;;0;;;;0
Narva Muusikakool;8146018;61304150110;Kazakova Darja;47810270074;Kazakova Ekaterina;28,5;34,5;;;34,5;58,5;;;4,5
Narva Muusikakool;8146115;61503180089;Kippar Anastasia;37901202229;Kippar Igor;0;;;;0;;;;0
Narva Muusikakool;8146212;61307160306;Konstantinova Maria;48403120056;Konstantinova Liubov;24;29;;;29;;;;53
Narva Muusikakool;8146319;51603210190;Kozlovski Deniss;48909153722;Kozlovskaja Natalja;-11,43;;;;0;;;;-11,43
Narva Muusikakool;8146416;50406084210;Krjukov Aleksandr;46301202221;Krjukova Alla;-32,67;;;;0;;;;-32,67
Narva Muusikakool;8146513;60509173710;Kuznetsova Juliana;48103273710;Kuznetsova Marina;0;;;;0;;;;0
Narva Muusikakool;8146610;50511023742;Lebedev Pavel;47703253723;Meng Galina;0;;;;0;;;;0
Narva Muusikakool;8146717;50511023742;Lebedev Pavel;47703253723;Meng Galina;0;;;;0;;;;0
Narva Muusikakool;8146814;60701053744;Lõssenko Jelizaveta;47210153735;Lõssenko Jekaterina;0;;;;0;;;;0
Narva Muusikakool;8146911;60403023735;Milovidova Alissa;47908213759;Milovidova Jelena;0;;;;0;;;;0
Narva Muusikakool;8147017;61310250024;Nadeeva Alisa;48607123737;Nadeeva Natalia;0;;;;0;;;;0
Narva Muusikakool;8147114;61602150218;Nikolajeva Liya;49101293716;Nikolajeva Julia;30;36;;;36;30;;;36
Narva Muusikakool;8147211;61609220129;Nosenkova Eva;38501193719;Nosenkov Sergei;48;29;;;29;24;;;53
Narva Muusikakool;8147318;61109123731;Oleksyuk  Anželika;48412013719;Oleksyuk Diana;-129,83;;;;0;;;;-129,83
Narva Muusikakool;8147415;61607040090;Ossipenko Polina;48509243720;Ossipenko Julia;0;;;;0;;;;0
Narva Muusikakool;8147512;61606190063;Parts Ellen;47707023732;Parts Teele;48;29;;;29;;;;77
Narva Muusikakool;8147619;61612010123;Petrova Elina;38307123727;Petrov  Vitali;0;;;;0;;;;0
Narva Muusikakool;8147716;51508280014;Prohhorenko Mihhail;47712273725;Prohhorenko Olga;-177,81;36;-36;;0;;;;-177,81
Narva Muusikakool;8147813;61309300123;Provotorova Valeria;47901223713;Provotorova Galina;48;29;;;29;;;;77
Narva Muusikakool;8147910;60602163748;Saar Tatjana;47011293713;Saar Zanna;0;;;;0;;;;0
Narva Muusikakool;8148016;51506260280;Shkuro Elisei;48302223720;Zahharova Natalja;24;29;;;29;24;;;29
Narva Muusikakool;8148113;60504020894;Sjomkina Alisa;37907063710;Sjomkin Anton;60;36;-36;;0;30;;;30
Narva Muusikakool;8148210;51212183711;Skljarov Platon;47704063723;Skljarova Natalja;-0,83;36;;;36;;;;35,17
Narva Muusikakool;8148317;51606200219;Sõtšov Nikita;47905313717;Surkova Oksana;0;;;;0;;;;0
Narva Muusikakool;8148414;50507203711;Stepanov  Nikita;35011223714;Jegorov Nikolai;18;11;;;11;18;;;11
Narva Muusikakool;8148511;60903293734;Subbotkina Nika;47401292256;Subbotkina Jelena;-32,67;;;;0;;;;-32,67
Narva Muusikakool;8148618;60507032724;Surgutšova Anastassia;47206232723;Kornilova Ilona;-11,43;;;;0;;;;-11,43
Narva Muusikakool;8148715;61312130123;Titova Zemfira;49111033710;Titova Kristina;0;;;;0;;;;0
Narva Muusikakool;8148812;60412083721;Treinbuk Kristel Viiri;37204283722;Treinbuk Virgo;0;;;;0;;;;0
Narva Muusikakool;8148919;51509170089;Tšurbakov Martin;48603073713;Tšurbakova Veronika;0;;;;0;;;;0
Narva Muusikakool;8149015;51206203710;Tšurbakov Timur;48603073713;Tšurbakova Veronika;11,67;36;-36;;0;11,67;;;0
Narva Muusikakool;8149112;61407080067;Tšurbakova Adel;49412023717;Tšurbakova Niina;-85,83;36;;;36;;;;-49,83
Narva Muusikakool;8149219;50301253721;Vangonen Paul;37304222218;Vangonen Anatoli;0;;;;0;;;;0
Narva Muusikakool;8149316;60811103711;Vasilieva Angelina;48912042279;Vasilieva Viktoriya;0;;;;0;;;;0
Narva Muusikakool;8149413;51506140086;Verguljanets Emil;38411092216;Verguljanets  Daniil;15;36;;;36;15;;;36
Narva Muusikakool;8149510;51207262226;Voronin Semjon;48502193736;Voronina Irina;-100;;;;0;;;;-100
Narva Muusikakool;8149617;51508070034;Yakovlev Aleksei;48904082214;Jakovleva Viktoria;0;;;;0;;;;0
Narva Muusikakool;8149714;51005097096;Adamka David;35812033716;Adamka Rudolf;0;36;;;36;30;;;6
Narva Muusikakool;8149811;61109122756;Aksjonova Angelina;46312132212;Smirnova Svetlana;102,5;36;;;36;;;;138,5
Narva Muusikakool;8149918;51311090109;Antipenkov Nikolai;38902013718;Antipenkov Deniss;60;36;;;36;;;;96
Narva Muusikakool;8150017;51306280168;Begunov Eldar;38309213714;Begunov  Grigori;30;36;;;36;;;;66
Narva Muusikakool;8150114;61101193736;Bojarova Eva;48701222218;Bojarova Darja;30;36;;;36;30;;;36
Narva Muusikakool;8150211;61309160120;Boltovskaja Darja;48010083746;Ojala Jelena;30;36;;;36;30;;;36
Narva Muusikakool;8150318;61109040084;Družinina Polina;47405033710;Trofimova Irena;30;36;;;36;30;;;36
Narva Muusikakool;8150415;61301230088;Dubik Aleksandra;48211233712;Dubik Veronika;30;36;;;36;30;;;36
Narva Muusikakool;8150512;50810283712;Dzhubatov Temirlan;37608193711;Dzhubatov Artur;30;36;;;36;;;;66
Narva Muusikakool;8150619;61309200161;Fjodorova Ivanna;48202133718;Fjodorova Julia;30;36;;;36;30;;;36
Narva Muusikakool;8150716;50103143723;Furminski Maksim;37411303711;Furminski Aleksei;-49;;;;0;;;;-49
Narva Muusikakool;8150813;61401100238;Glücksam Adriana Milena;38404167013;Vetšerenko Jelena;0;;;;0;;;;0
Narva Muusikakool;8150910;51509170176;Gordejev Martin;38403303752;Gordejev Sergei;-35;36;;;36;;;;1
Narva Muusikakool;8151016;50802213735;Grigorjev Dmitri;47311273719;Grigorjeva Natalja;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8151113;61510020106;Homjakova Mikaela;48205143718;Homjakova Viktoria;0;36;;;36;;;;36
Narva Muusikakool;8151210;51006162231;Kalinin Vitali;48808190076;Kalinina Svetlana;30;36;;;36;30;;;36
Narva Muusikakool;8151317;61510050345;Kanevskaja Alisia;48702113719;Kanevskaja Maria;0;;;;0;;;;0
Narva Muusikakool;8151414;50609053725;Karru Dmitri;47712203720;Karru Olga;0;;;;0;;;;0
Narva Muusikakool;8151618;60609180359;Kirillovskaja Kristina;47508143729;Starodubtseva Maria;0;;;;0;;;;0
Narva Muusikakool;8151715;60906123727;Krasnoumova Viktotia;46912292223;Logvinova Natalja;-0,83;;;;0;;;;-0,83
Narva Muusikakool;8151812;51208072825;Kuznetsov Timofei;48312263719;Vovdenko Natalja;115;36;;;36;115;;;36
Narva Muusikakool;8151919;61505120144;Latina Nora;48811086014;Garankina Natalija;0;36;;;36;30;;;6
Narva Muusikakool;8152015;61505120155;Latina Viktoria;48811086014;Garankina Natalija;30;36;;;36;30;;;36
Narva Muusikakool;8152112;51208143720;Lazarev Daniil;48903103712;Lazareva Kristina;30;36;;;36;;;;66
Narva Muusikakool;8152219;51305030138;Botšenkov Daniil;48901223711;Botšenkova Jekaterina;30;36;;;36;30;;;36
Narva Muusikakool;8152316;61301030130;Malõševa Uljana;48112062247;Malõševa Ramilja;30;36;;;36;30;;;36
Narva Muusikakool;8152413;61304140158;Nikitina Valeria;48707092230;Andrejeva Tatjana;50;36;;;36;40;;;46
Narva Muusikakool;8152510;61209223729;Nikitina Sofia;49005293711;Nikitina Veronika;-8,33;;;;0;;;;-8,33
Narva Muusikakool;8152617;61203093725;Novikova Ilona;45208093712;Novikova Alevtina;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8152714;60510083725;Oganesjan Lidia;35912033741;Oganesjan Ruben;60;36;;;36;;;;96
Narva Muusikakool;8152811;61412100150;Panteleeva Veronika;48507250073;Panteleeva Marina;0;;;;0;;;;0
Narva Muusikakool;8152918;61412100160;Panteleeva Eva;48507250073;Panteleeva Marina;0;;;;0;;;;0
Narva Muusikakool;8153014;51203153724;Parts Georg;36208213724;Parts Ilmar;30;36;;;36;30;;;36
Narva Muusikakool;8153111;50808093743;Pertman Rauno;47602192239;Petrman Tatjana;0;;;;0;;;;0
Narva Muusikakool;8153218;61504030031;Pirk Emilia;48010163716;Pirk Olga;30;36;;;36;30;;;36
Narva Muusikakool;8153315;51301290128;Poluektov Ustin;47609253728;Poluektova Elena;30;36;;;36;30;;;36
Narva Muusikakool;8153412;60301267010;Raina Diana;36003157017;Raina Aleksandr;0;;;;0;;;;0
Narva Muusikakool;8153519;50609273718;Raudsepp Edgar;47702113728;Raudsepp Tatjana;0;;;;0;;;;0
Narva Muusikakool;8153616;61402100080;Rjabova Taisia;47904183727;Hahhajeva Larissa;30;36;;;36;;;;66
Narva Muusikakool;8153713;51404010111;Rodionov Ruslan;37511223711;Rodionov Aleksandr;0;36;-36;;0;;;;0
Narva Muusikakool;8153810;61012213735;Romanova Olga;47610223721;Romanova Galina;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8153917;60406293723;Savitševa Viktoriya;47704082239;Savitseva Lidia;0;;;;0;;;;0
Narva Muusikakool;8154013;39905283719;Sekajev Andrei;39905283719;Sekajev Andrei;0;;;;0;;;;0
Narva Muusikakool;8154110;51504280284;Smirnov Fjodor;47503232257;Smirnova Yulia;27,5;36;;;36;;;;63,5
Narva Muusikakool;8154217;61009163712;Smirnova Anastasija;49104043728;Petrova Elena;60;36;;;36;60;;;36
Narva Muusikakool;8154314;61509150250;Sokolova Polina;48702043712;Sokolova Olga;-0,01;;;;0;;;;-0,01
Narva Muusikakool;8154411;51505240054;Veselko Jan;48107103728;Veselko Irina;57;41,5;-36;;5,5;;;;62,5
Narva Muusikakool;8154518;51205263714;Võssotski Nikita;47911063718;Võssotskaja Svetlana;-63,33;36;;;36;;;;-27,33
Narva Muusikakool;8154615;61404140063;Zaugarova Vasilissa;47903293724;Linnik Anna;-0,83;;;;0;;;;-0,83
Narva Muusikakool;8154712;61202113714;Zhelnova Sofia;48303073737;Zhelnova Mayya;-150,83;36;;;36;;;;-114,83
Narva Muusikakool;8154819;50010083742;Korvatšev Sergei;46304273717;Korvatsova Natalja;0;;;;0;;;;0
Narva Muusikakool;8168012;50712113730;Terentjev Pavel;47705243715;Terentjeva Natalja;0;;;;0;;;;0
Narva Muusikakool;8168313;60608213727;Smirnova Polina;47503232257;Smirnova Yulia;25;36;;;36;;;;61
Narva Muusikakool;8169118;60910013710;Zahharova Aleksandra;48605153726;Karpinen Maria;0;36;;;36;30;;;6
Narva Muusikakool;8169419;50811243755;Alekseev Evgeni;37306193714;Alekseev Roman;0;36;;;36;;;;36
Narva Muusikakool;8169914;60708283713;Nazarova Evelina;60708283713;Nazarova Ekaterina;0;;;;0;;;;0
Narva Muusikakool;8170411;60510013720;Ivanova Maria;47312093715;Ivanova Jelena;-12,78;;;;0;;;;-12,78
Narva Muusikakool;8170615;50611263728;Zaika Markus;47412173732;Zaika Natalja;0;;;;0;;;;0
Narva Muusikakool;8171119;60704257105;Allik Valeria;48206060326;Saveljeva Tatjana;0;;;;0;;;;0
Narva Muusikakool;8171216;50801233711;Smirnov Georgi;47503232257;Smirnova Yulia;-42,5;46,5;;;46,5;;;;4
Narva Muusikakool;8171410;60410243728;Marova Jekaterina;46812302229;Marova Jelena;65;36;;;36;;;;101
Narva Muusikakool;8171517;50510143724;Baškirov Daniil;47507062212;Baškirova Anna;0;;;;0;;;;0
Narva Muusikakool;8172419;60905093710;Šelepanova Jevgenia;47209063711;Šelepanova Jelena;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8172613;60811213724;Jakonen Arina;48606113736;Jakonen Olesja;0;36;;;36;60;;;-24
Narva Muusikakool;8174310;51002263715;Levanidov Jelissei;47107282226;Levanidova  Julia;30;36;-36;;0;30;;;0
Narva Muusikakool;8174718;50908043711;Karvelis Jan;48612203741;Karvelis Maria;30;36;;;36;30;;;36
Narva Muusikakool;8175115;50805123740;Gordejev Mihhail;48411210049;Gordejeva Emilia;-63,33;36;;;36;;;;-27,33
Narva Muusikakool;8176114;60005083731;Saukova Yulia;47112153716;Saukova  Tatiana;-28;;;;0;;;;-28
Narva Muusikakool;8176415;51009073712;Kuhharenkov Matvei;48609053718;Kukharenkova Erika;0;;;;0;;;;0
Narva Muusikakool;8176716;60908283730;Prohhorenko Sofia;47712273725;Prohhorenko Olga;-243,33;36;-36;;0;;;;-243,33
Narva Muusikakool;8177016;50809093737;Oleksyuk Kevin;48412013719;Oleksyuk Diana;0;;;;0;;;;0
Narva Muusikakool;8177414;61006123724;Esina Miroslava;36511243712;Esin Sergey;0;36;-36;;0;;;;0
Narva Muusikakool;8177511;60812063719;Khuber Beatriche;47301063729;Bogdanova Alexandra;30;36;;;36;30;;;36
Narva Muusikakool;8177618;60909103728;Kachan Evgeniya;48802133714;Kachan Anastasia;0;36;-36;;0;;;;0
Narva Muusikakool;8177919;60903293734;Subbotkina Nika;47401292256;Subbotkina Jelena;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8178112;60211193734;Asmer Erika;47304092223;Sokolovskaja Tatjana;-35;;;;0;;;;-35
Narva Muusikakool;8178219;50708173710;Morozov Aleksei;48909013710;Kichatova Olga;30;36;-36;;0;;;;30
Narva Muusikakool;8178413;60403133759;Komoshilova Anastasia;48401203726;Komoshilova Tatiana;0;;;;0;;;;0
Narva Muusikakool;8179111;51009143726;Koltunov Jelisei;48604257018;Žõkova Julia;30;36;;;36;90;;;-24
Narva Muusikakool;8179218;51006073724;Tsvek Ilja;47603192734;Tsvek Karin;30;36;;;36;30;;;36
Narva Muusikakool;8179917;61002020021;Voronina Valeria;38707103725;Voronin Alexander;0;;;;0;;;;0
Narva Muusikakool;8180511;50801233711;Smirnov Georgi;47503232257;Smirnova Yulia;25;36;-36;;0;;;;25
Narva Muusikakool;8180812;50512093719;Kakourov Mihhail;47901063714;Ivanova Oxana;-32;;;;0;;;;-32
Narva Muusikakool;8181112;60910053738;Borissova Aljona;48507263724;Klink Valeria;-62,9;;;;0;;;;-62,9
Narva Muusikakool;8181219;61107053725;Dedimova Sofia;48502093720;Dedimova Nadezda;30;36;;;36;;;;66
Narva Muusikakool;8181413;50901083726;Fomin Aleksandr;46710033728;Fomina Marina;30;36;;;36;30;;;36
Narva Muusikakool;8181510;61104280077;Mihhailova Aleksandra Olivia;48004283719;Mihhailova Marina;30;36;;;36;30;;;36
Narva Muusikakool;8181617;50905273729;Simson Erik;48310263711;Simson Julia;30;36;;;36;30;;;36
Narva Muusikakool;8181918;51208230129;Usatykh Arseni;47509043717;Oleinik Olga;15;36;;;36;;;;51
Narva Muusikakool;8182014;60609303711;Titova Alisa;47510203737;Fomtšenkova Jelena;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8182218;50905043733;Zaika Stefan;47412173732;Zaika Natalja;-141,26;36;;;36;;;;-105,26
Narva Muusikakool;8182315;50410190906;Gordejev Vjatšeslav;47511022235;Butkevitš Anželika;30;36;;;36;30;;;36
Narva Muusikakool;8182616;61201033728;Belova Karina;48609172233;Belova Olesja;-35;36;;;36;50;;;-49
Narva Muusikakool;8182810;61109293719;Dortman Anna;47407193712;Bogdanova Aleksandra;30;36;;;36;30;;;36
Narva Muusikakool;8182917;51203043733;Haesser Damian;48105262262;Haesser Marianna;30;36;;;36;30;;;36
Narva Muusikakool;8183013;61104263738;Kamõsheva Sofia;47512263723;Kamõsheva  Jelena;60;36;;;36;;;;96
Narva Muusikakool;8183615;60602133738;Golovkina Veronika;48104223724;Golovkina Varvara;24;29;;;29;24;;;29
Narva Muusikakool;8183712;60812063719;Khuber Beatriche;47301063729;Bogdanova Alexandra;0;29;;;29;;;;29
Narva Muusikakool;8184410;51108263726;Gordijevski Andrei;48304213712;Gordijevski Veera;90;36;;;36;90;;;36
Narva Muusikakool;8184614;61104223712;Verguljanets Anna;49209293715;Verguljanets Marina;-122,28;36;-36;;0;;;;-122,28
Narva Muusikakool;8184711;50909023713;Fomin Artjom;38804143719;Fomin Roman;-109,78;36;;;36;;;;-73,78
Narva Muusikakool;8184818;60709263726;Golubtsova Faina;47503163739;Golubtsova Zhanna;0;36;;;36;;;;36
Narva Muusikakool;8184915;50301043713;Lütter Allan;47807263720;Jurson Nadežda;72;43;;;43;36;;;79
Narva Muusikakool;8185011;61103263735;Ivanova Ksenia;49105083717;Ivanova Julia;0;;;;0;;;;0
Narva Muusikakool;8185118;61201123716;Arutjunova Elina;48609063714;Sokolova Anastassija;30;36;;;36;30;;;36
Narva Muusikakool;8185215;51112063710;Prohhorenko  Pavel;47712273725;Prohhorenko Olga;0;;;;0;;;;0
Narva Muusikakool;8185312;61307020077;Esina Evelina;36511243712;Esin Sergey;0;36;-36;;0;;;;0
Narva Muusikakool;8185419;61108173717;Gordejeva Milena;38403303752;Gordejev Sergei;-75,83;36;;;36;;;;-39,83
Narva Muusikakool;8185516;51005293718;Oleksyuk Michael;48412013719;Oleksyuk Diana;-150,01;;;;0;;;;-150,01
Narva Muusikakool;8186010;60812273716;Pantelejeva Snežana;38008113727;Pantelejev Maksim;30;36;;;36;30;;;36
Narva Muusikakool;8186214;61111103714;Miljutinova Natalja;49101113719;Miljutinova Tatjana;-75;36;;;36;;;;-39
Narva Muusikakool;8186311;61309060171;Panina Ainura;49406300234;Shorikova Kristina;30;36;;;36;30;;;36
Narva Muusikakool;8186719;61305090202;Pedari Emili;49304103723;Pedari Svetlana;30;36;;;36;30;;;36
Narva Muusikakool;8187213;61006123724;Esina Miroslava;36511243712;Esin Sergey;0;29;-29;;0;;;;0
Narva Muusikakool;8187417;61101293713;Petrištševa Anastassia;48001023716;Petrištševa Jelena;0;36;;;36;;;;36
Narva Muusikakool;8191113;51202043728;Drangovsky Timofey;49008102214;Drangovskaya Tatiana;0;;;;0;;;;0
Narva Kunstikool;8200116;61102143743;Jana Dadatskaja;47507133717;Soob  Elena;24;29;;;29;24;;;29
Narva Kunstikool;8200213;61109150195;Rudenko Anastasiia;48908250111;Rudenko Tetiana;-8,87;;;;0;;;;-8,87
Narva Kunstikool;8200310;60503243764;Gopich Eva;48112063712;Gopich Natalja;-50,32;;;;0;;;;-50,32
Narva Kunstikool;8200417;61105313738;Smirnova Elina;47510283727;Solovjova Natalja;24;29;;;29;24;;;29
Narva Kunstikool;8200514;50509253723;Olenevitš Daniil;47207062214;Olenevitš Valentina;-10,32;;;;0;;;;-10,32
Narva Kunstikool;8200611;60202193735;Agafonova Vladislava;47202233744;Agafonova Vlada;0;;;;0;;;;0
Narva Kunstikool;8200718;61001043729;Bojartšuk Marianna;38905223719;Bojartšuk Andrei;24;29;;;29;24;;;29
Narva Kunstikool;8200815;60407162225;Sadõkova Kelli;47208133735;Metsis Renata;-50,32;;;;0;;;;-50,32
Narva Kunstikool;8200912;60609143736;Bendi Jekaterina;47606172212;Bendi Veronika;0;;;;0;;;;0
Narva Kunstikool;8201018;60504143719;Luzanova Varvara;47105093715;Luzanova Olga;-50,32;;;;0;;;;-50,32
Narva Kunstikool;8201115;60403023735;Milovidova Alissa;38105212278;Milovidov Pavel;-5;;;;0;;;;-5
Narva Kunstikool;8201212;50501183714;Markov Sergei;47012263730;Markova Veronika;0;;;;0;;;;0
Narva Kunstikool;8201319;60303113742;Konoreva Kristina;47005223724;Konoreva Inna;0;;;;0;;;;0
Narva Kunstikool;8201416;60403143733;Pavlova Diana;37903012278;Pavlov Anatoli;-50,32;;;;0;;;;-50,32
Narva Kunstikool;8201513;61103113738;Kalinina Milolika;37903043715;Tutuka Tarass;22;29;;;29;;;;51
Narva Kunstikool;8201610;60607013732;Mihhailova Milena;46710033717;Zemtsova Larissa;0;;;;0;;;;0
Narva Kunstikool;8201717;60312153714;Vangonen Karina;47508183746;Vangonen Irina;-10,32;;;;0;;;;-10,32
Narva Kunstikool;8201814;61405270073;Treumova Elizaveta;39002133735;Treumov Ivan;0;;;;0;;;;0
Narva Kunstikool;8201911;60709027076;Minitš Ksenija;45909112293;Kossolapova Marina;0;;;;0;;;;0
Narva Kunstikool;8202017;60511013736;Mihhailova Anna;47510043716;Mihhailova Natalja;0;;;;0;;;;0
Narva Kunstikool;8202114;50605083715;Baskakov Vladislav;47504193711;Baskakova Julia;0;;;;0;;;;0
Narva Kunstikool;8202211;60609053748;Guljajeva Alisa;47402182716;Guljajeva Svetlana;0;;;;0;;;;0
Narva Kunstikool;8202318;61402240048;Andrejeva Anna;37609103719;Andrejev Deniss;17;20;;;20;17;;;20
Narva Kunstikool;8202415;61005203711;Openko Elisabet;48101072223;Openko Viktoria;24;29;;;29;;;;53
Narva Kunstikool;8202512;51008220073;Tšerkassov Marat;48509053715;Lgirtša Maia;-20;;;;0;;;;-20
Narva Kunstikool;8202619;60606223713;Jevstafjeva Aleksandra;47204262233;Jevstafjeva Galina;-2,99;;;;0;;;;-2,99
Narva Kunstikool;8202716;61011023719;Fedulova Anastassija;47909072219;Korbut-Fedulova Oksana;-35,23;;;;0;;;;-35,23
Narva Kunstikool;8202813;60711213710;Khatchenkova Diana;48107183720;Võssotskaja Jelena;0;;;;0;;;;0
Narva Kunstikool;8202910;60601033716;Kregždaite Valeria;47011073720;Kregždene Tatjana;0;;;;0;;;;0
Narva Kunstikool;8203016;61408170058;Jerjomina Arina;48402213727;Ivinskaja Aljona;17;20;;;20;17;;;20
Narva Kunstikool;8203113;50611020046;Pashutin Platon;37712110108;Pašshutin Vadim;0;;;;0;;;;0
Narva Kunstikool;8203210;60607117116;Semishkur Sofiya;47801160029;Semishkur Oxana;-2,99;;;;0;;;;-2,99
Narva Kunstikool;8203317;60705233718;Drakunova Anastasia;47507033711;Drakunova Nadežda;0;;;;0;;;;0
Narva Kunstikool;8203414;51410220114;Kondratjuk Elizar;48812202717;Raizvihh-Kondratjuk Katerina;0;;;;0;;;;0
Narva Kunstikool;8203511;60607033713;Tamberg Agneta ireen;46706022227;Tamberg Tiina;-32,67;;;;0;;;;-32,67
Narva Kunstikool;8203618;60907153720;Sokkojeva Ksenija;48212273712;Sokkojeva Galina;-50,32;;;;0;;;;-50,32
Narva Kunstikool;8203715;61403090130;Orlova Anastasssia;48606027017;Orlova Maria;17;20;;;20;17;;;20
Narva Kunstikool;8203812;61309060171;Panina Ainura;47612150243;Korovkina Anžela;17;20;;;20;17;;;20
Narva Kunstikool;8203919;60801160235;Alekseeva Ksenya;48612292240;Aleksejeva Aleksandra;3,01;29;;;29;3,01;;;29
Narva Kunstikool;8204015;60707047058;Karpetšenkova Karina;47808065228;Karpetšenkova Kristina;24;29;;;29;24;;;29
Narva Kunstikool;8204112;60709183723;Kornysheva  Irina;37502090017;Kornyshev Jurii;0;;;;0;;;;0
Narva Kunstikool;8204219;60609213721;Snetkova Anastasia;47505143714;Snetkova Natalja;24;29;;;29;24;;;29
Narva Kunstikool;8204316;60910133719;Šubina Jana;37203203716;Šubin Oleg;0;;;;0;;;;0
Narva Kunstikool;8204413;60604213718;Grigorieva Daria;47103162228;Grigorieva  Valeria;0;;;;0;;;;0
Narva Kunstikool;8204510;61311040010;Polgorodnik Diana;48608093719;Polgorodnik Maria;17;20;;;20;17;;;20
Narva Kunstikool;8204617;60604253746;Sokkojeva Uljana;48511263720;Sokkojeva Jekaterina;24;29;;;29;24;;;29
Narva Kunstikool;8204714;60705203726;Upeniek Ieva-Stefania;48106022213;Upeniek Tatjana;24;29;;;29;28;;;25
Narva Kunstikool;8204811;51411300122;Samusin Demid;48112273713;Vaganova Anna;12;14;;;14;12;;;14
Narva Kunstikool;8204918;60707043745;Volkova Angelika;48609253719;Maksimovitš Jekaterina;-16;;;;0;;;;-16
Narva Kunstikool;8205014;51403130246;Migatšov Maxim;48607173750;Migatšova Nadezhda;0;;;;0;;;;0
Narva Kunstikool;8205111;60407143718;Dadatskaja Alina;47507133717;Soob  Elena;0;;;;0;;;;0
Narva Kunstikool;8205218;45906293746;Bannikova Ljubov;45906293746;Bannikova Ljubov;-19;;;;0;;;;-19
Narva Kunstikool;8205315;50605033713;Moldon Evan;48307292252;Moldon Anastassia;24;29;;;29;24;;;29
Narva Kunstikool;8205412;60605073720;Širobokova Arina;48509282217;Širobokova Natalja;-12,67;;;;0;;;;-12,67
Narva Kunstikool;8205519;60307310018;Botorojeva Svetlana;47406110092;Botorojeva Natalia;-57,87;;;;0;;;;-57,87
Narva Kunstikool;8205616;60111093714;Gavrilova Tatjana;47504203718;Šumina Olga;-23;;;;0;;;;-23
Narva Kunstikool;8205713;51207053716;Grachev Grigori;47111173729;Gratšova Julia;0;;;;0;;;;0
Narva Kunstikool;8205810;61303170228;Sbitneva Valeria;48902023715;Sbitneva Svetlana;0;;;;0;;;;0
Narva Kunstikool;8205917;61409200077;Snežkova Victoria;49106273716;Snezkova Anna;17;20;;;20;17;;;20
Narva Kunstikool;8206013;60305233739;Korelina Yanika;47909233712;Korelina Marika;0;;;;0;;;;0
Narva Kunstikool;8206110;60709027076;Minitš Ksenija;45909112293;Kossolapova Marina;0;;;;0;;;;0
Narva Kunstikool;8206217;61306010076;Titova Ksenija;49004113710;Mikhailova Natalia;-16,33;;;;0;;;;-16,33
Narva Kunstikool;8206314;60512143724;Võssotskaja Anneli;37211203710;Võssotski Anatoli;0;;;;0;;;;0
Narva Kunstikool;8206411;60709027076;Minitš Ksenija;45909112293;Kossolapova Marina;0;;;;0;;;;0
Narva Kunstikool;8206518;39801213746;Husainov Timur;39801213746;Hussainov Timur;0;;;;0;;;;0
Narva Kunstikool;8206615;50407283742;Nilov Vladimir;45001213737;Chernenok Larisa;-57,87;;;;0;;;;-57,87
Narva Kunstikool;8206712;51309230104;Ustov Matvei;48604183714;Bocharova Yana;34;20;;;20;34;;;20
Narva Kunstikool;8206819;39901133713;Juhhimenko Veniamin;36410223723;Juhhimenko Valeri;-23;;;;0;;;;-23
Narva Kunstikool;8206916;61301290020;Vassiljeva Eleonora;49203223724;Skorobogatova Olesja;17;20;;;20;17;;;20
Narva Kunstikool;8207012;60209023715;Tšuševa Jekaterina;46906153736;Ogurova Irina;-1,67;;;;0;;;;-1,67
Narva Kunstikool;8207119;61303250068;Kisseljova Vera;48104083710;Kisseljova Jekaterina;17;20;;;20;17;;;20
Narva Kunstikool;8207216;61203073711;Morgunova Sofia;48512052219;Popova Maria;34;20;;;20;;;;54
Narva Kunstikool;8207313;61301220037;Olenina Vasilisa;48108053715;Pimenova Natlja;17;20;;;20;17;;;20
Narva Kunstikool;8207410;61303200088;Pagi Aleksandra-Sandra;49501153738;Tjutjavina Valentina;37;20;;;20;;;;57
Narva Kunstikool;8207517;61310040082;Belsner Angelina;49411253734;Belsner Ksenia;17;20;;;20;20;;;17
Narva Kunstikool;8207614;61202043739;Evstafjeva Ksenia;48511033718;Evstafieva Olesja;-25,16;;;;0;;;;-25,16
Narva Kunstikool;8207711;51211040083;Faruškin Jaromir;47803243720;Tjantova Marina;34;20;;;20;34;;;20
Narva Kunstikool;8207818;61309100188;Lenardson Sandra;48708112229;Lenardson Jekaterina;0;;;;0;;;;0
Narva Kunstikool;8207915;61110263724;Antipenko Adelina;48812193716;Antipenko Anastasia;24;29;;;29;24;;;29
Narva Kunstikool;8208011;61401230145;Kossobutskaja Emilia;49010023717;Kossobutskaja Julia;-19;20;;;20;;;;1
Narva Kunstikool;8208118;61308100030;Merkurieva Anastasia;46911213714;Merkurjeva Ljudmila;17;20;;;20;17;;;20
Narva Kunstikool;8208215;61005173710;Einasmaa Kristiina;48703103728;Einasmaa Natalja;0;;;;0;;;;0
Narva Kunstikool;8208312;61209290111;Striško Uljana;48801160086;Tepane Maria;0;;;;0;;;;0
Narva Kunstikool;8208419;61011250129;Dykhnych Milana;38707113721;Jemeljanov Konstantin;0;;;;0;;;;0
Narva Kunstikool;8208516;61303270278;Belonina Angelina;48305223724;Belonina Julia;0;;;;0;;;;0
Narva Kunstikool;8208613;61301140198;Timofejeva Arina;48610022213;Timofejeva  Maria;17;20;;;20;;;;37
Narva Kunstikool;8208710;61302130032;Sokolova Maia;48702043712;Sokolova Olga;0;;;;0;;;;0
Narva Kunstikool;8208817;61209013710;Gongadze Elene;48112113716;Antonova Tatjana;17;20;;;20;17;;;20
Narva Kunstikool;8208914;61202283714;Kumekhova Alisa;47905033713;Kumekhova Jelena;24;29;;;29;24;;;29
Narva Kunstikool;8209010;60802013735;Drževeretskaja Sofja;47301083710;Držerevetskaja Marina;-16;;;;0;;;;-16
Narva Kunstikool;8209117;46201133731;Kobenjak Jelena;46201133731;Kobenjak Jelena;36;43;;;43;36;;;43
Narva Kunstikool;8209214;51110060078;Ivanen Roman;38506092229;Ivanen Maksim;72;29;;;29;34;;;67
Narva Kunstikool;8209311;60908073711;Prõtkova Valerija;38402093715;Prõtkov Igor;0;29;;;29;;;;29
Narva Kunstikool;8209418;61002073711;Markova Maria;48206283735;Markova Jevgenia;24;29;;;29;53;;;0
Narva Kunstikool;8209515;60612053717;Poluektova Arina;47909253728;Poluektova Elena;0;;;;0;;;;0
Narva Kunstikool;8209612;51309300133;Provotorov Svjatoslav;47901223713;Provotorova Galina;0;;;;0;;;;0
Narva Kunstikool;8209719;60905253727;Safronova Valerija;48803053727;Safronova Maria;-12;;;;0;;-12;;0
Narva Kunstikool;8209816;61006293735;Assejeva Valeria;47512093710;Assejeva Natalja;24;29;;;29;24;;;29
Narva Kunstikool;8209913;60906233718;Kichatova Alina;48909013710;Kichatova Olga;0;;;;0;;;;0
Narva Kunstikool;8210012;61109153721;Andrejeva Alisa;48408103744;Andrejeva Maria;0;;;;0;;;;0
Narva Kunstikool;8210119;60703043714;Grunturs Uljana;48106163723;Grunturs Olga;-13,99;34;;;34;70;;;-49,99
Narva Kunstikool;8210216;61112053737;Belyaeva Arina;38509252250;Belyaev Yury;24;29;;;29;;;;53
Narva Kunstikool;8210313;61010170132;Boika Darya;47811040100;Khramelia Iryna;0;;;;0;;;;0
Narva Kunstikool;8210410;61010203712;Rodina Alisa;48205023720;Rodina Aleksandra;26;29;;;29;26;;;29
Narva Kunstikool;8210517;61105033712;Zaugarova Angelina;47903293724;Linnik Anna;-117,06;29;;;29;;;;-88,06
Narva Kunstikool;8210614;60903133720;Markelova Taissija;47604233711;Markelova Olga;12;29;;;29;36;;;5
Narva Kunstikool;8210711;60805193713;Senitšenkova Eva;37504073723;Senichenkov Vadim;0;;;;0;;;;0
Narva Kunstikool;8210818;60202043727;Leontovitš Uljana;60202043727;Leontovitš Uljana;0;;;;0;;;;0
Narva Kunstikool;8210915;39901073724;Spiridonov Artjoma;39901073724;Spiridonov Artjoma;0;;;;0;;;;0
Narva Kunstikool;8211011;60304010251;Artemjeva Marija;47607273732;Artemjeva Tatjana;-11;;;;0;;;;-11
Narva Kunstikool;8211118;50704233712;Kossorotov Vladislav;38106313737;Kossorotov Jevgeni;-40;;;;0;;;;-40
Narva Kunstikool;8211215;60712193743;Maksimova Miroslava;48211273718;Maksimova Varvara;-52,67;;;;0;;;;-52,67
Narva Kunstikool;8211312;60812223714;Konoš Milana;47407243716;Krainik Olga;24;29;;;29;;;;53
Narva Kunstikool;8211419;49606283749;Moiseeva Darja;49606283749;Moiseeva Daria;-1,67;;;;0;;;;-1,67
Narva Kunstikool;8211516;60612142752;Zaretskaja Anastasija;47812313736;Zaretskaja Julia;0;;;;0;;;;0
Narva Kunstikool;8211613;60610022722;Gering Miia-elisabeth;47204043716;Gering Larissa;56;34;;;34;84;;;6
Narva Kunstikool;8211710;60504023721;Pavlova Annika;47401073717;Pavlova Julianna;0;;;;0;;;;0
Narva Kunstikool;8211817;50402053717;Rutenburg Deniel;48003303722;Rutenburg Irina;-15,83;;;;0;;;;-15,83
Narva Kunstikool;8211914;60511243736;Smirnova Anastasia;48002212217;Streff Julia;0;;;;0;;;;0
Narva Kunstikool;8212010;50511113741;Zaitsev Jegor;47607143716;Zaitseva Jelena;0;;;;0;;;;0
Narva Kunstikool;8212117;50606123728;Iljin Jakov;47306163716;Golubeva  Olga;0;;;;0;;;;0
Narva Kunstikool;8212214;60505190855;Subotkevitš Daniela;47612113729;Subotkevitš Natalja;0;;;;0;;;;0
Narva Kunstikool;8212311;60609153721;Khorbaladze Safina;47504013726;Khorbaladze Svetlana;0;;;;0;;;;0
Narva Kunstikool;8212418;60708083745;Volkova Darina;48505133715;Merkulova Jelena;0;;;;0;;;;0
Narva Kunstikool;8212515;60602093719;Pugatšova Sofia;38005183728;Pugatšov Ilja;0;;;;0;;;;0
Narva Kunstikool;8212612;60806133711;Kišuns Anna;47707023710;Kišuns Svetlana;0;;;;0;;;;0
Narva Kunstikool;8212719;60712133712;ROOR NIKA;37907013719;ROOR ANTON;0;;;;0;;;;0
Narva Kunstikool;8212816;60905083747;Fedorova Sofja;48706023751;Fedorova Vladislava;0;;;;0;;;;0
Narva Kunstikool;8212913;51204283712;Hütt Mark;48507272233;Hütt Tatjana;0;;;;0;;;;0
Narva Kunstikool;8213019;60709122216;Smirnova Nonna;48703272224;Smirnova Olga;-28,67;;;;0;;;;-28,67
Narva Kunstikool;8213116;61306200070;Abuzova Arina;49105133721;Abuzova Anastassia;-6,33;;;;0;;;;-6,33
Narva Kunstikool;8213213;61202133717;Juganson Alisa;48309052299;JUGANSON ULJANA;0;;;;0;;;;0
Narva Kunstikool;8213310;60609023716;Bargan Aleksandra;47803063710;Bargan Julia;-32,67;;;;0;;;;-32,67
Narva Kunstikool;8213417;60508233716;Han  Lolita;48106133713;Han Vassilina;-32,67;;;;0;;;;-32,67
Narva Kunstikool;8213514;60606053733;Ivanova Sofia;48310122210;Demse Julia;-12,99;;;;0;;;;-12,99
Narva Kunstikool;8213611;61006197064;Shticalov Milana;48203083725;Shticalov Anželika;0;;;;0;;;;0
Narva Kunstikool;8213718;61204013718;Rumjantseva Uljana;48304112296;Rumyantseva Marina;24;29;;;29;24;;;29
Narva Kunstikool;8213815;61201223711;Terekhina Jekaterina;47501052230;Terehhina Olga;0;;;;0;;;;0
Narva Kunstikool;8213912;60505083713;Guskova Kristiina;48501103723;Komorova Tatjana;-32,67;;;;0;;;;-32,67
Narva Kunstikool;8214018;60512263711;Jakovleva Darja;46912293721;Jakovleva Jekaterina;-12,67;;;;0;;;;-12,67
Narva Kunstikool;8214115;51311070063;Danieljan Damian;48506013716;Danieljan Irina;-25,16;;;;0;;;;-25,16
Narva Kunstikool;8214212;60605153734;Loiko Karolina-Laura;48303113712;Loiko Janina;-88,99;;;;0;;;;-88,99
Narva Kunstikool;8214319;60603273722;ŠUMINA KSENIA;47504203718;Šumina Olga;-32,67;;;;0;;;;-32,67
Narva Kunstikool;8214416;61304220150;Harak Mischelle;49104143712;Bulõtševa Anastassija;-1,49;;;;0;;;;-1,49
Narva Kunstikool;8214513;60605153745;Vlassova Karina;37307073710;Vlassov Aleksei;-32,67;;;;0;;;;-32,67
Narva Kunstikool;8214610;51306060022;Ivanov Aleksandr;48510293714;Rumjantseva Jelena;0;;;;0;;;;0
Narva Kunstikool;8214717;60304293743;Bolšakova Sofija;37511073712;Bolšakov Denis;-10,32;;;;0;;;;-10,32
Narva Kunstikool;8214814;60406223740;Bussel Julija;46306152242;Bussel Jelena;-24,5;;;;0;;;;-24,5
Narva Kunstikool;8214911;61112083725;Torortseva Milana;48303133726;Toroptseva Tatjana;-15;;;;0;;;;-15
Narva Kunstikool;8215017;61202283758;Treumova Darja;48203243736;Treumova Irina;24;29;;;29;29;;;24
Narva Kunstikool;8215114;60505233723;Voronkova Anastassija;48212202231;Voronkova Olga;0;;;;0;;;;0
Narva Kunstikool;8215211;51109133748;Grigorjev Marat;49101233740;Grigorjeva Alina;0;29;;;29;;;;29
Narva Kunstikool;8215318;50507223714;Botštarjov Kiril;48109273718;Kobeleva Svetlana;-10,32;;;;0;;;;-10,32
Narva Kunstikool;8215415;50409163743;Gretškin Matvei;47904283711;Gretškina Anastassia;-50,32;;;;0;;;;-50,32
Narva Kunstikool;8215512;60511013736;Mihhailova Anna;47510043716;Mihhailova Natalja;0;;;;0;;;;0
Narva Kunstikool;8215619;61004060037;Kudriashova Daria;47206113722;Kudriashova Olga;0;;;;0;;;;0
Narva Kunstikool;8215716;61108250119;Moskovaja Milena;47305173729;Turaškina Jelena;24;29;;;29;24;;;29
Narva Kunstikool;8215813;60505203768;Akulova Alina;46802212215;Illarionova Galina;-20;;;;0;;;;-20
Narva Kunstikool;8215910;61012213735;Romanova Olga;47610223721;Romanova Galina;0;;;;0;;;;0
Narva Kunstikool;8216016;61303080044;Larikova Uljana;48402293717;Larikova Nadezhda;17;20;;;20;17;;;20
Narva Kunstikool;8216113;61012213740;Romanova Jaroslava;47610223721;Romanova Galina;0;;;;0;;;;0
Narva Kunstikool;8216210;50911303714;Streff Erik ;48002212217;Streff Julia;0;;;;0;;;;0
Narva Kunstikool;8216317;61202173712;Tkacheva Varvara;38812043718;Tkachev Alexey;0;;;;0;;;;0
Narva Kunstikool;8216414;61302250096;Malahhova Viktoria;49310183727;Bulatšenkova Anastassia;11;20;;;20;20;;;11
Narva Kunstikool;8216511;60609143736;Bendi Jekaterina;47606172212;Bendi Veronika;0;;;;0;;;;0
Narva Kunstikool;8216618;60509053712;Goncharova Jekaterina;46804113739;Trunova Tatiana;0;;;;0;;;;0
Narva Kunstikool;8216715;60511213715;Dronik Sofia;48407312216;Dronk Irina;0;;;;0;;;;0
Narva Kunstikool;8216812;60808233714;Kozeletskaja Ksenija;48712123730;Kozeletskaja Jelena;24;29;;;29;24;;;29
Narva Kunstikool;8216919;50812083732;Nikolajev Aleksei ;37009143718;Nikolajev Pavel;0;;;;0;;;;0
Narva Kunstikool;8217015;60807273759;Puhtejeva Elizaveta;36412013714;Dolgov Roman;24;29;;;29;24;;;29
Narva Kunstikool;8217112;60801283714;Romanova Liat Avital Assol;48207073710;Romanova Olga;0;;;;0;;;;0
Narva Kunstikool;8217219;50604173720;Zyuzin Matvei;47106143740;Zjuzina  Elena;0;;;;0;;;;0
Narva Kunstikool;8217316;61502130201;Belova Aljona;47911233717;Belova Jelena;0;;;;0;;;;0
Narva Kunstikool;8217413;51510220085;Grigorjev Renat;48804192235;Mintšenkova Jana;-12;14;;;14;12;;;-10
Narva Kunstikool;8217510;61504250133;Evzhinova Emilia;48704222222;Evzhinova Yulia;0;;;;0;;;;0
Narva Kunstikool;8217617;61504280154;Iljina Miroslava;47603053725;Iljina Marina;0;;;;0;;;;0
Narva Kunstikool;8217714;60004193739;Sedneva Lilija;46909093718;Sedneva Natalia;0;;;;0;;;;0
Narva Kunstikool;8217811;51504060116;Sahharov Kristjan;47610222256;Aleksejeva Rimma;12;14;;;14;12;;;14
Narva Kunstikool;8217918;61506090050;Silašina Sofia;48709263729;Silašina Tatjana;12;14;;;14;;;;26
Narva Kunstikool;8218014;61512160096;Uglanova Elizaveta;37408093710;Uglanov Deniss;24;14;;;14;24;;;14
Narva Kunstikool;8218111;60712053720;VOGT BRITTA-LIIS;46903243731;VOGT OKSANA;0;;;;0;;;;0
Narva Kunstikool;8218218;60901103710;Ippolitova Anastassia;37702043710;Ippolitov Vitali;23;29;;;29;;;;52
Narva Kunstikool;8218315;61311130151;Angere Jaroslava;48905232218;Angare Maria;34;20;;;20;;;;54
Narva Kunstikool;8218412;60709233716;Zimina Sofia;47308053713;Zimina Olga;24;29;;;29;24;;;29
Narva Kunstikool;8218519;61405290087;Glambotskaja Alisa;49309244713;Glambotskaja Elena;-10;;;;0;;;;-10
Narva Kunstikool;8218616;61406040176;Dubinskas Elina;49104243718;Dubinskas Ksenia;17;20;;;20;17;;;20
Narva Kunstikool;8218713;61408140072;Dukatš Jekaterina;48209119514;Dukatš Kristina;5;20;;;20;5;;;20
Narva Kunstikool;8218810;37211023712;Kuzmin Sergei;37211023712;Kuzmin Sergei;0;;;;0;;;;0
Narva Kunstikool;8218917;47908213759;Milovidova Jelena;47908213759;Milovidova Jelena;0;;;;0;;;;0
Narva Kunstikool;8219013;49607313722;Polunina Jelizaveta;49607313722;Polunina Jelizaveta;-31,67;;;;0;;;;-31,67
Narva Kunstikool;8219110;48709062219;Frants Olga;48709062219;Frants Olga;-1,67;;;;0;;;;-1,67
Narva Kunstikool;8219217;48302123725;Komarkova Marina;48302123725;Komarkova Marina;-31,67;;;;0;;;;-31,67
Narva Kunstikool;8219314;46509212241;Shchedrenkova Zoya;46509212241;Štšedrenkova Zoja;-1,67;;;;0;;;;-1,67
Narva Kunstikool;8219411;48408083717;Sazonova Aljona;48408083717;Sazonova Aljona;0;;;;0;;;;0
Narva Kunstikool;8219518;37912257018;Anto Anton;37912257018;Anto Anton;36;43;;;43;36;;;43
Narva Kunstikool;8219615;61210153736;Klessareva Anfisa;38710183717;Klessarev Artjom;-14;;;;0;;;;-14
Narva Kunstikool;8219712;61111033735;Voytyushko Milena;48312253712;Voytyushko Alina;-22,87;;;;0;;;;-22,87
Narva Kunstikool;8219819;61205103722;Styažhkina Milana;48903033716;Styažhkina Tatiana;0;;;;0;;;;0
Narva Kunstikool;8219916;61108303735;Dukatš Anna;48209119614;Dukatš Kristina;24;29;;;29;28;;;25
Narva Kunstikool;8220015;61004193728;Ramenskaja Sofia;47210083717;Ramenskaja Olga;0;;;;0;;;;0
Narva Kunstikool;8220112;60810093723;Dmitrijeva Anastassia;49312147025;Dmitrijeva Jelizaveta;0;;;;0;;;;0
Narva Kunstikool;8220219;60911273725;Misina Vladlena;48809017011;Misina Tatjana;24;29;;;29;24;;;29
Narva Kunstikool;8220316;50808093721;Morozov Semjon;47109283712;Morozova Jekaterina;24;29;;;29;24;;;29
Narva Kunstikool;8220413;60910053738;Borissova Aljona;37505053747;Borisov Sergey;24;29;;;29;24;;;29
Narva Kunstikool;8220510;50911123716;Kovalev Arseniy;48210133734;Kovaleva Elena;0;;;;0;;;;0
Narva Kunstikool;8220617;50905253715;Nikitin Arseniy;49003083737;Nikitina Marta;0;;;;0;;;;0
Narva Kunstikool;8220714;60905063711;Fedotova Uljana;48211083735;Maksimova Jelena;0;;;;0;;;;0
Narva Kunstikool;8220811;60811273711;Ishakova Alesja;38202233712;Ishakov Ruslan;0;29;;;29;24;;;5
Narva Kunstikool;8220918;60904283710;Lušnikova  Aleksandra;48103062215;Lušnikova Niina;0;29;;;29;24;;;5
Narva Kunstikool;8221014;60804203717;Dementjeva Anastasia;37712083730;Dementjev Fjodor;0;;;;0;;;;0
Narva Kunstikool;8221111;60805063730;Yakovleva Nicole;48506153728;Yakovleva Anastassia;48;29;;;29;48;;;29
Narva Kunstikool;8221218;50603273732;Fedyajev Saveliy;47201083718;Timofeeva Anna;0;;;;0;;;;0
Narva Kunstikool;8221315;60410243717;Spiridonova Sofija;36406053714;Spiridonov Andrei;28;34;;;34;28;;;34
Narva Kunstikool;8221412;60307023719;Frolova Marta;47403292723;Karina Anna;0;;;;0;;;;0
Narva Kunstikool;8221519;60501263713;Jurtšenko Polina;46807223712;Jurtsenko Svetlana;0;;;;0;;;;0
Narva Kunstikool;8221616;61308150119;Gvianidze Arina;48508303726;Gvianidze Ksenia;17;20;;;20;17;;;20
Narva Kunstikool;8221713;61306040129;Ivanenko Alisia;38604043718;Ivanenko Vitali;-16,33;;;;0;;;;-16,33
Narva Kunstikool;8221810;61309120027;Krankals Alisia;38108152216;Krankals Artur;17;20;;;20;17;;;20
Narva Kunstikool;8221917;51307250065;Kreyvald Dennis;37303250022;Kreyvald Valery;17;20;;;20;17;;;20
Narva Kunstikool;8222013;61301230077;Moltšanova Sofia;48504042238;Moltšanova Natalja;0;;;;0;;;;0
Narva Kunstikool;8222110;61202213713;Ossinina Kristina;48605152217;Ossinina Svetlana;24;29;;;29;24;;;29
Narva Kunstikool;8222217;61303020068;Rumjantseva Mileta;48712273738;Rumjantseva Liana;0;;;;0;;;;0
Narva Kunstikool;8222314;61305110055;Hrustaljova Milana;47612253730;Hrustaljova Alina;0;;;;0;;;;0
Narva Kunstikool;8222411;61210023742;Vesselova Sofia;48002123727;Vesselova Irina;17;;;;0;17;;;0
Narva Kunstikool;8222518;51304120034;Voznessenski Nazar;48006062238;Voznessenskaja Olga;-16,33;;;;0;;;;-16,33
Narva Kunstikool;8222615;51409020078;Hütt Tigran;48507272233;Hütt Tatjana;0;;;;0;;;;0
Narva Kunstikool;8222712;61412230110;Katajeva Alina;48109023715;Katajeva Larissa;4;14;;;14;12;;;6
Narva Kunstikool;8222819;60803063710;Djatlova Maria;48211233734;Kuzovleva Irina;24;29;;;29;24;;;29
Narva Kunstikool;8222916;60611103727;Rutenburg Diana;48003303722;Rutenburg Irina;-9,5;;;;0;;;;-9,5
Narva Kunstikool;8223012;60709223742;Savina Adelina;35506143714;Savin Vladimir;0;;;;0;;;;0
Narva Kunstikool;8223119;60112243729;Filippova Jelena;47401233723;Filippova Irina;-39,5;;;;0;;;;-39,5
Narva Kunstikool;8223216;60607303732;Kushteyn Sofia;47612270012;Kushteyn Irina;0;;;;0;;;;0
Narva Kunstikool;8223313;60403303717;Hussainova Tamara;47504032218;Hussainova Zoja;0;;;;0;;;;0
Narva Kunstikool;8223410;51103063733;Kukk Arseni;48310173710;Kukk Natalja;24;29;;;29;;;;53
Narva Kunstikool;8223517;61412230108;Katajeva Olesja;48109023715;Katajeva Larissa;12;14;;;14;12;;;14
Narva Kunstikool;8223614;61403280070;Kopjeva Arina;47508082307;Kopjeva Anastassija;0;;;;0;;;;0
Narva Kunstikool;8223711;61303140077;Noormägi Marta;48711103711;Noormägi Tatjana;9;20;;;20;9;;;20
Narva Kunstikool;8223818;60908243735;Pekkonen Ljubov;48204273718;Aleksejeva Maria;21,01;29;;;29;50;;;0,01
Narva Kunstikool;8223915;61309300123;Provotorova Valeria;47901223713;Provotorova Galina;-10;;;;0;;;;-10
Narva Kunstikool;8224011;61406180057;Kõlli Diana;47312313710;Kuzina Yanina;17;20;;;20;17;;;20
Narva Kunstikool;8224118;61003163737;Zhuravleva Sofia;46004192240;Shvedova  Svetlana;-32,67;;;;0;;;;-32,67
Narva Kunstikool;8224215;51405130060;Sevbjanov Damir;47907243718;Tikhomirova Galina;17;20;;;20;17;;;20
Narva Kunstikool;8224312;61001143746;Blat Anna;47610202220;Zaitseva Natalja;24;29;;;29;24;;;29
Narva Kunstikool;8224419;61406050117;Škinjova Nika;48205143729;Skinjova Jelizaveta ;17;20;;;20;17;;;20
Narva Kunstikool;8224516;51312090049;Belov Aleksei;47911233717;Belova Jelena;17;20;;;20;17;;;20
Narva Kunstikool;8224613;61312090094;Belova Maria;47911233717;Belova Jelena;17;20;;;20;17;;;20
Narva Kunstikool;8224710;61402060072;Evzhinova Adelina;48704222222;Evzhinova Yulia;0;;;;0;;;;0
Narva Kunstikool;8224817;61311290166;Gorbatšova Ksenia;49109263713;Knjazeva Alisa;-5;20;;;20;20;;;-5
Narva Kunstikool;8224914;51403120032;Ivanen Pjotr;48410183720;Ivanen Maria;0;;;;0;;;;0
Narva Kunstikool;8225010;61402150060;Kolyazina Zlata;49104113713;Kolyazina Vladislava;17;20;;;20;17;;;20
Narva Kunstikool;8225117;51407180279;Levshin Mikhail;48807232225;Štoda Anastasia;17;20;;;20;17;;;20
Narva Kunstikool;8225214;61012093729;Kostrichkina Nikoleta;48801033725;Neiman Irina;12;29;;;29;12;;;29
Narva Kunstikool;8225311;61312090061;Malysheva Sofia;48202102232;Malysheva Anna;17;20;;;20;20;;;17
Narva Kunstikool;8225418;61401080244;Pärnoja Katrin;47310270037;Konopleva Inga;17;20;;;20;17;;;20
Narva Kunstikool;8225515;51310250067;Salikov Nikita;48306052237;Salikova Irina;0;;;;0;;;;0
Narva Kunstikool;8225612;51401200076;Semashko Nikita;48310253713;Semashko Anzhelika;0;;;;0;;;;0
Narva Kunstikool;8225719;61501290179;Belova Jana;48211022228;Belova Oksana;12;14;;;14;12;;;14
Narva Kunstikool;8225816;61505190062;Asterdinova Viktoria;48408052275;Asterdinova Nina;-20;;;;0;;;;-20
Narva Kunstikool;8225913;61103183732;Žarkova Lika;49003283727;Zharkova Yulia;24;29;;;29;24;;;29
Narva Kunstikool;8226019;61005273738;Žuljeva Varvara;47212012279;Žuljeva Tatjana;24;29;;;29;24;;;29
Narva Kunstikool;8226116;61011293725;Jefimova Arina;47702073717;Belyaeva Jelena;24;29;;;29;24;;;29
Narva Kunstikool;8226213;51509020353;Halli Arsen;48006043722;Halli Jekaterina;12;14;;;14;12;;;14
Narva Kunstikool;8226310;51105183728;Nikitin Mikhail;49005293711;Nikitina Veronika;-9;;;;0;;;;-9
Narva Kunstikool;8226417;61303080099;Vassilevskaja Valeria;47806053718;Vassilevskaja Julia;17;20;;;20;20;;;17
Narva Kunstikool;8226514;61001122212;Zhuravleva Karolina;48403052245;Zhuravleva Natalia;-0,23;;;;0;;;;-0,23
Narva Kunstikool;8226611;60803283724;Beze Viktoria;46803152215;Boborenko Jelena;24;29;;;29;24;;;29
Narva Kunstikool;8226718;61502250080;Kiik Olivia;48912262228;Kiik Nadezda;12;14;;;14;12;;;14
Narva Kunstikool;8226815;60811243745;Chupreeva Uljana;47301062231;Nikolenko Elena;0;29;;;29;;;;29
Narva Kunstikool;8226912;60804097015;Eremina Tereza;47201030039;Eremina Irina;0;29;-29;;0;;;;0
Narva Kunstikool;8227018;61101113739;Khitretsova Anna;48212142220;Khitretsova Ekaterina;-6,74;;;;0;;;;-6,74
Narva Kunstikool;8227115;61106172220;Balabanova Sofja;48609293714;Balabanova Jelena;24;29;;;29;48;;;5
Narva Kunstikool;8227212;60808223718;Kartõševa Irina;37812063719;Kartõšev Roman;0;;;;0;;;;0
Narva Kunstikool;8227319;60812303740;Kassatskaja Taissija;47603300298;Kassatskaja Galina;24;29;;;29;24;;;29
Narva Kunstikool;8227416;61412250059;Mäeorg Milana;48910242237;Nikitina Natalja;0;;;;0;;;;0
Narva Kunstikool;8227513;61506120127;Tšumakova Sofja;48507093722;Tšumakova Ksenia;12;14;;;14;12;;;14
Narva Kunstikool;8227610;61508010070;Maksimova Vladislava;48211273718;Maksimova Varvara;0;;;;0;;;;0
Narva Kunstikool;8227717;60810293715;Stepanova Anastasia;47506103713;Stepanova Natalja;0;;;;0;;;;0
Narva Kunstikool;8227814;51306280168;Begunov Eldar;48805173713;Bolšunova Julia;17;;;;0;30;;;-13
Narva Kunstikool;8227911;60806263736;Bulavkina Anna;37803143712;Bulavkin Aleksandr;-2,99;;;;0;;;;-2,99
Narva Kunstikool;8228017;61301110220;Belskaja Polina ;38305062252;Belski Jevgeni;0;;;;0;;;;0
Narva Kunstikool;8228114;60802113722;Fedossejeva Evelina;47703103715;Fedossejeva Jelena;24;29;;;29;24;;;29
Narva Kunstikool;8228211;60706233712;Golovan Julia;47803233712;Golovan Svetlana;-24;29;;;29;24;;;-19
Narva Kunstikool;8228318;60710033729;Kruk Evelina;38506067019;Kruk Andrey;24;29;;;29;24;;;29
Narva Kunstikool;8228415;60801293710;Lidikauskaite Sandra;48509303720;Lidikauskiene Tatjana;0;29;-29;;0;;;;0
Narva Kunstikool;8228512;61404140147;Pavlova Sofia;47209163717;Pavlova Tatjana;14;;;;0;;;;14
Narva Kunstikool;8228619;60812183740;Kolomentseva Sofia;37710273714;Kolomentsev Evgeny;-20,16;;;;0;;;;-20,16
Narva Kunstikool;8228716;60712093715;Ossovik Aleksandra;37107243717;Ossovik Dmitri;24;29;;;29;24;;;29
Narva Kunstikool;8228813;51102093727;Larikov Serafim;38102083721;Larikov Igor;0;;;;0;;;;0
Narva Kunstikool;8228910;61504210116;Perevalova Alisa;48301163737;Volõnskaja Jekaterina;0;;;;0;;;;0
Narva Kunstikool;8229016;60801093720;Tširkunova Polina;48308292224;Solovjova Oksana;24;29;;;29;;;;53
Narva Kunstikool;8229113;60910023717;Ivanova Olesja;38502183717;Ivanov Aleksandr;0;;;;0;;;;0
Narva Kunstikool;8229210;61109020200;Nazimova Diana;48811120051;Nazimova Marina;-8,87;;;;0;;;;-8,87
Narva Kunstikool;8229317;60708133716;Vaino Jekaterina;47311203725;Vaino Tatjana;0;;;;0;;;;0
Narva Kunstikool;8229414;61004193719;Sinyakova Anastasia;47004113728;Sinjakova Elena;-14;;;;0;;;;-14
Narva Kunstikool;8229511;51106130198;Padkovich Raman;38408050312;Padkovich Dzmitry;0;;;;0;;;;0
Narva Kunstikool;8229618;60610223720;Koltsova Jekaterina;47506223711;Koltsova Julia;0;;;;0;;;;0
Narva Kunstikool;8229715;60701303716;Obmjotko Stefani;47808082240;Obmetko Oxana;0;;;;0;;;;0
Narva Kunstikool;8229812;60612157080;Voskressenskaja Marva;47905163718;Voskressenskaja Jekaterina;0;;;;0;;;;0
Narva Kunstikool;8229919;60301273714;Davydova Arina;47505063722;Davydova Tatiana;-32,67;;;;0;;;;-32,67
Narva Kunstikool;8230018;51207303721;Lavrov Damir;38706053758;Timoštšuk Jevgeni;0;;;;0;;;;0
Narva Kunstikool;8230115;50512303718;Jelissejev Daniil;47705313722;Jelissejeva Nadežda;-2,99;;;;0;;;;-2,99
Narva Kunstikool;8230212;61307300135;Butkevitš Alina;47511022235;Butkevitš Anželika;0;;;;0;;;;0
Narva Kunstikool;8230319;60407093727;Širokova Darja;47411242214;Širokova Svetlana;0;;;;0;;;;0
Narva Kunstikool;8230416;60608077065;Tarassova Viktoria;48309293727;Tarassova Julia;-12,67;;;;0;;;;-12,67
Narva Kunstikool;8230513;50203110246;Burjakov Leonid;47604163715;Burjakova Natalja;-12,67;;;;0;;;;-12,67
Narva Kunstikool;8230610;60610103722;Dmitrieva Alisa;48109192217;Dmitrieva  Ekaterina;-32,67;;;;0;;;;-32,67
Narva Kunstikool;8230717;60605263747;Gavrilova Aljona;47909073717;Gavrilova Irina;-32,67;;;;0;;;;-32,67
Narva Kunstikool;8230814;60501253717;Grizodub Polina;48501043734;Yagonen Julia;-12,67;;;;0;;;;-12,67
Narva Kunstikool;8230911;51303010060;Karjalainen Oleg;39011033717;Karjalainen Deniss;-6,33;;;;0;;;;-6,33
Narva Kunstikool;8231017;60510113759;Izotova  Angelina;47212182213;Izotova Tatjana;0;;;;0;;;;0
Narva Kunstikool;8231114;60610277133;Kravtšenko Jana;46812023745;Kravtšenko Inna;-32,67;;;;0;;;;-32,67
Narva Kunstikool;8231211;60512193715;Linnik  Tatjana;48105293723;Linnik Irina;-32,67;;;;0;;;;-32,67
Narva Kunstikool;8231318;60902103726;Šabanina Emeli;48701213720;Šabanina Aleksandra;23,59;29;;;29;24;;;28,59
Narva Kunstikool;8231415;61007210084;Pedaja Eva;48801227010;Medvedeva Tatiana;-9,5;;;;0;;;;-9,5
Narva Kunstikool;8231512;60510293744;Pukk Ksenija;48507283716;Shubarina Ekaterina;-2,99;;;;0;;;;-2,99
Narva Kunstikool;8231619;60602213741;Sohromova Anna;47612133710;Skripkina Veera;-0,01;;;;0;;;;-0,01
Narva Kunstikool;8231716;60511273713;Širokova Aleksandra;47411242214;Širokova Svetlana;0;;;;0;;;;0
Narva Kunstikool;8231813;61211283768;Chudakova Viktoria;48502063713;Chudakova Irina;0;;;;0;;;;0
Narva Kunstikool;8231910;60504203720;Vissarionova Sofia;46912033722;Vissarionova Svetlana;-50,32;;;;0;;;;-50,32
Narva Kunstikool;8232016;60504220884;Bahmatova Sandra;38312047016;Bahmatov Mihhail;-62,58;;;;0;;;;-62,58
Narva Kunstikool;8232113;61508100156;Talvet Emilia;48805283726;Talvet Jelizaveta;12;14;;;14;12;;;14
Narva Kunstikool;8232210;51508060114;Hohlov Akim;48810237016;Hohlova Svetlana;0;;;;0;;;;0
Narva Kunstikool;8232317;61504210051;Glotova Sofia;46502282211;Mantšinskaja Valentina;0;;;;0;;;;0
Narva Kunstikool;8232414;60904283721;Tikhomirova Yuliya;48306107011;Tikhomirova Maria;24;29;;;29;;;;53
Narva Kunstikool;8232511;51602140047;Baranov Ilja;47602262213;Ušanova Tatjana;12;14;;;14;12;;;14
Narva Kunstikool;8232618;51601020131;Burakov Daniil;48909262215;Burakova Viktoria;12;14;;;14;12;;;14
Narva Kunstikool;8232715;61603090027;Dambina Amelia;48612073712;Dambina Olga;26;;;;0;;;;26
Narva Kunstikool;8232812;61603250088;Demidova Marta;48705295234;Demidova Jekaterina;12;14;;;14;12;;;14
Narva Kunstikool;8232919;61512220096;Fjodorova Varvara;49010033724;Fjpdorova Anna;12;14;;;14;12;;;14
Narva Kunstikool;8233015;61603290126;Matjušina Lada;47908013725;Matyushina Elena;0;;;;0;;;;0
Narva Kunstikool;8233112;51612040108;Pantelejev Lev;38008113727;Pantelejev Maksim;12;14;;;14;12;;;14
Narva Kunstikool;8233219;61601190078;Persidskaja Stefania;48401192241;Vladoiu-Predi Svetlana;12;14;;;14;12;;;14
Narva Kunstikool;8233316;61602110038;Rumyantseva Margarita;47701052214;Solovjova Jekaterina;12;14;;;14;14;;;12
Narva Kunstikool;8233413;61605030148;Sestašvili Arianna;48612253721;Kartašova Darja;12;14;;;14;12;;;14
Narva Kunstikool;8233510;61601020095;Šubina Vasilina;48703033721;Lipatnikova Irina;12;14;;;14;12;;;14
Narva Kunstikool;8233617;61609170082;Vaynonen Sofia;49208213715;Vaynonen Julia;12;14;;;14;12;;;14
Narva Kunstikool;8233714;61606260109;Vernoslova Elina;47807083711;Nadzhafova Tatjana;12;14;;;14;12;;;14
Narva Kunstikool;8233811;61507270042;Alekseeva Aksinja;48405153717;Alekseeva Marina;12;14;;;14;15;;;11
Narva Kunstikool;8233918;61502030141;Gvianidze Aleksandra;48508303726;Gvianidze Ksenia;12;14;;;14;12;;;14
Narva Kunstikool;8234014;61504190111;Jeršova Sofia;48602082261;Jeršova Ksenia;12;;;;0;12;;;0
Narva Kunstikool;8234111;61411290191;Korako Myroslava;48710270155;Korako Mariia;0;14;;-14;0;;;;0
Narva Kunstikool;8234218;61504020188;Lanman Ilaria;48804133724;Lanman Anita;0;;;;0;;;;0
Narva Kunstikool;8234315;61502130136;Mihhejeva Aljona;47408073721;Mihhejeva Anita;12;14;;;14;12;;;14
Narva Kunstikool;8234412;61412290261;Nikandrova Ksenija;49401193720;Nikandrova Kristina;12;14;;;14;12;;;14
Narva Kunstikool;8234519;61309130176;Makarova Emilia;38311123729;Makarova Aleksandra;34;20;;;20;;;;54
Narva Kunstikool;8234616;61507160032;Patanen Alina;48502073716;Patanen Anna;12;14;;;14;12;;;14
Narva Kunstikool;8234713;61212310173;Makova Aljona;48909213722;Funtova Maria;-10;;;;0;;;;-10
Narva Kunstikool;8234810;61507260083;Tsarkova Leja;49112193719;Tsarkova Maria;12;14;;;14;;;;26
Narva Kunstikool;8234917;61408160064;Gorkaja Aljona;48404072258;Gorkaja Natalia;12;14;;;14;12;;;14
Narva Kunstikool;8235013;51512210033;Kiselev Stepan;47903210068;Koroleva Anna;2;;;;0;;;;2
Narva Kunstikool;8235110;51507070182;Švarts Daniil;49007253737;Švarts Olga;24;14;;;14;26;;;12
Narva Kunstikool;8235217;61412210053;Vassiljeva Elizaveta;37307012225;Vassiljev Sergei;12;14;;;14;12;;;14
Narva Kunstikool;8235314;50204193733;Suhhotin Semjon;46705043723;Suhhotina Jelena;36;43;;;43;72;;;7
Narva Kunstikool;8235411;46705063715;Anufrijeva Maia;46705063715;Anufrijeva Maja;0;72;;;72;72;;;0
Narva Kunstikool;8235518;47803063710;Bargan Julia;47803063710;Bargan Julia;60;72;;;72;60;;;72
Narva Kunstikool;8235615;47002132212;Gorskaja Galina;47002132212;Gorskaja  Galina;60;72;;;72;60;;;72
Narva Kunstikool;8235712;48410183720;Ivanen Maria;48410183720;Ivanen Maria;60;72;;;72;60;;;72
Narva Kunstikool;8235819;46410152219;Klimko Irina;46410152219;Klimko Irina;0;72;;;72;;;;72
Narva Kunstikool;8235916;46504192222;Lebedeva Svetlana;46504192222;Lebedeva Svetlana;60;72;;;72;60;;;72
Narva Kunstikool;8236012;47704183710;Smirnova Svetlana;47704183710;Smirnova Svetlana;60;72;;;72;60;;;72
Narva Kunstikool;8236119;46103132719;Sõtšinskaja Natalja;46103132719;Sõtšinskaja  Natalja;60;72;;;72;60;;;72
Narva Kunstikool;8236216;60905053737;Gadzovskaja Eva-Daniela;45404293721;Valentina Pavlova;0;;;;0;;;;0
Narva Kunstikool;8236313;39002142211;Korzunin Alexey;39002142211;Korzunin Alexey;0;;;;0;;;;0
Narva Kunstikool;8236410;60603100241;Lambing Nicole;47402180047;Alejeva Alla;60;72;;;72;60;;;72
Narva Kunstikool;823651#;47912113716;Pašina Viktoria;47912113716;Pasina Viktoria;0;;;;0;;;;0
Narva Kunstikool;8236614;60507063731;Škalikova Anastassia;47806047013;Reren Maria;60;72;;;72;60;;;72
Narva Kunstikool;8236711;60608103714;Žitinskaja Anastasija;49101233729;Žitinskaja Natalja;0;;;;0;;;;0
Narva Kunstikool;8236818;60609303711;Titova Alisa;47510203737;Fomtšenkova Jelena;0;72;;;72;70;;;2
Narva Kunstikool;8236915;48011230084;Varfolomeeva Valeriia;48011230084;Varfolomeeva Valeriia;60;72;;;72;60;;;72
Narva Kunstikool;8237011;61401140059;Darja Bojartšuk;48509243716;Bojartšuk Julia;17;20;;;20;17;;;20
Narva Kunstikool;8237118;50512053713;Aleksandrov Maksim;48407092210;Aleksandrova Olesja;0;;;;0;;;;0
Narva Kunstikool;8237215;50604263719;Kisseljov Nikolai;37009223710;Kisseljov Vladimir;0;;;;0;;;;0
Narva Kunstikool;8237312;50604273726;Murd Andres;48301212254;Murd Jekaterina;0;;;;0;;;;0
Narva Kunstikool;8237419;50607133729;Shchurkin Artjom;47001053724;Shchurkina Lidia;0;;;;0;;;;0
Narva Kunstikool;8237516;61404140063;Zaugarova Vasilissa;47903293724;Linnik Anna;14;20;;;20;14;;;20
Narva Kunstikool;8237613;50703303725;Karpovitš Nikita;37209213711;Karpovitš Aleksandr;0;;;;0;;;;0
Narva Kunstikool;8237710;61306080092;Jakovleva Maria;48807033711;Jakovleva Margarita;17;20;;;20;20;;;17
Narva Kunstikool;8237817;61305010049;Sadejeva Antonina;48301082214;Sadejeva Jevgenija;17;20;;;20;17;;;20
Narva Kunstikool;8237914;61307020142;Sokolova Jelena;48405200091;Sokolova Svetlana;17;20;;;20;;;;37
Narva Kunstikool;8238010;50907063720;OSTROVERHOV NIKITA;39010133718;Ostroverhov Artur;24;29;;;29;24;;;29
Narva Kunstikool;8238117;51301160208;Tabunov Jegor;48910222223;Tabunova Olesya;17;20;;;20;17;;;20
Narva Kunstikool;8238214;50908313719;Babi Timofei;38404130045;Babii Sergii;-5,23;;;;0;;;;-5,23
Narva Kunstikool;8238311;61301284710;Pugatsova Miroslava;48108143727;Pugatšova Tatjana;-1,49;;;;0;;;;-1,49
Narva Kunstikool;8238418;50911033728;Sahharov Anton;47906183715;Sahharova Natalja;-26;;;;0;;;;-26
Narva Kunstikool;8238515;50912093715;Mägi Alex;49112182214;Mägi Anneli;-40;;;;0;;;;-40
Narva Kunstikool;8238612;61301200090;Urbans Milena;38801133719;Urbans Vladimir;17;20;;;20;17;;;20
Narva Kunstikool;8238719;61302060025;Kiseleva Ljubov;47903210068;Koroleva Anna;0;;;;0;;;;0
Narva Kunstikool;8238816;51302130020;Pavlov Jevgeni;49202123735;Smirnova Olga;17;20;;;20;20;;;17
Narva Kunstikool;8238913;51012133725;Mayorov Vadim;48506103715;Mayorova Oksana;0;;;;0;;;;0
Narva Kunstikool;8239019;61103183721;Hruljova Alina;37207103726;Hruljov Aleksei;28;34;;;34;28;;;34
Narva Kunstikool;8239116;61109060196;Makhova Mariia;47903050149;Makhova Nataliia;0;;;;0;;;;0
Narva Kunstikool;8239213;51109053734;Ivanov Gleb;48703022216;Nikolaeva Liudmila;24;29;;;29;24;;;29
Narva Kunstikool;8239310;51109063719;Zadubin Ruslan;48809113724;Pavlenkona Ekaterina;0;29;;;29;;;;29
Narva Kunstikool;8239417;51111013725;Horlunov Maksim;37005073724;Horlunov Sergei;0;;;;0;;;;0
Narva Kunstikool;8239514;61206223725;Iljina Arina;48912063747;Iljina Elena;24;29;;;29;24;;;29
Narva Kunstikool;8239611;61205090145;Petrauskaite Polina;48311263714;Aleksejeva Julia;0;;;;0;;;;0
Narva Kunstikool;8239718;61006143727;Popova Anastasija Vlada;61006143727;Popova Anastasija Vlada;24;29;;;29;30;;;23
Narva Kunstikool;8239815;51112063710;Prohhorenko  Pavel;47712273725;Prohhorenko Olga;0;29;-29;;0;;;;0
Narva Kunstikool;8239912;61207173715;Hrenova Margarita;48406293715;Šutina Jekaterina;24;29;;;29;24;;;29
Narva Kunstikool;8240011;60912083736;Konoš Ksenija;38209253717;Konoš Maksim;24;29;;;29;29;;;24
Narva Kunstikool;8240118;61206163725;Molodtsova Diana;48306163725;Molodtsova Jelena;24;29;;;29;29;;;24
Narva Kunstikool;8240215;61003273717;Šturmanova Arina;47706263712;Šturmanova Veera;0;29;;;29;;;;29
Narva Kunstikool;8240312;61006033714;Luhaväli Milvi karolin;46902043714;Jegorova Irina;24;29;;;29;24;;;29
Narva Kunstikool;8240419;60908113725;Šapiro Alina;47107033710;Jefremova Olga;24;29;;;29;24;;;29
Narva Kunstikool;8240516;61007293718;Švarkova Janika;48206262212;Ganzevitš-Švarkova Alesja ;24;29;;;29;24;;;29
Narva Kunstikool;8240613;60909042715;Upadõševa Varvara;48005093719;Upadõševa Veronika;0;29;;;29;;;;29
Narva Kunstikool;8240710;60809233719;Danilova Sofja;47311053715;Danilova Alla;24;29;;;29;24;;;29
Narva Kunstikool;8240817;60801103718;Fedušina Anastasia;36009113717;Fedjušin Valeri;24;29;;;29;24;;;29
Narva Kunstikool;8240914;60306073738;Zakilova Ksenia;47207263724;Zakilova Jelena;-10,32;;;;0;;;;-10,32
Narva Kunstikool;8241010;61002203718;Petrova Sofia;48406123715;Petrova Julia;24;29;;;29;24;;;29
Narva Kunstikool;8241117;60802123726;Zhurina Aljona;48401172259;Zhurina Veronika;24;29;;;29;48;;;5
Narva Kunstikool;8241214;60707213725;Gussarova Sofia;48002123716;Altuhhova Natalja;84;;;;0;;;;84
Narva Kunstikool;8241311;60609180359;Kirillovskaja Kristina;47508143729;Starodubtseva Maria;28;;;;0;;;;28
Narva Kunstikool;8241418;60501063723;Kovaljova Polina;47904203721;Kovaljova Anna;-32,67;;;;0;;;;-32,67
Narva Kunstikool;8241515;61209103720;Jakovleva Olesja;48307313733;Jakovleva  Natalja;48;29;;;29;48;;;29
Narva Kunstikool;8241612;60404263714;Merkulaeva Sandra;60404263714;Merkulaeva Sandra;0;;;;0;;;;0
Narva Kunstikool;8241719;60506113719;Heinlaid Eneli;48402203714;Heinlaid Jelena;0;;;;0;;;;0
Narva Kunstikool;8241816;60507133738;Gukovskaya Diana;37608082244;Kazakov Kirill;0;;;;0;;;;0
Narva Kunstikool;8241913;60508183723;Sokolova Maria;46708113723;Tšaika Larissa;-16;;;;0;;;;-16
Narva Kunstikool;8242019;60607313745;Vesselko Lilian;48107103728;Veselko Irina;32;34;-34;;0;;;;32
Narva Kunstikool;8242116;60511013725;Tšudajeva Arina;47707023721;Tšudajeva Tatjana;0;;;;0;;;;0
Narva Kunstikool;8242213;60905093710;Šelepanova Jevgenia;47209063711;Šelepanova Jelena;24;29;;;29;24;;;29
Narva Kunstikool;8242310;50509223757;Adamka Nikita;35812033716;Adamka Rudolf;-2,74;;;;0;;;;-2,74
Narva Kunstikool;8242417;60512193726;Panova Diana;47903062259;Hjurri Julia;0;;;;0;;;;0
Narva Kunstikool;8242514;61209193717;Nikolajeva Kristina;48801242213;Nikolajeva Ksenia;24;29;;;29;24;;;29
Narva Kunstikool;8242611;61401100238;Glücksam Adriana Milena;48404167013;Vecherenko- Lipina Jelena;51;20;;;20;34;;;37
Narva Kunstikool;8242718;61210113719;Ostov Alisa;48708163729;Ostov Anastassia;24;29;;;29;;;;53
Narva Kunstikool;8242815;60602143723;Zubkova Leonsia;48505073710;Berezina Oksana;0;;;;0;;;;0
Narva Kunstikool;8242912;60603093724;Zaytseva Olga;47402143718;Zaitseva Tatjana;0;;;;0;;;;0
Narva Kunstikool;8243018;47703043715;Khokhlova Viktoria;47703043715;Khokhlova Viktoria;60;72;;;72;72;;;60
Narva Kunstikool;8243115;61103173747;Djakova Diana;38102113711;Djakov Dmitri;28;34;;;34;28;;;34
Narva Kunstikool;8243212;47311193716;Tychkova Natalja;47311193716;Tychkova Natalja;60;72;;;72;60;;;72
Narva Kunstikool;8243319;60605233726;Ozerova Jevgenija;48701313726;Berezina Aljona;0;;;;0;;;;0
Narva Kunstikool;8243416;60609173713;Tolstopyatova Jelena;48711143728;Tolstopyatova Svetlana;0;;;;0;;;;0
Narva Kunstikool;8243513;61105283715;Moldova Tatjana;48009153739;Moldova Eva;0;;;;0;;;;0
Narva Kunstikool;8243610;51202283724;Gontcharov Rodion;45708133724;Makarova Ljubov;17;20;;;20;;;;37
Narva Kunstikool;8243717;46008170328;Jakovskaja Tatjana;46008170328;Jakovskaja Tatjana;36;43;;;43;36;;;43
Narva Kunstikool;8243814;60612043754;Sokolova Viktoria;47710203710;Sokolova Olga;-50,32;;;;0;;;;-50,32
Narva Kunstikool;8243911;60612103710;Lobetskaja Marija;48807252217;Lobetskaja Natalja;0;;;;0;;;;0
Narva Kunstikool;8244017;60404063757;Tšernavina Darja;60404063757;Tšernavina Darja;0;34;;;34;;;;34
Narva Kunstikool;8244114;50605117116;Sidorov Ilja;37912097012;Sidorov Nikodim;0;34;;;34;;;;34
Narva Kunstikool;8244415;60702253739;Thigarkova Marjana;48707313734;Aruvald Natalja;0;;;;0;;;;0
Narva Kunstikool;8244512;61211223748;Pobežimova Jekaterina;49107072255;Lubnevskaja Juliana;-9;;;;0;;;;-9
Narva Kunstikool;8244619;60705092773;Fetisova Stefania;47601053720;Fetisova Anna;0;;;;0;;;;0
Narva Kunstikool;8244813;60511233718;Andrejeva Aljona;47609043720;Andrejeva Natalja;-37,74;;;;0;;;;-37,74
Narva Kunstikool;8244910;60706093719;Pilags Valeria;46407043713;Pilags Alla;24;29;;;29;24;;;29
Narva Kunstikool;8245113;60612293713;Darmenko Sofja;47911043715;Darmenko Elvira;24;29;;;29;24;;;29
Narva Kunstikool;8245210;60708233744;Teplõhh Emily;37404162210;Teplõhh Kirill;0;;;;0;;;;0
Narva Kunstikool;8245414;61006303711;Madina Karina;48101242214;Madina Jana;-37,74;;;;0;;;;-37,74
Narva Kunstikool;8245511;60303113742;Konoreva Kristina;47005223724;Konoreva Inna;0;;;;0;;;;0
Narva Kunstikool;8246015;60801147026;Leppik Margit;47112242210;Leppik Anna;-10,32;;;;0;;;;-10,32
Narva Kunstikool;8246219;61010050076;Orehhova Aleksandra;48707033719;Orekhova Natalia;-22,87;;;;0;;;;-22,87
Narva Kunstikool;8246316;60609270020;Koreshkova Ekaterina;47605040012;Koreshkova Marina;-7,74;;;;0;;;;-7,74
Narva Kunstikool;8246510;60811153713;Sumarok Aleksandra;38401173713;Sumarok Alexey;0;;;;0;;;;0
Narva Kunstikool;8246617;60710173719;Kulper Veroonika;48805133734;Pankratjeva Viktoria;24;29;;;29;29;;;24
Narva Kunstikool;8247218;60903013710;Morozova Varvara;49109093722;Morozova Olesja;24;29;;;29;24;;;29
Narva Kunstikool;8247315;61205103711;Rõõmus Julia;48001225711;Rõõmus Olesja;0;;;;0;;;;0
Narva Kunstikool;8247519;60904133724;Pitšugina Zlata;37605093712;Pitšugin Maksim;0;;;;0;;;;0
Narva Kunstikool;8247616;60904143720;Stepanova Sofija;38102253712;Stepanov Vladimir;24;29;;;29;;;;53
Narva Kunstikool;8248013;60906103713;Djakova Vassilina;47001063710;Abramova Jelena;24;29;;;29;24;;;29
Narva Kunstikool;8248615;60909163715;Moissejeva Milena;49009053724;Sorasenidze Anastassia;0;29;;;29;120;;;-91
Narva Kunstikool;8248819;60903143748;Ussanova Sofia;48607093725;Obbuhova Uljana;-12,74;;;;0;;;;-12,74
Narva Kunstikool;8248916;60601303724;Uliyakhova Oxana;47907303712;Uliyakhova Elena;24;29;;;29;;;;53
Narva Kunstikool;8249012;60911013737;Roosi Evelina;48505162210;Dikareva Oksana;24;29;;;29;30;;;23
Narva Kunstikool;8249119;49710043725;Žerebtsova Darja;36902082221;Žerebtsov Dmitri;0;;;;0;;;;0
Narva Kunstikool;8249216;60502122219;Kolobušina Veronika;00075009148;Narva linna sotsiaalabiamet Narva sotsiaaltöökeskus;0;;;;0;;;;0
Narva Kunstikool;8249313;61401080266;Solovjova Taisija;48202093721;Solovjova Olga;17;20;;;20;;;;37
Narva Kunstikool;8249410;51108293725;Dobrynin Vladislav;48012072218;Dobrynina Irina;-21,23;;;;0;;;;-21,23
Narva Kunstikool;8249517;61103103710;Gavrjušina Uljana;48005062211;Gavrjušina Svetlana;-7,23;;;;0;;;;-7,23
Narva Kunstikool;8249614;61006173726;Geveller Sofia;48504013728;Geveller Irina;-20,23;;;;0;;;;-20,23
Narva Kunstikool;8249711;61201096826;Spitsa Mia-Loore;48112146510;Avikson Mari-Liis;24;29;;;29;24;;;29
Narva Kunstikool;8249818;61104303715;Knjazeva Emili;49109263713;Knjazeva Alisa;50;29;;;29;35;;;44
Narva Kunstikool;8249915;61110243710;Kossenko Ksenia;47706063711;Kossenko Irina;20;29;;;29;20;;;29
Narva Kunstikool;8250014;61012083722;Sestašvili Alika;48612253721;Kartašova Darja;-16,1;;;;0;;;;-16,1
Narva Kunstikool;8250218;61203163721;Svetlõšenko Sofia;48601060019;Svetlyshenko Maria;-5;29;;;29;;;;24
Narva Kunstikool;8250412;61204043717;Tšaikina Varvara;47906063728;Tšaikina Olga;0;;;;0;;;;0
Narva Kunstikool;8250519;60710153716;Slepnjova Diana;48412142259;Slepnjova Jekaterina;-9;;;;0;;;;-9
Narva Kunstikool;8250917;60405203710;Niženskaja Anastassija;47810072219;Niženskaja Natalja;-56;;;;0;;;;-56
Narva Kunstikool;8251411;60609013718;Telling Darja;48211103732;Telling Svetlana;48;29;;;29;24;;;53
Narva Kunstikool;8251819;50207203724;Dokudin Ilja;45806293743;Dokudina Olga;-16;;;;0;;;;-16
Narva Kunstikool;8252119;50601313729;Kašlev Kiril;46908163742;Kashleva Natalia;-50,32;;;;0;;;;-50,32
Narva Kunstikool;8252313;60301267010;Raina Diana;36003157017;Raina Aleksandr;-50,32;;;;0;;;;-50,32
Narva Kunstikool;8252410;60107103716;Terentjeva Darja;37103253726;Terentjev Georgi;-0,32;;;;0;;;;-0,32
Narva Kunstikool;8252517;60604193713;Tjutina Nelli;47608203710;Keller Natalia;-32,67;;;;0;;;;-32,67
Narva Kunstikool;8252818;60910163733;Ivanova Uljana;48804203715;Ivanova Anastasia;-37,74;;;;0;;;;-37,74
Narva Kunstikool;8253011;60712243714;Boitsova Julija;49006103713;Vasilevskaya Olga;-32,67;;;;0;;;;-32,67
Narva Kunstikool;8253215;61003263721;Veressinina Darja;48607143718;Borina Olesya;24;29;;;29;24;;;29
Narva Kunstikool;8253312;45206023719;Gordejeva Tamara;45206023719;Gordejeva Tamara;36;43;;;43;36;;;43
Narva Kunstikool;8253419;60705197023;Menšakova Viktoria;48707123718;Tihhomirova Svetlana;24;29;;;29;24;;;29
Narva Kunstikool;8253613;60809243737;Bogomolova Sofija;47802052211;Bogomolova Jana;0;;;;0;;;;0
Narva Kunstikool;8253710;60805013740;Cheberya Mayya;47808152214;Tšeberja Olga;24;29;;;29;24;;;29
Narva Kunstikool;8253914;61005247063;Koroleva Sofia;48409293725;Koroleva Maria;24;29;;;29;24;;;29
Narva Kunstikool;8254117;60710233763;Zurova Anna;48604253716;Zurova Marina;4;29;;;29;24;;;9
Narva Kunstikool;8254311;61102010126;Vlasova Evelina;48209207018;Rahuorg Egge;24;29;;;29;24;;;29
Narva Kunstikool;8254418;61211073727;Grünvald Katalina;48707033722;Grünvald Aleksandra;24;29;;;29;24;;;29
Narva Kunstikool;8254515;61208063718;Kopõlova Veera;47802233718;Grebeškova Tatjana;22;29;;;29;;;;51
Narva Kunstikool;8254612;61208223713;Korabljova Darja;37110112260;Korabljov Roman;-9;;;;0;;;;-9
Narva Kunstikool;8254816;51209223739;Semenov Timur;46102103723;Semenova Svetlana;4;29;;;29;20;;;13
Narva Kunstikool;8254913;51203283718;Shabanov Ivan;48904133727;Shabanova Jelena;0;;;;0;;;;0
Narva Kunstikool;8255116;61202023715;Žuljeva Marjana;47212012279;Žuljeva Tatjana;24;29;;;29;24;;;29
Narva Kunstikool;8255310;61207050062;Gorodnichenko Veronika;48302210079;Gorodnichenko Ekaterina;-19;;;;0;;;;-19
Narva Kunstikool;8255417;61201013714;Demidova Nelli;48705295234;Demidova Jekaterina;24;29;;;29;24;;;29
Narva Kunstikool;8255912;61209223729;Nikitina Sofia;49005293711;Nikitina Veronika;0;;;;0;;;;0
Narva Kunstikool;8256115;51203183723;Šabunov Denis;48605102270;Shabunova Galina;-25,16;;;;0;;;;-25,16
Narva Kunstikool;8256319;51110063711;Yumashkin Sergey;39001150034;Yumashkin Vladimir;24;29;;;29;24;;;29
Narva Kunstikool;8256416;60910182212;Kerbe Karolina;48303292221;Zabalujeva Tatjana;-7,23;;;;0;;;;-7,23
Narva Kunstikool;8256513;60909223715;Balkanskaja Lina;48208063719;Balkanskaja Tatjana;0;;;;0;;;;0
Narva Kunstikool;8256610;61002013713;Finašenkova Ksenija;49005047010;Finašenkova Darja;-12,67;;;;0;;;;-12,67
Narva Kunstikool;8256717;61010193725;Klein Sophie;48608293720;Klein Anastassia;-7,23;;;;0;;;;-7,23
Narva Kunstikool;8256814;61012133748;Korsakova Yana;38705193712;Jeronin Stepan;24;29;;;29;24;;;29
Narva Kunstikool;8257114;61006183733;Upeniek Alisa;48106022213;Upeniek Tatjana;0;;;;0;;;;0
Narva Kunstikool;8257318;60911263729;Vlassova Evelina;47809013716;Vlassova Irina;24;29;;;29;24;;;29
Narva Kunstikool;8257512;60909233722;Varblane Mari-Liis;38710223725;Varblane Aleksandr;-12,9;;;;0;;;;-12,9
Narva Kunstikool;8257619;51008243720;Valitov Daniel;36301013735;Valitov Šamil;-8,23;;;;0;;;;-8,23
Narva Kunstikool;8257716;60906063727;Hiisku Kristina;47504213716;Hiisku Polina;24;29;;;29;24;;;29
Narva Kunstikool;8257813;50901203726;Golubtsov Antoni;47503163739;Golubtsova Zhanna;0;29;;;29;;;;29
Narva Kunstikool;8258113;60409053720;Arbelius Jelizaveta;48107223717;Arbelius Jekaterina;-12,67;;;;0;;;;-12,67
Narva Kunstikool;8258317;60612013733;Eruste Anita;37301312235;Eruste  Vadim;24;29;;;29;24;;;29
Narva Kunstikool;8258414;60604303717;Guryleva Varvara;48310222238;Tšepik Anastassia;20;29;;;29;20;;;29
Narva Kunstikool;8258511;60509293774;Nemets Dana;48308302222;Nemets Aleksandra;48;29;;;29;;;;77
Narva Kunstikool;8258618;60512293732;Razumejeva Jaroslava;48102183717;Razumejeva Tatjana;24;29;;;29;24;;;29
Narva Kunstikool;8258715;50807113710;Sadejev Aleksandr;37905103719;Sadejev Dmitri;-26;29;;;29;;;;3
Narva Kunstikool;8258812;60810162738;Abramson Andra Eliis;48305282257;Abramson Katrina;-16;;;;0;;;;-16
Narva Kunstikool;8258919;60811263715;Efimova Evelina;37712273713;Efimov Vasily;48;29;;;29;;;;77
Narva Kunstikool;8259015;60701063729;Jakovleva Jelizaveta;48307313733;Jakovleva  Natalja;0;;;;0;;;;0
Narva Kunstikool;8259112;50802173727;Petrauskas Daniil;48903022222;Petrauskas Olesja;-12,67;;;;0;;;;-12,67
Narva Kunstikool;8259316;60605233715;Rogova Darja;47105182254;Rogova Elena;-12,67;;;;0;;;;-12,67
Narva Kunstikool;8259413;60706043729;Vink Kristi ;47705252246;Vink Alesja;0;29;;;29;24;;;5
Narva Kunstikool;8259510;60508193719;Pechurova Vladlena;47808272223;EMELIYANOVA MARIA;0;;;;0;;;;0
Narva Kunstikool;8259617;60510223717;Kondrašova Elizaveta;48306113749;Kondrašova Jevgenia;0;;;;0;;;;0
Narva Kunstikool;8259714;60510043719;Švaiger Jana;47312153737;Švaiger Olga;0;;;;0;;;;0
Narva Kunstikool;8259811;60308303717;Maljavina Kristina;48204143735;Maljavina  Tatjana;0;;;;0;;;;0
Narva Kunstikool;8261715;60911153738;Pidvysotskiy Anastasia;48306163729;Pidvysotskiy Jelena;24;29;;;29;24;;;29
Narva Kunstikool;8261812;60001203733;Ginter Kristina;47708243719;Ginter Svetlana;0;;;;0;;;;0
Narva Kunstikool;8261919;60912103730;Petškurova Darja;47302232238;Pechkurova Oksana;24;29;;;29;24;;;29
Narva Kunstikool;8262112;50409293726;Potapenko Maksim;47503153711;Orlova Irina;-37,74;;;;0;;;;-37,74
Narva Kunstikool;8262219;61001153720;Rudnitskaja Evelina;48504072239;Rudnitskaja Olga;0;;;;0;;;;0
Narva Kunstikool;8262413;61003023725;Oborotova Sofia;47412193713;Pestova Marina;24;;;;0;24;;;0
Narva Kunstikool;8262510;61003033710;Virolainen Elina;47408143726;Virolainen Jelena;48;29;;;29;72;;;5
Narva Kunstikool;8262617;61003123731;Gusseva Margarita;48306293734;Gusseva Jekaterina;24;29;;;29;26;;;27
Narva Kunstikool;8263315;61007163724;BLINOVA VIKTORIA;48509183711;Blinova Olesja;0;;;;0;;;;0
Narva Kunstikool;8263616;61008053716;Semjonova Jekaterina;48305062242;Kaidalova Julia;24;;;;0;;;;24
Narva Kunstikool;8263713;61008180109;Stavrovitš Maria;48204283736;Samuilova Natalja;-8,23;;;;0;;;;-8,23
Narva Kunstikool;8263917;60911043725;Rulkova Evelina;45412173717;Korbi Liidia;-12,67;;;;0;;;;-12,67
Narva Kunstikool;8264110;61101193740;Popova Eva;48912263715;Koževnikova Katerina;24;29;;;29;24;;;29
Narva Kunstikool;8264217;61102072739;Aleksejeva Jekaterina;46207193715;Alekseeva Svetlana;-22,87;;;;0;;;;-22,87
Narva Kunstikool;8265012;61109193736;Persitskaja Taissija;48709063728;Persitskaya Evganiya;-2,1;;;;0;;;;-2,1
Narva Kunstikool;8267117;60204253712;Kublitskaja Maria;36704303718;Kublitski Aleksandr;0;;;;0;;;;0
Narva Kunstikool;8267214;61012273727;Sazonova Sofija;48803283716;Sazonova Kristina;24;29;;;29;24;;;29
Narva Kunstikool;8267311;61012143711;Umova Amelia;48906233732;Tonkonogova Natalia;9;29;;;29;29;;;9
Narva Kunstikool;8267418;50810107040;Fadejev  David;48403130019;Troshina Kateryna;-9,5;;;;0;;;;-9,5
Narva Kunstikool;8267515;50810107051;Fadejev  Kirill;48403130019;Troshina Kateryna;-9,5;;;;0;;;;-9,5
Narva Kunstikool;8267612;61112233713;Andreeva Anna;47711243721;Andrejeva  Julia ;17;29;;;29;;;;46
Narva Kunstikool;8267719;61101023729;Braim Katarina;48507163729;Braim Julia;0;;;;0;;;;0
Narva Kunstikool;8267816;60907313737;Jevtjuškina Anastasija;47912033713;Jevtjuškina Galina;0;29;;;29;;;;29
Narva Kunstikool;8267913;60909223726;Nikiforova Kira;49003123712;Nikiforova Svetlana;24;29;;;29;24;;;29
Narva Kunstikool;8268019;61202283736;Osmolovskaja Lika;48112143726;Osmolovskaja Julia;24;29;;;29;24;;;29
Narva Kunstikool;8268116;51201253717;Pomelov Arseni;48506093717;Martõnova Tstjana;0;;;;0;;;;0
Narva Kunstikool;8268213;51008123711;Samburenko Matvei;48605203725;Samburenko Jelizaveta;0;;;;0;;;;0
Narva Kunstikool;8268310;60808283716;Sidorova Natalja;48005312216;Sidorova Elvira;0;;;;0;;;;0
Narva Kunstikool;8268417;61403010107;Brjuhhova Violetta;48901132225;Zolina Svetlana;-56,33;;;;0;;;;-56,33
Narva Kunstikool;8268514;51405130191;Evstigneev Grigorii;38110280050;Evstigneev Aleksei;-6,33;;;;0;;;;-6,33
Narva Kunstikool;8268611;61405290174;Frants Emilia;48709062219;Frants Olga;0;;;;0;;;;0
Narva Kunstikool;8268718;61404100079;Gorodnichenko Viktoria;48302210079;Gorodnichenko Ekaterina;0;;;;0;;;;0
Narva Kunstikool;8268815;61411020119;Karjalainen Aleksandra;49311023720;Karjalainen Viktoria;-6,33;;;;0;;;;-6,33
Narva Kunstikool;8268912;61401200092;Ossipova Miroslava;47903282230;Ossipova Julia;-38,46;;;;0;;;;-38,46
Narva Kunstikool;8269018;61401290132;Sadekova Sofia;48012143734;Sadekova Irina;-0,03;;;;0;;;;-0,03
Narva Kunstikool;8269115;61408160136;Sviridova Arina;47610213714;Sviridova Irina;17;20;;;20;17;;;20
Narva Kunstikool;8269212;61410280124;Žarkova Nelli;49003283727;Zharkova Yulia;17;20;;;20;17;;;20
Narva Kunstikool;8269319;61406250162;Vinogradova Lada;47702197011;Jevgenjeva Jelena;34;20;;;20;;;;54
Narva Kunstikool;8269416;61308010205;Aleksejeva Uljana;48410263723;Aleksejeva Maria;0;;;;0;;;;0
Narva Kunstikool;8269513;61309270133;Aleksina Amelia;48302272246;Aleksina Viktoria;55,67;;;;0;;;;55,67
Narva Kunstikool;8269911;61308160224;Grigaite Evelina;48807043729;Grige Olga;0;;;;0;;;;0
Narva Kunstikool;8270117;51309300177;Lobetski Dmitri;38605212216;Lobetski Vjatseslav;17;20;;;20;;;;37
Narva Kunstikool;8270214;61306280310;Lovaris Jasmine Raphaella;48909193717;Smirnova Irina;15;20;;;20;15;;;20
Narva Kunstikool;8270311;61309170301;Matina Polina;38805092211;Matin Igor;34;20;;;20;34;;;20
Narva Kunstikool;8270418;61310040016;Polozova Milana;49107230027;Polazava Maryana;34;20;;;20;34;;;20
Narva Kunstikool;8270515;61303240028;Alandži Ksenia;48812112217;Alandzhi Anastasia;17;20;;;20;34;;;3
Narva Kunstikool;8270612;61304160096;Lutšinskaja Polina;47911233731;Luchinskaya Marina;0;;;;0;;;;0
Narva Kunstikool;8270719;61305230195;Russu Assol;48005153721;Horohordina Natalja;-18;20;;;20;;;;2
Narva Kunstikool;8270816;51305150136;Toropov Mark;48704173716;Toropova Victoria;0;;;;0;;;;0
Narva Kunstikool;8271718;60201173749;Tšistjakova Darja;47403083723;Tšistjakova  Jelena;-11;;;;0;;;;-11
Narva Kunstikool;8275015;60406053738;Lerner  Jelizaveta;37307162211;Lerner Mihhail;0;;;;0;;;;0
Narva Kunstikool;8281119;60311210021;Gladysheva Marija;47012090051;Gladysheva Tatjana;-8,52;;;;0;;;;-8,52
Narva Kunstikool;8281614;60511153726;Aleksejeva Varvara;37504183714;Aleksejev Igor;-37,57;;;;0;;;;-37,57
Narva Kunstikool;8286619;60506103723;Tšernova Nadežda;47801013731;Tšernova Svetlana;-50,32;;;;0;;;;-50,32
Narva Kunstikool;8287113;50706073716;Trenin Timofei;47808064213;Trenina Jekaterina;-0,01;;;;0;;;;-0,01
Narva Kunstikool;8287210;60512133717;Kurotškina Polina;47110222229;Kurotškina Svetlana;-50,32;;;;0;;;;-50,32
Narva Kunstikool;8287317;60501313728;Zamahhova Kristina;48010273731;Zamakhova Natalia;-70,32;;;;0;;;;-70,32
Narva Kunstikool;8288510;60308123726;Bolšakova Marija;47511192213;Tatjana Bolšakova;-12,58;;;;0;;;;-12,58
Narva Kunstikool;8288714;60802013724;Evsina Marija;46603222210;Korotkova Irina;-15;;;;0;;;;-15
Narva Kunstikool;8290210;60712072715;Yakovleva Alesja;45710073721;Stepanova Svetlana;0;;;;0;;;;0
Narva Kunstikool;8290317;60505053736;Galkina Natalja;47710073714;Galkina Natalja;-2,99;;;;0;;;;-2,99
Narva Kunstikool;8290511;60702123712;FEDORTSEVA ANNA;37906023710;Fedortsev Aleksei;0;29;;;29;;;;29
Narva Kunstikool;8290715;60809077124;Voinski Evelina;46211143720;Vorobjova Vassilina;-24,5;;;;0;;;;-24,5
Narva Kunstikool;8291617;47707112211;Anto Elena;47707112211;Anto Elena;36;43;;;43;36;;;43
Narva Kunstikool;8292111;45305203715;Kostjukevitš Jelena;45305203715;Kostjukevitš Jelena;36;43;;;43;36;;;43
Narva Kunstikool;8292616;50711133728;Agapov Radion;47108243712;Agapova Olga;24;29;;;29;24;;;29
Narva Kunstikool;8293819;60912153732;Iljina Alisa;48912063747;Iljina Elena;-12,67;;;;0;;;;-12,67
Narva Kunstikool;8294119;61209103731;Kulakovskaja Alisia;48910013713;Kulakovskaja Aleksandra;-25,16;;;;0;;;;-25,16
Narva Kunstikool;8294711;45703103755;Skubi Svetlana;45703103755;Skubi Svetlana;0;;;;0;;;;0
Narva Kunstikool;8295516;60601163710;Petuhova Alisa;37506150364;Petuhov Denis;0;;;;0;;;;0
Narva Kunstikool;8295817;60708053724;Khramtsova Eleanora;48306223729;Khramtsova Irina;28;34;;;34;28;;;34
Narva Kunstikool;8295914;46702043721;Surikova Nadežda;46702043721;Surikova Nadežda;-1,67;;;;0;;;;-1,67
Narva Kunstikool;8296719;60507303718;Pärnoja Anneli;47609012267;Julia Rostenko;-50,32;;;;0;;;;-50,32
Narva Kunstikool;8296816;60802263727;Barch Charlotte;48303222253;Barch Liina;24;29;;;29;24;;;29
Narva Kunstikool;8296913;50911157050;Galimov Barit;47810312245;Yakub Natalia;-37,74;;;;0;;;;-37,74
Narva Kunstikool;8297116;50807043736;Zavjalov Ivan;39803063735;Bašurov Dmitri;0;;;;0;;;;0
Narva Kunstikool;8297310;60510083714;Grishina Ksenija;47303023711;Lazareva Natalja;0;;;;0;;;;0
Narva Kunstikool;8297417;51509080133;Belkov Artjom;49006273724;Belkova Ksenia;10;;;;0;10;;;0
Narva Kunstikool;8297514;61306010098;Matsi Eveliina;48108173734;Matsi Olga;0;;;;0;;;;0
Narva Kunstikool;8297611;61109100138;Osmanova Tayra;45611113720;Osmanova Khasyane;0;;;;0;;;;0
Narva Kunstikool;8297718;50902203710;Travitski German;48109142248;Travinski Ljudmila;0;;;;0;;;;0
Narva Kunstikool;8297815;61110273710;Denissenko Anna;36712052220;Denissenko Fedor;0;29;;;29;;;;29
Narva Kunstikool;8297912;61501070240;Parfenova Milena;38908113710;Parfenov Aleksandr;12;14;;;14;12;;;14
Narva Kunstikool;8298018;61412260115;Bogdanova Polina;37909303729;Bogdanov Sergei;0;;;;0;;;;0
Narva Kunstikool;8298115;61006183722;Kalev Anneli;48802243716;Kalev Ksenia;24;29;;;29;24;;;29
Narva Kunstikool;8298212;51511040190;Anufrijev Artjom;48404093715;Anufrijeva Aleksandra;0;;;;0;;;;0
Narva Kunstikool;8298319;50903313716;Tšaikin Ivan;47906063728;Tšaikina Olga;0;;;;0;;;;0
Narva Kunstikool;8298416;61501180122;Feofanova Polina;48306043713;Feofanova Tatjana;12;14;;;14;26;;;0
Narva Kunstikool;8298513;61502100061;Krjukova Viktoria;38904182219;Krjukov Maksim;0;;;;0;;;;0
Narva Kunstikool;8298610;61008060035;Galperman Mikaela;48707083721;Galperman Olga;0;;;;0;;;;0
Narva Kunstikool;8298717;51107133727;Kordontšuk Kristo;48309302238;Kordontšuk Aljona;24;29;;;29;;;;53
Narva Kunstikool;8298814;49902103742;Krjukova Antonina;49902103742;Krjukova Antonina;0;;;;0;;;;0
Narva Kunstikool;8298911;60708300019;Reva Daria;47510110137;Reva Yevheniia;0;;;;0;;;;0
Narva Kunstikool;8299017;60708300027;Reva Kateryna;47510110137;Reva Yevheniia;0;29;;-29;0;;;;0
Narva Muusikakool;8300113;50905053714;Šabanov Maksim;48201092229;Šabanova Jevgenia;0;29;-29;;0;24;;;-24
Narva Muusikakool;8301219;61004133721;Pirk Elizaveta;47907213732;Chatkina Olga;6;11;;;11;15;;;2
Narva Muusikakool;8302014;61210243724;Litvinjuk Maria;38002103712;Litvinjuk Andrei;0;29;;;29;;;;29
Narva Muusikakool;8302111;60112153729;Anderžanova Jelizaveta;47504193722;Anderžanova Olga;-17,15;;;;0;;;;-17,15
Narva Muusikakool;8302218;61303280176;Istratova Nika;48501273712;Istratova Jelena;28,5;34,5;;;34,5;28,5;;;34,5
Narva Muusikakool;8302810;51005313712;Sahharov Jegor;37703152240;Sahharov Aleksei;24;29;;;29;;;;53
Narva Muusikakool;8303411;60411083727;Ashlapova Anna;48102062210;Ashlapova Jelena;-7;;;;0;;;;-7
Narva Muusikakool;8304012;60705163722;Lazareva Vasilina;48006153724;Levochkina Evgeniya;36;43;;;43;36;;;43
Narva Muusikakool;8304216;50501123722;Khokhlov Alekisei;48011113729;Golovko Vita;-10,39;;;;0;;;;-10,39
Narva Muusikakool;8304313;60808113716;Tšuševa Anastassia;48206192238;Lulla Julia;-20;;;;0;;;;-20
Narva Muusikakool;8304410;50805063729;Porošin Arseni;47610053719;Matsijanskaite Virginia;0;;;;0;;;;0
Narva Muusikakool;8304711;60706263711;Yagodina Anna;36102233716;Oskolkov Jevgeniy;0;;;;0;;;;0
Narva Muusikakool;8304818;50708133726;Drozdov Viktor;48704283718;Shevtsova Olga;0;;;;0;;;;0
Narva Muusikakool;8304915;61107093720;Belova Olesja;48303313724;Belova Olga;24;29;;;29;24;;;29
Narva Muusikakool;8305011;60805193713;Senitšenkova Eva;47503253717;Gološeva Natalja;0;;;;0;;;;0
Narva Muusikakool;8305312;60811043722;Krylova Ksenia;46011223717;Krylova Elena;-27;;;;0;;;;-27
Narva Muusikakool;8305516;60509273758;Voronina Antonina;48502193736;Voronina Irina;-140,83;;;;0;;;;-140,83
Narva Muusikakool;8305613;51202080057;Vasiliev Roman;37809123739;Vasiliev Dmitry;0;36;;;36;;;;36
Narva Muusikakool;8305710;51109300258;Roslialov Grigorii;48603040066;Rosliakova Anastasiia;-5;;;;0;;;;-5
Narva Muusikakool;8305914;60410293720;Zagarskih Aleksandra Katarina;37110183728;Zagarskih Vjatšeslav;0;;;;0;;;;0
Narva Muusikakool;8306010;50710083730;FESHCHENKO ALEKSANDR;47701313724;OGNJOVA JELENA;0;;;;0;;;;0
Narva Muusikakool;8306117;50901123723;Malovanenko Konstantin;48302017014;Malovanenko Jekaterina;48;29;;;29;120;;;-43
Narva Muusikakool;8307019;50612213722;Leonov Aleksandr;47306033711;Leonova Tatjana;0;;;;0;;;;0
Narva Muusikakool;8309114;50906253717;Ivkin Semjon;47202103728;Ivkina Svetlana;24;29;;;29;24;;;29
Narva Muusikakool;8309318;61211063720;Zaika Gloria;47412173732;Zaika Natalja;-1,23;36;;;36;;;;34,77
Narva Muusikakool;8309415;61106163733;Kaljumäe Aia;46609290011;Zhuravskaya Elena;0;;;;0;;;;0
Narva Muusikakool;8309512;51008013715;Zaytsev Matias;47612292250;Zubkova Ekaterina;-4;29;;;29;;;;25
Narva Muusikakool;8309619;60408073729;Davõdova  Jekaterina;47511262213;Davõdova Jelena;0;;;;0;;;;0
Narva Muusikakool;8309716;51001083712;Mazanov Danila;47504073724;Mazanova Tatiana;-20;;;;0;;;;-20
Narva Muusikakool;8310116;50903283726;Issakov Nikita;48305272228;Kantemirova Julia;24;29;;;29;24;;;29
Narva Muusikakool;8310213;50906253720;Matjušin Daniil;47908013725;Matyushina Elena;30;36;;;36;25;;;41
Narva Muusikakool;8310310;60411103743;Dõrina Anastassija;47001162239;Dyrina Valentina;-10,61;;;;0;;;;-10,61
Narva Muusikakool;8310417;60702213722;Pavlova Anna;48103033736;Pavlova Maria;35,5;43;;;43;35,5;;;43
Narva Muusikakool;8310514;60907237134;Barsukova Nadežda;48309283710;Barsukova Antonina;-32,67;;;;0;;;;-32,67
Narva Muusikakool;8310718;60811213713;Sizova Tatjana;48009293718;Sizova Natalja;28,5;34,5;;;34,5;28,5;;;34,5
Narva Muusikakool;8310815;60712033717;Jurna Marja;39701043719;Jurna Maksim;-40;;;;0;;;;-40
Narva Muusikakool;8311018;61404070034;Zueva Arina;48306173714;Zueva  Anna;0;;;;0;;;;0
Narva Muusikakool;8311115;60601173717;Zaozerskaja Marcela;46409293715;Zaozerskaja Galina;-40;;;;0;;;;-40
Narva Muusikakool;8311212;60109213717;Raudsepp Ingrid;47702113728;Raudsepp Tatjana;0;;;;0;;;;0
Narva Muusikakool;8312211;61207223719;Džariašvili Darina;48008203727;Džariašvili Natalja;24;29;;;29;24;;;29
Narva Muusikakool;8312318;50801153726;Põrjajev Aleksandr;37403073715;Põrjajev Vladimir;-14;;;;0;;;;-14
Narva Muusikakool;8312716;51209203714;Egorov Daniel;38710033731;Egorov Ivan;30;36;;;36;30;;;36
Narva Muusikakool;8312910;51209013731;Fevraljov Aleksei;48903253720;Podkletnova Ksenia;60;36;;;36;60;;;36
Narva Muusikakool;8313016;61102163713;Žukova Sofja;47510172260;Žukova Anna;24;29;;;29;24;;;29
Narva Muusikakool;8313113;61309300036;Gordejeva Elana;38403303752;Gordejev Sergei;-75,83;36;;;36;;;;-39,83
Narva Muusikakool;8313511;61005193724;Garafutdinova Sofia;48003243730;Garafutdinova Tatjana;0;;;;0;;;;0
Narva Muusikakool;8313618;61005193713;Garafutdinova Ksenia;48003243730;Garafutdinova Tatjana;0;;;;0;;;;0
Narva Muusikakool;8313715;61301250156;Grigorjeva Arina;48910223710;Titova Svetlana;24;29;;;29;24;;;29
Narva Muusikakool;8313812;51101093711;Barinov  Deniss;47908223711;Barinova Nadežda;24;29;;;29;24;;;29
Narva Muusikakool;8313919;51106193731;Knjazev Semjon;47907212212;Knjazeva Jekaterina;-164,2;29;;;29;;;;-135,2
Narva Muusikakool;8314112;51104163711;Goodman Evan;48710273717;Goodman Ekaterina;65;39,5;;;39,5;70;;;34,5
Narva Muusikakool;8314219;60612073731;Gubaydullina Azalia;48512253718;Gubaydullina Irina;0;;;;0;;;;0
Narva Muusikakool;8314316;50912193726;Kuzmin Nikolai;47102020296;Kuzmina Aleksandra;0;29;;;29;;;;29
Narva Muusikakool;8314413;60402143728;Turks Diana anastassija;48001023727;Turks Kristina;-7;;;;0;;;;-7
Narva Muusikakool;8314510;60909243729;Rozhkova  Inessa;48705082758;Kondratjeva Julia;-40;;;;0;;;;-40
Narva Muusikakool;8315810;51008103727;Golub Aleksei;48801070043;Golub Yana;24;29;;;29;24;;;29
Narva Muusikakool;8316110;60904203716;Šurmina Margarita;37510082238;Šurmin Viktor;24;29;;;29;24;;;29
Narva Muusikakool;8316217;51204283712;Hütt Mark;48507272233;Hütt Tatjana;-3,73;;;;0;;;;-3,73
Narva Muusikakool;8316314;60808113749;Ramenskaja Sofija;47905043720;Ramenskaja Jelena;95,5;29;;;29;;;;124,5
Narva Muusikakool;8316712;60802123715;Volkova Alina;47605033715;Volkova  Marina;0;;;;0;;;;0
Narva Muusikakool;8316819;60804133721;Titova Alina;47306172214;Titova Natalia;0;;;;0;;;;0
Narva Muusikakool;8316916;60803013718;Luik  Karina;47508123726;Luik Maria;0;;;;0;;;;0
Narva Muusikakool;8317012;60810083723;Pirk Olivia;48010163716;Pirk Olga;30;36;;;36;30;;;36
Narva Muusikakool;8317119;60707202820;Petrova Esfir;47006013721;Petrova Zoja;0;;;;0;;;;0
Narva Muusikakool;8317216;60805064716;SIBILEVA DARJA;47911222215;STROTŠENKOVA TATJANA;0;;;;0;;;;0
Narva Muusikakool;8317313;60512063743;Perova Polina;48002123727;Vesselova Irina;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8317410;60708263710;Püdja Elisabet;47406063713;Püdja Irina;0;;;;0;;;;0
Narva Muusikakool;8317517;60607313739;Zholudova Anna;46206103724;Zholudova Vera;0;;;;0;;;;0
Narva Muusikakool;8317711;60808103731;Bažutova Sabina;47712292219;Bažutova Oksana;-14;;;;0;;;;-14
Narva Muusikakool;8317818;60601103712;Jurna Kristina;39701043419;Jurna Maksim;-70;;;;0;;;;-70
Narva Muusikakool;8318011;60112253725;Kalistratova Anna;37005273714;Kalistratov Vladimir;-17,15;;;;0;;;;-17,15
Narva Muusikakool;8318312;50805127097;Sjomkin Anton;37907063710;Sjomkin Anton;0;;;;0;;;;0
Narva Muusikakool;8318516;50702273719;Ivanov Juri;48411263717;Ivanova Elvira;0;;;;0;30;;;-30
Narva Muusikakool;8318613;50802013712;Ivanov Andrei;48411263717;Ivanova Elvira;0;;;;0;;;;0
Narva Muusikakool;8318710;61104263738;Kamõsheva Sofia;47512263723;Kamõsheva  Jelena;48;29;;;29;;;;77
Narva Muusikakool;8319117;49901143721;Filatova Darja;47502103726;Filatova Galina;-14;;;;0;;;;-14
Narva Muusikakool;8320517;61012013739;Kitajevski Simona;38106133723;Kitajevski Pavel;24;29;;;29;24;;;29
Narva Muusikakool;8321419;61302110095;Klimova Anastasia;48909132210;Klimova Viktoria;0;;;;0;;;;0
Narva Muusikakool;8321817;61206053756;Kruchinina Kristina;49002052213;Kruchinina Viktoria;4,5;34,5;;;34,5;40;;;-1
Narva Muusikakool;8322117;51212043710;Getalov Matvei;47902153718;Solovjova Oksana;-20;;;;0;;;;-20
Narva Muusikakool;8323417;61308010205;Aleksejeva Uljana;48410263723;Aleksejeva Maria;-32,67;;;;0;;;;-32,67
Narva Muusikakool;8324212;61308100237;Nevzorova Daniella;49106063727;Nevzorova Ekaterina;24;29;;;29;;;;53
Narva Muusikakool;8324319;61302120025;Mishchenko Darja;48311163723;Korotina Natalia;-50,32;;;;0;;;;-50,32
Narva Muusikakool;8324911;61208133725;Belova Sofia;48805053715;Belova Ljubov;30;36;;;36;30;;;36
Narva Muusikakool;8325415;51206253712;Zuev Artemi;48306173714;Zueva  Anna;0;;;;0;;;;0
Narva Muusikakool;8325716;61012123719;Ussoltseva Jana;48412227018;Ussoltseva Jelena;24;29;;;29;24;;;29
Narva Muusikakool;8325813;61108280097;Krause Mia kamila;48409143711;Krause Olga;0;;;;0;;;;0
Narva Muusikakool;8326016;61303250068;Kisseljova Vera;48104083710;Kisseljova Jekaterina;-17,61;;;;0;;;;-17,61
Narva Muusikakool;8326618;60404033736;Kuzmina Anastassija;47304152212;Kuzmina Marina;-17,61;;;;0;;;;-17,61
Narva Muusikakool;8326715;51203023719;Polunin Lev;47207273731;Polunina Olga;28,5;34,5;;;34,5;28,5;;;34,5
Narva Muusikakool;8326812;51101313728;Kongo Martin;47507193715;Pavlova Natalja;0;;;;0;;;;0
Narva Muusikakool;8326919;51203073721;Davõdovski Bogdan;48612203730;Davõdovskaja Darja;48;29;;;29;;;;77
Narva Muusikakool;8327219;51001203712;Gribov  Jevsei;47105173734;Gribova Svetlana;-40;;;;0;;;;-40
Narva Muusikakool;8327413;61001093742;Luik Vladislava;47608273715;Luik Jelena;60;36;;;36;;;;96
Narva Muusikakool;8327811;61001053714;Tšurbakova Vanessa;48603073713;Tšurbakova Veronika;0;36;-36;;0;;;;0
Narva Muusikakool;8327918;60711223728;Tšurbakova Daniela;48603073713;Tšurbakova Veronika;0;36;-36;;0;;;;0
Narva Muusikakool;8328014;60809193711;Kurašova Valeria;37603173716;Kurašov Sergei;24;29;;;29;24;;;29
Narva Muusikakool;8328111;60903093711;Komissarova  Vladislava;47712073713;Komissarova Valentina;-32,67;;;;0;;;;-32,67
Narva Muusikakool;8330316;39910223733;Säde Artur;45912013728;Säde Larissa;0;;;;0;;;;0
Narva Muusikakool;8330413;60304093718;Lasberg Olesja;36702062212;Lasberg Raino;-11,43;;;;0;;;;-11,43
Narva Muusikakool;8330617;50111303712;Klimenkov Jefim;46809173729;Klimenkova Aleksandra;-1,04;;;;0;;;;-1,04
Narva Muusikakool;8330918;50202193712;Orava Vladimir;47007062219;Orava Natalia;-11,43;;;;0;;;;-11,43
Narva Muusikakool;8331014;50301253721;Vangonen Paul;37304222218;Vangonen Anatoli;-20;;;;0;;;;-20
Narva Muusikakool;8331810;49910193711;Šeljahhovska Polina;46403013716;Šeljahhovska Tatjana;0;;;;0;;;;0
Narva Muusikakool;8333119;51310070208;Mihhailov Jaroslav;48606173734;Toropova Olga;0;;;;0;;;;0
Narva Muusikakool;8333216;50202283733;Küttis Martin-Allar;46608163722;Küttis Natalja;-25;;;;0;;;;-25
Narva Muusikakool;8333915;61112073718;Mihhailova Darina;38110133720;Mihhailov Artjom;28,5;34,5;;;34,5;28,5;;;34,5
Narva Muusikakool;8334516;60102043713;Tšudakova Darina;47110072231;Tšudakova Nelli;-26;;;;0;;;;-26
Narva Muusikakool;8338017;60108257020;Tsavelidze Ksenia;47801300021;Tsavenidze Natalia;-7;;;;0;;;;-7
Narva Muusikakool;8338716;61412290261;Nikandrova Ksenija;49401193720;Nikandrova Kristina;0;;;;0;;;;0
Narva Muusikakool;8339210;60304073717;Nikiforova Jelena;48112032215;Nikiforova Julia;-28;;;;0;;;;-28
Narva Muusikakool;8339919;60007213766;Poltarakova Veronika;35605043739;Russkihh Viktor ;0;;;;0;;;;0
Narva Muusikakool;8348214;50405253733;Sobolev Konstantin;47106212216;Soboleva Elena;0;;;;0;;;;0
Narva Muusikakool;8348719;60510083725;Oganesjan Lidia;35912033741;Oganesjan Ruben;0;;;;0;;;;0
Narva Muusikakool;8348816;60507227039;Nazarova Maria;45507182217;Nazarova Liidia;9;11;;;11;9;;;11
Narva Muusikakool;8348913;50010293728;Pavlenko Martin;46911263728;Pavlenko Lena;-20;;;;0;;;;-20
Narva Muusikakool;8350613;60310303758;Koop Evelina;47207272734;Koop Jelena;0;;;;0;;;;0
Narva Muusikakool;8351311;50202193712;Orava Vladimir;47007062219;Orava Natalia;0;;;;0;;;;0
Narva Muusikakool;8354512;50408033711;Kreyvald Dmitri;37303250022;Kreyvald Valery;0;;;;0;;;;0
Narva Muusikakool;8355715;51311040042;Prohhorenko Andrei;47712273725;Prohhorenko Olga;-156,23;36;-36;;0;;;;-156,23
Narva Muusikakool;8356015;50206263717;Kreyvald Evgeni;37303250022;Kreyvald Valery;0;;;;0;;;;0
Narva Muusikakool;8357111;50605253717;Ratsevitš Mark;48311273710;Furman Natalia;30;36;;;36;30;;;36
Narva Muusikakool;8357315;50511023742;Lebedev Pavel;47703253723;Meng Galina;-10,32;;;;0;;;;-10,32
Narva Muusikakool;8358314;60410033713;Reinsalu Sille;47704043731;Reinsalu Jelena;0;;;;0;;;;0
Narva Muusikakool;8365611;50706133727;Knjazev Timofei;47907212212;Knjazeva Jekaterina;0;;;;0;;;;0
Narva Muusikakool;8365912;50502053719;Krutov Maxim;48007293719;Muraeva Svetlana;-12,78;;;;0;;;;-12,78
Narva Muusikakool;8367017;50601283740;Dmitrijev Timofei;36707263714;Dmitrijev Dmitri;0;;;;0;;;;0
Narva Muusikakool;8367211;60803203723;Aleksina Anastasia;48302272246;Aleksina Viktoria;0;;;;0;;;;0
Narva Muusikakool;8368715;60709023719;Kongo Diana;47507193715;Pavlova Natalja;0;;;;0;;;;0
Narva Muusikakool;8369617;60606293718;Hussainova Sofia;47504032218;Hussainova Zoja;0;;;;0;;;;0
Narva Muusikakool;8370619;60612083738;Sinijärv Alisa;47705313711;Kabanova Natalja;-10;;;;0;;;;-10
Narva Muusikakool;8377612;60708033710;Piskarjova Marija;47401303719;Piskarjova Jekaterina;-38,38;;;;0;;;;-38,38
Narva Muusikakool;8377913;50804152792;Volossov Nikita;48709163723;Volossova Asja;-25,56;;;;0;;;;-25,56
Narva Muusikakool;8378912;50705133711;Ivanov Jevgeni;48002273713;Ivanova  Marina;0;;;;0;;;;0
Narva Muusikakool;8379018;60404173715;Saikonen Marika;47810252217;Saikonen Julia;18;11;;;11;;;;29
Narva Muusikakool;8379814;50501210841;Sedakov Aleksandr;46409172241;Sedakova Anne;-0,42;;;;0;;;;-0,42
Narva Muusikakool;8379911;50803163725;Volkov  Artjom;48509033712;Kippari Natalja;0;;;;0;;;;0
Narva Muusikakool;8381019;39606233746;Šturmanov Nikita;39606233746;Sturmanov Nikita;0;;;;0;;;;0
Narva Muusikakool;8382416;60809223745;Toropina Alina;48409233721;Toropina Anastasia;0;;;;0;;;;0
Narva Muusikakool;8383114;51501140094;Semenov Miroslav;49108013716;Semenova  Jana;24;29;;;29;36;;;17
Narva Muusikakool;8383211;50707203728;Ude Albert;47805193725;Ude Jelena;0;;;;0;;;;0
Narva Muusikakool;8385413;50905283736;Knjazev Matvei;47907212212;Knjazeva Jekaterina;-184,13;29;;;29;;;;-155,13
Narva Muusikakool;8386917;60707167045;Lohmatova Varvara;47703223713;Lohmatova Žanna;0;;;;0;;;;0
Narva Muusikakool;8387013;60607243710;Donina Jekaterina;47509063731;Donina Natalja;-20;;;;0;;;;-20
Narva Muusikakool;8387110;50301043724;Strekalov Nikita;47811073722;Strekalova Oksana;0;;;;0;;;;0
Narva Muusikakool;8387518;60602163748;Saar Tatjana;47011293713;Saar Zanna;0;;;;0;;;;0
Narva Muusikakool;8387615;50902212720;Kudimov Feodor;37607213711;Kudimov Boris ;0;46,5;;;46,5;;;;46,5
Narva Muusikakool;8387712;50507203711;Stepanov  Nikita;35011223714;Jegorov Nikolai;-50,32;;;;0;;;;-50,32
Narva Muusikakool;8388410;61003263710;Antonenko Alisia;48806143719;Antonenko Kristina;-8;29;;;29;;;;21
Narva Muusikakool;8388517;51002143717;Tysyachnikov Nikita;47308242710;Gusseva Žanna;24;29;;;29;24;;;29
Narva Muusikakool;8388915;60702247045;Sjomkina Anželika;37907063710;Sjomkin Anton;0;;;;0;;;;0
Narva Muusikakool;8389516;60601103712;Jurna Kristina;45206203728;Jürna Ljubov;-10;;;;0;;;;-10
Narva Muusikakool;8391216;60901273710;Rušeljuk Paula;48404064212;Rušeljuk Anna;24;29;;;29;29;;;24
Narva Muusikakool;8391711;50908203717;Ivanov Aleksey;38104207011;Ivanov Andrey;-20,32;;;;0;;;;-20,32
Narva Muusikakool;8391818;50903143714;Issatšenkov Danil;38510112219;Issatšenkov Anton;92;29;;;29;92;;;29
Narva Muusikakool;8391915;50810063730;Belov Ilja;48101222233;Belova Anastassia;24;29;;;29;24;;;29
Narva Muusikakool;8392419;50707167055;Lohmatov Igor;47703223713;Lohmatova Žanna;-3,73;;;;0;;;;-3,73
Narva Muusikakool;8392613;60712213748;Gorškova Lija;48706293713;Gorškova Anastassia;0;;;;0;;;;0
Narva Muusikakool;8393010;61009222759;Goncharova Anastasia;47504243737;Timanova Nadezhda;0;29;;;29;;;;29
Narva Muusikakool;8393117;60707033757;Tšuševa  Anna;48206192238;Lulla Julia;-32,67;;;;0;;;;-32,67
Narva Muusikakool;8393311;60812253713;Astapova Elana;48112023717;Mikheeva Arina;0;29;;;29;24;;;5
Narva Muusikakool;8393418;51005097226;Vasiliev Kirill;48412312261;Vasilieva Natalia;0;36;;;36;;;;36
Narva Muusikakool;8393612;60803023714;Dmitrijeva Eva;48612183714;Dmitrijeva Yulia;0;;;;0;;;;0
Narva Muusikakool;8393719;60705193721;Maksimenkova Viktoria;48006240035;Maksimenkova Anastasiya;0;;;;0;;;;0
Narva Muusikakool;8393816;61001143746;Blat Anna;47610202220;Zaitseva Natalja;0;;;;0;;;;0
Narva Muusikakool;8394116;50501103752;Jakovlev Maksim;46608143719;Jakovleva Tatjana;-32,67;;;;0;;;;-32,67
Narva Muusikakool;8394213;60809203713;Pomogaibo Niina;48911133727;Pomogaibo Anastassia;0;29;-29;;0;;;;0
Narva Muusikakool;8394514;51012293729;Šemarin Serafim;48705302227;Šemarina Jekaterina;-28;;;;0;;;;-28
Narva Muusikakool;8394718;61002043734;Parts Emili;47707023732;Parts Teele;57;34,5;;;34,5;;;;91,5
Narva Muusikakool;8394815;50707202818;Petrov Samuil;47006013721;Petrova Zoja;0;;;;0;;;;0
Narva Muusikakool;8395018;60507233711;Shchuchkina Dariya;47908272226;Shchuchkina Elena;-14;;;;0;;;;-14
Narva Muusikakool;8395416;61007103726;Šiškova Sofja;48708167019;Šiškova Olga;30;36;;;36;30;;;36
Narva Muusikakool;8396114;61011083717;Žavoronkova Milana;37601223721;Žavoronkov Vladimir;28,5;34,5;;;34,5;28,5;;;34,5
Narva Muusikakool;8396211;50907233733;Nefedov Jegor;48305193723;Ložkina Galina;72;29;;;29;72;;;29
Narva Muusikakool;8396512;50904083727;Shkuro Arseni;48302223720;Zahharova Natalja;0;;;;0;;;;0
Narva Muusikakool;8396619;51402020032;Tsarjov Timofei;48403023738;Tsarjova Svetlana;0;;;;0;;;;0
Narva Muusikakool;8396716;60910223751;Slepova Varvara;48002163711;Slepova Daria;24;29;;;29;24;;;29
Narva Muusikakool;8397016;50706083723;Zaozerski Milan ;46409293715;Zaozerskaja Galina;-32,67;;;;0;;;;-32,67
Narva Muusikakool;8397113;61409200044;Vasilieva Irina;37809123739;Vasiliev Dmitry;0;36;;;36;;;;36
Narva Muusikakool;8398811;60804273733;Ivanova Anastasia;48307193722;Ivanova Svetlana;0;;;;0;;;;0
Narva Muusikakool;8399519;50703173718;VANINOV ILJA;46707270348;VANINOVA OLGA;-32,67;;;;0;;;;-32,67
Narva Muusikakool;8400217;61003123731;Gusseva Margarita;48306293734;Gusseva Jekaterina;-75,48;;;;0;;;;-75,48
Narva Muusikakool;8400411;60810162738;Abramson Andra Eliis;48305282257;Abramson Katrina;-20;;;;0;;;;-20
Narva Muusikakool;8401119;60010203710;Babikova Maria;47607273710;Babikova Anastassia;-40,93;;;;0;;;;-40,93
Narva Muusikakool;8401517;61105313716;Novitski Milana;38706153711;Novitski Ivan;-25,83;36;;;36;25;;;-14,83
Narva Muusikakool;8401711;60701307062;Bogovskaja Marianna;48412310256;Bogovskaja Marina;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8402118;60906273735;Belaja Maria;47505273724;Belaya Oksana;-30;36;;;36;;;;6
Narva Muusikakool;8402613;60509273738;Ginter Karina;47708243719;Ginter Svetlana;0;;;;0;;;;0
Narva Muusikakool;8402710;60706013719;Gorbunova Lora;47901233716;Gorbunova Jana;-38,73;;;;0;;;;-38,73
Narva Muusikakool;8402914;60611073715;Jakovleva Anfisa;47208113710;Jakovleva Oksana;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8403010;60406053716;Sergejeva Alina;47801013716;Sergejeva Irina;0;;;;0;;;;0
Narva Muusikakool;8403719;61508010070;Maksimova Vladislava;48211273718;Maksimova Varvara;-14;;;;0;;;;-14
Narva Muusikakool;8404213;60712143730;Homjakova Milana;44810023753;Homjakova Ljudmila;0;36;;;36;;;;36
Narva Muusikakool;8404718;60910022818;Jaggo Ketrin;47209193727;Jaggo Olga;30;36;;;36;30;;;36
Narva Muusikakool;8404912;50501183714;Markov Sergei;47012263730;Markova Veronika;0;;;;0;;;;0
Narva Muusikakool;8405018;60701293718;Pille Meribel;47305170335;Pille Kirsti;0;;;;0;;;;0
Narva Muusikakool;8405513;60701073725;Poltoruhho Darja;48302113736;Poltoruhho Anna;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8405717;60609193716;Sankova Svetlana;37406113716;Sankov Sergei;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8406017;60510022741;Rojak Sonja;48207107013;Rojak Olesja;0;;;;0;;;;0
Narva Muusikakool;8406318;60911023711;Platonova Ksenija;48201062241;Platonova Tatjana;15;36;;;36;;;;51
Narva Muusikakool;8406415;60903293712;Nikitina Anastasia;48301172224;Nikitina Veronika;0;46,5;;;46,5;;;;46,5
Narva Muusikakool;8406512;60609270020;Koreshkova Ekaterina;47605040012;Koreshkova Marina;0;;;;0;;;;0
Narva Muusikakool;8406910;60601133722;Pärtels Alli riin;46908275215;Lausmaa Riina;-62,9;;;;0;;;;-62,9
Narva Muusikakool;8407113;47811293737;Ponomarjova Anastasia;47811293737;Ponomarjova Anastassia;-20;;;;0;;;;-20
Narva Muusikakool;8407317;60903173725;Gugnina Tatiyana;47001043728;Turaeva Liudmila;0;;;;0;;;;0
Narva Muusikakool;8407414;60902257058;Orlova Ustinia;47709083740;Homjakova Sofja;0;36;-36;;0;;;;0
Narva Muusikakool;8407618;49810223715;Gurkina Aleksandra;46403273715;Gurkina Irina;-38,21;;;;0;;;;-38,21
Narva Muusikakool;8407812;39801113718;Pljuško Andreas;39801113718;Plyushko Andreas;-200;;;;0;;;;-200
Narva Muusikakool;8407919;61307190197;Zaitseva Arina;47304142238;Zaitseva Svetlana;-17,61;;;;0;;;;-17,61
Narva Muusikakool;8408015;50211213749;Afanasjev David;46809133712;Afanasjeva Žanna;0;;;;0;;;;0
Narva Muusikakool;8408112;60209113714;Belova Angelina;48211153753;Belova Jekaterina;-25;;;;0;;;;-25
Narva Muusikakool;8408219;50710107015;Tsurkan Roman;36510220234;Tsurkan Roman;0;;;;0;;;;0
Narva Muusikakool;8408811;60611083722;Shevtsova Anna;48708113738;Shevtsova Diana;-140,83;;;;0;;;;-140,83
Narva Muusikakool;8409111;60903263746;Soboleva Amina;47910233715;Soboleva Irina;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8409218;60411233715;Sidorkina Jekaterina;47705273714;Sidorkina Jelena ;36;43;;;43;36;;;43
Narva Muusikakool;8409713;50609053774;Vasilenko Timofei;37108059514;Vassilenko Aleksandr;0;;;;0;;;;0
Narva Muusikakool;8410812;60908172230;Akimova Viktoria;48808192244;Korženevskaja Alevtina;24;29;;;29;24;;;29
Narva Muusikakool;8411015;50212043719;Koort Aleks ;50212043719;Koort Aleks;36;43;;;43;;;;79
Narva Muusikakool;8411112;49704293738;Lerner Alina;37307162211;Lerner Mihhail;0;;;;0;;;;0
Narva Muusikakool;8411219;51007233722;Vesselko Kristian;48107103728;Veselko Irina;40;36;-36;;0;;;;40
Narva Muusikakool;8411316;60706063710;Zhelnova Anastasia;48303073737;Zhelnova Mayya;0;;;;0;;;;0
Narva Muusikakool;8411413;49606010066;Abramova Alina;49606010066;Abramova Alina;0;;;;0;;;;0
Narva Muusikakool;8411510;60308143711;Ivanova Jekaterina;47202233733;Ivanova Dali;-17;;;;0;;;;-17
Narva Muusikakool;8412616;61003063717;Zhelnova Lidia;48303073737;Zhelnova Mayya;-88,33;36;;;36;;;;-52,33
Narva Muusikakool;8412713;50407313710;Aksenov Maksim;47201143718;Aksjonova Svetlana;0;43;;;43;;;;43
Narva Muusikakool;8412810;49901143743;Zubova Anastasia;35811092222;Zubov Nikolai;-13,18;;;;0;;;;-13,18
Narva Muusikakool;8412917;61502220059;Arendi Nicole;48112083726;Maisjuk Olga;36;43;;;43;36;;;43
Narva Muusikakool;8413013;60307053740;Teppo Livia;46910153721;Teppo Maria;0;;;;0;;;;0
Narva Muusikakool;8413217;51612090047;Kordontšuk Mihhail;48309302238;Kordontšuk Aljona;48;29;;;29;24;;;53
Narva Muusikakool;8413712;61105263723;Aleksejeva Vladislava;37607153711;Aleksejev Deniss;30;36;;;36;30;;;36
Narva Muusikakool;8413819;61512120057;Artemjeva  Miroslava;38410073717;Artemjev Aleksandr;0;;;;0;;;;0
Narva Muusikakool;8413916;60810293731;Rosenthal Dominika;47806253719;Altunbas Jelena;0;;;;0;;;;0
Narva Muusikakool;8414119;61705220074;Kukka Aina;49209253731;Kukka Olesya;0;;;;0;;;;0
Narva Muusikakool;8414216;60902052213;Maria Maškova;46202053722;Meštšerjakova Irina;0;36;-36;;0;;;;0
Narva Muusikakool;8414313;61107243719;Andreeva Amalia;47702113729;Mirošnikova Olga;-0,38;;;;0;;;;-0,38
Narva Muusikakool;8414410;61104072738;Alekseeva Emilia;46109122219;Smirnova Juzefta;0;36;-36;;0;;;;0
Narva Muusikakool;8414517;51003250047;Arkhipov Aleksandr;47203230045;Arkhipova Albina;30;36;;;36;;;;66
Narva Muusikakool;8414614;50401143711;ARŽANTSEV DANIIL ;48006182214;IVANOVA OLGA;0;;;;0;;;;0
Narva Muusikakool;8414711;49505273723;Mirzojeva Sabina;49505273723;Mirzojeva Sabina;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8414818;51102263729;Baranov Artjom;49003113716;Babi Inna;30;36;;;36;30;;;36
Narva Muusikakool;8414915;60902223724;Metsma Elina;48606203713;Roos-Metsma Jelena;30;36;;;36;30;;;36
Narva Muusikakool;8415011;51210050150;Barkashev Mark Mikhail;47809240061;Barkasheva Olga;75;;;;0;;;;75
Narva Muusikakool;8415118;50704103729;Jemeljanov Artjom;47306123710;Jemeljanova Tatjana;-15,83;;;;0;;;;-15,83
Narva Muusikakool;8415710;60805013728;Kazakova Darja;48003283736;Kazakova Tatiana;30;36;;;36;30;;;36
Narva Muusikakool;8415817;51407170021;Belozor Pavel;48410272210;Belozor Pavel;30;36;;;36;30;;;36
Narva Muusikakool;8415914;60608307115;Kazakova Anastasia;47810270074;Kazakova Ekaterina;0;36;;;36;30;;;6
Narva Muusikakool;8416010;60706293710;Berestova Anastasia;48102253724;Berestova Darja;0;;;;0;;;;0
Narva Muusikakool;8416117;60606083710;Johannes Francesca;46611232211;Johannes Laine;0;;;;0;;;;0
Narva Muusikakool;8416311;50403133747;Gurõljov Rodion;47805152210;Hozjainova Margarita;0;;;;0;;;;0
Narva Muusikakool;8416719;60803273717;Khomitskaya Milana;48610243715;Trussova Anastassia;0;;;;0;;;;0
Narva Muusikakool;8417310;50802213735;Grigorjev Dmitri;47311273719;Grigorjeva Natalja;0;;;;0;;;;0
Narva Muusikakool;8417417;51210243712;Fenin Ivan;48908043726;Fenina Anna;-10;36;;;36;35;;;-9
Narva Muusikakool;8417912;60801163755;Daško Polina;46910062213;Daško Anna;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8418018;61003230023;Kozhemyakina Varvara;48511133726;Kozhemyakina Vlada;-0,95;;;;0;;;;-0,95
Narva Muusikakool;8418115;50609223727;Boiko Platon;47312033717;Boiko Bela;30;;;;0;30;;;0
Narva Muusikakool;8418212;61203183713;Forstiman Arina;48305312236;Forstiman Julia;60;36;;;36;;;;96
Narva Muusikakool;8418319;51208020121;Kudriashov Ivan;47206113722;Kudriashova Olga;-1,4;29;-29;;0;;;;-1,4
Narva Muusikakool;8418416;51208073746;Khomutov  Roman;49207193743;Khomutova Maria;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8418513;51309020064;Brjakin Timofei;47312163711;Valizer Julia;30;36;;;36;30;;;36
Narva Muusikakool;8418610;50311153729;Pohjaranta Samuil Aleksi;47301203710;Pohjaranta Irina;0;;;;0;;;;0
Narva Muusikakool;8418717;60808083715;Rodionova Lilia;37511223711;Rodionov Aleksandr;0;36;-36;;0;;;;0
Narva Muusikakool;8418814;60710153727;Dmitrijenko Viktoria;47509303729;Dmitrijenko Jelena;0;;;;0;;;;0
Narva Muusikakool;8418911;51109303717;Grati Jaroslav;47910153723;Grati Tatjana;60;36;;;36;30;;;66
Narva Muusikakool;8419017;51506280217;Doroškov Aaron Elisey;48504280057;Doroshkova Maria;0;;;;0;;;;0
Narva Muusikakool;8419114;61002283730;Darja Voronova;47205313729;Raud Elvina;30;36;;;36;;;;66
Narva Muusikakool;8419512;60912172749;Fjodorova Jelizaveta;49004202222;Fjodorova Viktoria;-28;;;;0;;;;-28
Narva Muusikakool;8419716;61507040053;Lazareva  Uljana;48006153724;Levochkina Evgeniya;24;29;;;29;24;;;29
Narva Muusikakool;8419813;61110263746;Feofanova Jelizaveta;48306043713;Feofanova Tatjana;0;;;;0;;;;0
Narva Muusikakool;8419910;50503213731;Egorov Erik;46905312239;Egorova Natalia;60;36;;;36;85;;;11
Narva Muusikakool;8420019;61001213718;Krasavina Sofia;47511203714;Marina Krasavina;30;36;;;36;36;;;30
Narva Muusikakool;8420116;50701223723;Tsõgankov Dmitri;38004193725;Tsõgankov Gennadi;30;36;;;36;;;;66
Narva Muusikakool;8420213;50710083730;FESHCHENKO ALEKSANDR;47701313724;OGNJOVA JELENA;30;36;;;36;30;;;36
Narva Muusikakool;8420310;60706193737;Dobrovolskaja Aleksandra;46405283710;Dobrovolskaja Marina;-62,9;;;;0;;;;-62,9
Narva Muusikakool;8420417;51404270056;Fedotov Aleksandr;49401257010;Fedotova Tatiana;-2,78;;;;0;;;;-2,78
Narva Muusikakool;8420514;61012133737;Norman Elizaveta;37807142212;Norman Ivan;85;;;;0;;;;85
Narva Muusikakool;8420611;61405290174;Frants Emilia;48709062219;Frants Olga;30;36;;;36;30;;;36
Narva Muusikakool;8420718;50701013715;Skvortsov Daniil;48010203713;Skvortsova Natalja;-40;;;;0;;;;-40
Narva Muusikakool;8420815;51305280196;Gorlovitš Aleksandr;48907122261;Gorlovitš Jekaterina;30;36;;;36;30;;;36
Narva Muusikakool;8420912;60509053712;Goncharova Jekaterina;46804113739;Trunova Tatiana;0;;;;0;;;;0
Narva Muusikakool;8421018;50906224729;Ivanichenko Gleb;48203172211;Ivanichenko Irina;-0,83;;;;0;;;;-0,83
Narva Muusikakool;8421115;51109303717;Grati Jaroslav;47910153723;Grati Tatjana;0;;;;0;;;;0
Narva Muusikakool;8421212;61002153725;Lazareva Melissa;48903103712;Lazareva Kristina;30;36;;;36;;;;66
Narva Muusikakool;8421319;61605200085;Grati Lilian;47910153723;Grati Tatjana;60;36;;;36;30;;;66
Narva Muusikakool;8421416;60403233732;Sõtšova Taissija;46809293716;Sõtšova Jelena;0;;;;0;;;;0
Narva Muusikakool;8421814;50707193719;Aseev Ustin;47406133713;Ivantsova Svetlana;0;;;;0;;;;0
Narva Muusikakool;8421911;60402273722;Jadrina Marija;46407272215;Jadrina Jurena;0;;;;0;;;;0
Narva Muusikakool;8422017;61202173712;Tkacheva Varvara;49203243727;Intjasõva Darina;-62,9;;;;0;;;;-62,9
Narva Muusikakool;8422114;60905223728;Grigorjeva Polina;38310302218;Grigorjev Kirill;0;;;;0;;;;0
Narva Muusikakool;8422211;38312022213;Lobanov Igor;38312022213;Lobanov Igor;-25;;;;0;;;;-25
Narva Muusikakool;8422318;50605203759;Gusev Artur Owenta;47411023719;Guseva Tatiana;0;;;;0;;;;0
Narva Muusikakool;8422415;60712143730;Homjakova Milana;44810023753;Homjakova Ljudmila;48;;;;0;;;;48
Narva Muusikakool;8422512;50708193735;Nikitin Maik-Matvei;48301252216;Nukitina Maria;-12;43;;;43;;;;31
Narva Muusikakool;8422619;61411140096;Horeva Anastasia;48204233712;Horeva Viktoria;0;;;;0;;;;0
Narva Muusikakool;8422716;50701157035;Sõtšev Kirill;47701073737;Valašas Ljubov;60;36;;;36;;;;96
Narva Muusikakool;8422910;60611183728;Ljauman  Zoja;46011272210;Ljauman Ljudmila;0;43;;;43;;;;43
Narva Muusikakool;8423016;50905107013;Lugovski  Nikita;47703110222;Tamberg-Lugovskaja Ilona;34,5;41,5;;;41,5;;;;76
Narva Muusikakool;8423113;60903073725;Danjuk Anna;47101203715;Danjuk Irina;0;;;;0;;;;0
Narva Muusikakool;8423210;60909123717;Karavajeva Alia;47101162242;Karavajeva Jelena;0;;;;0;;;;0
Narva Muusikakool;8423317;61102033723;Ignatova Aleksandra;47210173727;Ignatova Tatjana;-30;36;;;36;;;;6
Narva Muusikakool;8423414;61603070086;Horn Anita;49004282212;Horn Sofya;30;36;;;36;30;;;36
Narva Muusikakool;8423511;60308163714;Jarmuhhamedova Ksenija;47808073710;Jarmuhhamedova Marina;0;;;;0;;;;0
Narva Muusikakool;8423919;48708113738;Diana Shevtsova;48708113738;Shevtsova Diana;-14;;;;0;;;;-14
Narva Muusikakool;8424015;48607052221;Jurjeva Anastassia;48607052221;Jurjeva Anastassia;-25;;;;0;;;;-25
Narva Muusikakool;8424112;51109082714;Tarasov Georgi;47404052787;Nõmm Jelena;30;36;;;36;30;;;36
Narva Muusikakool;8424316;61604160115;Maksimova  Milana;48912053729;Maksimova Anna;0;;;;0;;;;0
Narva Muusikakool;8424413;60708313725;Baškirova Jekaterina;47807302219;Baškirova Marjana;0;;;;0;;;;0
Narva Muusikakool;8424510;50301153715;Volotšinkov Maksim;50301153715;Volotšinkov Maksim;0;;;;0;;;;0
Narva Muusikakool;8424617;61405190037;Ivanova Valeria;48010283725;Lavrova Jelena;0;36;;;36;;;;36
Narva Muusikakool;8424714;51012053711;Tulženko Serafim;38910172218;Tulženko Nikolai;9;11;;;11;;;;20
Narva Muusikakool;8425111;49902253740;Auer Laura;35506123722;Auer Sergei;0;;;;0;;;;0
Narva Muusikakool;8425218;61502270126;Jakovenko Marjana;48804173719;Jakovenko Marina;15;36;;;36;60;;;-9
Narva Muusikakool;8425315;51005073725;Pogorževski Arseni;38609203727;Pogorževski Aleksandr;0;;;;0;;;;0
Narva Muusikakool;8425412;51002013723;Sazonov  Mihhail;47910262227;Sazonova Natalja;30;36;;;36;;;;66
Narva Muusikakool;8425810;51001193714;Kravtšenko Timofei;48507272244;Kravtšenko Jekaterina;30;36;;;36;30;;;36
Narva Muusikakool;8425917;60803173733;Rõženkova  Maria;37002013711;Rõženkov Vjatšeslav;0;;;;0;;;;0
Narva Muusikakool;8426110;51608150258;Manda Constantin;48503039512;Tikhomirova Maria;9;11;;;11;9;;;11
Narva Muusikakool;8426217;60706293710;Berestova Anastasia;44701253733;Baranova Svetlana;0;;;;0;;;;0
Narva Muusikakool;8426314;50405133713;Moissejev Dmitri;47803243720;Tjantova Marina;-52,27;;;;0;;;;-52,27
Narva Muusikakool;8426411;50501103752;Jakovlev Maksim;46608143719;Jakovleva Tatjana;30;36;;;36;;;;66
Narva Muusikakool;8426518;60904283710;Lušnikova  Aleksandra;48103062215;Lušnikova Niina;30;36;;;36;30;;;36
Narva Muusikakool;8426615;50903163739;Moskaljov Roman;47206242229;Moskaleva Nadezda;0;36;;;36;;;;36
Narva Muusikakool;8426712;50705232753;Voronin Stepan;48502193736;Voronina Irina;-140,83;;;;0;;;;-140,83
Narva Muusikakool;8426819;60908253712;Ivanova Sofija;37701173742;Ivanov Sergei;30;36;;;36;30;;;36
Narva Muusikakool;8428011;60809263751;Dubik Polina;48211233712;Dubik Veronika;-3,73;;;;0;;;;-3,73
Narva Muusikakool;8428118;60412243727;Blohhina Evelina;36905262212;Blohhin Anatoli;-3,73;;;;0;;;;-3,73
Narva Muusikakool;8428215;50212143714;Chistodelov Ivan;48205063715;Chistodelova Jekaterina;0;;;;0;;;;0
Narva Muusikakool;8429010;51212210188;Kalatšov Kirill;47505103720;Kalatšova Julia;30;36;;;36;30;;;36
Narva Muusikakool;8429214;51710110045;Mašjanov Artjom;38909163728;Mašjanov Dmitri;-7;;;;0;;;;-7
Narva Muusikakool;8429311;60804143745;Korabljova Valerija;37401162217;Korabljov Dmitri;0;;;;0;;;;0
Narva Muusikakool;8429719;50808017099;Pöörman Nikita;45209013716;Pavlova Irina;0;;;;0;;;;0
Narva Muusikakool;8429816;61207163719;Lušnikova Maria;48103062215;Lušnikova Niina;30;36;;;36;30;;;36
Narva Muusikakool;8429913;60805013739;Moldova Lilia;48009153739;Moldova Eva;0;;;;0;;;;0
Narva Muusikakool;8430012;60611073715;Jakovleva Anfisa;47208113710;Jakovleva Oksana;30;36;;;36;;;;66
Narva Muusikakool;8430119;60804097015;Eremina Tereza;47201030039;Eremina Irina;0;;;;0;;;;0
Narva Muusikakool;8430313;61410100074;Miljutinova Julia;49101113719;Miljutinova Tatjana;-75;36;;;36;;;;-39
Narva Muusikakool;8430410;60902113722;Oleksyuk Polina;37512023715;Oleksjuk Oleg;-75;36;;;36;;;;-39
Narva Muusikakool;8430818;50411123734;Cheremisinov Genadi;45401013737;Tarassova Svetlana;-10;;;;0;;;;-10
Narva Muusikakool;8430915;60912013712;Pantjuhhina Mia;48609073710;Pantjuhhina Irina;30;36;;;36;30;;;36
Narva Muusikakool;8431011;50304293731;Kuksov Ilja;48012153728;Kuksova Janina;-14;;;;0;;;;-14
Narva Muusikakool;8431516;51208013715;Saukov Georgi;47112153716;Saukova  Tatiana;12;29;;;29;36;;;5
Narva Muusikakool;8431613;61206013728;Antonova Alisa;48509152234;Antonova Olga;-7;;;;0;;;;-7
Narva Muusikakool;8431710;61407040017;Jakson Anastasia;48210033728;Jakson Anna;60;36;;;36;60;;;36
Narva Muusikakool;8431817;51105160041;Belski Edward;48709173719;Belski Natalja;24;29;;;29;24;;;29
Narva Muusikakool;8432214;60902273726;Puškina Polina;48204233723;Puškina Olga;30;36;;;36;30;;;36
Narva Muusikakool;8432311;50708253713;Jelissejev Aleksei;46705153714;Jelissejeva  Natalja;0;;;;0;;;;0
Narva Muusikakool;8432418;61105310170;Razuk Aleksija;48203162235;Razuk Oksana;24;29;;;29;;;;53
Narva Muusikakool;8432515;51109193713;Bogatov Artjom;46208033727;Bogatova Helena;-3;43;;;43;;;;40
Narva Muusikakool;8432612;60204223746;Ostroushko Jekaterina;46210062214;Tšaštšina Natalja;-11,43;;;;0;;;;-11,43
Narva Muusikakool;8433019;50111023741;Sergejev Sergei;47308063720;Vassilkova Antonina;0;;;;0;;;;0
Narva Muusikakool;8433116;49603223736;Hartšenko Valentina;49603223736;Hartšenko Valentina;0;;;;0;;;;0
Narva Muusikakool;8433213;60705253710;Jermakova Uljana;47411033715;Jermakova Natalja;30;36;;;36;;;;66
Narva Muusikakool;8433310;61206013728;Antonova Alisa;48509152234;Antonova Olga;0;36;;;36;;;;36
Narva Muusikakool;8433514;60510083725;Oganesjan Lidia;46301043724;Tsaturjan Karine;0;;;;0;;;;0
Narva Muusikakool;8433611;60510283726;Klimanova Nadežda;47507233723;Klimanova Karina;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8434018;60708283735;Jakovenko Milena;48502093730;Jakovenko Anastassia;-0,78;;;;0;;;;-0,78
Narva Muusikakool;8434416;61101043710;Komlova Emilia;47802243714;Komlova Olesja;30;36;;;36;30;;;36
Narva Muusikakool;8434513;61503300219;Kharlamova Elizaveta ;47804253720;Poltorukho Tatiana;15;36;;;36;15;;;36
Narva Muusikakool;8434610;60511100842;Puusta Elina;48305243716;Tšotšis Lia;0;;;;0;;;;0
Narva Muusikakool;8435318;60705057099;Naumova Darja;47201280282;NAUMOVA JELENA;0;;;;0;;;;0
Narva Muusikakool;8435415;51107133727;Kordontšuk Kristo;48309302238;Kordontšuk Aljona;30;36;;;36;;;;66
Narva Muusikakool;8435512;61512120057;Artemjeva  Miroslava;38410073717;Artemjev Aleksandr;30;36;;;36;30;;;36
Narva Muusikakool;8435619;61312270113;Pihlakas Emily;48110093712;Pihlakas Jelena;0;29;;;29;;;;29
Narva Muusikakool;8436016;60712293738;Fedina Miloslava;48606270041;Tikka Nadežda;0;36;;;36;;;;36
Narva Muusikakool;8436113;61004053729;Geveller Anna;47607153712;Geveller Irina;30;36;;;36;30;;;36
Narva Muusikakool;8436210;60609270020;Koreshkova Ekaterina;47606040012;Koreshkova Marina;30;36;;;36;30;;;36
Narva Muusikakool;8436317;60904143711;Kullamaa Jekaterina;48009012218;Tihane Olga;30;36;;;36;;;;66
Narva Muusikakool;8436414;51001293742;Postolenko Gabriel David;49012270053;Postolenko Manuelle;-203,73;;;;0;;;;-203,73
Narva Muusikakool;8436511;60907153719;Rusis Liana;48111273715;Rusis Natalja;30;36;;;36;30;;;36
Narva Muusikakool;8436618;61101303711;Sagaidatšnaja Aljona;48401172249;Savvatjeva Olga;30;36;;;36;30;;;36
Narva Muusikakool;8436715;60809113721;Ševela Roksana;48110013722;Ševela Olga;30;36;;;36;;;;66
Narva Muusikakool;8436812;61007123718;Skrinda Darina;48006283732;Skrinda Jekaterina;36;43;;;43;36;;;43
Narva Muusikakool;8436919;60902013727;Solonenko  Anastasija;48304042256;Solonenko  Jekaterina;-111,01;36;;;36;;;;-75,01
Narva Muusikakool;8437015;61010133716;Vassiljeva Alisa;48601172211;Vassiljeva Viktoria;15;36;;;36;15;;;36
Narva Muusikakool;8437112;60705303736;Korkiainen Juliana;45104293723;Luks Klavdia;60;36;;;36;60;;;36
Narva Muusikakool;8437219;60509153729;Burjakova Angelina;47604163715;Burjakova Natalja;0;;;;0;;;;0
Narva Muusikakool;8437617;51105200036;Orlov Lukian;47709083740;Homjakova Sofja;0;41,5;;;41,5;;;;41,5
Narva Muusikakool;8437714;61103233769;Peussa Vasilisa;48105283738;Peussa Ljudmila;0;;;;0;;;;0
Narva Muusikakool;8437811;61206110100;Postolenko Felicia;49012270053;Postolenko Manuelle;-203,73;;;;0;;;;-203,73
Narva Muusikakool;8437918;61302130032;Sokolova Maia;48702043712;Sokolova Olga;0;;;;0;;;;0
Narva Muusikakool;8438014;51101250029;Zaitsev Mark;47102209517;Šabas Irina;30;36;;;36;;;;66
Narva Muusikakool;8438111;61105063744;Korolyak Polina;47803160039;Korolyak Larisa;-30;;;;0;;;;-30
Narva Muusikakool;8438218;50603103710;Gavrilov Ivan;46612042211;Gavrilova Tatjana;0;;;;0;;;;0
Narva Muusikakool;8438315;61606210140;Kotko Solomia;48908153739;Kotko Ekaterina;30;36;;;36;;;;66
Narva Muusikakool;8438412;50804233726;Karru Oleg;47712203720;Karru Olga;0;;;;0;;;;0
Narva Muusikakool;8438519;60801043736;ODINTSEVA ANASTASIA;48909203715;ODINTSEVA TATIANA;0;;;;0;;;;0
Narva Muusikakool;8438616;60610313730;Plesneva Polina;48309213726;Plesneva Rimma;-0,78;;;;0;;;;-0,78
Narva Muusikakool;8438713;60410243717;Spiridonova Sofija;46505102226;Spiridonova Ljudmila;-11,43;;;;0;;;;-11,43
Narva Muusikakool;8438917;61706280094;Pavlova Margarita;49209243724;Pavlova Kseniya;0;;;;0;;;;0
Narva Muusikakool;8439013;60503303731;Lestenkova Polina;36801150019;Lestenkov Sergey;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8439110;50508063713;Krasnoumov Nikita;46912292223;Logvinova Natalja;68;43;;;43;;;;111
Narva Muusikakool;8439217;60708053713;Levin Maria;48303263715;Levin Jelena;-62,9;;;;0;;;;-62,9
Narva Muusikakool;8439314;60404293713;BABARÕKINA EVELINA;47112163727;BABARÕKINA LJUDMILA ;0;;;;0;;;;0
Narva Muusikakool;8439518;61106163744;Polozova Melitta;49107230027;Polazava Maryana;24;29;;;29;20;;;33
Narva Muusikakool;8439615;60711193727;Panteleeva Viktoria;48507250073;Panteleeva Marina;-15,83;;;;0;;;;-15,83
Narva Muusikakool;8439712;60804223720;Kriina Alisa;47201293726;Netšajeva Natalja;0;;;;0;;;;0
Narva Muusikakool;8439819;51306160061;Pevtsov Mstislav;48012083712;Protassova Tatjana;0;29;;;29;;;;29
Narva Muusikakool;8440316;50703233738;Roshchin Vitali;48108102237;Roshchina Elena;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8440413;51305050065;Baikov Bogdan;38208113722;Baikov Andrei;0;;;;0;;;;0
Narva Muusikakool;8441315;51506250153;Bendi Arseni;47309113718;Bendi Jelena;30;36;;;36;30;;;36
Narva Muusikakool;8441412;51103233746;Juronen Kirill;36807253710;Yuronen Eduard;48;43;;;43;54;;;37
Narva Muusikakool;8441519;50706083712;Solonenko  Dmitri;48304042256;Solonenko  Jekaterina;0;;;;0;;;;0
Narva Muusikakool;8441713;50609273718;Raudsepp Edgar;47702113728;Raudsepp Tatjana;27;11;;;11;27;;;11
Narva Muusikakool;8441810;51101282741;Liiva Sten-Erich;48709236525;Liiva Kätlin;30;36;;;36;30;;;36
Narva Muusikakool;8442013;61310040180;Rudakova  Maria;47206013716;Demidova  Larissa;0;29;;;29;;;;29
Narva Muusikakool;8442110;61410220170;Rubannikova Aida;48511213729;Rubannikova Tatjana;-17,61;;;;0;;;;-17,61
Narva Muusikakool;8442217;50903183742;Kuznetsov Daniil;48701173712;Farafonova Anna;0;;;;0;;;;0
Narva Muusikakool;8442314;51209183731;Luik Vladimir;47608273715;Luik Jelena;60;36;;;36;;;;96
Narva Muusikakool;8442411;50709182758;Losev Leonid;47405172212;Loseva Elena;0;;;;0;;;;0
Narva Muusikakool;8442518;60505190855;Subotkevitš Daniela;47612113729;Subotkevitš Natalja;72;43;;;43;72;;;43
Narva Muusikakool;8442615;50806053716;Matvejev Andrei;48304033747;Miller Anatsassia;-28,73;;;;0;;;;-28,73
Narva Muusikakool;8442712;50612042745;Šadrin Kirill;37403142213;Šadrin Aleksei;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8442819;51107093719; Mihhailov Daniil;47810033727;Mihhailova Jelena;30;36;;;36;66;;;0
Narva Muusikakool;8442916;48606270041;Tikka Nadežda;48606270041;Tikka Nadežda;0;;;;0;;;;0
Narva Muusikakool;8443012;60909243736;Gandšu Amelia;35305083736;Gandšu Juri;30;36;;;36;30;;;36
Narva Muusikakool;8443119;50908192766;Mihhailov Jan;36501223716;Mihhailov Vassili;34,5;36;;;36;34,5;;;36
Narva Muusikakool;8443313;61711050062;Sabinina Sofia;48401063723;Sabinina Antonina;9;11;;;11;9;;;11
Narva Muusikakool;8443410;50707063714;Cheremisinov Artem;45401013737;Tarassova Svetlana;0;;;;0;;;;0
Narva Muusikakool;8443517;60507163715;Garenskihh Anastassija;47212293746;Garenskihh Olga;-25;;;;0;;;;-25
Narva Muusikakool;8443614;50810083755;Illipe Koit;47709053719;Haava-Illipe Marika;30;36;;;36;30;;;36
Narva Muusikakool;8443711;60507303718;Pärnoja Anneli;47609012267;Julia Rostenko;0;;;;0;;;;0
Narva Muusikakool;8443818;50801313714;Ivanov Kirill;47008193727;Zinovjeva Jevgenia;0;;;;0;;;;0
Narva Muusikakool;8444312;50305245216;Matsi Enno;37207305213;Matsi Leho;0;;;;0;;;;0
Narva Muusikakool;8444419;50807223712;Naumanis Jaan;47408122214;Naumanis Jekaterina;36;43;;;43;36;;;43
Narva Muusikakool;8444613;61710080034;Sergejeva Taisa;48005013718;Gurõljova Oksana;0;11;;;11;;;;11
Narva Muusikakool;8444710;61102203710;Morozova Ekaterina;48703052215;Timofeeva Olga;0;36;;;36;;;;36
Narva Muusikakool;8445214;50510313715;Strižov Anton;36304193713;Strižov  Andrei;-62,9;;;;0;;;;-62,9
Narva Muusikakool;8445311;60411163730;Eroshkina Marija;47406223725;Solovjova Jelena;0;;;;0;;;;0
Narva Muusikakool;8445418;61401080244;Pärnoja Katrin;47310270037;Konopleva Inga;30;36;;;36;30;;;36
Narva Muusikakool;8445515;50903073735;Gorelenok Jegor;47208012239;Laknovskaja Jelena;0;36;;;36;;;;36
Narva Muusikakool;8445612;50903052217;Sukorkin Fjodor;47912122214;Vesselova Anna;0;36;;;36;;;;36
Narva Muusikakool;8446116;61005163714;Alikmäe Emili;48509153710;Allikmäe Ljubov;30;36;;;36;30;;;36
Narva Muusikakool;8446310;51702150166;Švan Deniss;49001012213;Švan Sofia;0;;;;0;;;;0
Narva Muusikakool;8446417;61003223726;Cheremisinova Vasilisa;37206187017;Cheremisinov Artem;12,5;41,5;-36;;5,5;12,5;;;5,5
Narva Muusikakool;8446514;60911153738;Pidvysotskiy Anastasia;48306163729;Pidvysotskiy Jelena;0;;;;0;;;;0
Narva Muusikakool;8446611;51101263713;Eliseev Danil;45202283742;Jelissejeva Antonina;3,5;36;;;36;36;;;3,5
Narva Muusikakool;8446815;61801010033;Tikhomirova Anastasia;48503039512;Tikhomirova Maria;9;11;;;11;9;;;11
Narva Muusikakool;8446912;61102030020;Kirichum Simona;48209042212;Kirichun Anna;-20;;;;0;;;;-20
Narva Muusikakool;8447319;61511090116;Evgenieva  Eva;48007293719;Muraeva Svetlana;0;;;;0;;;;0
Narva Muusikakool;8447814;50810272741;Ovsjannikov  Viktor;46103132719;Sõtšinskaja  Natalja;-11,9;;;;0;;;;-11,9
Narva Muusikakool;8447911;60908273712;Pill Ilona;47809283711;Pill Julia;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8448017;60911153738;Pidvysotskiy Anastasia;48306163729;Pidvysotskiy Jelena;60;36;;;36;60;;;36
Narva Muusikakool;8448114;61508180255;Kudriashova Viktoriia;47206113722;Kudriashova Olga;0;;;;0;;;;0
Narva Muusikakool;8448211;51106293737;Kirka Ivan;46704162262;Istomina-Kirka Svetlana;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8448415;51711220030;Verguljanets Markus;38411092216;Verguljanets  Daniil;9;11;;;11;9;;;11
Narva Muusikakool;8448512;60811243734;Vinogradova Jelizaveta;48012093719;Vinogradova Sofia;-62,9;;;;0;;;;-62,9
Narva Muusikakool;8448910;50204193733;Suhhotin Semjon;46705043723;Suhhotina Jelena;-49;;;;0;;;;-49
Narva Muusikakool;8449511;61308200203;Merelaid Sofia Viktoria;48311273710;Furman Natalia;30;36;;;36;30;;;36
Narva Muusikakool;8449618;61308020082;Pantjuhhina Alexa;48609073710;Pantjuhhina Irina;30;36;;;36;30;;;36
Narva Muusikakool;8449715;60505183725;Podolyak Veronika;45404212233;Kozlova Niina;0;;;;0;;;;0
Narva Muusikakool;8449812;50301193710;Belov Sergei;46902153716;Nikitina Svetlana;0;;;;0;;;;0
Narva Muusikakool;8449919;51005073725;Pogorževski Arseni;38609203727;Pogorževski Aleksandr;30;36;;;36;30;;;36
Narva Muusikakool;8450018;60401063731;Galimova  Uljana;47502103737;Dubskihh Svetlana;0;;;;0;;;;0
Narva Muusikakool;8450115;61105283726;Jakovleva Arina;38312123739;Jakovlev Dmitri;4,5;36;-36;;0;;;;4,5
Narva Muusikakool;8450212;51107203712;Karyaev Kirill;48304163719;Einman Olga;0;;;;0;;;;0
Narva Muusikakool;8450319;51005153750;Klyukin Artemi;48012033710;Kubatškova Jelena;36;43;;;43;36;;;43
Narva Muusikakool;8450416;61007283711;Kolesnikova Anastasia;35902172229;Ivanov Valeri;0;;;;0;;;;0
Narva Muusikakool;8450513;51103063733;Kukk Arseni;48310173710;Kukk Natalja;0;;;;0;;;;0
Narva Muusikakool;8450610;50906113719;Prosvetov Miron;46403053711;Prosvetova Jelena;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8450717;51008214729;Šutov Aleksandr;48105073719;Šutova Anastassia;0;;;;0;;;;0
Narva Muusikakool;8451114;61105033712;Zaugarova Angelina;47903293724;Linnik Anna;0;;;;0;;;;0
Narva Muusikakool;8451512;61004163731;Pjatnitskaja Marjana;49205263762;Strahhova Svetlana;75;;;;0;;;;75
Narva Muusikakool;8451716;51007233722;Vesselko Kristian;48107103728;Veselko Irina;60;36;-36;;0;;;;60
Narva Muusikakool;8451813;51402140183;Kayryak Lauri;47703240046;Moiseeva Iuliia;30;36;;;36;100;;;-34
Narva Muusikakool;8451910;61301220037;Olenina Vasilisa;48108053715;Pimenova Natlja;0;;;;0;;;;0
Narva Muusikakool;8452016;51211103727;Reinol Filipp;47407153717;Reinol Jelena;30;36;;;36;30;;;36
Narva Muusikakool;8452113;50909243717;Moldov Ivan;48009153739;Moldova Eva;53,99;36;;;36;53,99;;;36
Narva Muusikakool;8452210;60602153719;Pohjaranta Elina Elsa Maria;47301203710;Pohjaranta Irina;27;11;;;11;;;;38
Narva Muusikakool;8452317;61411110097;Gandšu Aina;48604163728;Gandšu Olga;30;36;;;36;30;;;36
Narva Muusikakool;8452414;61602190115;Ponomarjova Anastasia;48908013716;Ponomarjova Jekaterina;0;;;;0;;;;0
Narva Muusikakool;8452511;50709043721;Filippov Matvei;36406163716;Filippov Sergei;30;36;;;36;;;;66
Narva Muusikakool;8452618;51005153728;Jarmuhhamedov Tamir;47808073710;Jarmuhhamedova Marina;0;36;;;36;;;;36
Narva Muusikakool;8453015;60602153719;Pohjaranta Elina Elsa Maria;47301203710;Pohjaranta Irina;-4,79;;;;0;;;;-4,79
Narva Muusikakool;8453112;50906287098;Kirichun Gregory;48209042212;Kirichun Anna;-20;;;;0;;;;-20
Narva Muusikakool;8453219;51407100245;Popov Emil-Aleksandr;37203263747;Popov  Aleksey;0;36;;;36;36;;;0
Narva Muusikakool;8453316;51006143715;Belov Ustin;48211153753;Belova Jekaterina;-22,43;;;;0;;;;-22,43
Narva Muusikakool;8453918;61307180059;Hussainova Jelizaveta;47504032218;Hussainova Zoja;0;36;;;36;;;;36
Narva Muusikakool;8454014;61712240050;Rajevskaja Sofja;39008273722;Rajevski Anton;-27;11;;;11;;;;-16
Narva Muusikakool;8454111;50612093711;Brindas Konstantin Mihai;44809052262;Gavrilova Ljudmila;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8454218;61405300074;Randoja Ester;48606180097;Masato-Randoja Irene;30;36;;;36;30;;;36
Narva Muusikakool;8454315;50806203737;Anisimov Arseni;47707233718;Anisimova Natalia;65;36;;;36;65;;;36
Narva Muusikakool;8454412;50801230296;Jekimov Daniil;48107153710;Jekimova Natalja;-49;;;;0;;;;-49
Narva Muusikakool;8455518;60303283764;Gruzdeva Angelina;60303283764;Gruzdeva Angelina;0;;;;0;;;;0
Narva Muusikakool;8456119;61207243711;Rychkova Adelina;47605073710;Tarassova Anastassia;35;36;;;36;36;;;35
Narva Muusikakool;8456216;61309150146;Ossipenko Evelina;48509243720;Ossipenko Julia;-12,9;;;;0;;;;-12,9
Narva Muusikakool;8456313;51209053715;Maslakov Andrei;38001093716;Maslakov Andrei;28,5;34,5;;;34,5;28,5;;;34,5
Narva Muusikakool;8456517;50810203711;Veselko Artjom;48107103728;Veselko Irina;115;36;-36;;0;;;;115
Narva Muusikakool;8456614;61502270166;Maksimova Nikoletta;49412220030;Maksimova Marina;0;;;;0;;;;0
Narva Muusikakool;8456711;60510022741;Rojak Sonja;48207107013;Rojak Olesja;9;11;;;11;;;;20
Narva Muusikakool;8456818;61105183718;Ivanova Marjana;48804203715;Ivanova Anastasia;0;;;;0;;;;0
Narva Muusikakool;8456915;61104133713;Gromova Milana;48505093734;Gromova Jevgenia;0;34,5;;;34,5;29;;;5,5
Narva Muusikakool;8457914;60804097015;Eremina Tereza;47201030039;Eremina Irina;0;;;;0;;;;0
Narva Muusikakool;8458311;61209203737;Murashova Veronika;48803090045;Murashova Tatiana;60;36;;;36;30;;;66
Narva Muusikakool;8458418;61310250024;Nadeeva Alisa;48607123737;Nadeeva Natalia;0;;;;0;;;;0
Narva Muusikakool;8458515;60812043716;Savtšenko Maria;49209113719;Yatskova Anna;38,5;46,5;;;46,5;;;;85
Narva Muusikakool;8458719;60906287099;Saan Milena;48607192244;Saan Linda;0;;;;0;;;;0
Narva Muusikakool;8458816;60809087088;Horeva Elizaveta;48204233712;Horeva Viktoria;0;;;;0;;;;0
Narva Muusikakool;8458913;60905063711;Fedotova Uljana;48211083735;Maksimova Jelena;-62,9;;;;0;;;;-62,9
Narva Muusikakool;8459019;60502273714;Belaja Anastassija;47505273724;Belaya Oksana;-30;36;;;36;;;;6
Narva Muusikakool;8459116;61304160052;Verguljanets Polina;49209293715;Verguljanets Marina;-141,23;36;-36;;0;;;;-141,23
Narva Muusikakool;8459213;61309290093;Stepanova Sofija;47401052216;Stepanova Natalia;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8459310;51306020169;Sadala Dominik;48910103712;Sadala Olesja;30;36;;;36;30;;;36
Narva Muusikakool;8459417;43611233714;Šemeleva Ljudmila;43611233714;Šemeleva Ljudmila;-25;;;;0;;;;-25
Narva Muusikakool;8459611;60607313745;Vesselko Lilian;48107103728;Veselko Irina;0;;;;0;;;;0
Narva Muusikakool;8459718;60702023728;Revina Ellina;46311093719;Revina Olga;30;36;;;36;30;;;36
Narva Muusikakool;8459815;51307110064;Ivanov Matvei;49105083717;Ivanova Julia;0;;;;0;;;;0
Narva Muusikakool;8459912;61403210043;Samoljotova Amelia;47304043730;Rogova Irina;0;36;;;36;;;;36
Narva Muusikakool;8460011;50812133714;Panteleev Maksim;48507250073;Panteleeva Marina;-15,83;;;;0;;;;-15,83
Narva Muusikakool;8460118;61408140192;Sazonova Diana;47311297013;Zarekovkina Galina;30;36;;;36;30;;;36
Narva Muusikakool;8460215;51106200215;Taltavull Astafyeva Nikita;48201290084;Romanova Anna;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8460312;51403100160; Seleznev Jaroslav;49007193726; Kuznetsova Tatjana;30;36;;;36;;;;66
Narva Muusikakool;8460419;50207142215;Malinovski Jan Daniel;47902022215;Malinovska Anna;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8460516;61205010090;Kozhemyakina Taisija;48511133726;Kozhemyakina Vlada;40;36;;;36;40;;;36
Narva Muusikakool;8460914;61102040060;Rosenthal Mia;48507213744;Rosenthal Ksenia;15;36;;;36;25;;;26
Narva Muusikakool;8461010;60607117116;Semishkur Sofiya;47801160029;Semishkur Oxana;30;36;;;36;30;;;36
Narva Muusikakool;8461117;51307250065;Kreyvald Dennis;37303250022;Kreyvald Valery;0;29;-29;;0;;;;0
Narva Muusikakool;8461214;51401200076;Semashko Nikita;43510303724;Semaško Liidia;-0,01;;;;0;;;;-0,01
Narva Muusikakool;8461311;61201223711;Terekhina Jekaterina;47501052230;Terehhina Olga;-30,32;;;;0;;;;-30,32
Narva Muusikakool;8461418;61205233738;Solovieva Victoria;48702013713;Koroljova Ljudmila;10;29;-29;;0;20;;;-10
Narva Muusikakool;8461515;61210300123;Capecchi Anita;48101272257;Lopatina  Ekaterina;24;29;;;29;24;;;29
Narva Muusikakool;8462912;60008253715;Jelissejenko Samanta;48304033747;Miller Anatsassia;-16;;;;0;;;;-16
Narva Muusikakool;8463018;61507290056;Sazonova Diana;48803283716;Sazonova Kristina;24;29;;;29;24;;;29
Narva Muusikakool;8463115;61210113719;Ostov Alisa;48708163729;Ostov Anastassia;30;36;;;36;30;;;36
Narva Muusikakool;8463212;61603290126;Matjušina Lada;47908013725;Matyushina Elena;0;;;;0;;;;0
Narva Muusikakool;8463319;39909280280;Lennuk Edgar;36908243711;Lennuk Eduard;-13;;;;0;;;;-13
Narva Muusikakool;8463513;61702240100;Vinogradova Alisa;48807270052;Vinogradova  Iuliia;0;;;;0;;;;0
Narva Muusikakool;8463610;50903233724;Toivonen Robert;47807272229;Toivonen Olga;0;;;;0;;;;0
Narva Muusikakool;8463717;51108083717;Shutov Evald;47712012228;Shutova Marina;0;36;-36;;0;;;;0
Narva Muusikakool;8463814;60507227039;Nazarova Maria;45507182217;Nazarova Liidia;0;;;;0;;;;0
Narva Muusikakool;8463911;60210163763;Kudukis Anastassija;46502093726;Kudukis Albina;0;;;;0;;;;0
Narva Muusikakool;8464017;61303010213;Kalamees Jelizaveta;47302080016;Kalamees Ekaterina;15;36;;;36;30;;;21
Narva Muusikakool;8464114;60401283735;Setško Anastassija;47210282210;Setško Jelena;60;;;;0;60;;;0
Narva Muusikakool;8464211;51108103711;Ivanov Devid;48411263717;Ivanova Elvira;20;36;;;36;;;;56
Narva Muusikakool;8464318;51304100020;Zolin Ivan;47801063722;Deryabina Elena;60;36;;;36;60;;;36
Narva Muusikakool;8464415;61002113719;Ivanova Elina;48411263717;Ivanova Elvira;15;36;;;36;15;;;36
Narva Muusikakool;8464512;50801273717;Zaugarov Nikita;47903293724;Linnik Anna;0;;;;0;;;;0
Narva Muusikakool;8464619;51402160186;Shutov Stefan;47712012228;Shutova Marina;-25;36;-36;;0;;;;-25
Narva Muusikakool;8464716;60301283732;Golubtsova Olga;47503163739;Golubtsova Zhanna;-15,83;;;;0;;;;-15,83
Narva Muusikakool;8464813;50408203757;Klimberg German;37604033720;Smirnov Ilja;40;36;;;36;30;;;46
Narva Muusikakool;8464910;51605020184;Živolunov Aleksei;37805133715;Živolunov Aleksandr;0;;;;0;;;;0
Narva Muusikakool;8465016;60408063722;Tarlõkova Valerija;46402143727;Tarlõkova Galina;-17,61;;;;0;;;;-17,61
Narva Muusikakool;8465113;60411063724;Smirnova Marija;47503232257;Smirnova Yulia;115;36;;;36;;;;151
Narva Muusikakool;8465210;51304070106;Granditski Nikita;38106063716;Granditski Aleksandr;0;36;;;36;;;;36
Narva Muusikakool;8465317;61307300135;Butkevitš Alina;47511022235;Butkevitš Anželika;30;36;;;36;30;;;36
Narva Muusikakool;8465414;61410160104;Živolunova Aleksandra;37805133715;Živolunov Aleksandr;0;;;;0;;;;0
Narva Muusikakool;8465511;61301140198;Timofejeva Arina;48610022213;Timofejeva  Maria;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8465618;50211293728;Mihhailov Andrei;46709269511;Mihhailova Olga;0;;;;0;;;;0
Narva Muusikakool;8465715;50609183741;Oleksyuk Roman;37512023715;Oleksjuk Oleg;0;;;;0;;;;0
Narva Muusikakool;8465812;60411063724;Smirnova Marija;47503232257;Smirnova Yulia;-62,5;36;-36;;0;;;;-62,5
Narva Muusikakool;8465919;50204193722;Russin Jegor;47601083727;Russina Julia;0;;;;0;;;;0
Narva Muusikakool;8466015;61108273723;Nikitina Anna;48301172224;Nikitina Veronika;0;36;;;36;;;;36
Narva Muusikakool;8466510;61402080129;Kuttanen Viktoria;48602222220;Kuttanen Jekaterina;30;36;;;36;60;;;6
Narva Muusikakool;8466617;50307013722;Kuzmin Jan;46506173727;Kuzmina Irina;0;;;;0;;;;0
Narva Muusikakool;8466714;49807183710;Soboljeva Julia;49807183710;Soboleva Julia;0;;;;0;;;;0
Narva Muusikakool;8466811;51209120132;Lisjenko Boriss;48108100101;Lebedeva Nadežda;30;36;;;36;;;;66
Narva Muusikakool;8466918;51407080338;Lisenko Viktor;48108100101;Lebedeva Nadežda;30;36;;;36;;;;66
Narva Muusikakool;8467014;61702040165;Šutova Asja;48105073719;Šutova Anastassia;0;36;;;36;;;;36
Narva Muusikakool;8467111;51010053734;Märtson Saveli;48208242229;Märtson Jana;0;;;;0;;;;0
Narva Muusikakool;8467519;60809223745;Toropina Alina;48409233721;Toropina Anastasia;34,5;;;;0;;;;34,5
Narva Muusikakool;8467616;61401190094;Sõmer Amelia;48906263711;Sõmer Veronika;-8,44;;;;0;;;;-8,44
Narva Muusikakool;8467713;61207193718;Oleksyuk Evnika;47705233720;Oleksyuk  Natalia;-62,5;36;;;36;;;;-26,5
Narva Muusikakool;8467810;61401180054;Kuznetsova Polina;37209269519;Kuznetsov Aleksei;14,27;36;;;36;36;;;14,27
Narva Muusikakool;8467917;60408073740;Kamaeva Maya;48107063711;Kamajeva Olga;0;;;;0;;;;0
Narva Muusikakool;8468013;60511080868;Svirepova Anna;36510313725;Sednev Vladimir;0;43;;;43;;;;43
Narva Muusikakool;8468110;61107123710;Semishkur Maria;47801160029;Semishkur Oxana;0;36;-36;;0;;;;0
Narva Muusikakool;8468411;50903133718;Ignatov Andrei;47210173727;Ignatova Tatjana;-5;36;;;36;;;;31
Narva Muusikakool;8468518;50806263713;Chikin Arseni;48304012224;Kostištšina Natalja;30;36;;;36;30;;;36
Narva Muusikakool;8469517;51001063711;Rjabov Robert;47904183727;Hahhajeva Larissa;30;36;;;36;;;;66
Narva Muusikakool;8469614;60307053740;Teppo Livia;46910153721;Teppo Maria;0;;;;0;;;;0
Narva Muusikakool;8469711;51507150108;Sergejev Ustin;38007053722;Sergejev Jevgeni;0;;;;0;;;;0
Narva Muusikakool;8469818;60408313727;Pahhalujeva Darja;46909213718;Pahhalujeva Irina;34;11;;;11;25;;;20
Narva Muusikakool;8469915;61307030116;Mihhailova Sofia;49207093737;Mihhailova Natalia;0;;;;0;;;;0
Narva Muusikakool;8470014;50708253713;Jelissejev Aleksei;46705153714;Jelissejeva  Natalja;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8470111;61202173712;Tkacheva Varvara;49203243727;Intjasõva Darina;0;;;;0;;;;0
Narva Muusikakool;8470218;61506120182;Zabarina Alina;47606073715;Zabarina Jelena;30;36;;;36;;;;66
Narva Muusikakool;8470315;60201183734;Zaika Anželika;47412173732;Zaika Natalja;0;;;;0;;;;0
Narva Muusikakool;8470412;60609033712;Turbina Varvara;47106182215;Turbina Irina;0;;;;0;;;;0
Narva Muusikakool;8470519;61105283726;Jakovleva Arina;48312282246;Olga Smoljakova;-32,67;;;;0;;;;-32,67
Narva Muusikakool;8471916;51505170058;Panin  Roman;38704233737;Panin Aleksandr;30;36;;;36;30;;;36
Narva Muusikakool;8472012;61303220221;Miljutinova Anastassia;49101113719;Miljutinova Tatjana;-75;36;;;36;;;;-39
Narva Muusikakool;8473419;61110043720;Shlukum Jekaterina;48204222218;Shlukum Svetlana;90;36;;;36;;;;126
Narva Muusikakool;8473516;51009063716;Rodionov Aleks;37511223711;Rodionov Aleksandr;0;36;-36;;0;;;;0
Narva Muusikakool;8473817;60812063730;Šutova Emili;37804053718;Šutov Vadim;-7,28;36;-36;;0;;;;-7,28
Narva Muusikakool;8474117;61110253717;Tšerkašina Arina;47306283725;Tšerkašina Tatjana;90;36;;;36;90;;;36
Narva Muusikakool;8474214;61201096826;Spitsa Mia-Loore;48112146510;Avikson Mari-Liis;-62,9;;;;0;;;;-62,9
Narva Muusikakool;8474311;50707202818;Petrov Samuil;47006013721;Petrova Zoja;30;36;;;36;;;;66
Narva Muusikakool;8474719;61011243712;Udodenko Darya;46911122218;Zhuravleva Tatiana;-5;36;;;36;30;;;1
Narva Muusikakool;8474816;50609093710;Gurõljov Anton;47805152210;Hozjainova Margarita;15,92;;;;0;;;;15,92
Narva Muusikakool;8474913;60812242220;Turkova Viktoria;46312132212;Smirnova Svetlana;77,5;36;;;36;;;;113,5
Narva Muusikakool;8475019;50802283729;Stolle Artur;47901253719;Vulla Marika;-37,9;;;;0;;;;-37,9
Narva Muusikakool;8475116;61512160096;Uglanova Elizaveta;48112050045;Uglanova Mariia;60;36;;;36;30;;;66
Narva Muusikakool;8475213;51304270053;Lugovski  Robert;47703110222;Tamberg-Lugovskaja Ilona;0;36;;;36;;;;36
Narva Muusikakool;8475310;61004133710;Karlovskaja  Albina;48409032211;Karlovskaja Olga;0;;;;0;;;;0
Narva Muusikakool;8475611;51309170279;Sinijärv Viktor;47409152218;Sinijarv Elena;30;36;;;36;30;;;36
Narva Muusikakool;8476018;60403143711;Veremi Mišel;47410043728;Veremi Liilia;0;;;;0;;;;0
Narva Muusikakool;8476115;50703173718;VANINOV ILJA;46707270348;VANINOVA OLGA;0;;;;0;;;;0
Narva Muusikakool;8476212;50406203714;SIZOV SERGEI;48009293718;Sizova Natalja;-4,43;;;;0;;;;-4,43
Narva Muusikakool;8476319;61504210116;Perevalova Alisa;48301163737;Volõnskaja Jekaterina;-11,43;;;;0;;;;-11,43
Narva Muusikakool;8476416;50804033714;Mosin Maxim;47812212221;Mosin Jekaterina;30;36;;;36;30;;;36
Narva Muusikakool;8476513;50112203744;Chesnokov Valeri;46812043726;Chesnokova Rufina;-25,03;;;;0;;;;-25,03
Narva Muusikakool;8476610;50405253733;Sobolev Konstantin;47106212216;Soboleva Elena;-17,61;;;;0;;;;-17,61
Narva Muusikakool;8476717;61108273745;Peterson Pavla;49004023711;Peterson Eteri;0;;;;0;;;;0
Narva Muusikakool;8476814;61503160227;Mughal Susanna;48402223712;Lobanova Irina;24;29;;;29;24;;;29
Narva Muusikakool;8477318;39903113731;Zjuzin Nikita;47106143740;Zjuzina  Elena;0;;;;0;;;;0
Narva Muusikakool;8477415;60603113718;Zueva Ksenija;47003153729;Istomina Irina;30;36;;;36;;;;66
Narva Muusikakool;8477512;50407133712;Zuev Vyacheslav;48306173714;Zueva  Anna;23;36;;;36;;;;59
Narva Muusikakool;8477619;51008113715;Zorin Emilien;38310073725;Zorin Rene;-50;;;;0;;;;-50
Narva Muusikakool;8477910;60605233737;ŠTŠEPOTJEVA KRISTINA;47005272217;Štšepotjeva Irina;0;;;;0;;;;0
Narva Muusikakool;8478016;61206263710;Vasilieva Eva;49010083715;Vasilieva Tatiana;30;36;;;36;30;;;36
Narva Muusikakool;8478113;51307110205;Ivanichenko Nitita;48203172211;Ivanichenko Irina;0;;;;0;;;;0
Narva Muusikakool;8478210;51110263712;Denisov Daniel;48601122264;Denisova Olesja;0;;;;0;;;;0
Narva Muusikakool;8478317;60810030011;Abdullina Kamila;46609013719;Abdullina Elmira;73;;;;0;72;;;1
Narva Muusikakool;8478414;60510203714;Vallimets Marika;47505233713;Vallimets Olga;24,5;39,5;;;39,5;24,5;;;39,5
Narva Muusikakool;8478919;51602100128;Jakovlev Ivan;47302113716;Jakovelva Jelena;-11,43;;;;0;;;;-11,43
Narva Muusikakool;8479015;50906013713;Zolotukhin Avenir;47403293720;Zolotukhina Evgenia;15;36;;;36;;;;51
Narva Muusikakool;8479112;61009133713;Šumina Evelina;48211152211;Šumina Anna;0;;;;0;;;;0
Narva Muusikakool;8479219;51309050248;Uglanov Mihhail;48112050045;Uglanova Mariia;60;36;;;36;30;;;66
Narva Muusikakool;8479316;50507183717;Švarts Kirill;46411093711;Švarts Jelena;0;36;;;36;;;;36
Narva Muusikakool;8479413;61210192734;Safronova Anna-Sofia;47807242226;Safronova Svetlana;0;36;;;36;;;;36
Narva Muusikakool;8479811;50303313720;Dumchenko Mark;46402203727;Dumchenko Madina;0;;;;0;;;;0
Narva Muusikakool;8480211;61104102804;Terehhova Rada;47902272752;Terehhova Olesja;-18;;;;0;;;;-18
Narva Muusikakool;8480512;60907082836;Terehhova Eva;47902272752;Terehhova Olesja;0;36;-36;;0;;;;0
Narva Muusikakool;8480619;61010133716;Vassiljeva Alisa;48601172211;Vassiljeva Viktoria;0;29;;;29;;;;29
Narva Muusikakool;8480716;50108263713;Krjutškov Vjatšeslav;37307042213;Krjutškov Deniss;-14;;;;0;;;;-14
Narva Muusikakool;8481113;60812153718;Vassina Sofia;48012153718;Bahlinova Inna;-43,73;;;;0;;;;-43,73
Narva Muusikakool;8481210;49810283729;Vorontšihhina Alina;49810283729;Vorontšihhina Alina;30;36;;;36;;;;66
Narva Muusikakool;8481317;50611203721;Linnik Gleb;48202262236;Linnik Natalja;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8481414;60408123744;Tihhomirova Jelena;47307213714;Tihhomirova Oksana;-62,9;;;;0;;;;-62,9
Narva Muusikakool;8481511;61406300122;Võssotskaja Emili;47911063718;Võssotskaja Svetlana;30;36;;;36;30;;;36
Narva Muusikakool;8481618;61602100118;Jakovleva Ksenia;47302113716;Jakovelva Jelena;-11,43;;;;0;;;;-11,43
Narva Muusikakool;8481715;60806303722;Zorina Evangelina;38310073725;Zorin Rene;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8483810;60912063711;Võssotskaja Kristina;37211203710;Võssotski Anatoli;-63,06;36;;;36;;;;-27,06
Narva Muusikakool;8485119;60607313750;Tjantova Alika;48207043744;TJANTOVA ANNA;-0,73;;;;0;;;;-0,73
Narva Muusikakool;8485216;51108023719;Vassiltšenko Nazar;48003193726;Vassiltšenko Anna;30;36;;;36;30;;;36
Narva Muusikakool;8485313;51606010018;Sein Aleksandr;48201302228;Sein Oksana;30;36;;;36;30;;;36
Narva Muusikakool;8485410;51304190061;Savtšukov Robert;47904200033;Ismailova Nil;0;;;;0;;;;0
Narva Muusikakool;8485517;61404050064;Mägi Vasilissa;49003123734;Mägi Aleksandra;60;36;;;36;88,21;;;7,79
Narva Muusikakool;8485614;51112113725;Koževin Demid;46807273714;Koževina Irina;30;36;;;36;30;;;36
Narva Muusikakool;8486710;60710153727;Dmitrijenko Viktoria;47509303729;Dmitrijenko Jelena;0,36;36;;;36;;;;36,36
Narva Muusikakool;8486817;60706063710;Zhelnova Anastasia;48303073737;Zhelnova Mayya;-87,28;36;;;36;;;;-51,28
Narva Muusikakool;8486914;61101163729;Vallimets Veronika;47505233713;Vallimets Olga;-10;36;;;36;90;;;-64
Narva Muusikakool;8487311;39512273711;Timofeev Iliya;39512273711;Timofeev Iliya;-11,43;;;;0;;;;-11,43
Narva Muusikakool;8489018;50910022806;Jaggo Kristjan;37009165214;Jaggo Andres;30;36;;;36;30;;;36
Narva Muusikakool;8489115;61405070202;Erilaid Anna;48506262210;Zamirajeva Julia;30;36;;;36;30;;;36
Narva Muusikakool;8489212;51204053723;Antipenkov Dmitri;49112123758;Antipenkova Jelena;37;11;;;11;;;;48
Narva Muusikakool;8489319;51505190224;Vassiljev Kirill;48405133717;Šustrova Olga;0;29;;;29;;;;29
Narva Muusikakool;8489610;60505273740;Zolotukhina Diana;37310140020;Zolotuhhin Vladislav;-25;;;;0;;;;-25
Narva Muusikakool;8489717;51602150098;Alak Martin;48409280079;Alak Martina;55;;;;0;;;;55
Narva Muusikakool;8489814;60509293774;Nemets Dana;48308302222;Nemets Aleksandra;-9,9;;;;0;;;;-9,9
Narva Muusikakool;8489911;60406253739;Nemets Milana;48308302222;Nemets Aleksandra;0;;;;0;;;;0
Narva Muusikakool;8490010;50604173720;Zyuzin Matvei;47106143740;Zjuzina  Elena;30;36;;;36;30;;;36
Narva Muusikakool;8490117;61001183752;Veremi Isabelle;47410043728;Veremi Liilia;30;36;;;36;;;;66
Narva Muusikakool;8490214;50510143724;Baškirov Daniil;47507052212;Baškirova Anna;0;;;;0;;;;0
Narva Muusikakool;8490311;50501123722;Khokhlov Alekisei;48011113729;Golovko Vita;9;11;;;11;9;;;11
Narva Muusikakool;8490418;50311103728;Tšassovskihh Kristian;47012303727;Tšassovskihh Anžela;-11,43;;;;0;;;;-11,43
Narva Muusikakool;8490515;50604083732;Bobryshev Aleksandr;47812093719;Suup Regina;0;;;;0;;;;0
Narva Muusikakool;8490612;60912143714;Kiritšuk Uljana;48308243720;Kirtšuk Ljubov;-62,9;;;;0;;;;-62,9
Narva Muusikakool;8490719;60306093719;Somova Polina;46504283719;Somova Ljubov;0;;;;0;;;;0
Narva Muusikakool;8490816;60405193723;Petrova Jelizaveta;46807143712;Nikiforova Irina;-17,61;;;;0;;;;-17,61
Narva Muusikakool;8491912;60504283713;Kornejeva Sofja;48509113726;Kornejeva Anastassia;9;11;;;11;;;;20
Narva Muusikakool;8492018;51706090033;Denisov Kirill;48601122264;Denisova Olesja;0;;;;0;;;;0
Narva Muusikakool;8492115;61012060107;Kudriashova Iana;47206113722;Kudriashova Olga;0;;;;0;;;;0
Narva Muusikakool;8492212;60310303758;Koop Evelina;47207272734;Koop Jelena;0;;;;0;;;;0
Narva Muusikakool;8493415;61004060037;Kudriashova Daria;47206113722;Kudriashova Olga;0;;;;0;;;;0
Narva Muusikakool;8493512;50408033711;Kreyvald Dmitri;37303250022;Kreyvald Valery;-0,83;;;;0;;;;-0,83
Narva Muusikakool;8493813;60405303727;Kovaltšuk Ksenija;46712273712;Kovaltšuk Svetlana;0;;;;0;;;;0
Narva Muusikakool;8493910;60006143714;Lapotškina Vlada;47801253727;Lapochkina Tatiana;0;;;;0;;;;0
Narva Muusikakool;8494016;61509180140;Kruglova Viktoria;48706273710;Kruglova Tatjana;-7;;;;0;;;;-7
Narva Muusikakool;8494618;60408220018;Burtseva Darja;47906140021;Kolomiytseva Elena;-40,83;;;;0;;;;-40,83
Narva Muusikakool;8495015;60607313745;Vesselko Lilian;38105022229;Vesselko Sergei;0;;;;0;;;;0
Narva Muusikakool;8495112;60611293730;Sokolova Sofia;47901123714;Talik Katerina;0;;;;0;;;;0
Narva Muusikakool;8495219;61512280137;Denisova Alisa;48805202252;Denisova Maria;12;29;;;29;;;;41
Narva Muusikakool;8495316;61503170082;Sopina Agnessa;36504153713;Sopin Yuri;24;29;;;29;24;;;29
Narva Muusikakool;8495413;61408200181;Pulkina Kira;38510173737;Pulkin Dmitri;0;;;;0;50;;;-50
Narva Muusikakool;8495510;60103090294;Noorkõiv Karin;47605253722;Noorkõiv Katrin;-26,42;;;;0;;;;-26,42
Narva Muusikakool;8495617;51710050143;Doronin Lev;49611210013;Doronina Varvara;20;11;;;11;;;;31
Narva Muusikakool;8495714;50810203711;Veselko Artjom;38105022229;Vesselko Sergei;40;36;-36;;0;;;;40
Narva Muusikakool;8495811;61307020077;Esina Evelina;36511243712;Esin Sergey;0;29;-29;;0;;;;0
Narva Muusikakool;8495918;51407290226;Khokhlov  Stepan;48405213711;Khokhlova Natalia;-17,61;;;;0;;;;-17,61
Narva Muusikakool;8496014;50501103752;Jakovlev Maksim;46608143719;Jakovleva Tatjana;0;11;;;11;;;;11
Narva Muusikakool;8496111;50609053725;Karru Dmitri;47712203720;Karru Olga;15;36;;;36;;;;51
Narva Muusikakool;8496218;60611073715;Jakovleva Anfisa;47208113710;Jakovleva Oksana;0;;;;0;;;;0
Narva Muusikakool;8496315;61103070097;Yurina Marthe;48209203716;Balõševa  Anastassia;30;36;;;36;;;;66
Narva Muusikakool;8496412;60910107109;Naumova Marja;47201280282;NAUMOVA JELENA;0;36;-18;;18;;;;18
Narva Muusikakool;8496519;51409050131;Knjazev Iakov;47907212212;Knjazeva Jekaterina;10;29;;;29;;;;39
Narva Muusikakool;8496616;51201023720;Markov Timur;47109233732;Zaitseva Oksana;-8,73;;;;0;;;;-8,73
Narva Muusikakool;8496713;50111023741;Sergejev Sergei;47308063720;Vassilkova Antonina;0;;;;0;;;;0
Narva Muusikakool;8497217;51601020131;Burakov Daniil;48909262215;Burakova Viktoria;-0,01;;;;0;;;;-0,01
Narva Muusikakool;8497314;61503160184;Kvitko Kira;48609042285;Kvitko Tatiana;0;;;;0;;;;0
Narva Muusikakool;8497411;51512160029;Vasiliev Maksim;44910223724;Vasilieva Galina;-11,43;;;;0;;;;-11,43
Narva Muusikakool;8497518;61307240037;Kalamees Katriin;48203273713;Kuznetsova Olga;0;;;;0;;;;0
Narva Muusikakool;8497615;49304253717;Gundjajeva Maaja;46709173726;Gundjajeva Aljona;-17,61;;;;0;;;;-17,61
Narva Muusikakool;8497712;61511040169;Sednev Greta;49005282250;Sedneva Elena;-11,43;;;;0;;;;-11,43
Narva Muusikakool;8498216;47901302236;Boitsova Olga;47901302236;Boitsova Olga;-17,61;;;;0;;;;-17,61
NNMK;8700111;50407303780;Vlasenko Artjom;47809052235;Vlasenko Inna;0;;;;0;;;;0
NNMK;8700218;50206213748;Podlegajev Vladislav;48002033717;Baikova Tatjana;-4,2;;;;0;;;;-4,2
NNMK;8700315;51208143716;Belousov Pavel;37707273712;Belousov Juri;0;;;;0;;;;0
NNMK;8700412;51407100245;Popov Emil-Aleksandr;37203263747;Popov  Aleksey;0;;;;0;;;;0
NNMK;8700519;50508153745;Pšenitšnikov Artjom;48403252218;Varfolomejeva Olesja;38;13;;;13;;;;51
NNMK;8700616;51005097096;Adamka David;39007173722;Kukk Sergei;20;13;;;13;12;;;21
NNMK;8700713;51103213710;Ivanov Jevgeni;48510293714;Rumjantseva Jelena;0;;;;0;;;;0
NNMK;8700810;51201103712;Konovalov Miroslav;47703053711;Konovalova Jelena;10;13;;;13;10;;;13
NNMK;8700917;51208013715;Saukov Georgi;47112153716;Saukova  Tatiana;10;13;;;13;40;;;-17
NNMK;8701013;51206260173;Detiuk Vladislav;38603260160;Detiuk Dmitro;0;;;;0;;;;0
NNMK;8701110;50512153719;Bers Albert;47504083719;Bers Elena;-50;13;;;13;;;;-37
NNMK;8701217;50602183717;Gordejev Stanislav;48204123710;Gordejeva Viktoria;0;;;;0;;;;0
NNMK;8701314;51005183727;Vangonen Bogdan;48812292235;Vangonen Natalja;-43;;;;0;;;;-43
NNMK;8701411;51304190028;Meša Roman;47503163729;Meša Anna;10;13;-13;;0;10;;;0
NNMK;8701518;51104273735;Meša Vladimir;47503163729;Meša Anna;10;13;-13;;0;10;;;0
NNMK;8701615;50712190032;Lisienko Ruslan;37906060235; Lisienko Nikolay;0;13;-13;;0;;;;0
NNMK;8701712;51211243728;Säde Max;48803173714;Antonenko Ekaterina;0;;;;0;;;;0
NNMK;8701819;50106253729;Ivanov Mihhail;47204303739;Ivanova Ija;10;;;-10;-10;;;;0
NNMK;8701916;50807143753;Gruznov Georgi;48104163713;Gruznova Olga;-2,63;;;;0;;;;-2,63
NNMK;8702012;51205283739;Žukov Veniamin;47908133723;Žukova Olga;0;;;;0;;;;0
NNMK;8702119;50604283711;Leonov Aleksandr;47708043718;Boikova Svetlana;-6,2;;;;0;;;;-6,2
NNMK;8702216;61106163733;Kaljumäe Aia;46609290011;Zhuravskaya Elena;0;;;;0;;;;0
NNMK;8702313;50702167161;Stepanov Andrey;48703010074;Stepanova Nadezhda;20;13;;;13;10;;;23
NNMK;8702410;50906227132;Reinol Jelissei;46805273726;Reinol Maie;0;13;;;13;;;;13
NNMK;8702517;50811053739;Fomin Martin;48012262212;Fomina Ekaterina;0;;;;0;;;;0
NNMK;8702614;51208243737;Datsko Dmitri;48702170018;Datsko Ekaterina;0;;;;0;;;;0
NNMK;8702711;50312113718;Stimmer Dmitri;47604243718;Stimmer Ingrid;0;;;;0;;;;0
NNMK;8702818;61107243719;Andreeva Amalia;47702113739;Mirošnikova Olga;0;;;;0;;;;0
NNMK;8702915;50404210905;Rozov Daniil;38112162714;Rozov Sergei;-0,5;13;-13;;0;;;;-0,5
NNMK;8703011;50709123735;Krõlov Vladislav;48503053718;Krõlova Jelena;-0,2;;;;0;;;;-0,2
NNMK;8703118;60510193749;Ille Sofija;47606092214;Koltšanova Jelena;0;13;;;13;;;;13
NNMK;8703215;60701153740;Velmar Alina;48710043728;Kudryavtseva Natalia;0;;;;0;;;;0
NNMK;8703312;60701307062;Bogovskaja Marianna;48412310256;Bogovskaja Marina;30;13;;;13;32;;;11
NNMK;8703419;61501290179;Belova Jana;38405233711;Belov Aleksei;0;13;;;13;;;;13
NNMK;8703516;50401083711;Nikolajenkov Aleksei;46902133713;Nikolajenkova Olga;0;;;;0;;;;0
NNMK;8703613;50407223744;Novossad Daniil;45402103719;Novosad Galina;-24,5;;;;0;;;;-24,5
NNMK;8703710;51509160201;Ivanov Jaroslav;48904172213;Ivanova Aleksandra;14;13;;;13;8;;;19
NNMK;8703817;39312233754;Terukov Aleksey;39312233754;Terukov Aleksey;-13,07;;;;0;;;;-13,07
NNMK;8703914;61310130059;Serebrjakova Maia;49302233733;Serebrjakova Jekaterina;10;;;;0;10;;;0
NNMK;8704010;50706233722;Žukovski Dmitri;48401247023;Žukovskaja Viktoria;0;;;;0;;;;0
NNMK;8704117;60609293711;Andrejeva Evelina;48709173725;Andrejeva Jane;0;;;;0;;;;0
NNMK;8704214;50810303717;Gavrilin Dmitri;47902233710;Gavrilina Maria;0;;;;0;;;;0
NNMK;8704311;50810133715;Malõšev Timur;49002052235;Korsunova Kristina;0;;;;0;;;;0
NNMK;8704418;60608020306;Kekšina Veronika;48205177019;Nüganen Katri;0;13;-13;;0;;;;0
NNMK;8704515;61108280097;Krause Mia kamila;48409143711;Krause Olga;-3,5;;;;0;;;;-3,5
NNMK;8704612;60704307011;Makarova Valeria;48108033717;Makarova Olga;10;13;;;13;;;;23
NNMK;8704719;51501040077;Kozhemyakin Aleksei;48511133726;Kozhemyakina Vlada;0;;;;0;;;;0
NNMK;8704816;50903233724;Toivonen Robert;47807272229;Toivonen Olga;0;;;;0;;;;0
NNMK;8704913;61205010090;Kozhemyakina Taisija;48511133726;Kozhemyakina Vlada;0;;;;0;;;;0
NNMK;8705019;61003023736;Ekimova Anastasiya;48205103723;Lagoida Elena;10;13;;;13;10;;;13
NNMK;8705116;51106303724;Zhuravlev Ljubomir;49408213737;Zhuravleva Karina;0;13;-13;;0;;;;0
NNMK;8705213;50607223717;Patoka Artjom;48008103710;Patoka Olga;0;;;;0;;;;0
NNMK;8705310;50906092216;Adamtšik Nikita;47802250000;Adamtšik Kristina;-6,5;;;;0;;;;-6,5
NNMK;8705417;50909153729;Mordovin Rodion;47907283726;Mordovina Viktoria;10;13;;;13;10;;;13
NNMK;8705514;51304100075;Zhuravlev Ratmir;49408213737;Zhuravleva Karina;0;13;-13;;0;;;;0
NNMK;8705611;50209273749;Ilin Ilja;37401023736;Ilin Vitali;0;13;;;13;;;;13
NNMK;8705718;61410040106;Maslova Lilia;49501183748;Kalabanova veera;20;13;;;13;;;;33
NNMK;8705815;51007063717;Bodrov Sergey;48506193712;Bodrova Vitaliya;-5,07;;;;0;;;;-5,07
NNMK;8705912;51208173719;Fomin Anton;48304212236;Fomina Anzela;10;13;;;13;10;;;13
NNMK;8706018;39401283728;Skolnov Valentin;47104170433;Skvortsova Jelena;-10;;;;0;;;;-10
NNMK;8706115;51109143711;Chistyakov Sergey;47701133726;Chistyakova Elena;-20;13;;;13;;;;-7
NNMK;8706212;51009073712;Kuhharenkov Matvei;48609053718;Kukharenkova Erika;-5,07;;;;0;;;;-5,07
NNMK;8706319;51206110089;Kovaljov Viktor;47503193717;Kovaljova Tatjana;20;13;;;13;10;;;23
NNMK;8706416;51207140060;Orro Oskar;48805013731;Orro Marta;10;13;;;13;;;;23
NNMK;8706513;50912023737;Zavorotnõi Vladimir;47708083713;Zavorotnaja Olga;0;;;;0;;;;0
NNMK;8706610;51411220108;Potjomkin Maksim;48905062249;Reinsalu Marianna;20;;;;0;;;;20
NNMK;8706717;50509183727;Vasiliev Ilja;48411203726;Vasilieva Rina;-5,07;;;;0;;;;-5,07
NNMK;8706814;51401090196;Babi Matvei;38404130045;Babii Sergii;22;13;;;13;;;;35
NNMK;8706911;50904267063;Pletser Martin;38105133729;Pletser Andrei;10;13;;;13;10;;;13
NNMK;8707017;50704093713;Jazev Artjom;48703213719;Jazeva Darja;0;;;;0;;;;0
NNMK;8707114;50012063716;Zenzinov Mikhail;37001012263;Zenzinov Aleksandr;-13,07;;;;0;;;;-13,07
NNMK;8707211;50710103713;Rjabov Roman;48803182245;Rjabova Anna;-8;;;;0;;;;-8
NNMK;8707318;50905253715;Nikitin Arseniy;49003083737;Nikitina Marta;-8;13;-13;;0;;;;-8
NNMK;8707415;60602153719;Pohjaranta Elina Elsa Maria;34812312231;Pohjaranta Oiva veiko kalervo;30;13;;;13;;;;43
NNMK;8707512;51004223730;Tint Georgi;37103133717;Tint Mihhail;-50;13;;;13;;;;-37
NNMK;8707619;61003223726;Cheremisinova Vasilisa;37206187017;Cheremisinov Artem;0;13;-13;;0;;;;0
NNMK;8707716;51110170167;Bogdanov Gordei;47301310079;Talimäe Liili;0;13;;;13;50;;;-37
NNMK;8707813;50804273710;Zajats Arseni;47111303725;Zayats Elena;0;;;;0;;;;0
NNMK;8707910;50707243745;Bodrov Kirill;38310283711;Vitaly Levchenko;30;13;;;13;;;;43
NNMK;8708016;61504060052;Kruchinina Gabriella;49305063753;Kruchinina Margarita;6;13;;;13;;;;19
NNMK;8708113;50510143724;Baškirov Daniil;47507062212;Baškirova Anna;30;13;;;13;30;;;13
NNMK;8708210;51005285711;Sazonov Arseni;48508195226;Kotina Aleksandra;10;13;;;13;10;;;13
NNMK;8708317;60802243724;Sazonova Olesja;48508195226;Kotina Aleksandra;10;13;;;13;10;;;13
NNMK;8708414;61209173736;Timofejeva Veronika;47408013710;Timofejeva Ljubov;0;13;-13;;0;;;;0
NNMK;8708511;50410123718;Manuilov Maksim;48407193725;Manuilova Anastassia;0;;;;0;;;;0
NNMK;8708618;50801313714;Ivanov Kirill;47008193727;Zinovjeva Jevgenia;0;13;;;13;65;;;-52
NNMK;8708715;50908243723;Petrov Aleksandr;47412283723;Petrova Natalja;-44,41;13;;;13;;;;-31,41
NNMK;8708812;50605143726;Ivkin Nikita;36905193769;Ivkin Andrei;0;;;;0;;;;0
NNMK;8708919;61003213719;Timofejeva Margarita;47408013710;Timofejeva Ljubov;0;13;-13;;0;;;;0
NNMK;8709015;39603043726;Kotisov Pavel;39603043726;Kotisov Pavel;0;;;;0;;;;0
NNMK;8709112;51111263739;Polgorodnik Vitali;45911282210;Polgorodnik Marjana;-20,13;;;;0;;;;-20,13
NNMK;8709219;50511063726;Pilainis Semjon;47707192234;Rjabova Tatjana;0;;;;0;;;;0
NNMK;8709316;50508263747;Pronin Maksim;48511233743;Pronina Oxana;-8;;;;0;;;;-8
NNMK;8709413;61409200044;Vasilieva Irina;37809123739;Vasiliev Dmitry;0;13;-13;;0;;;;0
NNMK;8709510;61101183722;Ippolitova Sofia;37702043710;Ippolitov Vitali;12;;;;0;12;;;0
NNMK;8709617;51405310036;Dvorikov Martin;49201223714;Drovikova Olga;-2;13;;;13;10;;;1
NNMK;8709714;50403083732;Uhhin Artjom;46212233724;Uhhina Natalja;0;;;;0;;;;0
NNMK;8709811;60605203727;Kuznetsova Alina;48708233725;Kuznetsova Anna;0;;;;0;;;;0
NNMK;8709918;60208100831;Fominõhh Darja;60208100831;Fominõhh Darja;0;;;;0;;;;0
NNMK;8710017;51312270210;Loginov Timofei;48801220260;Nesterova Ksenia;0;13;;;13;16;;;-3
NNMK;8710114;61509280037;Kabina Elvira;48907232217;Kabina Tatjana;8;;;;0;;;;8
NNMK;8710211;51110243720;Glebov Damir;36110094214;Glebov German;0;;;;0;;;;0
NNMK;8710318;50907033743;Ossipov Artur;47903282230;Ossipova Julia;0;13;-13;;0;;;;0
NNMK;8710415;61401200092;Ossipova Miroslava;47903282230;Ossipova Julia;0;13;-13;;0;;;;0
NNMK;8710512;51410130083;Smirnov Veniamin;48904233711;Zubova Svetlana;10;13;;;13;10;;;13
NNMK;8710619;51001183718;Sobolev Bogdan;49202073742;Romanova Jekaterina;38;13;;;13;40;;;11
NNMK;8710716;60908273712;Pill Ilona;47809283711;Pill Julia;0;;;;0;;;;0
NNMK;8710813;39810193729;Ayzup Mikhail;37304163727;Aizup Dmitri;-5,5;;;;0;;;;-5,5
NNMK;8710910;50301193732;Drechin Artjom;46908183712;Damelgart Alla;0;;;;0;;;;0
NNMK;8711016;61109122756;Aksjonova Angelina;46312132212;Smirnova Svetlana;-32;;;;0;;;;-32
NNMK;8711113;50402103710;Mitrofanov Daniil;48203162246;Mitrofanova Anastassia;0;;;;0;;;;0
NNMK;8711210;61012133737;Norman Elizaveta;37807142212;Norman Ivan;0;;;;0;;;;0
NNMK;8711317;50610013711;Šaparenko Leonti ;47705242228;Šaparenko Larissa;-1,2;;;;0;;;;-1,2
NNMK;8711414;60507133716;Grudkina Marina;37901313735;Mehläinen Vadim;0;;;;0;;;;0
NNMK;8711511;60507133727;Grudkina Inna;37901313735;Mehläinen Vadim;0;;;;0;;;;0
NNMK;8711618;60906273735;Belaja Maria;47505273724;Belaya Oksana;-13;;;;0;;;;-13
NNMK;8711715;50106253729;Ivanov Mihhail;47204303739;Ivanova Ija;0;;;;0;;;;0
NNMK;8711812;50503143746;Giblov Georgy;47106143733;Shemyakina Svetlana;30;13;;;13;39;;;4
NNMK;8711919;50707203728;Ude Albert;47805193725;Ude Jelena;0;;;;0;;;;0
NNMK;8712015;50602283712;Maslov Aleksandr;47404123725;Maslova Anna;-20,13;;;;0;;;;-20,13
NNMK;8712112;51307170182;Linnik Kristian;46104283729;Linnik Natalja;0;13;;;13;;;;13
NNMK;8712219;50805130037;Tarasov Danylo;47702140104;Tarasova Oksana;0;13;;-13;0;;;;0
NNMK;8712316;60610223719;Balyabkina Anastasia;37709213713;Balabkin Dmitry;0;;;;0;;;;0
NNMK;8712413;61011243712;Udodenko Darya;46911122218;Zhuravleva Tatiana;-24;;;;0;;;;-24
NNMK;8712510;51001193736;Dratšan Fjodor;48104033726;Dratšan Anna;-6,5;;;;0;;;;-6,5
NNMK;8712617;50101103762;Kuznetsov Vladimir;47106073722;Kuznetsova Tatjana;-32,5;;;;0;;;;-32,5
NNMK;8712714;51206070190;Tarasov Mykhailo;47702140104;Tarasova Oksana;0;13;;-13;0;;;;0
NNMK;8712811;61506290127;Rozova Natalia;38112162714;Rozov Sergei;0;13;-13;;0;;;;0
NNMK;8712918;61506290116;Rozova Ksenia;38112162714;Rozov Sergei;0;13;-13;;0;;;;0
NNMK;8713014;51209043730;Lepekhin Ivan;47602252228;Lepekhina Svetlana;10;13;;;13;;;;23
NNMK;8713111;50104033737;Arhipenko Arseni;47501183722;Arkhipenko Elena;-13;;;;0;;;;-13
NNMK;8713218;51207022720; Ude Leonard;47805193725;Ude Jelena;0;;;;0;;;;0
NNMK;8713315;50903313716;Tšaikin Ivan;47906063728;Tšaikina Olga;0;;;;0;;;;0
NNMK;8713412;50708143711;Ostapenko Ilja;49002133714;Ostapenko Maria;38;13;;;13;38;;;13
NNMK;8713519;61103173714; Gongadze Maria;48112113716;Antonova Tatjana;-40;13;;;13;25;;;-52
NNMK;8713616;61005203711;Openko Elisabet;48101072223;Openko Viktoria;-50;13;;;13;;;;-37
NNMK;8713713;51405230316;Savenok Nykyta;48703030164;Savenok Iryna;0;13;;-13;0;;;;0
NNMK;8713810;51405230305;Savenok Jaroslav;48703030164;Savenok Iryna;0;13;;-13;0;;;;0
NNMK;8713917;50910260086;Šulženko Daniil;48703030164;Savenok Iryna;0;13;;-13;0;;;;0
NNMK;8714013;61012303717;Plõta Aleksandra;48209163719;Bõstrova Anastassia;0;13;;;13;;;;13
NNMK;8714110;61502270166;Maksimova Nikoletta;49412220030;Maksimova Marina;20;13;;;13;33;;;0
NNMK;8714217;50903013753;Dukatš Artjom;37707133722;Dukatš Aleksandr;0;;;;0;;;;0
NNMK;8714314;51002163715;Dragunov Matvei;47605193719;Dragunova Marija;6;;;-10;-10;;;;-4
NNMK;8714411;51004063713;Antipov Egor;47101083715;Antipova Natalja;-0,13;;;;0;;;;-0,13
NNMK;8714518;50608113716;Yanchenko Aleksandr;48608043717;Yanchenko Alevtina;0;;;;0;;;;0
NNMK;8714615;51006193717;Koptjakov Arseni;38902123720;Koptjakov Ivan;0;;;;0;;;;0
NNMK;8714712;50809213726;Šitov Mark;47802013714;Šitova Jelena;-1,2;;;;0;;;;-1,2
NNMK;8714819;50909013728;Jakovlev Nikita;48708313717;Jakovleva Veronika;10;13;;;13;23;;;0
NNMK;8714916;51412110133;Karsakov Deniss;48502122712;Ivanova Natalja;20;13;;;13;23;;;10
NNMK;8715012;61603240211;Podlegajeva Jesenia;48002033717;Baikova Tatjana;0;13;;;13;15;;;-2
NNMK;8715119;51608010083;Dimitrov Nikita;48408173738;Dimitrova Irina;10;13;;;13;;;;23
NNMK;8715216;50904233740; Barinov Marat;47908223711;Barinova Nadežda;-1,2;;;;0;;;;-1,2
NNMK;8715313;50901073719;Baškirov Aleksandr;48107082216;Baškirova Natalja;0;;;;0;;;;0
NNMK;8715410;61002093714;Zolina Arina;47801063722;Deryabina Elena;0;;;;0;;;;0
NNMK;8715517;50911157050;Galimov Barit;47810312245;Yakub Natalia;0;;;;0;;;;0
NNMK;8715614;50605013743;Shilov Mikhail;48705132217;Shilova Aleksandra;-1,2;;;;0;;;;-1,2
NNMK;8715711;50809043713;Persidski Artemi;48401192241;Vladoiu-Predi Svetlana;0;;;;0;;;;0
NNMK;8715818;50710303714;Stulov Ivan;36502073722;Stulov Oleg;0;;;;0;;;;0
NNMK;8715915;60312013713;Roosi Sofia;47512083725;Roosi Viktoria;-13,13;;;;0;;;;-13,13
NNMK;8716011;39603213717;Doketov Vladislav;36909153717;Doketov Sergei;-6,5;;;;0;;;;-6,5
NNMK;8716118;50904170020;Popovych Nikita;45803230097;Popovych Olha;0;13;;-13;0;;;;0
NNMK;8716215;51104143741;Boychenko Damir;48504242252;Boychenko Svetlana;0;13;-13;;0;;;;0
NNMK;8716312;51208033718;Boychenko Matvei;48504242252;Boychenko Svetlana;0;13;-13;;0;;;;0
NNMK;8716419;51409290018;Boychenko Nikita;48504242252;Boychenko Svetlana;0;13;-13;;0;;;;0
NNMK;8716516;51206060183;Bolshakov Maksim;49112243723;Bolshakova Tatjana;0;13;-13;;0;;;;0
NNMK;8716613;51111033728;Lesnichenko Maxim;49201113745;Lesnichenko Evgenia;0;13;-13;;0;;;;0
NNMK;8716710;61103233736;Reinol Olivia;45605093710;Gulenok Tatjana;20;13;;;13;;;;33
NNMK;8716817;51206253712;Zuev Artemi;48306173714;Zueva  Anna;0;13;-13;;0;;;;0
NNMK;8716914;51206160145;Vivcharchuk Volodymyr;48712150183;Vivcharchuk Olena;0;13;;-13;0;;;;0
NNMK;8717010;61503140192;Vivcharchuk Oksana;48712150183;Vivcharchuk Olena;0;13;;-13;0;;;;0
NNMK;8717117;51004300078;Vivcharchuk Vitalii;48712150183;Vivcharchuk Olena;0;13;;-13;0;;;;0
NNMK;8717214;61411290191;Korako Myroslava;48710270155;Korako Mariia;0;13;;-13;0;;;;0
NNMK;8717311;61408230223;Lomakina Sofiia;48704180133;Lomakina Oksana;0;;;;0;;;;0
NNMK;8717418;51404210047;Leonov Daniil;48910253720;Sjutkina Jekaterina;0;13;;;13;65;;;-52
NNMK;8717515;51407220221;Gontšarov Matvei;38402183714;Gontšarov Dmitri;0;;;;0;;;;0
NNMK;8717612;51109290216;Kondrashkin Danila;48807230068;Voronina Ekaterina;10;;;-10;-10;;;;0
NNMK;8717719;51312020284;Voronin Artem;48807230068;Voronina Ekaterina;10;;;-10;-10;;;;0
NNMK;8717913;51310070134;Kottšanov Jelisei;47606092214;Koltšanova Jelena;0;13;;;13;;;;13
NNMK;8718019;51209063733;Kostrichkin Gordei;38001253737;Kostrichkin Nikolay;10;13;;;13;;;;23
NNMK;8718116;61208063718;Kopõlova Veera;47802233718;Grebeškova Tatjana;20;13;;;13;33;;;0
NNMK;8718213;61207183733;Giblova Maria;47106143734;Shemyakina svetlana;20;13;;;13;20;;;13
NNMK;8718310;51506200133;Tüvi Vladlen;37606053722;Tüvi Vladimir;20;13;;;13;33;;;0
NNMK;8718417;60508053718;Brzezitskaja Evelina;47907243718;Tikhomirova Galina;10;13;;;13;20;;;3
NNMK;8718514;51310310023;Manuilov Vladimir;37905253716;Manuilov Andrey;10;13;;;13;10;;;13
NNMK;8718611;51505230189;Gusseinov Artjom;49502103719;Iotsis Anna;10;13;;;13;10;;;13
NNMK;8718718;60208083719;Sussi Viktorija;60208083719;Sussi Viktorija;10;13;;;13;75;;;-52
NNMK;8718815;51004220017; Zabegaev Vladimir;48501080074;Zabegaeva Irina ;-50;13;;;13;15;;;-52
NNMK;8719018;60911030020;Barabanova Viktoria;48401263713;Barabanova Irina;0;13;;-13;0;;;;0
NNMK;8719115;61005240062;Dmitriieva Yaroslava;48711070131;Dmitriieva Maryna;0;13;;-13;0;;;;0
NNMK;8719212;50711300031;Dmitriiev Artem;48711070131;Dmitriieva Maryna;0;13;;-13;0;;;;0
NNMK;8719319;50906173717;Lavrentsov Matvei;48204193737;Lavrentsova Anna;10;13;;;13;11;;;12
NNMK;8719416;50606213738;Lavrentsov Daniil;48204193737;Lavrentsova Anna;10;13;;;13;11;;;12
NNMK;8719513;50109023722;Bõkov Ilja;47307123715;Bõkova Galina;-5,5;;;;0;;;;-5,5
NNMK;8719610;50804093734;Dovnar Igor;48306292247;Dovnar Olga;-1,2;;;;0;;;;-1,2
NNMK;8719717;50703133712;Persitski Anton;37509212215;Persitski Deniss;0;;;;0;;;;0
NNMK;8719814;50806183721;Belov Sergei;48609172233;Belova Olesja;0;;;;0;;;;0
NNMK;8719911;50707167055;Lohmatov Igor;36802093712;Lohmatov Sergei;0;;;;0;;;;0
NNMK;8720010;50705053719;Gritsenko Aleksandr;48410043719;Gritsenko Natalja;-50;13;;;13;15;;;-52
NNMK;8720117;50410223713;Fedoseev Rodion;47507183719;Fedoseeva Yana;0;;;;0;;;;0
NNMK;8720214;51203070118;Letitski Roman;37902133725;Letitski Roman;30;13;;;13;;;;43
NNMK;8720311;50504243735;Izjumov Daniil;47301073736;Izjumova Viktoria;0;;;;0;;;;0
NNMK;8720418;51010033716; Persidski Vsevolod;48401192241;Vladoiu-Predi Svetlana;0;;;;0;;;;0
NNMK;8720515;60609073718;Kriina Aleksandra ;47201293726;Netšajeva Natalja;-5,07;;;;0;;;;-5,07
NNMK;8720612;50706073716;Trenin Timofei;37709072256;Trenin Roman;0;;;;0;;;;0
NNMK;8720719;50903023716;Poljakov Danil ;47608062231; Nekrassova Viktoria;0;;;;0;;;;0
NNMK;8720816;60910107109;Naumova Marja;47201280282;NAUMOVA JELENA;-20,13;;;;0;;;;-20,13
NNMK;8720913;51003203733; Romanov Ruslan;47909167018;Romanova Oxana ;-5,07;;;;0;;;;-5,07
NNMK;8721019;50810123719;Šitov Ernest;38311073719;Šitov Vladimir;-2;13;;;13;;;;11
NNMK;8721116;51309300122;Antipenko Vladimir;48006153717;Antipenko Jekaterina;10;13;;;13;10;;;13
NNMK;8721213;51008214729;Šutov Aleksandr;48105073719;Šutova Anastassia;0;13;;;13;;;;13
NNMK;8721310;50711217055;Botskov Vsevolod;36807313732;Bõtškov Valeri;8;13;;;13;;;;21
NNMK;8721417;50711123710;ILJIN MAKSIM;46106063713;ILJINA NIINA;-1;;;;0;;;;-1
NNMK;8721514;50906227132;Reinol Jelissei;44609283721;Reinol Valentina;-52;13;;;13;15;;;-54
NNMK;8721611;50908113718;Grigorjev Veniamin;37312043712;Grigorjev Nikolai;0;;;;0;;;;0
NNMK;8721718;50803290227;Bõkov Artur;33901170324;Bõkov Albert;30;13;;;13;;;;43
NNMK;8721815;50009090014;Kulikov Lev;48109280060;Kulikova Jekaterina;0;;;;0;;;;0
NNMK;8721912;50911303714;Streff Erik ;48002212217;Streff Julia;0;;;;0;;;;0
NNMK;8722018;60502273714;Belaja Anastassija;36504103711;Belõi Boriss;30;13;;;13;30;;;13
NNMK;8722115;50802233716; Ivanov Vjatšeslav;48606103718; Ivanova Olesja;0;;;;0;;;;0
NNMK;8722212;50901073719;Baškirov Aleksandr;48107082216;Baškirova Natalja;-20,13;;;;0;;;;-20,13
NNMK;8722319;50709182758;Losev Leonid;47405172212;Loseva Elena;38;13;;;13;;;;51
NNMK;8722416;51109033720;Smolennikov Maksim;47810013719;Smolennikova Jelena;38;;;;0;38;;;0
NNMK;8722513;50611093717;Voronin Evgeni;47910192212;SOKOLOVSKAYA SVETLANA;-5;;;;0;;;;-5
NNMK;8722610;60906273735;Belaja Maria;47505273724;Belaya Oksana;20;;;;0;;;;20
NNMK;8722717;50612232728;Tapner German;48410122213;Tapner Olga;-20,13;;;;0;;;;-20,13
NNMK;8722814;50701083716;Markelov Deniss;48203293716;Markelova Darja;17,87;;;-20;-20;;;;-2,13
NNMK;8722911;60404210917;Rozova Diana;48309083719;Vihoreva Olga;0;13;-13;;0;;;;0
NNMK;8723017;50908313719;Babi Timofei;38404130045;Babii Sergii;-20,13;;;;0;;;;-20,13
NNMK;8723114;51011293713;Babi Nikita;38404130045;Babii Sergii;-20,13;;;;0;;;;-20,13
NNMK;8723211;51111013725;Horlunov Maksim;47206213717;Horlunova Svetlana;38;13;;;13;93;;;-42
NNMK;8723318;61108280097;Krause Mia kamila;46608063716;Valme Jelena;0;;;;0;;;;0
NNMK;8723415;61102213717;Sborik Lilia ;48712043716;Ushakova Anastasia;20;13;;;13;20;;;13
NNMK;8723512;50806153711;Avaryaskin Anton;38310213717;Avaryaskin Alexander;-8;13;;;13;;;;5
NNMK;8723619;61001153720;Rudnitskaja Evelina;48504072239;Rudnitskaja Olga;0;;;;0;;;;0
NNMK;8723716;50508183755; Netšajev Nikita;37606273715; Netšajev Deniss;0;;;;0;;;;0
NNMK;8723813;50702213710;Kuzmin Aleksei;48004103734;Kuzmina Maria ;-5,07;;;;0;;;;-5,07
NNMK;8723910;60109213717;Raudsepp Ingrid;47702113728;Raudsepp Tatjana;-20,13;;;;0;;;;-20,13
NNMK;8724016;50911280043;Zobnev Oleksii;49102020071;Zobnieva Nadezda;0;13;;-13;0;;;;0
NNMK;8724113;51109083722;Rubannikov Svjatoslav;48606113747;Rubannikova Liudmila;0;13;;;13;;;;13
NNMK;8724414;60901133720;Grigirjeva Milena;48302143717;Grigorieva  Nadezhda;-13;;;;0;;;;-13
NNMK;8724511;60901133714;Grigorjeva Polina;48302143717;Grigorieva  Nadezhda;-13;;;;0;;;;-13
NNMK;8724618;60606067118;Gvozdeva Daria;48707022214;Gvozdeva Diana;-8;;;;0;;;;-8
NNMK;8724715;60601013724;Maikova Ksenija;47112273729;Maikova Larissa;-6,5;;;;0;;;;-6,5
NNMK;8724812;51409260117; Ushakov Demid;48712043716;Ushakova Anastasia;0;;;;0;;;;0
NNMK;8724919;60510163728;Šlokun Aleksa;48004243735;Šlokun Svetlana;-19,5;;;;0;;;;-19,5
NNMK;8725015;51312020088; Rassokhin Vitali;48112132210; Makarenkova Elena;10;13;;;13;10;;;13
NNMK;8725112;60903013710;Morozova Varvara;49109093722;Morozova Olesja;-6,5;;;;0;;;;-6,5
NNMK;8725510;50811193718;Noga Ivan;47606240378;Danilova Inga;-0,2;;;;0;;;;-0,2
NNMK;8725811;50703013758;Kukk Martin;48303133748;Kukk Olga;-6,5;;;;0;;;;-6,5
NNMK;8725918;39308063745;Tarasjuk Sergei;47204303728;Tarasjuk Natalja;-21,07;;;;0;;;;-21,07
NNMK;8726014;50706143712;Ivanov Daniil;38401053726;Ivanov Mihhail;30;13;;;13;43;;;0
NNMK;8726315;50612283716;KOLYAZIN DANIEL;47906173719;MATVEJEVA JELENA;-6,5;;;;0;;;;-6,5
NNMK;8726616;50712260257;Kurganski Marat;00075009148;Narva linna sotsiaalabiamet Narva sotsiaaltöökeskus;0;;;;0;;;;0
NNMK;8727013;50804233726;Karru Oleg;36212243730;Karru Juri;20;13;;;13;;;;33
NNMK;8727110;60705253721;Pogodina Dominika;48401192241;Vladoiu-Predi Svetlana;0;13;-13;;0;;;;0
NNMK;8727217;51305200271;Schmidt Saveli ;49003143715;Slyuzova Julia;30;13;;;13;30;;;13
NNMK;8727314;51308140111;Dylev Maksim;38307193710;Dylev Dmitri;0;;;;0;;;;0
NNMK;8727411;60709143728;Kurling Veronika;47812303718;Kurling Natalja;0;;;;0;;;;0
NNMK;8727916;50904213737;Serzhant Aleksandr;36104163719;Serzhant Gennady;18;13;;;13;18;;;13
NNMK;8728711;60508053718;Brzezitskaja Evelina;47907243718;Tikhomirova Galina;30;13;;;13;30;;;13
NNMK;8729817;50803163714;Bobylev Ilia;47102282234;Vaskovskaia Natalia;0;;;;0;;;;0
NNMK;8729914;50906223710;Külaots Dmitri;48012312227;Külaots Eerika;-1,2;;;;0;;;;-1,2
NNMK;8730013;60708073749;Morozova Maria;48505313718;Morozova Anastasia;0;;;;0;;;;0
NNMK;8730110;51301080131; Borodin Timofey;48709252213; Borodina Anna;0;13;;;13;;;;13
NNMK;8730217;50903093732;Ivanov Arseni;37702253728;Ivanov Oleg;-1,2;;;;0;;;;-1,2
NNMK;8730819;60807297086;Porotikova Neva;47707244918;Porotikova Jelena;-35,13;;;;0;;;;-35,13
NNMK;8730916;60808113738;Puzyrevskaya Darja;48704202219;Puzyrevskaja Tatjana;0;;;;0;;;;0
NNMK;8731012;60811043722;Krylova Ksenia;46011223717;Krylova Elena;-40;13;;;13;;;;-27
NNMK;8731313;50807033729;Stepanov Miroslav;38301073715;Stepanov Mihhail;-20,13;;;;0;;;;-20,13
NNMK;8731614;50711217055;Botskov Vsevolod;36807313732;Bõtškov Valeri;0;;;;0;;;;0
NNMK;8731711;51004163741;Luks Kristian;37602213728;Menšagin Sergei;0;;;;0;;;;0
NNMK;8731818;50706093741;Yakovlev Denis;48603143731;Kuprijanova Julia;0;;;;0;;;;0
NNMK;8731915;51011183711;Dmitrijev Ruslan;48707113711;Dmitrijeva Anastassia;0;13;;;13;10;;;3
NNMK;8732011;61209103731;Kulakovskaja Alisia;48910013713;Kulakovskaja Aleksandra;10;13;;;13;10;;;13
NNMK;8732118;50307090024;Vodolazko Aleksandr;46705020108;Vasileva Elena;-1,2;;;;0;;;;-1,2
NNMK;8732215;50103053713;Bondarev Aleksandr;50103053713;Bondarev Aleksandr;0;;;;0;;;;0
NNMK;8732312;50304263721;Kuznetsov Sergei;47510072254;Zguro-kuznetsova Jelena;-7,7;;;;0;;;;-7,7
NNMK;8732419;51112123765; Manuilov Artjom;38412153723;Manuilov Aleksander ;10;13;;;13;13;;;10
NNMK;8732516;60701043748;Gavrilenko Evelina;46007023712;Gavrilenko Irina;-0,13;;;;0;;;;-0,13
NNMK;8732613;51203313719;Salmanov Viktor;48706123713;Salmanova  Alexandra;20;13;;;13;20;;;13
NNMK;8732710;51308010150;Prantsus Damir ;48409112247; Prantsus Lisandra;0;;;;0;;;;0
NNMK;8732817;51104213715;Frolov Viktor;47403292723;Karina Anna;0;13;;;13;;;;13
NNMK;8732914;50804137120;Keksin Nikita;48205177019;Nüganen Katri;0;13;-13;;0;;;;0
NNMK;8733010;51005153744;Sevjakov Marat;48911242219;Burkina Natalja;16,93;13;;;13;;;;29,93
NNMK;8733117;50910053715;Elksnitis Andrei;47910303711;Elksnitis Svetlana;-8;13;;;13;13;;;-8
NNMK;8733214;50505033710;ZHILIN ARTUR;48610082211;NI YANA;-13,07;;;;0;;;;-13,07
NNMK;8733311;50904273713; Ni Aleksandr;48610082211;NI YANA;-13,07;;;;0;;;;-13,07
NNMK;8733418;51001033710; Golubev Aleksei;48107073730; Golubeba Jelena;0;;;;0;;;;0
NNMK;8733515;50707133721;Babtšenkov Timofei;47407272248;Batšenkova Tatjana;0;;;;0;;;;0
NNMK;8733612;50111284236; Viks Ervin;50111284236; Viks Ervin;0;;;;0;;;;0
NNMK;8733719;50905133717;Chekin Danil ;48808013724; Chekina Julija;-13,07;;;;0;;;;-13,07
NNMK;8733816;51110053737; Pavlov Platon;48009263719;Luchezarnaya Tatjana;-13,07;;;;0;;;;-13,07
NNMK;8733913;50904223722; Alandži Ivan;48812112217;Alandzhi Anastasia;-5,07;;;;0;;;;-5,07
NNMK;8734019;50910243716; Mirežin Maksim;48305053711;Mirezina Tatjana;0;;;;0;;;;0
NNMK;8734116;50909193746; Buiko Aleksandr;37703013726; Buiko Roman;0;;;;0;;;;0
NNMK;8734213;51002233749; Roiu Daniil;48705053723; Roiu Viktoria;0;;;;0;;;;0
NNMK;8734310;51012243727; Roju Marat;49201183717; Roju Jevgenia;0;;;;0;;;;0
NNMK;8734417;60608307115;Kazakova Anastasia;47810270074;Kazakova Ekaterina;0;;;;0;;;;0
NNMK;8734514;60807173720; Ustinova Darina;48303073748; Agabekova Galina;0;;;;0;;;;0
NNMK;8734611;51012293729;Šemarin Serafim;38602253716; Šemarin Mihhail;0;;;;0;;;;0
NNMK;8734718;50610013711;Šaparenko Leonti ;47705242228;Šaparenko Larissa;0;;;;0;;;;0
NNMK;8734815;61102173720;Lantova Jaroslava;48106233730;Matakova Maria;0;;;;0;;;;0
NNMK;8734912;61011123714; Gruznova Anastassija;49006063716; Gruznova Jelena;0;;;;0;;;;0
NNMK;8735018;50809107015; Tarakanov Alex;48710222228; Tarakanova Ekaterina;0;;;;0;;;;0
NNMK;8735115;51109293729;Fremin Mikael;47801273719;Karpenko Natalja;-5,07;;;;0;;;;-5,07
NNMK;8735212;51105063710;Tšerkassov Mark;37702273719;Tšerkassov Sergei;0;;;;0;;;;0
NNMK;8735319;50509293751;Baranov Juri;35808063730;Baranov Oleg;10;13;;;13;10;;;13
NNMK;8735416;51308140111;Dylev Maksim;48204122745; Dyleva Irina;-80;;;;0;;;;-80
NNMK;8735513;51102013715;Golubev Lukas;48302173716;Golubeva Svetlana;0;;;;0;;;;0
NNMK;8735610;51003053723;Kuznetsov Timofei;48902082237;Kuznetsova Anna;0;13;;;13;13;;;0
NNMK;8735717;51209043728;Pavlishin Artjom;48010263711;Pavlishina Olga;0;13;;;13;;;;13
NNMK;8735814;50906287098;Kirichun Gregory;48209042212;Kirichun Anna;0;13;;;13;;;;13
NNMK;8735911;61102030020;Kirichum Simona;48209042212;Kirichun Anna;0;13;;;13;;;;13
NNMK;8736017;51501260233;Žuravljov Artjom;47204223725;Žuravljova Jelena;0;13;;;13;;;;13
NNMK;8736114;50710077069;Mohurenko Daniel;48608150336;Gorislavskaja Juliana;-13,07;;;;0;;;;-13,07
NNMK;8736211;61111083710;Kulpina Anita;48703062266;Kulpina Jelena;0;;;;0;;;;0
NNMK;8736318;51011070087;Strigunov Svjatoslav;47601043713;Virunen Natalja;-13,07;;;;0;;;;-13,07
NNMK;8736415;51202233711;Timanov Aleksandr;47110223717;Timanova Olga;0;;;;0;;;;0
NNMK;8736512;50609223716;Belov Nikita;48005052248;Belova Alla;-5,07;;;;0;;;;-5,07
NNMK;8736619;50211243726;Karganov Marat;50211243726;Karganov Marat;0;;;;0;;;;0
NNMK;8736716;50711013727;Utryakov Nikita;48801143716;Klementieva Tatjana;0;;;;0;;;;0
NNMK;8736813;51201063715;Elksnins Devid;48405263744;Elksnitis Anna;-5,07;;;;0;;;;-5,07
NNMK;8750213;50904133712;Kutõrin Kirill;47601222213;Kutõrina Irina;13,92;13;;;13;13;;;13,92
NNMK;8750310;51011053717;Abuzov Veniamin;49105133721;Abuzova Anastassia;-5,07;;;;0;;;;-5,07
NNMK;8750815;50306183717;Zuev Vladislav;48306173714;Zueva  Anna;0;13;-13;;0;;;;0
NNMK;8750912;61307290137;Zõkova Maria;48805170036;Zykova Elena;-5,07;;;;0;;;;-5,07
NNMK;8751018;50407133712;Zuev Vyacheslav;48306173714;Zueva  Anna;0;13;-13;;0;;;;0
NNMK;8751319;50706120360;Dõmov Artjom;38306223728;Dymov Andres;0;;;;0;;;;0
NNMK;8751814;50506143741;Pikaljov Aleksei;47202083734;Pikaljova Jevgenia;22;13;;;13;22;;;13
NNMK;8751911;51001177046;Kurikov Sergei;47503093711;Lõtkina Marina;0;13;;;13;10;;;3
NNMK;8752017;60607273719;Semjonova Jana;48712253713;Semjonova Maria;0;13;;;13;13;;;0
NNMK;8752415;50408113714;Kaletin Juri;48107043719;Kaletina Olga;0;;;;0;;;;0
NNMK;8752512;50804303711;Petrov Evgeniy;37507263710;Tsvetkov Yuri;-13;;;;0;;;;-13
NNMK;8752619;50804083738;Dorokhov Oleg;48901313710;Dorokhova Gera;-51;;;;0;;;;-51
NNMK;8755218;39709273726;Fomin Sergei;46804222232;Hajuzko Jelena;-5,07;;;;0;;;;-5,07
NNMK;8756314;37907113714;Kuznetsov Aleksei;37907113714;Kuznetsov Aleksei;0;;;;0;;;;0
NNMK;8757818;50103133716;Filippov Kirill;37710163712;Filippov Aleksandr;-20,13;;;;0;;;;-20,13
NNMK;8758215;61004273711;Jermohhina Alisa;48202222230;Jermohhina Anastassia;-20,13;;;;0;;;;-20,13
NNMK;8758312;50411123734;Cheremisinov Genadi;37206187017;Cheremisinov Artem;0;13;-13;;0;;;;0
NNMK;8760711;50007123715;Ivanov Mark;44705193716;Jelina Zinaida;0;;;;0;;;;0
NNMK;8760818;50904303769; Jefimov Aleksandr;48809093729; Malõševa Natalja;0;;;;0;;;;0
NNMK;8760915;50708167114; Muravljov Nikita;48406242226; Muravljova Natalja;-8;;;;0;;;;-8
NNMK;8761011;51202033710; Leonov Maksim;48310313713;Leonova Irina;0;;;;0;;;;0
NNMK;8761118;51203283718;Shabanov Ivan;48904133727;Shabanova Jelena;-5,07;;;;0;;;;-5,07
NNMK;8761215;51403100160; Seleznev Jaroslav;49007193726; Kuznetsova Tatjana;0;13;;;13;10;;;3
NNMK;8761312;61202043739;Evstafjeva Ksenia;48511033718;Evstafieva Olesja;-5,07;;;;0;;;;-5,07
NNMK;8761419;51007263729;Orlov Edvard;48009303716;Reiman Diana;-5,07;;;;0;;;;-5,07
NNMK;8761516;51407030293; Gajevskis-Terehins Ivans;48103060080; Orover Jekaterina;0;;;;0;;;;0
NNMK;8761613;51301080131; Borodin Timofey;48709252213; Borodina Anna;-5,07;;;;0;;;;-5,07
NNMK;8761710;50904233740; Barinov Marat;47908223711;Barinova Nadežda;-5,07;;;;0;;;;-5,07
NNMK;8761817;51209203714;Egorov Daniel;38710033731;Egorov Ivan;0;;;;0;;;;0
NNMK;8761914;51101113716; Rubin Mihhail;47404193719;Rubina Olga;0;;;;0;;;;0
NNMK;8762010;51005097226;Vasiliev Kirill;37809123739;Vasiliev Dmitry;0;13;-13;;0;;;;0
NNMK;8762117;51202080057;Vasiliev Roman;37809123739;Vasiliev Dmitry;0;13;-13;;0;;;;0
NNMK;8762214;51211283734; Silantjev Aleksei;48508133713; Silantjeva Jekaterina;14;13;;;13;13;;;14
NNMK;8762311;51006153711; Šutov Artur;48204082248;Šutova Anna;0;;;;0;;;;0
NNMK;8762418;61109053713;Kilina Ioanna;47912120024;Vengerska Olena;0;;;;0;;;;0
NNMK;8762515;51103063733;Kukk Arseni;48310173710;Kukk Natalja;30;13;;;13;;;;43
NNMK;8762612;51407080338;Lisenko Viktor;37906060235; Lisienko Nikolay;0;13;-13;;0;;;;0
NNMK;8762719;51209120132;Lisjenko Boriss;37906060235; Lisienko Nikolay;0;13;-13;;0;;;;0
NNMK;8762816;61001047042; Pajussaar Jessica;48006280269; Volkova Jan;0;;;;0;;;;0
NNMK;8762913;61009293728;Kovalkova Alina;48511022215;Kovalkova Marina;-5,07;;;;0;;;;-5,07
NNMK;8763019;51211253724; Kovalkov Arseni;48511022215;Kovalkova Marina;-5,07;;;;0;;;;-5,07
NNMK;8763116;51107093719; Mihhailov Daniil;47610033727; Mihhailova Jelena;0;;;;0;;;;0
NNMK;8763213;50812083732;Nikolajev Aleksei ;37009143718;Nikolajev Pavel;0;;;;0;;;;0
NNMK;8763310;61204110036;Troitskaja Anzelika;48404143730;Troitskaja Olesja;0;;;;0;;;;0
NNMK;8763417;50710193721;Mend Edgar;48711202219;Mend Svetlana;0;;;;0;;;;0
NNMK;8763514;50106013722;Kostin Vladislav;46511243724;Kostina Elena;0;;;;0;;;;0
NNMK;8763611;50106113717;Lõssenkov Maksim;47609152213;Lõssenkova Jevgenia;0;;;;0;;;;0
NNMK;8763718;39911133728;Surkov Daniil;39911133728;Surkov Daniil;0;;;;0;;;;0
NNMK;8763815;51106293726;Sõtšov Kirill;47905313717;Surkova Oksana;0;;;;0;;;;0
NNMK;8763912;61103233769;Peussa Vasilisa;48105283738;Peussa Ljudmila;-10;;;;0;;;;-10
NNMK;8764018;51506190142;Avarjaskin Arkadi;38310213717;Avaryaskin Alexander;30;13;;;13;;;;43
NNMK;8764115;61407100126;Demidova Varvara;49004037013;Demidova Ksenia;10;13;;;13;20;;;3
NNMK;8764212;60410273727;Skobeleva Stanislava;48009073714;Skobeleva Oksana ;0;;;;0;;;;0
NNMK;8767918;50205033734;Mõško Aleksandr;37606103726;Myshko Andrey;0;;;;0;;;;0
NNMK;8768014;51105183752;Boiko Ilja;48707263719;Ivanova Olga;0;;;;0;;;;0
NNMK;8770316;51105183741;Boiko Artjom;48707263719;Ivanova Olga;0;;;;0;;;;0
NNMK;8770918;39511083723;Karu Bogdan;36703312222;Karu Pjotr;-13,07;;;;0;;;;-13,07
NNMK;8771616;38403242210;Fjodorov Ilja;38403242210;Fjodorov Ilja;0;;;;0;;;;0
NNMK;8771713;50010243737;Volotšinkov Aleksandr;37202083711;Volotšinkov Sergei;-13,07;;;;0;;;;-13,07
NNMK;8771810;50301153715;Volotšinkov Maksim;37202083711;Volotšinkov Sergei;-13,07;;;;0;;;;-13,07
NNMK;8772411;50305023719;Daniltšenko Pavel;37301153716;Daniltšenko Sergei;0;;;;0;;;;0
NNMK;8773313;50301193732;Drechin Artjom;46908183712;Damelgart Alla;10;;;-10;-10;;;;0
NNMK;8774613;50404213722;Kudrjavtsev Pavel;47109112214;Kudrjavtseva Irina;0;13;;;13;13;;;0
NNMK;8775010;60204043737; Zušnikova Anastassija;47910053728;Ivanova Jevgenia;0;;;;0;;;;0
NNMK;8775418;50506013734;Beloshapkin Maksim;37010303716;Beloshapkin Aleksandr;-5,07;;;;0;;;;-5,07
NNMK;8775515;51006163729;Lobin Igor;46911133712;Lobina Alla;0;13;;;13;13;;;0
NNMK;8775612;50703183714;Kirsanov Maksim;48709132226;Veselova Ksenia;0;;;;0;;;;0
NNMK;8776019;50410113722;Ždanov Vladislav;48103143716;Satalkina Jekaterina;-5,07;;;;0;;;;-5,07
NNMK;8777018;50512293742;Varakin Ilja;47703192247;Varakina Natalja;-6,5;;;;0;;;;-6,5
NNMK;8777814;60202153729;Liiv Irina;47602062223;Liiv Nadežda;-5,5;;;;0;;;;-5,5
NNMK;8778114;50509203721;Marokin Evgeni;36407040024;Marokin Andrey;-0,2;;;;0;;;;-0,2
NNMK;8778211;50608133723;Kurotškin Arkadi;37301112223;Kurotškin Aleksei;-24,94;;;;0;;;;-24,94
NNMK;8778318;60609100011;Zhuravskaya Daria;46609290011;Zhuravskaya Elena;-8;13;;;13;;;;5
NNMK;8779618;60802123726;Zhurina Aljona;48401172259;Zhurina Veronika;0;;;;0;;;;0
NNMK;8780018;50305080247;Erjazov Mario;48002117011;Erjazova Natalja;-37;;;;0;;;;-37
NNMK;8780416;50110213719;Issajev Dmitri;48112083726;Maisjuk Olga;0;;;;0;;;;0
NNMK;8780513;50810193713;Egorov Maksim;47509273739;Gladun Irina;-24;13;;;13;20;;;-31
NNMK;8780610;50308133736;Makarov Sergei;45201193738;Solodushenko Valentina;0;;;;0;;;;0
NNMK;8781910;50609273718;Raudsepp Edgar;47702113728;Raudsepp Tatjana;30;13;;;13;;;;43
NNMK;8782210;60401133716;Masterova Anastassija;46002083726;Masterova Natalia;0;13;;;13;;;;13
NNMK;8783413;50707073710;Gadalšin Stepan;47607232217;Gadalšina Ljubov;0;13;;;13;40;;;-27
NNMK;8783714;50812285215; Puškarjov Nikita;48504093718;Puškarjova Natalja;0;;;;0;;;;0
NNMK;8783811;51107123731; Jegorov Klim;47906093727; Jegorova Viktoria;20;13;;;13;;;;33
NNMK;8783918;50309183732;Dylev Nikita;48204122745; Dyleva Irina;0;;;;0;;;;0
NNMK;8784014;51104193721; Konovalov Arseni;37904052245;Konovalov Dmitri ;20;13;;;13;10;;;23
NNMK;8784111;50608313710; Rassokhin Nikita;48112132210; Makarenkova Elena;6,93;13;;;13;6,93;;;13
NNMK;8784218;50905313715; Nikiforov Jevgeni;48209092214; Korzjukova-Nikiforova Jaana;10;13;;;13;;;;23
NNMK;8784315;51112113725;Koževin Demid;46807273714;Koževina Irina;10;13;;;13;22;;;1
NNMK;8784412;61308100150; Kozlova Arina;49105223731; Jamalainen Anastasia;20;13;;;13;;;;33
NNMK;8784519;60201012726;Kutuzova Kristina;48005303738;Rogožina Jekaterina;8,93;;;-10;-10;;;;-1,07
NNMK;8784616;51009113719; Karnavkhov Nikita;47301096523; Karnavkhova Svetlana;-40;13;;;13;;;;-27
NNMK;8784713;51001193714;Kravtšenko Timofei;48507272244;Kravtšenko Jekaterina;0;;;;0;;;;0
NNMK;8784810;51102223712; Kravchenko Maksim;48507272244;Kravtšenko Jekaterina;0;;;;0;;;;0
NNMK;8784917;51110263712;Denisov Daniel;48601122264;Denisova Olesja;0;;;;0;;;;0
NNMK;8785013;50509200022; Karnavkhov Kirill;47301096523; Karnavkhova Svetlana;-40;13;;;13;;;;-27
NNMK;8785110;51109083711;Petra Vladimir ;47903113728;Petra Jelena;0;;;;0;;;;0
NNMK;8785217;50810272741;Ovsjannikov  Viktor;46103132719;Sõtšinskaja  Natalja;0;;;;0;;;;0
NNMK;8785314;61108273723;Nikitina Anna;48301172224;Nikitina Veronika;-5,07;;;;0;;;;-5,07
NNMK;8785411;60903293712;Nikitina Anastasia;48301172224;Nikitina Veronika;-5,07;;;;0;;;;-5,07
NNMK;8785518;60704223717;Malõševa Monika ;36907083711; Malõševa Vadima;-5,07;;;;0;;;;-5,07
NNMK;8785615;51002053718;Perov Ivan;38102060264;Perov Vadim;0;;;;0;;;;0
NNMK;8785712;61002053725;Perova Vera;38102060264;Perov Vadim;0;;;;0;;;;0
NNMK;8785819;50809113731; Makarov Stepan;47712203710;Makarova Oksana;0;13;;;13;;;;13
NNMK;8785916;50910053715;Elksnitis Andrei;47910303711;Elksnitis Svetlana;-13,07;;;;0;;;;-13,07
NNMK;8786012;50411123745; Dargel Nikita;48102183739; Dargel Jekaterina;-13,07;;;;0;;;;-13,07
NNMK;8786119;51201023720;Markov Timur;47109233732;Zaitseva Oksana;-13,07;;;;0;;;;-13,07
NNMK;8786216;51105200036;Orlov Lukian;47709083740;Homjakova Sofja;0;;;;0;;;;0
NNMK;8788117;50403233720;Filippov Nikolai;37710163712;Filippov Aleksandr;30;13;;;13;30;;;13
NNMK;8789019;50111033726;Šatilov Kirill;47910043710;Šatilova Olga;0;;;;0;;;;0
NNMK;8789116;50701233722;Krivonoi Bogdan;48409293725;Koroleva Maria;-26;;;;0;;;;-26
NNMK;8789514;50201233737;Bakunin Jegor;46702062213;Iduškevitš Lesja;-5,07;;;;0;;;;-5,07
NNMK;8789611;51309120186;Terentjev Aleksandr;49509273710;Terentjeva  Jekaterina;0;13;-13;;0;;;;0
NNMK;8789718;50204303748;Mihhejenkov Deniss;47004022231;Mihhejenkova Irina;0;;;;0;;;;0
NNMK;8789815;50210103714;Malovanenko Ivan;47602222218;Igotti Anna;0;;;;0;;;;0
NNMK;8789912;51309120190;Terentjev Mark;49509273710;Terentjeva  Jekaterina;0;13;-13;;0;;;;0
NNMK;8790011;50503252734;Martynov Matvey;47808213712;Kotljakova Jekaterina;-107,07;;;;0;;;;-107,07
NNMK;8790118;61411270057; Potapova Alina;46101222229;Potapova Ljudmila;0;13;;;13;36;;;-23
NNMK;8790215;50707063714;Cheremisinov Artem;37206187017;Cheremisinov Artem;0;13;-13;;0;;;;0
NNMK;8791515;50206013714;Burak Artjom;47803133728;Savtšenko Jelena;-1,2;;;;0;;;;-1,2
NNMK;8791913;51001083712;Mazanov Danila;47504073724;Mazanova Tatiana;-6,5;;;;0;;;;-6,5
NNMK;8792213;60708313725;Baškirova Jekaterina;47807302219;Baškirova Marjana;0;;;;0;;;;0
NNMK;8792611;50910083714;Levtšenko Igor;48306293723;Jarinitš Nadežda;10;13;;;13;13;;;10
NNMK;8792718;60602133727;BOGDANOVA ALISA;38010183730;Bogdanov Dmitri;0;;;;0;;;;0
NNMK;8793416;60602133716;Stupnikova Viktoria;45904193728;Stupnikova Natalia;0;;;;0;;;;0
NNMK;8793513;50309183721;Vaganov Ivan;48112273713;Vaganova Anna;-2,63;;;;0;;;;-2,63
NNMK;8793610;50802243712;Dmitrijev Arseni;38506112245;Dmitrijev Pavel;-20,13;;;;0;;;;-20,13
NNMK;8793717;50211263732;Mihailov Aleksei;99999999999;Selgitamata Selgitamata;0;;;;0;;;;0
NNMK;8794017;60812242220;Turkova Viktoria;46312132213;Smirnova Svetlana;-70;13;;;13;;;;-57
NNMK;8794114;60803193747;Salmanova Jekaterina;35701113740;Subbota Sergey;20;13;;;13;20;;;13
NNMK;8794211;51109193713;Bogatov Artjom;38805287016;Fokin Jevgeni ;30;13;;;13;43;;;0
NNMK;8794318;60607183743;Bulychova Marina;48009133714;Tehhnikova Ekaterina;29,8;13;;;13;25;;;17,8
NNMK;8794415;50803163736;Yaroshenko Aleks;48708073719;Yaroshenko Jelena;0;13;;;13;30;;;-17
NNMK;8794716;50903163739;Moskaljov Roman;47206242229;Moskaleva Nadezda;30;13;;;13;43;;;0
NNMK;8794813;50002270217;Chivil Georgi;50002270217;Chivil Georgi ;0;;;;0;;;;0
NNMK;8794910;51010153729;Minabutdinov Nikita;49106183717;Tsybulya Margarita;-20,13;;;;0;;;;-20,13
NNMK;8795016;51010083711;Trenin Ilja;37709072256;Trenin Roman;0;;;;0;;;;0
NNMK;8795113;51108162723;Bogens Arsen;48408230083;Bogens Ramilya;0;;;;0;;;;0
NNMK;8795210;50612142762;Zaretski Mihhail;47812313736;Zaretskaja Julia;30;13;;;13;40;;;3
NNMK;8795511;51104293716;Salmanov Sergei;48706123713;Salmanova  Alexandra;20;13;;;13;;;;33
NNMK;8795618;51005043726;Salmanov Andrey;48706123713;Salmanova  Alexandra;20;13;;;13;20;;;13
NNMK;8796015;50207313748;Šatalin Anton;47410173711;Šatalina Galina;-5,5;;;;0;;;;-5,5
NNMK;8796112;50311257027;Yanchuk Daniil;47708033711;Ivanova Dina;-50;13;;;13;;;;-37
NNMK;8796219;50807273725;Dankovtsev Nikita;47610082231;Dankovtseva Ljudmila;0;;;;0;;;;0
NNMK;8796316;50706213719;Blagihh Artur;34604223720;Blagihh Klavdia;-1,3;;;;0;;;;-1,3
NNMK;8796413;61112153732;Drel Vitalina;45504153712; Drel Tatjana;0;13;-13;;0;;;;0
NNMK;8796510;50802143717;Bakhvalov Gleb;47206132216;Švaiko Svetlana;0;;;;0;;;;0
NNMK;8796617;60611233721;Bakhvalova Alina;47206132216;Švaiko Svetlana;0;;;;0;;;;0
NNMK;8796714;51112153720;Drel Arseni ;45504153712; Drel Tatjana;0;13;-13;;0;;;;0
NNMK;8796811;50801053724;Sile Oskar;47210123714;Sile Tatjana;0;;;;0;;;;0
NNMK;8797014;50803213736;Dzirun Daniil;47606223714;Jedunova Natalja;-12,13;;;;0;;;;-12,13
NNMK;8797111;50603023718;Mayorov Ivan;48506103715;Mayorova Oksana;0;13;;;13;;;;13
NNMK;8797315;50809173729;Polyakov Jevgeni;47411033737;Mahhašvili Marina;-1,2;;;;0;;;;-1,2
NNMK;8797412;50908063725;Linnik Konstantin;48105293723;Linnik Irina;0;13;;;13;65;;;-52
NNMK;8797519;50809253732;Tsõganov Grigori;47407073747;Tsõganova  Larissa;0;13;;;13;;;;13
NNMK;8797616;50912023715;Smirnov Fjodor;47310043725;Bogatenkova Marina;0;13;;;13;13;;;0
NNMK;8797713;60604163714;Balabanovitš Katarina;47605053718;Balabanovitš Tatjana;0;;;;0;;;;0
NNMK;8798110;50704113725;Kuzmin Nikita;48504113712;Kuzmina Irina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8800118;61504230119;Makarova Darja;47712203710;Makarova Oksana;-11;;;;0;;;;-11
Kultuurimaja Rugodiv;8800215;34905213715;Kosenkov Vladimir;34905213715;Kosenkov Vladimir;4;5;;;5;4;;;5
Kultuurimaja Rugodiv;8800312;47709192222;Tcathuk Anna;47709192222;Tcathuk Anna;-1,35;;;;0;;;;-1,35
Kultuurimaja Rugodiv;8800419;60209093715;Izotova Polina;48012183735;Izotova Irina;-4,65;;;;0;;;;-4,65
Kultuurimaja Rugodiv;8800516;49411113711;Kuslap Polina;49411113711;Kuslap Polina;-0,15;;;;0;;;;-0,15
Kultuurimaja Rugodiv;8800613;61611190136;Popova Melania;49011163712;Levitskaja Valeria;0;;;;0;;;;0
Kultuurimaja Rugodiv;8800710;61403190093;Seleznjova Anastassia;49201103749;Galašova Maria;0;;;;0;;;;0
Kultuurimaja Rugodiv;8800817;61702140040;Geveller Emilia;48801273732;Geveller Natalja;22;13;;;13;22;;;13
Kultuurimaja Rugodiv;8800914;61509090239;Bõstrova Maria;38808023719;Bõstrov Aleksandr;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8801010;60711303710;Belavina Margarita;47509073727;Suhhanova Irina;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8801117;61306100238;Elonen Emily;36703083718;Elonen Nikolai;0;;;;0;;;;0
Kultuurimaja Rugodiv;8801214;61003093719;Fatejeva Lerika;48710133716;Fatejeva Lesja;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8801311;61507290056;Sazonova Diana;48803283716;Sazonova Kristina;-18;;;;0;;;;-18
Kultuurimaja Rugodiv;8801418;61303080044;Larikova Uljana;48402293717;Larikova Nadezhda;-12;;;;0;;;;-12
Kultuurimaja Rugodiv;8801515;61111203720;Kabanova Ksenija;48709023722;Mišihhina Jelena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8801612;47902043716;Pilainis Natalja;47902043716;Pilainis Natalja;0;13;;;13;13;;;0
Kultuurimaja Rugodiv;8801719;47003213729;Korelina Tatjana;47003213729;Korelina Tatjana;-6,4;;;;0;;;;-6,4
Kultuurimaja Rugodiv;8801816;61606200188;Nefedova Polina;49001182213;Nefedova Anna;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8801913;60902103737;Khatchenkova Marianna;48107183720;Võssotskaja Jelena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8802019;61306280310;Lovaris Jasmine Raphaella;48909193717;Smirnova Irina;-13,35;13;;;13;13,35;;;-13,7
Kultuurimaja Rugodiv;8802116;61605150081;Balaban Elizaveta;47904193712;Balaban Jelena;-0,35;;;;0;;;;-0,35
Kultuurimaja Rugodiv;8802213;60506223710;Ida Juta;47911073725;Ida Jekaterina;-4,97;13;;;13;4,97;;;3,06
Kultuurimaja Rugodiv;8802310;60506053719;Kurkova Polina;47707243714;Kurkova Julia;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8802417;61009173719;Ots Karina;48206082748;Ots Veronika;0;;;;0;;;;0
Kultuurimaja Rugodiv;8802514;60505053725;Busygina Alina;48005203712;Busygina Jelena;42;13;;;13;31;;;24
Kultuurimaja Rugodiv;8802611;50301223722;Uljev Artur;47312303747;Uljeva Inna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8802718;51006103711;Makarenko Aleksandr;47705043725;Lijepa Nadezda;0;;;;0;;;;0
Kultuurimaja Rugodiv;8802815;61308040183;Teplova Anastasiia;48601052235;Mahhalova Valentina;33;13;;;13;33;;;13
Kultuurimaja Rugodiv;8802912;60212050823;Lavrinovitš Darja;48107183720;Võssotskaja Jelena;-5,7;;;;0;;;;-5,7
Kultuurimaja Rugodiv;8803018;47704082239;Savitseva Lidia;47704082239;Savitseva Lidia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8803115;61102163746;Tamvilius Varvara;35505040331;Shalamov Jury;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8803212;61402120163;Serova Maria;47704183710;Smirnova Svetlana;0;13;;;13;22;;;-9
Kultuurimaja Rugodiv;8803319;61512290068;Šutova Aljona;48305073736;Ivanova Oksana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8803416;44609013715;Syakki Sofiya;44609013715;Syakki Sofiya;-3;5;;;5;4;;;-2
Kultuurimaja Rugodiv;8803513;48406010001;Bazhenovskaya Hanna;48406010001;Bazhenovskaya Hanna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8803610;44607283722;Samsonova Elena;44607283722;Samsonova Elena;0;5;;;5;4;;;1
Kultuurimaja Rugodiv;8803717;61601130101;Šurmina Marina;37510082238;Šurmin Viktor;22;13;;;13;22;;;13
Kultuurimaja Rugodiv;8803814;61009293728;Kovalkova Alina;48511022215;Kovalkova Marina;42;;;;0;42;;;0
Kultuurimaja Rugodiv;8803911;51607090068;Gheorghiceanu Madalin-Costinel;47710313712;Gheorghiceanu Ilona;-9;13;;;13;;;;4
Kultuurimaja Rugodiv;8804017;51607090166;Fokin Andrey;38805287016;Fokin Jevgeni ;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8804114;61607120255;Korõsova Sofia;48009213739;Vernikova Svetlana;-12;;;;0;;;;-12
Kultuurimaja Rugodiv;8804211;51612040108;Pantelejev Lev;38008113727;Pantelejev Maksim;0;;;;0;;;;0
Kultuurimaja Rugodiv;8804318;60505193726;Lijepa Anastassija;47705043725;Lijepa Nadezda;7,3;13;;;13;7,3;;;13
Kultuurimaja Rugodiv;8804415;61408080094;Gruznova Julia;49101182216;Gruznova Irina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8804512;48902270270;Jefremova Anastassija;48902270270;Jefremova Anastassija;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8804619;61507220062;Bodõljova Melissa;48105032215;Bodõljova Irina;11;;;;0;;;;11
Kultuurimaja Rugodiv;8804716;48201302228;Sein Oksana;48201302228;Sein Oksana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8804813;48710133716;Fatejeva Lesja;48710133716;Fatejeva Lesja;-8;;;;0;;;;-8
Kultuurimaja Rugodiv;8804910;61209193717;Nikolajeva Kristina;48801242213;Nikolajeva Ksenia;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8805016;60205223718;Kobenjak Jelena;47503062236;Kobenjak Svetlana;-0,65;;;;0;;;;-0,65
Kultuurimaja Rugodiv;8805113;47707023732;Parts Teele;47707023732;Parts Teele;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8805210;49404157028;Bazhukova Olga;49404157028;Bazhukova Olga;0;;;;0;;;;0
Kultuurimaja Rugodiv;8805317;50701157035;Sõtšev Kirill;47701073737;Valašas Ljubov;0;;;;0;;;;0
Kultuurimaja Rugodiv;8805414;47703053711;Konovalova Jelena;47703053711;Konovalova Jelena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8805511;46609290011;Zhuravskaya Elena;46609290011;Zhuravskaya Elena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8805618;46911043713;Kangas Jelena;46911043713;Kangas Jelena;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8805715;61602040140;Mihhailova Uljana;48902083724;Mihhailova Kristina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8805812;49801033716;Van Dajana;49801033716;Van Dajana;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8805919;61803070139;Ahmadova Amalia;45409263725;Ots Sofia;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8806015;39707153730;Krutikov Arseni;39707153730;Krutikov Arseni;0;;;;0;;;;0
Kultuurimaja Rugodiv;8806112;51503250301;Kobzar Aleksei;48301212210;Sidorenko Svetlana;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8806219;51304050180;Ivanov Arseni;48404153748;Ivanova Jana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8806316;61409050198;Lazareva Milena;48412113714;Lazareva Irina;-0,15;;;;0;;;;-0,15
Kultuurimaja Rugodiv;8806413;61311230037;Zyuzina Likerija;48705143722;Zyuzina Anna;-9;13;;;13;;;;4
Kultuurimaja Rugodiv;8806510;61401080244;Pärnoja Katrin;37008292245;Pärnoja Artur;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8806617;60708083745;Volkova Darina;48505133715;Merkulova Jelena;-9;;;;0;;;;-9
Kultuurimaja Rugodiv;8806714;36009233726;Klibanov Igor;36009233726;Klibanov Igor;-1,35;;;;0;;;;-1,35
Kultuurimaja Rugodiv;8806811;39505123714;Naumov Nikita;39505123714;Naumov Nikita;-1,7;;;;0;;;;-1,7
Kultuurimaja Rugodiv;8806918;60803133716;Olde Kamilla;48408103733;Shpak Ksenia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8807014;61404300221;Kovaljova Diana;48711203745;Kovaljova Tatjana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8807111;60110273732;Aleksandrova Jelizaveta;47306223716;Zvereva Olga;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8807218;61306030253;Bartoš Angelika;48102273716;Bartoš Alina;-5;13;;;13;11;;;-3
Kultuurimaja Rugodiv;8807315;61012133737;Norman Elizaveta;47906083720;Semjonova Tatjana;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8807412;60201193752;Nikulina Arina;38104273747;Nikulin Vladimir;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8807519;61411200030;Merkulova Polina;48505133715;Merkulova Jelena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8807616;61712090084;Drovikova Nikol;49201223714;Drovikova Olga;0;;;;0;;;;0
Kultuurimaja Rugodiv;8807713;61406110226;Berlin Eva;49007162240;Berlin Ksenia;6;13;;;13;13;;;6
Kultuurimaja Rugodiv;8807810;60812263720;Latina Maria;47701053712;Latina Julia;-4,65;;;;0;;;;-4,65
Kultuurimaja Rugodiv;8807917;60407203731;Voronovich Xenia;46604093728;Markova Ljudmila;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8808013;61502050046;Silina Ksenia;48601242218;Rulkova Veronika;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8808110;60808233725;Lenina Viktoria;48604093710;Lenina Maria;0;;;;0;;;;0
Kultuurimaja Rugodiv;8808217;61004140034;Khlebodarova Apollinariia;47004140050;Fedorova Jelena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8808314;61707020121;Judina Amelia;48011122228;Judina Anastassia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8808411;61402080129;Kuttanen Viktoria;48602222220;Kuttanen Jekaterina;11;13;;;13;24;;;0
Kultuurimaja Rugodiv;8808518;61303190133;Kolesnik Sofia;36911113720;Kolesnik Sergey;0;;;;0;;;;0
Kultuurimaja Rugodiv;8808615;60910063745;Lartsenko Karina;47806083717;Lartsenko Anna;-11;;;;0;11;;;-22
Kultuurimaja Rugodiv;8808712;61108280097;Krause Mia kamila;48409143711;Krause Olga;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8808819;51708280124;Vinogradov Akim;48005223726;Vinogradova Julia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8808916;49904263723;Donina Darja;49904263723;Donina Daria;-3,3;;;;0;;;;-3,3
Kultuurimaja Rugodiv;8809012;61110053727;Matvejuk Sofia;38206062210;Matvejuk Aleksei;22;13;;;13;22;;;13
Kultuurimaja Rugodiv;8809119;61112143714;Lartsenko Alina;47806083717;Lartsenko Anna;-9;;;;0;11;;;-20
Kultuurimaja Rugodiv;8809216;60803083723;Andreeva Anna;47601053710;Jermatškova Jelena;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8809313;61607070153;Zinovieva Jeva;38111012261;Zinoviev Konstantin;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8809410;45211112221;Semenova Nina;45211112221;Semenova Nina;15;5;;;5;;;;20
Kultuurimaja Rugodiv;8809517;48203222257;Andreeva Natalya;48203222257;Andreeva Natalya;-14;;;;0;;;;-14
Kultuurimaja Rugodiv;8809614;45802223729;Osipenkova Galina;45802223729;Osipenkova Galina;-15,35;;;;0;;;;-15,35
Kultuurimaja Rugodiv;8809711;50504140028;Smirnov Aleksandr;50504140028;Smirnov Aleksandr;0;;;;0;;;;0
Kultuurimaja Rugodiv;8809818;61304210110;Groshina Zlata;47508272247;Groshina Marina;-1;;;;0;;;;-1
Kultuurimaja Rugodiv;8809915;60810223726;Vassiljeva Nadezda;48109022217;Vassiljeva Maria;0;;;;0;;;;0
Kultuurimaja Rugodiv;8810014;61207020096;Sukiasyan  Eva;48603123717;Jehrõševa Olga;22;;;;0;;;;22
Kultuurimaja Rugodiv;8810111;46710200001;Chepik Anzhelika;46710200001;Chepik Anzhelika;0;;;;0;;;;0
Kultuurimaja Rugodiv;8810218;51308020277;Kostarev Kirill;47710153717;Kostareva Julia;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8810315;47001043739;Lvova Larissa;47001043739;Lvova Larissa;0;13;;;13;11;;;2
Kultuurimaja Rugodiv;8810412;61208133736;Anina Sofia;47805033710;Anina Inna;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8810519;60508293714;klimtsova Valerija;47811212216;Klimtsova Tatjana;-7,15;;;;0;;;;-7,15
Kultuurimaja Rugodiv;8810616;61210263716;Mihhejenkova Milana;48210293716;Mihhejenkova Natalja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8810713;60510203714;Vallimets Marika;47505233713;Vallimets Olga;-8;;;;0;;;;-8
Kultuurimaja Rugodiv;8810810;61011023719;Fedulova Anastassija;47909072219;Korbut-Fedulova Oksana;-27;;;;0;;;;-27
Kultuurimaja Rugodiv;8810917;61311040010;Polgorodnik Diana;48608093719;Polgorodnik Maria;0;;;;0;;;;0
Kultuurimaja Rugodiv;8811013;60302123722;Agafontseva Kristina;47306250027;Agafontseva Natalja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8811110;60912143725;Zaitseva Emilia;48008022220;Zaitseva Regina;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8811217;39910040036;Nuriev Damir;39910040036;Nuriev Damir;0;;;;0;;;;0
Kultuurimaja Rugodiv;8811314;61605200085;Grati Lilian;47910153723;Grati Tatjana;9;;;;0;;;;9
Kultuurimaja Rugodiv;8811411;51607230191;Sumerin Andrei;49608243742;Pavlova Anna;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8811518;61108013746;Ivanova Jana;48908153728;Ivanova Natalja;-12;;;;0;;;;-12
Kultuurimaja Rugodiv;8811615;61212210069;Muravjova Maria;48209042245;Muravjova Jekaterina;-13,65;;;;0;;;;-13,65
Kultuurimaja Rugodiv;8811712;61711050062;Sabinina Sofia;48401063723;Sabinina Antonina;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8811819;61301040061;Kazakova Jevdokiya;48003283736;Kazakova Tatiana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8811916;51202233711;Timanov Aleksandr;47110223717;Timanova Olga;0;;;;0;;;;0
Kultuurimaja Rugodiv;8812012;51806220217;Kivistik Julian Alvares;48306192219;Dubrovina Maria;-7;;;;0;;;;-7
Kultuurimaja Rugodiv;8812119;61506150039;Dubrovina Esenia;48306192219;Dubrovina Maria;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8812216;60907033711;Pavlova Arina;48701093701;Evdokimova Anastasia;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8812313;51105183728;Nikitin Mikhail;49005293711;Nikitina Veronika;0;;;;0;;;;0
Kultuurimaja Rugodiv;8812410;61209223729;Nikitina Sofia;49005293711;Nikitina Veronika;0;;;;0;;;;0
Kultuurimaja Rugodiv;8812517;46702153743;Kongo Katrin;46702153743;Kongo Katrin;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8812614;36212303719;Jerohhin Vadim;36212303719;Jerohhin Vadim;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8812711;46712153725;Nadejeva Valeria;46712153725;Nadejeva Valeria;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8812818;51608050012;Kink Adrian;48506173714;Kink Tatjana;0;13;;;13;11;;;2
Kultuurimaja Rugodiv;8812915;61610160110;Pratkunas Sofia;48003273729;Gromova Irina;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8813011;49612313712;Ovtšinskaja Liina;34003162231;Fedorov Alexandr;-19,2;;;;0;;;;-19,2
Kultuurimaja Rugodiv;8813118;61502250080;Kiik Olivia;48912262228;Kiik Nadezda;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8813215;61307090016;Krivonoi Kira;48302132267;Krivonoy Polina;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8813312;61805030067;Babikova Vasilissa;49006103713;Vasilevskaya Olga;4;13;;;13;;;;17
Kultuurimaja Rugodiv;8813419;51711040121;Topkin Arseni;49007033744;Topkin Anna;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8813516;49901083721;Lazareva Maria;47512173713;Lazareva Natalja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8813613;60609053748;Guljajeva Alisa;47402182716;Guljajeva Svetlana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8813710;47707023721;Tšudajeva Tatjana;47707023721;Tšudajeva Tatjana;-3;13;;;13;;;;10
Kultuurimaja Rugodiv;8813817;60408073740;Kamaeva Maya;48107063711;Kamajeva Olga;0;;;;0;;;;0
Kultuurimaja Rugodiv;8813914;61403160039;Serpuhhina Amelia;36406203713;Serpuhhin Aleksei;0;13;;;13;13;;;0
Kultuurimaja Rugodiv;8814010;47801063722;Deryabina Elena;47801063722;Deryabina Elena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8814117;51207303721;Lavrov Damir;38706053758;Timoštšuk Jevgeni;-0,15;;;;0;;;;-0,15
Kultuurimaja Rugodiv;8814214;61110043720;Shlukum Jekaterina;48204222218;Shlukum Svetlana;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8814311;60105053735;Aleksandrova Alina;45905182219;Aleksandrova Ljudmila;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8814418;61212070109;Poljakova Alina;47908113720;Poljakova Jelena;-13,65;;;;0;;;;-13,65
Kultuurimaja Rugodiv;8814515;60212203726;Fedossova Aljona;46411083726;Maltseva Galina;-1,35;;;;0;;;;-1,35
Kultuurimaja Rugodiv;8814612;61302250106;Kornejeva Polina;48509113726;Kornejeva Anastassia;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8814719;61308010205;Aleksejeva Uljana;48410263723;Aleksejeva Maria;-12;;;;0;;;;-12
Kultuurimaja Rugodiv;8814816;61306040129;Ivanenko Alisia;48905072212;Ivanenko Olga;-16;;;;0;;;;-16
Kultuurimaja Rugodiv;8814913;61211163726;Shumskaya Anna;49411113711;Kuslap Polina;-0,15;;;;0;;;;-0,15
Kultuurimaja Rugodiv;8815019;60401133716;Masterova Anastassija;46002083726;Masterova Natalia;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8815116;45205173755;Podolskaja Natalja;45205173755;Podolskaja Natalja;0;5;;;5;;;;5
Kultuurimaja Rugodiv;8815213;51210243712;Fenin Ivan;48908043726;Fenina Anna;-41,7;;;;0;;;;-41,7
Kultuurimaja Rugodiv;8815310;61404100079;Gorodnichenko Viktoria;48302210079;Gorodnichenko Ekaterina;-0,15;;;;0;;;;-0,15
Kultuurimaja Rugodiv;8815417;61208223713;Korabljova Darja;47507272214;Korabljova Julia;-13,65;;;;0;;;;-13,65
Kultuurimaja Rugodiv;8815514;47310212218;Medvedeva Anna;47310212218;Medvedeva Anna;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8815611;46405243715;Sheff Tatjana;46405243715;Sheff Tatjana;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8815718;61507210044;Aleksandrova Stanislava;47001293710;Kalinina Svetlana;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8815815;61209290111;Striško Uljana;48801160086;Tepane Maria;-13,65;;;;0;;;;-13,65
Kultuurimaja Rugodiv;8815912;60107063741;Bashurova Jana ;47911163713;Bashurova Olga;-15,35;;;;0;;;;-15,35
Kultuurimaja Rugodiv;8816018;51002263715;Levanidov Jelissei;47107282226;Levanidova  Julia;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8816115;61207163719;Lušnikova Maria;48103062215;Lušnikova Niina;-58;13;;;13;11;;;-56
Kultuurimaja Rugodiv;8816212;61202283736;Osmolovskaja Lika;48112143726;Osmolovskaja Julia;-4,15;;;;0;;;;-4,15
Kultuurimaja Rugodiv;8816319;61203073711;Morgunova Sofia;48512052219;Popova Maria;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8816416;60902023712;Golovkina Darja;47109303717;Golovkina Julia;-4,65;;;;0;;;;-4,65
Kultuurimaja Rugodiv;8816513;61803220214;Zueva Viktoria;48908237011;Zueva Natalia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8816610;47801083714;Kalikova Natalia;47801083714;Kalikova Natalia;2;13;;;13;13;;;2
Kultuurimaja Rugodiv;8816717;51201063715;Elksnins Devid;48405263744;Elksnitis Anna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8816814;60901193729;Tšahhutina Sofja;47312133712;Tšahhutina Julia;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8816911;61502220113;Iis Sofia;46005043746;Kamenskaja Ljudmila;14,7;13;;;13;14,7;;;13
Kultuurimaja Rugodiv;8817017;37501162218;Vishnjakov Igor;37501162218;Vishnjakov Igor;-2,2;;;;0;;;;-2,2
Kultuurimaja Rugodiv;8817114;61303200099;Neprimerova Marta;48409123719;Kuznetsova Natalja;-11;13;;;13;;;;2
Kultuurimaja Rugodiv;8817211;61304220150;Harak Mischelle;49104143712;Bulõtševa Anastassija;0;;;;0;;;;0
Kultuurimaja Rugodiv;8817318;60909023747;Karimova Uljana;48804103714;Karimova Tatjana;-1,35;;;;0;;;;-1,35
Kultuurimaja Rugodiv;8817415;61201263728;Mustonen Tiina;47404293725;Mustonen Jelena;-4,15;;;;0;;;;-4,15
Kultuurimaja Rugodiv;8817512;61509180140;Kruglova Viktoria;48706273710;Kruglova Tatjana;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8817619;51512160182;Kudryvtsev Nikolai;44707023737;Goršenina Svetlana;-18,35;;;;0;;;;-18,35
Kultuurimaja Rugodiv;8817716;60406113716;Tepljakova Polina;47804263716;Tepljakova Olga;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8817813;61006173726;Geveller Sofia;48504013728;Geveller Irina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8817910;61208183716;Girejeva Kassandra;46906253716;Seppenen Natalia;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8818016;47309143728;Patotosova Ljudmila;47309143728;Patotosova Ljudmila;0;;;;0;;;;0
Kultuurimaja Rugodiv;8818113;61503160227;Mughal Susanna;48402223712;Lobanova Irina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8818210;48110143716;Voitik Marina;48110143716;Voitik Marina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8818317;61602100118;Jakovleva Ksenia;47302113716;Jakovelva Jelena;-11;13;;;13;;;;2
Kultuurimaja Rugodiv;8818414;60303043746;Kutuzova Arina;37609262269;Kutuzov Igor;-2,4;;;;0;;;;-2,4
Kultuurimaja Rugodiv;8818511;61603280185;Goldman Diana;48305083710;Goldman Tatjana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8818618;60612050031;Mishina Marianna;47105310103;Galitskaja Juliia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8818715;51009073712;Kuhharenkov Matvei;48609053718;Kukharenkova Erika;0;;;;0;;;;0
Kultuurimaja Rugodiv;8818812;61503160227;Mughal Susanna;48402223712;Lobanova Irina;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8818919;61502250080;Kiik Olivia;48912262228;Kiik Nadezda;0;;;;0;;;;0
Kultuurimaja Rugodiv;8819015;61310270055;Prikhodko Varvara;46804062248;Prikhodko Yulia;-1,35;;;;0;;;;-1,35
Kultuurimaja Rugodiv;8819112;61511020199;Goryunova Anna;48905203728;Rõndina Jevgenia;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8819219;61104072738;Alekseeva Emilia;46109122219;Smirnova Juzefta;0;13;;;13;11;;;2
Kultuurimaja Rugodiv;8819316;61202023715;Žuljeva Marjana;47212012279;Žuljeva Tatjana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8819413;60801160235;Alekseeva Ksenya;48612292240;Aleksejeva Aleksandra;9,65;13;;;13;;;;22,65
Kultuurimaja Rugodiv;8819510;61705070037;Zerkalova Viktoria;48206093730;Zerkalova Svetlana;-11;13;;;13;11;;;-9
Kultuurimaja Rugodiv;8819617;61005257037;Starõhh Margarita;48106163745;Reinsalu Oksana;-4,65;;;;0;;;;-4,65
Kultuurimaja Rugodiv;8819714;51210253729;Männik Egor;47508192233;Männik Natalja;-13,65;;;;0;;;;-13,65
Kultuurimaja Rugodiv;8819811;60908243746;Kandalova Eva;48707312225;Kandalova Varvara;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8819918;47501273710;Bursova Svetlana;47501273710;Bursova Svetlana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8820017;60302173724;Khokhlova Anastasija;47703043715;Khokhlova Viktoria;0;;;;0;;;;0
Kultuurimaja Rugodiv;8820114;61710110079;Kozõreva Polina;49804213751;Kozõreva Darja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8820211;61602270020;Vinogradova Alexa;49512073733;Vinogradova Katrina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8820318;61405080035;Rezvukhina Anita;48212062217;Rezvukhina Elina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8820415;51410130083;Smirnov Veniamin;48904233711;Zubova Svetlana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8820512;60204293751;Moissejeva Aleksandra;60204293751;Moissejeva Aleksandra;2;;;;0;;;;2
Kultuurimaja Rugodiv;8820619;61405280221;Gulova Anastassia;49002213728;Gulova Aleksandra;0;;;;0;;;;0
Kultuurimaja Rugodiv;8820716;51806250075;Jegorov Georgi;48303070054;Jegorova Anna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8820813;51702220086;Roop Aleksandr;39402127015;Hetun Mykhailo;22;13;;;13;;;;35
Kultuurimaja Rugodiv;8820910;50808257062;Gerstman Maksim;48607243713;Gerstman Natalja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8821016;45207022226;Zakharova Liubov;45207022226;Zakharova Liubov;4;5;;;5;8;;;1
Kultuurimaja Rugodiv;8821113;60604163714;Balabanovitš Katarina;47605053718;Balabanovitš Tatjana;-4,65;;;;0;;;;-4,65
Kultuurimaja Rugodiv;8821210;61308100237;Nevzorova Daniella;49106063727;Nevzorova Ekaterina;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8821317;61609150100;Shvetsova Uljana;49208023715;Shvetsova Olga;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8821414;46510013719;Dubinina Ljudmila;46510013719;Dubinina Ljudmila;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8821511;60411263736;Laanemann Alyona;47309283731;Laanemann Tanya;0;;;;0;;;;0
Kultuurimaja Rugodiv;8821618;61503290156;Takhtarova Valeria;49209213747;Takhtarova Ekaterina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8821715;44303132710;Gussarova Ljudmila;44303132710;Gussarova Ljudmila;4;5;;;5;4;;;5
Kultuurimaja Rugodiv;8821812;51203283718;Shabanov Ivan;48904133727;Shabanova Jelena;-13,65;;;;0;;;;-13,65
Kultuurimaja Rugodiv;8821919;61810250246;Dymova Mariia;38010173711;Dymov Dmitrii;11;;;;0;11;;;0
Kultuurimaja Rugodiv;8822015;51808160031;Urenjov Maksim;49310123732;Urenjova Irina;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8822112;60202043738;Krasnova Renata;47703103715;Fedossejeva Jelena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8822219;35208223729;Laryushin Alexander;35208223729;Laryushin Alexander;0;;;;0;;;;0
Kultuurimaja Rugodiv;8822316;51004163719;Kangur Kristofer;47611172235;Košeleva Jelena;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8822413;61411200030;Merkulova Polina;48505133715;Merkulova Jelena;8,65;13;;;13;9;;;12,65
Kultuurimaja Rugodiv;8822510;60609093721;Šafrova Jana;48901263717;Šafrova Jekaterina;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8822617;60412143732;Lugina Alina;48002163711;Slepova Daria;15;13;;;13;15;;;13
Kultuurimaja Rugodiv;8822714;45609033717;Voronina Tatiana;45609033717;Voronina Tatiana;8;5;;;5;8;;;5
Kultuurimaja Rugodiv;8822811;50204083731;Tsistjakov Aleksei;47309133724;Tsistjakova Alla;0;;;;0;;;;0
Kultuurimaja Rugodiv;8822918;60410243728;Marova Jekaterina;46812302229;Marova Jelena;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8823014;61708100064;Naumova Maria;48609172218;Ratsõborskaja Sofia;-9;;;;0;;;;-9
Kultuurimaja Rugodiv;8823111;49003283716;Remizova Olesya;49003283716;Remizova Olesya;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8823218;61211070279;Sokolova Janika;37510040086;Sokolov Aleksandr;0;;;;0;;;;0
Kultuurimaja Rugodiv;8823315;50601123736;Koptšikov Jegor;49502153732;Žurikova Kristina;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8823412;60406293723;Savitševa Viktoriya;47502053714;Savitševa Lidia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8823519;61108303713;Rezvukhina Vasilisa;48212062217;Rezvukhina Elina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8823616;61203273712;Andreeva Kristina;48404123716;Andreeva Olga;22;;;;0;22;;;0
Kultuurimaja Rugodiv;8823713;37104103712;Starichkov Dmitry;37104103712;Starichkov Dmitry;-1,35;;;;0;;;;-1,35
Kultuurimaja Rugodiv;8823810;51104273713;Kornõšev Jaroslav;47805293731;Kornõševa Julia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8823917;61206113734;Ivanova Kira;38108163721;Ivanov Ilya;-2,65;;;;0;;;;-2,65
Kultuurimaja Rugodiv;8824013;50702183710;Pukk Miroslav;38109113724;Pukk Eduard;-0,15;;;;0;;;;-0,15
Kultuurimaja Rugodiv;8824110;51402090190;Jefimov Saveli;47702073717;Belyaeva Jelena;-9;13;;;13;;;;4
Kultuurimaja Rugodiv;8824217;61603130057;Stolfat Liel;49301123733;Stolfat Anna;0;13;;;13;13;;;0
Kultuurimaja Rugodiv;8824314;60502023755;Raud Angelina;46904213748;Raud Svetlana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8824411;45003043723;Tsarjova Tatjana;45003043723;Tsarjova Tatjana;0;5;;;5;;;;5
Kultuurimaja Rugodiv;8824518;44701103732;Gorbacheva Liudmila;44701103732;Gorbacheva Liudmila;0;5;;;5;;;;5
Kultuurimaja Rugodiv;8824615;44103312234;Ivoylova Nina;44103312234;Ivoylova Nina;0;5;;;5;;;;5
Kultuurimaja Rugodiv;8824712;45408193713;Randoja Veera;45408193713;Randoja Veera;0;5;;;5;;;;5
Kultuurimaja Rugodiv;8824819;45309242243;Tuuder Tiiu;45309242243;Tuuder Tiiu;0;5;;;5;;;;5
Kultuurimaja Rugodiv;8824916;45406102285;Kaasik Liidia;45406102285;Kaasik Liidia;0;5;;;5;;;;5
Kultuurimaja Rugodiv;8825012;61006023718;Merkulaeva Angelina;47711073729;Merkulaeva Liubov;-4,65;;;;0;;;;-4,65
Kultuurimaja Rugodiv;8825119;60203153723;Moissejenko Darja;47506273711;Moissejenko Irina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8825216;50305193721;Urm Margus;46903313721;Urm Maria;0;;;;0;;;;0
Kultuurimaja Rugodiv;8825313;51305200271;Schmidt Saveli ;49003143715;Slyuzova Julia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8825410;60902103726;Šabanina Emeli;45711032211;Šabanina Alla;0;;;;0;;;;0
Kultuurimaja Rugodiv;8825517;61002083729;Danilova Nika;48412032213;Danilova Anna;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8825614;60801293710;Lidikauskaite Sandra;48509300720;Lidikauskiene Tatjana;11;13;;;13;15;;;9
Kultuurimaja Rugodiv;8825711;51212043710;Getalov Matvei;47902153718;Solovjova Oksana;-4,65;;;;0;;;;-4,65
Kultuurimaja Rugodiv;8825818;51806010217;Mihhailov Oliver;48403302211;Mihhailov Irina;-64,5;;;;0;;-64,5;;0
Kultuurimaja Rugodiv;8825915;61601150148;Sonder Vera;47407073714;Sonder Jekaterina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8826011;61610020153;Terehhova Polina;47902272752;Terehhova Olesja;31;;;;0;;;;31
Kultuurimaja Rugodiv;8826118;50110253725;Urm Sergo;46903313721;Urm Maria;-5,7;;;;0;;;;-5,7
Kultuurimaja Rugodiv;8826215;60912253727;Tolstopyatova Sofia;48711143728;Tolstopyatova Svetlana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8826312;60103263733;Skvortsova Olesja;48011112210;Kutuzova Anna;-0,15;;;;0;;;;-0,15
Kultuurimaja Rugodiv;8826419;61008253728;Naumova Karina;46211143720;Vorobjova Vassilina;-11;;;;0;;;;-11
Kultuurimaja Rugodiv;8826516;61203143718;Kozlovskaja Uljana;48310172223;Kozlovskaja Maria;0;13;;;13;11;;;2
Kultuurimaja Rugodiv;8826613;61107273729;Titova Ksenia;47410193725;Titova Julia;0;13;;;13;11;;;2
Kultuurimaja Rugodiv;8826710;51203020118;Shcherbinin Savely;48111182233;Shcherbinina Olga;-13,65;;;;0;;;;-13,65
Kultuurimaja Rugodiv;8826817;60408193738;Korniitšuk Olga;47305233735;Korniitšuk Svetlana;-18;;;;0;;;;-18
Kultuurimaja Rugodiv;8826914;61804120126;Logvinenko Eva;48312193723;Logvinenko Zhanna;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8827010;61107263711;Vasilieva Aljona;48106223712;Shevchenko Oxana;9,65;13;;;13;11;;;11,65
Kultuurimaja Rugodiv;8827117;61709090234;Savolainen Meliana;48710212254;Savolainen Anna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8827214;61011293725;Jefimova Arina;47702073717;Belyaeva Jelena;-4,85;;;;0;;;;-4,85
Kultuurimaja Rugodiv;8827311;61512090078;Ponomarjova Taisia;49510153726;Sonder Jelizaveta;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8827418;60304023715;Deysner Vlada;47505282250;Deysner Zhanna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8827515;51309180024;Kuznetsov Bogdan;48512302213;Lukovkina- Kuznetsova Tatjana;-21;;;;0;;;;-21
Kultuurimaja Rugodiv;8827612;51204273716;Shiryaev Stanislav;48001083714;Shiryaeva Yana;-4,65;;;;0;;;;-4,65
Kultuurimaja Rugodiv;8827719;61005243717;Šilina Alisa;48209183711;Šilina Jelena;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8827816;60010203710;Babikova Maria;47607273710;Babikova Anastassia;-14;;;;0;;;;-14
Kultuurimaja Rugodiv;8827913;61407190091;Raskidajeva Milia;47906122219;Popkova Jevgenia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8828019;60912023727;Semykina Alisa;48505033714;Semykina Yulia;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8828116;61612010123;Petrova Elina;38307123727;Petrov  Vitali;0;;;;0;;;;0
Kultuurimaja Rugodiv;8828213;61110083715;Kokhanovich Zlata;48311053717;Lapotskina Jevgenia;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8828310;61301250156;Grigorjeva Arina;48910223710;Titova Svetlana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8828417;60903173725;Gugnina Tatiyana;47001043728;Turaeva Liudmila;0;13;;;13;22;;;-9
Kultuurimaja Rugodiv;8828514;61701040160;Tsernõsova Mari anna;48310273738;Tsernõsova Valentina;-29;;;;0;;;;-29
Kultuurimaja Rugodiv;8828611;61703010062;Persitskaja Viktoria;48705063719;Persitskaja Anna;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8828718;61302250106;Kornejeva Polina;48509113726;Kornejeva Anastassia;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8828815;61502270166;Maksimova Nikoletta;49412220030;Maksimova Marina;-4,65;;;;0;;;;-4,65
Kultuurimaja Rugodiv;8828912;61309160120;Boltovskaja Darja;48010083746;Ojala Jelena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8829018;49607193722;Golubeva Jelizaveta;47307253731;Lavrentjeva Jelena;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8829115;50801032746;Jarovoi Ervin;47704213711;Govorova Elena;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8829212;51607090068;Gheorghiceanu Madalin-Costinel;47710313712;Gheorghiceanu Ilona;11;13;;;13;25;;;-1
Kultuurimaja Rugodiv;8829319;61801080049;Fanfora Anissia;49612103715;Fanfora Anfissa;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8829416;61401230112;Safronova Karina;48205063726;Safronova Svetlana;0;13;;;13;11;;;2
Kultuurimaja Rugodiv;8829513;50708253713;Jelissejev Aleksei;46705153714;Jelissejeva  Natalja;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8829610;61208133725;Belova Sofia;48805053715;Belova Ljubov;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8829717;61605180025;Kostjajeva Tajana;48810203715;Kostjajeva Aleksandra;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8829814;61404250054;Karvelis Anna;47801062213;Karvelis Olga;0;;;;0;;;;0
Kultuurimaja Rugodiv;8829911;61407090248;Sannikova Arina;47911232211;Velitško Marina;0;13;;;13;11;;;2
Kultuurimaja Rugodiv;8830010;61712070113;Filinova Aglaja;48003193726;Vassiltšenko Anna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8830117;47612292216;Krell Svetlana;47612292216;Raznotovskaja Svetlana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8830214;47002270034;Riis Olga ;47002270034;Riis Olga ;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8830311;61704190128;Andrejeva Darja;49207023732;ANDREJEVA JEKATERINA;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8830418;61401190094;Sõmer Amelia;48906263711;Sõmer Veronika;-1,35;;;;0;;;;-1,35
Kultuurimaja Rugodiv;8830515;44303103727;Ivanova Aleksandra;44303103727;Ivanova Aleksandra;15;5;;;5;15;;;5
Kultuurimaja Rugodiv;8830612;60312093725;Sidorova Viktoria;47903282219;Sidorova Ljubov;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8830719;45006082213;Ivanova Ljudmila;43503113719;Kashkina Maria;15;5;;;5;15;;;5
Kultuurimaja Rugodiv;8830816;61507210044;Aleksandrova Stanislava;39004293727;Aleksandrov Andrei;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8830913;61306140113;Kozlova Milana;47812082225;Akrõmova Nadežda;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8831019;50609223727;Boiko Platon;47312033717;Boiko Bela;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8831116;61309260170;Dorokhova Jekaterina;48901313710;Dorokhova Gera;0;;;;0;;;;0
Kultuurimaja Rugodiv;8831213;61408070239;Repjuk Dalia;48808032229;Repjuk Ksenia;10,65;13;;;13;30;;;-6,35
Kultuurimaja Rugodiv;8831310;50803313713;Grigorjev Timur ;38701082214;Grigorjev Sergei;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8831417;61207173715;Hrenova Margarita;48406293715;Šutina Jekaterina;-13,65;;;;0;;;;-13,65
Kultuurimaja Rugodiv;8831514;61303280176;Istratova Nika;48501273712;Istratova Jelena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8831611;61211163726;Shumskaya Anna;49411113711;Kuslap Polina;-4,65;;;;0;;;;-4,65
Kultuurimaja Rugodiv;8831718;61305210159;Kuslap Monika;48212253731;Kuslap Julia;-4,65;;;;0;;;;-4,65
Kultuurimaja Rugodiv;8831815;61207313718;Šilina Anisia;48209183711;Šilina Jelena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8831912;60808283716;Sidorova Natalja;48005312216;Sidorova Elvira;-23;;;;0;;;;-23
Kultuurimaja Rugodiv;8832018;61404250054;Karvelis Anna;47801062213;Karvelis Olga;0;13;-13;;0;;;;0
Kultuurimaja Rugodiv;8832115;50412243748;Pakk Matvei ;47402113719;Tsvetkova Anzela;-21,65;;;;0;;;;-21,65
Kultuurimaja Rugodiv;8832212;60811073710;Klussova Karolina;48205123726;Klussova Tatjana;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8832319;51606300127;Startsev Vsevolod;48801263714;Startseva Maria;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8832416;61606260142;Zahharova Kira;37909083723;Zahharov Aleksei ;0;;;;0;;;;0
Kultuurimaja Rugodiv;8832513;47312013714;Sahharova Natalja;47312013714;Sahharova Natalja;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8832610;61107063710;Kachalova Darina;36803263720;Kachalov Alexandr;-22;;;;0;;;;-22
Kultuurimaja Rugodiv;8832717;60805213718;Dehant Aleksandra;47507174219;Dehant Natalja;6;;;;0;;;;6
Kultuurimaja Rugodiv;8832814;51604140024;Kirillov Makar;47411253730;Eduvald Svetlana;0;13;;;13;11;;;2
Kultuurimaja Rugodiv;8832911;61901210081;Kirillova Mia;47411253730;Eduvald Svetlana;0;13;;;13;11;;;2
Kultuurimaja Rugodiv;8833017;60508293714;klimtsova Valerija;47811212216;Klimtsova Tatjana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8833114;61510100011;Galimova Damira;47810312245;Yakub Natalia;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8833211;61603210093;Markarova Ulyana;48409122210;Orlova Elena;-5,85;;;;0;;;;-5,85
Kultuurimaja Rugodiv;8833318;60507063731;Škalikova Anastassia;47806047013;Reren Maria;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8833415;61510190030;Krasnova Polina;47712263718;Krasnova Jelkaterina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8833512;51302280181;Petrov Marat;48109033722;Vinokurova Jelena;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8833619;61211133716;Orlova Adelina;48907113728;Orlova Svetlana;-4,65;;;;0;;;;-4,65
Kultuurimaja Rugodiv;8833716;46409192244;Silantjeva Niina;46409192244;Silantjeva Niina;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8833813;61210260104;Zalužjeva Uljana;38111302217;Zalužjev Maksim;-8;;;;0;;;;-8
Kultuurimaja Rugodiv;8833910;60906163711;Maliarova Margarita;47508062261;Maliarova Natalia;6;13;;;13;11;;;8
Kultuurimaja Rugodiv;8834016;50208193713;Mihhailov Emil;47607173722;Mihhailova Svetlana;-5,7;;;;0;;;;-5,7
Kultuurimaja Rugodiv;8834113;46507063719;Semjonova Marina;46507063719;Semjonova Marina;0;13;;;13;26;;;-13
Kultuurimaja Rugodiv;8834210;60708123711;Võssotskaja Alina;48609083717;Võssotskaja Tatjana;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8834317;61809230118;Toropova Alisia;48904153726;Tkachuk Yana;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8834414;51803280311;Minin Sander;48901053720;Minina Daria;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8834511;61007130037;Jakovleva Evelina;47811223710;Jakovleva Anastassia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8834618;51104143741;Boychenko Damir;48504242252;Boychenko Svetlana;-1,35;;;;0;;;;-1,35
Kultuurimaja Rugodiv;8834715;51207253717;Sotskov Matvei;37605122215;Sotskov Oleg;0;;;;0;;;;0
Kultuurimaja Rugodiv;8834812;45604023754;Zimina Liudmila;45604023754;Zimina Liudmila;0;5;;;5;10;;;-5
Kultuurimaja Rugodiv;8834919;51810100161;Antonenko Matvei;49901083721;Antonenko Maria;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8835015;60504283713;Kornejeva Sofja;48509113726;Kornejeva Anastassia;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8835112;60202023724;Vainura Anne-mari;47812313728;Vainura Anika;-5,7;;;;0;;;;-5,7
Kultuurimaja Rugodiv;8835219;45608153724;Fomtšenkova Olga;45608153724;Fomtšenkova Olga;0;5;;;5;;;;5
Kultuurimaja Rugodiv;8835316;61209173714;Iljina Viktoria;48712173710;Iljina Zanna;-5,85;;;;0;;;;-5,85
Kultuurimaja Rugodiv;8835413;43709103715;Krel Ljubov;43709103715;Krel Ljubov;15;5;;;5;15;;;5
Kultuurimaja Rugodiv;8835510;47804263716;Tepljakova Olga;47804263716;Tepljakova Olga;0;13;;;13;65;;;-52
Kultuurimaja Rugodiv;8835617;50210282240;Tsirp Sven;47806133753;Tsirp Kersti;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8835714;61612070121;Rodionova Dominika;49011092218;Rodionova Viktoria;-13,65;;;;0;;;;-13,65
Kultuurimaja Rugodiv;8835811;50010253711;Pilainis  Mihhail;47902043716;Pilainis Natalja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8835918;60406073721;Pilainis Liana;47902043716;Pilainis Natalja;-4,65;13;;;13;;;;8,35
Kultuurimaja Rugodiv;8836014;50608192212;Odintsov Vladislav;48407042219;Odintsova Natalia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8836111;50302253715;Petersell Kristjan;47709253724;Petersell Jelena;-5,7;;;;0;;;;-5,7
Kultuurimaja Rugodiv;8836218;50202223724;Tirman Marko;47510173711;Tirman Maia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8836315;61305230195;Russu Assol;48005153721;Horohordina Natalja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8836412;61108023720;Issakova Marianna;47707243736;Issakova Jekaterina;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8836519;61209260276;Smirnova Anna;48312120117;Smirnova Valentina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8836616;60303283764;Gruzdeva Angelina;45406093720;Gruzdeva Irina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8836713;35511263713;Solovjov Juri;35511263713;Solovjov Juri;0;5;;;5;;;;5
Kultuurimaja Rugodiv;8836810;61607030147;Lobatševa Amelia;38204193725;Lobatšev Konstantin;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8836917;60805013728;Kazakova Darja;48003283736;Kazakova Tatiana;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8837013;61108293715;Makarova Polina;45207013728;Sklabovskaja Natalja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8837110;61202072717;Guseynova Uljana;47812113713;Guseynova Viktoria;0;13;;;13;65;;;-52
Kultuurimaja Rugodiv;8837217;61209183721;Emajõe Nika;48303183717;Emajõe Jelena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8837314;61311120079;Gerstman Miroslava;48607243713;Gerstman Natalja;21,85;13;;;13;;;;34,85
Kultuurimaja Rugodiv;8837411;61010133716;Vassiljeva Alisa;48601172211;Vassiljeva Viktoria;-27;;;;0;;;;-27
Kultuurimaja Rugodiv;8837518;51307240167;Drozdik Georgi;47502023712;Drozdik Yulia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8837615;48712093729;Lutus Kristi;48712093729;Lutus Kristina;-1,35;;;;0;;;;-1,35
Kultuurimaja Rugodiv;8837712;61010033721;Zujeva Veronika;48210062238;Zujeva Anna;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8837819;60508293714;klimtsova Valerija;47811212216;Klimtsova Tatjana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8837916;47906083720;Semjonova Tatjana;47906083720;Semjonova Tatjana;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8838012;61406190173;Arbelius Vasilissa;48107223717;Arbelius Jekaterina;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8838119;61305110055;Hrustaljova Milana;47612253730;Hrustaljova Alina;22;13;;;13;22;;;13
Kultuurimaja Rugodiv;8838216;51201143718;Plodukhin Martin;48502172235;Plodukhina Julia;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8838313;61702240100;Vinogradova Alisa;48807270052;Vinogradova  Iuliia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8838410;60411113728;Radtšenko  Jekaterina;47505083714;Radtšenko Natalja;-12;;;;0;;;;-12
Kultuurimaja Rugodiv;8838517;51512160029;Vasiliev Maksim;44910223724;Vasilieva Galina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8838614;60508303723;Julina Alina;48403302211;Mihhailov Irina;42;13;;;13;64,5;;;-9,5
Kultuurimaja Rugodiv;8838711;61312190105;Ivanova Tatjana;48307013715;Kruglova Olga;-4,65;13;;;13;;;;8,35
Kultuurimaja Rugodiv;8838818;60508023728;Leonova Darja;48310313713;Leonova Irina;22;13;;;13;11;;;24
Kultuurimaja Rugodiv;8838915;61407070016;Kulikovskaja Alisa;48308263712;Kulikovskaja Kristina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8839011;39102083712;Serebrjakov Andrei;47009063738;Andreeva-Serebrjakova Olga;0;;;;0;;;;0
Kultuurimaja Rugodiv;8839118;60712143728;Hvatova Angelina;36409192221;Hvatov Sergey;22;13;;;13;;;;35
Kultuurimaja Rugodiv;8839215;61408220195;Vikhrova Valeria;48009283722;Soldatova Jekaterina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8839312;61407210183;Kožakina Jelizaveta;47907113715;Kozhakina Tatiana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8839419;44008072214;Kalavus Milvi;44008072214;Milvi Kalavus;-1,55;;;;0;;;;-1,55
Kultuurimaja Rugodiv;8839516;61305010049;Sadejeva Antonina;48301082214;Sadejeva Jevgenija;0;;;;0;;;;0
Kultuurimaja Rugodiv;8839613;61809050087;Afanasieva Maria;48101293714;Afanasieva Tatjana;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8839710;60912053715;Peterson Olivia;47810152211;Peterson Veera;-9;;;;0;;;;-9
Kultuurimaja Rugodiv;8839817;61510190030;Krasnova Polina;47712263718;Krasnova Jelkaterina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8839914;61805080190;Luchnikova Lina;48205143735;Lutšnikova Marina ;11;;;;0;11;;;0
Kultuurimaja Rugodiv;8840013;47011033714;Gorjatšova Viktoria;47011033714;Gorjatševa Viktoria;2;13;;;13;2;;;13
Kultuurimaja Rugodiv;8840110;61706220096;Skobeleva Eva;49302243725;Skobeleva Ida;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8840217;61801230070;Skripljonok Jesenia;38102132238;Skripljonok Konstantin;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8840314;51208103747;Grudkin Jaroslav;46403052213;Grudkina Irina;-13,65;;;;0;;;;-13,65
Kultuurimaja Rugodiv;8840411;60402283729;Janno Nicole;47504083719;Bers Elena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8840518;35208173736;Kalinkin Gennady;35208173736;Kalinkin Gennady;-3;5;;;5;4;;;-2
Kultuurimaja Rugodiv;8840615;50902263729;Võssotski Nikita;48609083717;Võssotskaja Tatjana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8840712;51204080092;Frantsev Daniel;48708043714;Frantseva Polina;-4,65;;;;0;;;;-4,65
Kultuurimaja Rugodiv;8840819;61401010108;Antonova Elina;49002223713;Stõngatš Julia;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8840916;61109030239;Lidikauskaite Amelia;48509303720;Lidikauskiene Tatjana;11;13;;;13;15;;;9
Kultuurimaja Rugodiv;8841012;37807142212;Norman Ivan;37807142212;Norman Ivan;0;;;;0;;;;0
Kultuurimaja Rugodiv;8841119;61407210183;Kožakina Jelizaveta;47907113715;Kozhakina Tatiana;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8841216;43603263723;Levina Niina;43603263723;Levina Niina;15;5;;;5;15;;;5
Kultuurimaja Rugodiv;8841313;48202263723;Treumova Alevtina;48202263723;Treumova Alevtina;-9;;;;0;;;;-9
Kultuurimaja Rugodiv;8841410;61206263710;Vasilieva Eva;49010083715;Vasilieva Tatiana;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8841517;48105173714;Poskina Darja;48105173714;Poskina Darja;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8841614;61011043711;Pahhomova Diana;38208093728;Pahhomov Jevgeni;10,3;13;;;13;11;;;12,3
Kultuurimaja Rugodiv;8841711;60407273758;Varkki Karina;47710193712;Varkki Jelena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8841818;60811073710;Klussova Karolina;48205123726;Klussova Tatjana;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8841915;61408010092;Ojavere Daria;47904083710;Ojavere Alla;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8842011;61110263724;Antipenko Adelina;48812193716;Antipenko Anastasia;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8842118;48806083730;Bohhan Tatjana;48806083730;Bohhan Tatjana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8842215;61001153742;Kabina Polina;43911123732;Kabina Svetlana;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8842312;46705153714;Jelissejeva Natalja;46705153714;Jelissejeva  Natalja;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8842419;60709203728;Kisseljova Anžela;37009223710;Kisseljov Vladimir;0;;;;0;;;;0
Kultuurimaja Rugodiv;8842516;61002057065;Timofejeva Adriana ;49409073717;Koroleva Oksana;-5,35;;;;0;;;;-5,35
Kultuurimaja Rugodiv;8842613;60510022741;Rojak Sonja;48207107013;Rojak Olesja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8842710;60903133720;Markelova Taissija;47604233711;Markelova Olga;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8842817;61508070046;Sokolova Sofia;49311173728;Sokolova Lina;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8842914;60407223723;Smirnova Anastassija;47202043717;Smirnova Žanna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8843010;62002040092;Jakimova Amelia;48704212215;Jakimova Margarita;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8843117;61804160089;Novikova Maija;39512083739;Novikov Denis;31;;;;0;;;;31
Kultuurimaja Rugodiv;8843214;49507123714;Sergucheva Natalia;49507123714;Sergutšova Natalia;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8843311;61805270030;Fjodorova Taisiia;47906183737;Nedvigina Viktoria;0;;;;0;;;;0
Kultuurimaja Rugodiv;8843418;46106043710;Šerjakova Marina;46106043710;Šerjakova Marina;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8843515;60409043713;Mihhailova Anastassija;47309243723;Sjomotškina Larissa;-8;;;;0;;;;-8
Kultuurimaja Rugodiv;8843612;47902272752;Terehhova Olesja;47902272752;Terehhova Olesja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8843719;47712307017;Kruglova Ljudmila;47712307017;Kruglova Ljudmila;11;13;;;13;22;;;2
Kultuurimaja Rugodiv;8843816;49606080245;Suhhorukova Svetlana;49606080245;Galiguzova Svetlana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8843913;61306140113;Kozlova Milana;47812082225;Akrõmova Nadežda;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8844019;60606053733;Ivanova Sofia;48310122210;Demse Julia;-16;;;;0;;;;-16
Kultuurimaja Rugodiv;8844116;36310042213;Markus Andrei;36310042213;Markus Andrei;-7;13;;;13;;;;6
Kultuurimaja Rugodiv;8844211;46208283719;Jermosina Ljubov;46208283719;Jermosina Ljubov;0;;;;0;;;;0
Kultuurimaja Rugodiv;8844310;45811287017;Kiritšun Tatjana ;45811287017;Kiritšun Tatjana ;-2,35;;;;0;;;;-2,35
Kultuurimaja Rugodiv;8844417;37108083738;Zaitshev Mihhail;37108083738;Zaitshev Mihhail;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8844514;37312172221;Drozdik Sergei;37312172221;Drozdik Sergei;0;;;;0;;;;0
Kultuurimaja Rugodiv;8844611;49409073717;Koroleva Oksana;49409073717;Koroleva Oksana;-9,7;;;;0;;;;-9,7
Kultuurimaja Rugodiv;8844718;61211023714;Berestova Anna;48102253724;Berestova Darja;22;13;;;13;22;;;13
Kultuurimaja Rugodiv;8844815;44402293713;Saprykina Liudmila;44402293713;Saprykina Liudmila;15;5;;;5;15;;;5
Kultuurimaja Rugodiv;8844912;37503253716;Markov Maksim;37503253716;Markov Maksim;0;;;;0;;;;0
Kultuurimaja Rugodiv;8845018;60909253714;Han Sofia;48904203734;Ivahnova Margarita;0;;;;0;;;;0
Kultuurimaja Rugodiv;8845115;61312190105;Ivanova Tatjana;48307013715;Kruglova Olga;9;13;;;13;;;;22
Kultuurimaja Rugodiv;8845212;61511090154;Štoda Ariana;48808122217;Štoda Viktorija;11;13;;;13;13;;;11
Kultuurimaja Rugodiv;8845319;61606220114;Poltoruhho Sofja;48302113736;Poltoruhho Anna;11;13;;;13;13;;;11
Kultuurimaja Rugodiv;8845416;61608100104;Saffran Darja;38303312236;Saffran Pavel;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8845513;61804160093;Novikova Mija;39512083739;Novikov Denis;31;;;;0;;;;31
Kultuurimaja Rugodiv;8845610;48404120115;Firsova Larysa;48404120115;Firsova Larysa;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8845717;61409110187;Sonman Alisa;49008253720;Sonman Julija;0;;;;0;;;;0
Kultuurimaja Rugodiv;8845814;61409230294;Unukainen Laura;48803163718;Unukainen Angelina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8845911;48711093713; Mihhailova Marina;48711093713; MIHHAILOVA Marina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8846017;61304300011;Malashonok Regina;49302253721;Malashonok Tatiana;-12;;;;0;;;;-12
Kultuurimaja Rugodiv;8846114;43512133710;Fedosjuk Zoja;43512133710;Fedosjuk Zoja;15;5;;;5;15;;;5
Kultuurimaja Rugodiv;8846211;60306303740;Semibratova Diana;46510273718;Semibratova Jelena;-16;;;;0;;;;-16
Kultuurimaja Rugodiv;8846318;60609183731;Belitskaja Jana;46508153712;Mihhailova Jelena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8846415;61803280180;Šõpka Elina;48804083742;Shypka Marina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8846512;61512080147;Volina Alisa ;47609077010;Volina Jekaterina;-8,4;13;;;13;50;;;-45,4
Kultuurimaja Rugodiv;8846619;61112083725;Torortseva Milana;48303133726;Toroptseva Tatjana;-9;13;;;13;13;;;-9
Kultuurimaja Rugodiv;8846716;50909093718;Tšigarkov Maksim ;47910163720;Tšigarkova Natalja;-1,35;;;;0;;;;-1,35
Kultuurimaja Rugodiv;8846813;60606083710;Johannes Francesca;46611232211;Johannes Laine;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8846910;61306280267;Trifonova Nika;48804220712;Nazarova Ekaterina;10,2;13;;;13;11;;;12,2
Kultuurimaja Rugodiv;8847016;45110053733;Frolova Nadezda;45110053733;Frolova Nadezda;15;5;;;5;15;;;5
Kultuurimaja Rugodiv;8847113;60208103713;Rõžkova Ksenia;47712112212;Rõžkova Natalja;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8847210;51112113725;Koževin Demid;46807273714;Koževina Irina;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8847317;49311072714;Fjodorova Alina;49311072714;Fjodorova Alina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8847414;60907033722;Gorovtsova Kira;38305213716;Gorovtsov Igor;-0,35;;;;0;;;;-0,35
Kultuurimaja Rugodiv;8847511;61512230102;Frolukova Jarina;48008213734;Frolukova Svetlana;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8847618;60403213718;Dõdorova  Anastassija;47806142263;Dõdorova Marina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8847715;60509273738;Ginter Karina;47708243719;Ginter Svetlana;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8847812;61702190118;Puhhova Eva;48501142220;Puhhova Julia;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8847919;61601020056;Leonova Natalja;47708043718;Boikova Svetlana;0;13;;;13;11;;;2
Kultuurimaja Rugodiv;8848015;60907103718;Timofejeva Anna;48701193726;Izotova Nadežda;0;;;;0;;;;0
Kultuurimaja Rugodiv;8848112;46107233731;Jegorova Svetlana;46107233731;Jegorova Svetlana;2;;;;0;;;;2
Kultuurimaja Rugodiv;8848219;47703053711;Konovalova Jelena;47703053711;Konovalova Jelena;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8848316;61801270076;Piirak Sofija;48810173725;Piirak Nadezda;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8848413;39804115226;Tirman Marvin;37103305245;Tirman Peter;0;;;;0;;;;0
Kultuurimaja Rugodiv;8848510;46609290011;Zhuravskaya Elena;46609290011;Zhuravskaya Elena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8848617;60907313737;Jevtjuškina Anastasija;47912033713;Jevtjuškina Galina;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8848714;38502103716;Buka Aleksei;38502103716;Buka Aleksei;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8848811;39703162719;Tikk Martin ;39703162719;Tikk Martin ;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8848918;61712090084;Drovikova Nikol;49201223714;Drovikova Olga;11;13;;;13;22;;;2
Kultuurimaja Rugodiv;8849014;51002263715;Levanidov Jelissei;47107282226;Levanidova  Julia;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8849111;61709090234;Savolainen Meliana;48710212254;Savolainen Anna;9;;;;0;;;;9
Kultuurimaja Rugodiv;8849218;51707240185;Fjodorov Matvei-Mathias;48605142233;Fjodorova Juliana;9;;;;0;;;;9
Kultuurimaja Rugodiv;8849315;61709190142;Kvjatkovskaja Amelia;49410133720;Kvjatkovskaja Darina;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8849412;49002222215;Berezina Taja;49002222215;Berezina Taja;-1;13;;;13;;;;12
Kultuurimaja Rugodiv;8849519;44806102262;Chesnikova Valentina;44806102262;Chesnikova Valentina;15;5;;;5;30;;;-10
Kultuurimaja Rugodiv;8849616;46106222210;Pavlova Irina;46106222210;Pavlova Irina;-13;5;;;5;;;;-8
Kultuurimaja Rugodiv;8849713;60710163712;Nikolajeva Anna;48409233732;Nikolajeva Maria;-26;;;;0;;;;-26
Kultuurimaja Rugodiv;8849810;60908213714;Gluhhova Ariana;47608223735;Gluhhova Irina;-8,35;;;;0;;;;-8,35
Kultuurimaja Rugodiv;8849917;61710270061;Balõševa Maia;48711243723;Balõševa Katerina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8850016;61202293710;Maksimova Alina;37403093718;Maksimov Vjatšeslav;0;;;;0;;;;0
Kultuurimaja Rugodiv;8850113;61001043718;Bogdanova Liana;49007022261;Bogdanova Alina;11;13;;;13;22;;;2
Kultuurimaja Rugodiv;8850210;60401253714;Bobõleva Darja;37008183717;Bobõlev Vladimir;0;;;;0;;;;0
Kultuurimaja Rugodiv;8850317;44106303729;Sokolova Adelina;44106303729;Sokolova Adelina;-0,6;5;;;5;4;;;0,4
Kultuurimaja Rugodiv;8850414;33705263715;Kaplun Vladimir;33705263715;Kaplun Vladimir;-4,9;;;;0;;;;-4,9
Kultuurimaja Rugodiv;8850511;51407040201;Komarkov Arseni;48302123725;Komarkova Marina;-10;13;;;13;;;;3
Kultuurimaja Rugodiv;8850618;35104010326;Kargin Leonid;35104010326;Kargin Leonid;0;5;;;5;4;;;1
Kultuurimaja Rugodiv;8850715;50504083731;Efe Berke;47901103711;Efe Tatiana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8850812;38603023721;Suhhorukov Vladimir;38603023721;Suhhorukov Vladimir;0;;;;0;;;;0
Kultuurimaja Rugodiv;8850919;60709143717;Fedotova Polina;48402032220;Fedotova Jelena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8851015;60611293730;Sokolova Sofia;47901123714;Talik Katerina;-12;;;;0;;;;-12
Kultuurimaja Rugodiv;8851112;61702250162;Baranova Maria;48708213722;Baranova Anna;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8851219;61706160161;Säkki Emilia;48611092234;Säkki Marina;11;13;;;13;13;;;11
Kultuurimaja Rugodiv;8851316;60712143728;Hvatova Angelina;38409262210;Hvatov Anton;-11;;;;0;22;;;-33
Kultuurimaja Rugodiv;8851413;61610110032;Vojevodina Ksenija;48608013740;Vojevodina Nadežda;0;;;;0;;;;0
Kultuurimaja Rugodiv;8851510;60804233716;Burunova Zlata;47505190050;Burunova Irina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8851617;51602100128;Jakovlev Ivan;47302113716;Jakovelva Jelena;-11;13;;;13;;;;2
Kultuurimaja Rugodiv;8851714;61108083735;Grigorjeva Arina;47808113728;Grigorjeva Anna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8851811;60801160235;Alekseeva Ksenya;48612292240;Aleksejeva Aleksandra;0;;;;0;9,65;;;-9,65
Kultuurimaja Rugodiv;8851918;49609123727;Citavica Jelena;49609123727;Shtertsel Elena;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8852014;60905203747;Roosipuu Diana;47906072265;Serdjukova Jelena;-12;;;;0;;;;-12
Kultuurimaja Rugodiv;8852111;48511090001;Shuvalova Ekaterina;48511090001;Shuvalova Ekaterina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8852218;61307120202;Milovidova Luiza;47908213759;Milovidova Jelena;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8852315;61707110197;Pankratjeva Polina;48805133734;Pankratjeva Viktoria;11;13;;;13;13;;;11
Kultuurimaja Rugodiv;8852412;61801270032;Džurgenova Anna;47211143711;Džurgenova Oksana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8852519;61608130136;Komarova Jana;48807122267;Zinukova Inga;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8852616;48608083734;Sokolova Maria;48608083734;Sokolova Maria;0;;;;0;;;;0
Kultuurimaja Rugodiv;8852713;47807263720;Jurson Nadezda;47807263720;Jurson Nadežda;0;;;;0;;;;0
Kultuurimaja Rugodiv;8852810;61310250024;Nadeeva Alisa;48607123737;Nadeeva Natalia;-14;;;;0;;;;-14
Kultuurimaja Rugodiv;8852917;61602250148;Truhina Sofia;49008302215;Ziolkowska Alesja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8853013;61202043739;Evstafjeva Ksenia;48511033718;Evstafieva Olesja;-5,7;;;;0;;;;-5,7
Kultuurimaja Rugodiv;8853110;60906193765;Yakovleva Aljona;48904082214;Jakovleva Viktoria;0;;;;0;;;;0
Kultuurimaja Rugodiv;8853217;49311072714;Fjodorova Alina;46904213748;Raud Svetlana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8853314;51403030044;Železnikov Roman;48307143742;Železnikova Natalja;-37,35;;;;0;;;;-37,35
Kultuurimaja Rugodiv;8853411;60409073723;Gorjatševa Marija;47011033714;Gorjatševa Viktoria;-0,15;;;;0;;;;-0,15
Kultuurimaja Rugodiv;8853518;47701073737;Valašas Ljubov;47701073737;Valašas Ljubov;-18;;;;0;;;;-18
Kultuurimaja Rugodiv;8853615;61201033728;Belova Karina;48609172233;Belova Olesja;-38;13;;;13;20;;;-45
Kultuurimaja Rugodiv;8853712;44407093722;Šuškevitš Galina;44407093722;Šuškevitš Galina;15;5;;;5;;;;20
Kultuurimaja Rugodiv;8853819;61501170083;Nikolajeva Anastassia;48409233732;Nikolajeva Maria;-12,65;;;;0;;;;-12,65
Kultuurimaja Rugodiv;8853916;61609220075;Švarkova Virsavia;48206262212;Ganzevitš-Švarkova Alesja ;-27;;;;0;;;;-27
Kultuurimaja Rugodiv;8854012;48503230002;Gracheva Elena;48503230002;Gracheva Elena;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8854119;61411030104;Johannes Dominika;48812123711;Johannes Kristel;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8854216;43912113719;Brehunova Valentina;43912113719;Brehunova Valentina;4;5;;;5;;;;9
Kultuurimaja Rugodiv;8854313;43506273716;Lukjanova Galina;43506273716;Lukjanova Galina;-0,45;;;;0;;;;-0,45
Kultuurimaja Rugodiv;8854410;61311040010;Polgorodnik Diana;45911282210;Polgorodnik Marjana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8854517;61305230195;Russu Assol;48005153721;Horohordina Natalja;22;13;;;13;;;;35
Kultuurimaja Rugodiv;8854614;61512070140;Hvatova Valeria;48809282215;Hvatova Maria;-21,35;;;;0;;;;-21,35
Kultuurimaja Rugodiv;8854711;44508053746;Kaljumäe Ljubov;44508053746;Kaljumäe Ljubov;4;5;;;5;4;;;5
Kultuurimaja Rugodiv;8854818;61210113719;Ostov Alisa;48708163729;Ostov Anastassia;-0,15;;;;0;;;;-0,15
Kultuurimaja Rugodiv;8854915;44512022212;Churgel Liudmila;44512022212;Churgel Liudmila;-0,45;;;;0;;;;-0,45
Kultuurimaja Rugodiv;8855011;43709213739;Vassiljeva Galina;43709213739;Vassiljeva Galina;4;5;;;5;4;;;5
Kultuurimaja Rugodiv;8855118;43808283720;Morozova Valentina;43808283720;Morozova Valentina;4;5;;;5;4;;;5
Kultuurimaja Rugodiv;8855215;61601020056;Leonova Natalja;47708043718;Boikova Svetlana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8855312;60808267081;Chepkasova Alina;48002083719;Solovjova Natalja;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8855419;50911157050;Galimov Barit;47810312245;Yakub Natalia;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8855516;61809230118;Toropova Alisia;48904153726;Tkachuk Yana;22;13;;;13;;;;35
Kultuurimaja Rugodiv;8855613;61211223748;Pobežimova Jekaterina;49107072255;Lubnevskaja Juliana;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8855710;61810300163;Zaitseva Veronika;38811253710;Zaitsev Vladislav;-11;;;;0;;;;-11
Kultuurimaja Rugodiv;8855817;60610123725;Sang Bogdana;48004082210;Sang Viktoria;-12;;;;0;;;;-12
Kultuurimaja Rugodiv;8855914;61304300164;Abakumova Jelizaveta;48304200311;Abakumova Olga;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8856010;61501120070;Kanevskaja Emilia;48708173725;Korzinina Marina;8;13;;;13;28;;;-7
Kultuurimaja Rugodiv;8856117;51703080120;Jagutkin Ignat;47310182261;Jagutkina Alla;-22;13;;;13;;;;-9
Kultuurimaja Rugodiv;8856214;61407060053;Bessonova Adelina;49102183725;Bessonova Anastassia;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8856311;60406213733;Larchenko Elizaveta;47109053712;Larchenko Stanislava;-21;;;;0;;;;-21
Kultuurimaja Rugodiv;8856418;61007153728;Romanovskaja Maria;48003183719;Romanovskaja Žanna;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8856515;49003283716;Remizova Olesya;46210133719;Gorbatšova Tatjana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8856612;61212043722;Timofejeva Aleksandra;48302213713;Timofejeva Natalja;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8856719;43908233710;Kopõlova Niina;43908233710;Kopõlova Niina;15;5;;;5;15;;;5
Kultuurimaja Rugodiv;8856816;61708050114;Zubkova Valeria;48710083723;Zubkova Olga;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8856913;61310010039;Lavrentieva Ekaterina;48711193730;Lavrentieva Liudmila;0;;;;0;;;;0
Kultuurimaja Rugodiv;8857019;61307300113;Strekalova Sofia;47811073722;Strekalova Oksana;10,65;13;;;13;;;;23,65
Kultuurimaja Rugodiv;8857116;47906083720;Semjonova Tatjana;47906083720;Semjonova Tatjana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8857213;61311220041;Tokareva Sofia;38811053715;Tokarev Andrei;6;13;;;13;6;;;13
Kultuurimaja Rugodiv;8857310;49107072255;Lubnevskaja Juliana;49107072255;Lubnevskaja Juliana;-7;;;;0;;;;-7
Kultuurimaja Rugodiv;8857417;61206163725;Molodtsova Diana;48306113738;Molodtsova Jelena;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8857514;43907313719;Tsarkova Marija;43907313719;Taskova Marija;-1,9;;;;0;;;;-1,9
Kultuurimaja Rugodiv;8857611;61601150268;Gredel Alissa;48908080153;Gredel Olga;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8857718;60905093710;Šelepanova Jevgenia;47209063711;Šelepanova Jelena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8857815;61901020108;Koltakova Vesta;49102033711;Vilde Jana;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8857912;61904180280;Makarova Aleksandra Jlena;48402113710;Makarova Jelena;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8858018;61506090050;Silašina Sofia;48709263729;Silašina Tatjana;-5;13;;;13;;;;8
Kultuurimaja Rugodiv;8858115;43609193731;Tkatšenko Niina;43609193731;Tkatšenko Niina;-0,45;;;;0;;;;-0,45
Kultuurimaja Rugodiv;8858212;51402270166;Korotkov Artjom;48805172226;Katsalukha Natalia;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8858319;61109183729;Pogodina Sofia;47201262218;Vollacoo Natalja;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8858416;61607130077;Dedimova Rimma;38304113716;Dedimov Maxim ;0;;;;0;;;;0
Kultuurimaja Rugodiv;8858513;44006263729;Protassova Olga;44006263729;Protassova Olga;-7,55;;;;0;;;;-7,55
Kultuurimaja Rugodiv;8858610;46811223719;Maksimova Olga;46811223719;Maksimova Olga;0;;;;0;;;;0
Kultuurimaja Rugodiv;8858717;47904183727;Hahhajeva Larissa;47904183727;Hahhajeva Larissa;0;;;;0;;;;0
Kultuurimaja Rugodiv;8858814;51509230045;Obolonski Andrei;48802073714;Obolonskaja Tatjana;9;13;;;13;;;;22
Kultuurimaja Rugodiv;8858911;50803063720;Sharipov Timur;37903193728;Sharipov Valery;-14;;;;0;;;;-14
Kultuurimaja Rugodiv;8859017;37503253716;Markov Maksim;37503253716;Markov Maksim;0;;;;0;;;;0
Kultuurimaja Rugodiv;8859114;60601273723;Doketova Serafima;36909153717;Doketov Sergei;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8859211;50511143718;Korobov Egor;47904253712;Rayapu Elena;22;;;;0;;;;22
Kultuurimaja Rugodiv;8859318;61410070029;Mohhova Jaana;48312010311;Murina Ekaterina ;0;;;;0;;;;0
Kultuurimaja Rugodiv;8859415;61301040061;Kazakova Jevdokiya;48003283736;Kazakova Tatiana;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8859512;61412290261;Nikandrova Ksenija;49401193720;Nikandrova Kristina;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8859619;50509073776;Nikitin Aleks;48405263744;Elksnitis Anna;11;;;;0;;;;11
Kultuurimaja Rugodiv;8859716;60412253744;Badajev Deniss;48406122217;Badajeva Irina;22;;;;0;;;;22
Kultuurimaja Rugodiv;8859813;45510143711;Kalinina Valentina;45510143711;Kalinina Valentina;4;5;;;5;4;;;5
Kultuurimaja Rugodiv;8859910;60512223727;Vassilenko Evelina;47510313717;Vassilenko Natalja;-12;;;;0;;;;-12
Kultuurimaja Rugodiv;8860019;50410053711;Jeršov Andrei;47002133721;Jeršova Tatjana;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8860116;34801063715;Mikhailov Leonid;34801063715;Mikhailov Lenid;0;5;;;5;22;;;-17
Kultuurimaja Rugodiv;8860213;61408220195;Vikhrova Valeria;48009283722;Soldatova Jekaterina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8860310;60608312714;Ossip Liana;48311113728;Ivashenko Kristina;-12;;;;0;;;;-12
Kultuurimaja Rugodiv;8860417;51201213747;Hozjainov Miron;48504297010;Hozjainova Maria;1;13;;;13;;;;14
Kultuurimaja Rugodiv;8860514;60811243745;Chupreeva Uljana;47301062231;Nikolenko Elena;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8860611;60508233716;Han  Lolita;48106133713;Han Vassilina;11;;;;0;;;;11
Kultuurimaja Rugodiv;8860718;50503093720;Mäekivi Alexander;37006225232;Mäekivi Meelis;22;;;;0;22;;;0
Kultuurimaja Rugodiv;8860815;61609120287;Bolshakova Karolina;48412303719;Bolshakova Ekaterina;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8860912;60608312725;Ossip Ailis;48311113728;Ivashenko Kristina;-12;;;;0;;;;-12
Kultuurimaja Rugodiv;8861018;45111102255;Šumilo Tatjana;45111102255;Šumilo Tatjana;0;5;;;5;;;;5
Kultuurimaja Rugodiv;8861115;45104033735;Jermolajeva Ljudmila;45104033735;Jermolajeva Ljudmila;0;5;;;5;;;;5
Kultuurimaja Rugodiv;8861212;61306010098;Matsi Eveliina;45210143713;Švets Nadezda;11;13;;;13;9;;;15
Kultuurimaja Rugodiv;8861319;61706040098;Borissova Milana;49308263725;Borissova Viktoriya;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8861416;46105043716;Klibanova Natalja;46105043716;Klibanova Natalja;-28,05;;;;0;;;;-28,05
Kultuurimaja Rugodiv;8861513;61410280124;Žarkova Nelli;49003283727;Zharkova Yulia;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8861610;61408070239;Repjuk Dalia;48808032229;Repjuk Ksenia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8861717;46001253734;Klever Tatjana;46001253734;Klever Tatjana;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8861814;45907043726;Krasnova Niina;45907043726;Krasnova Niina;-11;;;;0;;;;-11
Kultuurimaja Rugodiv;8861911;47001293710;Kalinina Svetlana;47001293710;Kalinina Svetlana;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8862017;62002140065;Kuttanen Nicole;48602222220;Kuttanen Jekaterina;11;13;;;13;24;;;0
Kultuurimaja Rugodiv;8862114;61907110160;Kljutšenkova Maria;48712073760;Nikolajenkova Olga;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8862211;60906287099;Saan Milena;48607192244;Saan Linda;-16;;;;0;;;;-16
Kultuurimaja Rugodiv;8862318;61602030079;Leonova Sofia;48310313713;Leonova Irina;22;13;;;13;11;;;24
Kultuurimaja Rugodiv;8862415;61711090188;Vladoiu-Predi Nikoletta Florentina;48401192241;Vladoiu-Predi Svetlana;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8862512;61706230059;Kontseus Dominika;48409182219;Kontseus Kristina;22;13;;;13;11;;;24
Kultuurimaja Rugodiv;8862619;61202043751;Jurna Aljona;39701043719;Jurna Maksim;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8862716;61605170116;Antonenko Olivia;49106063730;Subbotina Jekaterina;33;13;;;13;22;;;24
Kultuurimaja Rugodiv;8862813;61505270076;Naumova Milana;49112230039;Naumova Yulianna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8862910;61010113746;Vangonen Annika;47505223717;Vangonen Marina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8863016;50809143729;Širobokov Artur;48509282217;Širobokova Natalja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8863113;61112153732;Drel Vitalina;47912313728;Drel Angelina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8863210;45112100342;Gaav Anna;45112100342;Gaav Anna;4;5;;;5;4;;;5
Kultuurimaja Rugodiv;8863317;39001303710;Bugakov Valentin;39001303710;Bugakov Valentin;-5,7;;;;0;;;;-5,7
Kultuurimaja Rugodiv;8863414;61507270314;Mostotskaja Anfisa;48412270141;Kovatsenko Mariia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8863511;51112153720;Drel Arseni ;47912313728;Drel Angelina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8863618;61901070110;Kuznetsova Miraslava;49004223723;Nikitina Nadezda;11;;;;0;;;;11
Kultuurimaja Rugodiv;8863715;61704110160;Vassilenko Elizaveta;48511032745;Vassilenko Ljubov;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8863812;61203163721;Svetlõšenko Sofia;48601060019;Svetlyshenko Maria;-27,65;;;;0;;;;-27,65
Kultuurimaja Rugodiv;8863919;51704230059;Rezvukhin Radmir;37808042255;Rezvukhin Vladimir;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8864015;60809093716;Slobodjan Nadežda;46710163722;Slobodjan Irina;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8864112;61502130136;Mihhejeva Aljona;48408073721;Mihhejeva Anita;0;;;;0;;;;0
Kultuurimaja Rugodiv;8864219;36507043715;Golubõhh Oleg;36507043715;Golubõhh Oleg;-1,35;;;;0;;;;-1,35
Kultuurimaja Rugodiv;8864316;60006283726;Zotejava Marina;60006283726;Zotejeva Marina;-5;;;;0;;;;-5
Kultuurimaja Rugodiv;8864413;61806270231;Žukovskaja Anastasia;49101042259;Tšernokoškina Kristina;2;13;;;13;13;;;2
Kultuurimaja Rugodiv;8864510;60501303731;Pekarski Nikita;38112040249;Pekarski Aleksandr;11;;;;0;;;;11
Kultuurimaja Rugodiv;8864617;60802093714;Levanidova Evilina;47107282226;Levanidova  Julia;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8864714;61112233735;Medvedeva Nelli;48907013733;Medvedeva Yana;-7;;;;0;;;;-7
Kultuurimaja Rugodiv;8864811;37211282224;Bazarov Dmitry;37211282224;Bazarov Dmitry;0;13;;;13;55;;;-42
Kultuurimaja Rugodiv;8864918;45207133715;Kondrashkina Evgenia;45207133715;Kondrashkina Evgenia;4;5;;;5;4;;;5
Kultuurimaja Rugodiv;8865014;51201213747;Hozjainov Miron;38510202218;Hozjainov Roan;1;13;;;13;;;;14
Kultuurimaja Rugodiv;8865111;60901203738;Ponomareva Sofia;48808273712;Logunova Anastasia;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8865218;50608293738;Tsigarkov Aleksandr;46705052232;Tsigarkova Inna;11;;;;0;11;;;0
Kultuurimaja Rugodiv;8865315;46505242213;Kozlova Stella;46505242213;Kozlova Stella;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8865412;61408230223;Lomakina Sofiia;48704180133;Lomakina Oksana;-27;;;;0;;;;-27
Kultuurimaja Rugodiv;8865519;46102253731;Popova Valentina;46102253731;Popova Valentina;-28;;;;0;;;;-28
Kultuurimaja Rugodiv;8865616;61808050128;Krylova Varvara;49002090073;Gavrilova Jana;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8865713;60804143745;Korabljova Valerija;37401162217;Korabljov Dmitri;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8865810;46107113711;Maksimova Alla;46107113711;Maksimova Alla;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8865917;46507083733;Smirnova Marina;46507083733;Smirnova Marina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8866013;51207163740;Dmitrijev Kristian;37807083732;Dmitrijev Aleksandr;-13,65;;;;0;;;;-13,65
Kultuurimaja Rugodiv;8866110;61708300122;Sevbyanova Alisa;47907083725;Sevbyanova Alija;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8866217;61401070194;Estrada Lutus Elizabeth ;48712093729;Lutus Kristina;-1,35;;;;0;;;;-1,35
Kultuurimaja Rugodiv;8866314;51207253717;Sotskov Matvei;37605122215;Sotskov Oleg;11;13;;;13;13;;;11
Kultuurimaja Rugodiv;8866411;45401052223;Soboleva Aleksandra;45401052223;Soboleva Aleksandra;4;5;;;5;4;;;5
Kultuurimaja Rugodiv;8866518;61504280154;Iljina Miroslava;47603053725;Iljina Marina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8866615;60301283732;Golubtsova Olga;47503163739;Golubtsova Zhanna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8866712;60404263714;Merkulaeva Sandra;47711073729;Merkulaeva Liubov;0;;;;0;;;;0
Kultuurimaja Rugodiv;8866819;61004020015;Gladysheva Aleksandra;47012090051;Gladysheva Tatjana;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8866916;60604023724;Pavlova Arina;48303153735;Pavlova Elrna;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8867012;48304112230;Abushkevich Yana;48304112230;Abushkevich Yana;11;;;;0;;;;11
Kultuurimaja Rugodiv;8867119;47007033718;Smirnova Svetlana;47007033718;Smirnova Svetlana;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8867216;47902272752;Terehhova Olesja;47902272752;Terehhova Olesja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8867313;60410033713;Reinsalu Sille;37204143721;Reisalu Mehis;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8867410;47005123773;Kurotškina Anna;47005123773;Kurotškina Anna;11;;;;0;11;;;0
Kultuurimaja Rugodiv;8867517;60901193739;Balaban Aylin;47501143727;Balaban Anna;22;;;;0;22;;;0
Kultuurimaja Rugodiv;8867614;35811022228;Ivanov Valeriy;35811022228;Ivanov Valeriy;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8867711;49802153722;Ignatova Anastassia;37402133710;Ignatov Anatoli;0;;;;0;;;;0
Kultuurimaja Rugodiv;8867818;61004263715;Fedorova Taisia;48006133710;Lavrukova Svetlana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8867915;61005273738;Žuljeva Varvara;47212012279;Žuljeva Tatjana;-5,7;;;;0;;;;-5,7
Kultuurimaja Rugodiv;8868011;60601013713;Tšagina Uljana;36608202253;Tšagin Valeri;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8868118;46008132218;Komarova Irina;46008132218;Komarova Irina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8868215;61712050121;Zhukova Alisia;46604093717;Zhukova Natalia;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8868312;60408243742;Minonen Jana;60408243742;Minonen Jana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8868419;61106163733;Kaljumäe Aia;46609290011;Zhuravskaya Elena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8868516;61504260173;Goncharova Vasilissa;49208063743;Goncharova Lidiya;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8868613;47108243712;Agapova Olga;47108243712;Agapova Olga;-9;13;;;13;;;;4
Kultuurimaja Rugodiv;8868710;47206242229;Moskaleva Nadezda;47206242229;Moskaleva Nadezda;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8868817;51612150070;Terekhov Daniil;48111063718;Terekhova Irina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8868914;51811070121;Pavlov Daniil;38807153719;Pavlov Dmitri;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8869010;60609100011;Zhuravskaya Daria;46609290011;Zhuravskaya Elena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8869117;60809083720;Zamorskaya Polina;47805163715;Pjulrju Natalja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8869214;61208113711;Berlin Emilia;48903013724;Berlin Diana;-12;;;;0;;;;-12
Kultuurimaja Rugodiv;8869311;61811130111;Makova Jekaterina;48302213713;Timofejeva Natalja;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8869418;61904020243;Willer Alexandra;37005092218;Willer Andrei;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8869515;61001253715;Minina Alina;48408203717;Markelova Sveta;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8869612;61308200203;Merelaid Sofia Viktoria;48311273710;Furman Natalia;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8869719;61502100061;Krjukova Viktoria;48801283717;Krjukova Maria;0;;;;0;;;;0
Kultuurimaja Rugodiv;8869816;47305290061;Manyakina Natalja;47305290061;Manyakina Natalja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8869913;61308120153;Danilova Anna;48803012245;Danilova Aleksandra;-4,65;;;;0;;;;-4,65
Kultuurimaja Rugodiv;8870012;61710200078;Erro Viktorija;49403153723;Erro Uliana ;11;;;;0;22;-11;;0
Kultuurimaja Rugodiv;8870119;60510073718;Moskalenko Angelina;44805203717;Moskalenko Anna;-22,65;;;;0;;;;-22,65
Kultuurimaja Rugodiv;8870216;61808060168;Ljudvig Amelia;38002183724;Ljudvig Aleksander;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8870313;61805300129;Jakovleva Maya;49105073710;Jakovleva Lilija;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8870410;50708133726;Drozdov Viktor;48704283718;Shevtsova Olga;-10;;;;0;;;;-10
Kultuurimaja Rugodiv;8870517;61604040052;Jakovleva Karolina;49105073710;Jakovleva Lilija;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8870711;47603123726;Plotnikova Olga;47603123726;Plotnikova Olga;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8870818;61508170302;Maiatnikova Arina;38901190468;Maiatnikov Dmitri;11;13;;;13;24;;;0
Kultuurimaja Rugodiv;8870915;61406250162;Vinogradova Lada;47702197011;Jevgenjeva Jelena;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8871011;61506120182;Zabarina Alina;47606073715;Zabarina Jelena;-13,65;;;;0;;;;-13,65
Kultuurimaja Rugodiv;8871118;50709193718;Sumarov Ivan;47802243747;Šumarova Viktoria;0;;;;0;;;;0
Kultuurimaja Rugodiv;8871215;61610100080;Erro Sofija;49403153723;Erro Uliana ;11;;;;0;22;-11;;0
Kultuurimaja Rugodiv;8871312;51406170082;Sapjorov Stefan;47510053716;Helk Anne;-14;;;;0;;;;-14
Kultuurimaja Rugodiv;8871419;61304300011;Malashonok Regina;49302253721;Malashonok Tatiana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8871516;50804097058;Eremin Makar;47201030039;Eremina Irina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8871613;61709200017;Kossutskaja Nikol;47911093717;Kossutskaja Natalja;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8871710;61012093729;Kostrichkina Nikoleta;48801033725;Neiman Irina;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8871817;47810133728;Nikiforova Irina;47810133728;Nikiforova Irina;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8871914;61910220076;Bespalova Irina;38408272212;Bespalov Vladimir;11;13;;;13;22;;;2
Kultuurimaja Rugodiv;8872010;61704070054;Nikandrova Veronika;49401193720;Nikandrova Kristina;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8872117;61605080150;Perovscaia Anna;49002220112;Perovscaia Nina;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8872214;61906190100;Kornilova Varvara;48406153736;Kornilova Darja;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8872311;47004022231;Mihhejenkova Irina;47004022231;Mihhejenkova Irina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8872418;48005243718;Intyashova Irina;48005243718;Intyashova Irina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8872515;60707033760;Dmitrieva Viktoria;48202203714;Dmitrieva Inassa;0;;;;0;;;;0
Kultuurimaja Rugodiv;8872612;47705253722;Skvortsova Jelena;47705253722;Skvortsova Lelena;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8872719;60211113733;Ignatova Oksana;37402133710;Ignatov Anatoli;-1;;;;0;;;;-1
Kultuurimaja Rugodiv;8872816;46409242226;Malinova Julia;46409242226;Malinova Julia;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8872913;50410053711;Jeršov Andrei;47002133721;Jeršova Tatjana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8873019;60311213731;Otvagina Aleksandra;47212032249;Otvagina Julia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8873116;50804097047;Eremin Zakhar;47201030039;Eremina Irina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8873213;47705252246;Vink Alesya;47705252246;Vink Alesja;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8873310;47505142216;Traks Svetlana;47505142216;TRAKS SVETLANA;11;;;;0;11;;;0
Kultuurimaja Rugodiv;8873417;45907312214;Kalatšova Ljubov;45907312214;Kalatšova Ljubov;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8873514;61506210162;Pronina Darina;49012113726;Morozjuk Svetlana;-6,7;;;;0;;;;-6,7
Kultuurimaja Rugodiv;8873611;45604183747;Nikitina Antonina;45604183747;Nikitina Antonina;4;5;;;5;4;;;5
Kultuurimaja Rugodiv;8873718;46911173718;Rogushina Valentina;46911173718;Rogushina Valentina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8873815;45809163720;Selenkova Jelena;45809163720;Selenkova Jelena;11;5;;;5;11;;;5
Kultuurimaja Rugodiv;8873912;47212153712;Mihhailova Jelena;47212153712;Mihhailova Jelena;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8874018;61311290166;Gorbatšova Ksenia;49109263713;Knjazeva Alisa;-12,65;;;;0;;;;-12,65
Kultuurimaja Rugodiv;8874115;47110142216;Bossak Erika;47110142216;Bossak Erika;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8874212;61512290068;Šutova Aljona;48305073736;Ivanova Oksana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8874319;61402070275;Alekseenkova Darja;46307193729;Alekseenkova Inna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8874416;61710160157;Šagandina Taisia;49407063722;Martjanova Jaana;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8874513;47408122214;Naumanis Jekaterina;47408122214;Naumanis Jekaterina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8874717;61709300102;Lugina Milena;48402173719;Lugina Maria;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8874814;61109122756;Aksjonova Angelina;46312132212;Smirnova Svetlana;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8874911;60910223751;Slepova Varvara;48002163711;Slepova Daria;0;;;;0;;;;0
Kultuurimaja Rugodiv;8875017;50709193729;Kõrve Kirill;47206220036;Kõrve Irina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8875114;51403030044;Železnikov Roman;48307143742;Železnikova Natalja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8875211;60802193715;Šutova Sofia;48204082248;Šutova Anna;-12;;;;0;;;;-12
Kultuurimaja Rugodiv;8875318;46910023727;Grebenyuk Natalia;46910023727;Grebenyuk Natalia;11;;;;0;11;;;0
Kultuurimaja Rugodiv;8875415;47311133738;Gratiy Natalja;47311133738;Gratiy Natalja;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8875512;61309090157;Katarina Vassiljeva;48305293729;Aleksejeva Nadežda;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8875619;46611232211;Johannes Laine;46611232211;Johannes Laine;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8875716;48011073711;Sazonova Natalja;48011073711;Sazonova Natalja;-5;;;;0;;;;-5
Kultuurimaja Rugodiv;8875813;60911023711;Platonova Ksenija;48201062241;Platonova Tatjana;6;13;;;13;;;;19
Kultuurimaja Rugodiv;8875910;51509300128;Kriina Roman;48108173729;Kriina Anna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8876016;61007280143;Kapranova Diana;48010053714;Kapranova Natalja;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8876113;61605300254;Kapranova  Viveja;48010053714;Kapranova Natalja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8876210;61201223733;Yudina Vladislava;48007272262;YUDINA JELENA;-14;;;;0;;;;-14
Kultuurimaja Rugodiv;8876317;61610140064;Bagašvili Diana;48205303713;Margarjan Lianna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8876414;61401080266;Solovjova Taisija;48202093721;Solovjova Olga;-0,15;;;;0;;;;-0,15
Kultuurimaja Rugodiv;8876511;44611303723;Arsenieva Elena;44611303723;Arsenieva Elena;0;5;;;5;;;;5
Kultuurimaja Rugodiv;8876618;61602190115;Ponomarjova Anastasia;48908013716;Ponomarjova Jekaterina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8876715;61606070148;Kurtšanova Milana;48411273713;Morozova Evgeniya;0;;;;0;;;;0
Kultuurimaja Rugodiv;8876812;61308010133;Štruf Arina;48111213746;Rumjantseva Jekaterina;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8876919;60410303739;Tarassova Anastassija;38309223721;Tarassov Dmitri;22;13;;;13;;;;35
Kultuurimaja Rugodiv;8877015;61401080244;Pärnoja Katrin;47310270037;Konopleva Inga;0;;;;0;;;;0
Kultuurimaja Rugodiv;8877112;51608150258;Manda Constantin;48503039512;Tikhomirova Maria;0;;;;0;;;;0
Kultuurimaja Rugodiv;8877219;47411253730;Eduvald Svetlana;47411253730;Eduvald Svetlana;0;13;;;13;11;;;2
Kultuurimaja Rugodiv;8877316;60605073720;Širobokova Arina;48509282217;Širobokova Natalja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8877413;61409230163;Aminova Marianna;48606182265;Aminova Valentina;-7;;;;0;;;;-7
Kultuurimaja Rugodiv;8877510;61404290169;Takhtarova Vasilissa;47201212227;Takhtarova Larisa;-5,7;;;;0;;;;-5,7
Kultuurimaja Rugodiv;8877617;61002043734;Parts Emili;47707023732;Parts Teele;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8877714;61309280131;Izotova Laura;48012183735;Izotova Irina;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8877811;61511260020;Gavritšenkova Anastasia;48701090065;Redina Anna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8877918;61511090116;Evgenieva  Eva;48007293719;Muraeva Svetlana;-9;;;;0;;;;-9
Kultuurimaja Rugodiv;8878014;61706050039;Solovjova Vasilisa;47602012243;Solovjova Veronika;11;13;;;13;22;;;2
Kultuurimaja Rugodiv;8878111;61706050028;Solovjova Milana;47602012243;Solovjova Veronika;11;13;;;13;22;;;2
Kultuurimaja Rugodiv;8878218;61510100033;Medvedeva Valeria;48801227010;Medvedeva Tatiana;0;13;;;13;11;;;2
Kultuurimaja Rugodiv;8878315;60908123737;Koksharova Ekaterina;47902163736;Ljukina Natalja ;0;;;;0;;;;0
Kultuurimaja Rugodiv;8878412;61605050042;Usmanova Veronika;37704170014;Usmanov Albert;0;;;;0;;;;0
Kultuurimaja Rugodiv;8878519;60910143737;Budniskaja Ksenija;49205053743;Yudaeva Viktoriya;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8878616;61307110185;Orlova Uljana;48702233717;Kozõreva Julia;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8878713;60509143711;Kobljakova Anastasia;46508070065;Bondarchuk Galina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8878810;61301310145;Alejeva Jana;46703220012;Aleeva Svetlana;-5;13;;;13;11;;;-3
Kultuurimaja Rugodiv;8878917;61606070148;Kurtšanova Milana;48411273713;Morozova Evgeniya;-9;;;;0;;;;-9
Kultuurimaja Rugodiv;8879013;61203013713;Dõdorova Katerina ;47806142263;Dõdorova Marina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8879110;60609100011;Zhuravskaya Daria;46609290011;Zhuravskaya Elena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8879217;61312190105;Ivanova Tatjana;48307013715;Kruglova Olga;0;;;;0;;;;0
Kultuurimaja Rugodiv;8879314;47902272752;Terehhova Olesja;47902272752;Terehhova Olesja;24;13;;;13;;;;37
Kultuurimaja Rugodiv;8879411;61103173747;Djakova Diana;48101113718;Djakova Julia;-12;;;;0;;;;-12
Kultuurimaja Rugodiv;8879518;61406110226;Berlin Eva;49007162240;Berlin Ksenia;11;13;;;13;24;;;0
Kultuurimaja Rugodiv;8879615;61504250086;Sharipova Emilia;48810172238;Sharipova Yana;-4,65;;;;0;;;;-4,65
Kultuurimaja Rugodiv;8879712;47012090051;Gladysheva Tatjana ;47012090051;Gladysheva Tatjana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8879819;46706303718;Protassevitš Olga;46706303718;Protassevitš Olga;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8879916;51804300167;Vassiljev Andrei;49105100078;Tammine Jana;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8880015;60409013714;Andrejeva Angelina;46109122219;Smirnova Juzefta;-7;;;;0;;;;-7
Kultuurimaja Rugodiv;8880112;61702170126;Abolina Antonina;49109273716;Abolina Anastassia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8880219;50708253713;Jelissejev Aleksei;36403273714;Jelissejev Valeri;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8880316;61704110159;Ozerova Viktoria;47702282219;Ozerova Svetlana;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8880413;61409033100;Krõlova Lada;37611163725;Krõlov Maksim;-9;;;;0;;;;-9
Kultuurimaja Rugodiv;8880510;61308130040;Levitskaja Janina;48210143726;Levitskaja Natalja;-7;;;;0;;;;-7
Kultuurimaja Rugodiv;8880617;51303040092;Kazatšok Gleb;49407063722;Martjanova Jaana;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8880714;46912283714;Jakovleva Olga;46912283714;Jakovleva Olga;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8880811;61904220026;Batjajeva Klaarika;49501263718;Petrovskaya Svetlana;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8880918;47505273730;Gerasimova Natalia;47505273730;Gerasimova Natalia;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8881014;61605180025;Kostjajeva Tajana;48810203715;Kostjajeva Aleksandra;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8881111;61404060071;Ilina Taissija;49406213716;Ilina Janika;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8881218;60404073720;Lanbert Vlada;47706163740;Lanbert Irina;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8881412;35211223720;Jezov Nikolai;35211223720;Jezov Nikolai;15;5;;;5;;;;20
Kultuurimaja Rugodiv;8881519;49311072714;Fjodorova Alina;49311072714;Fjodorova Alina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8881616;35212272218;Palkin Aleksandr;35212272218;Palkin Aleksandr;0;;;;0;;;;0
Kultuurimaja Rugodiv;8881713;45304132227;Palkina Larissa;45304132227;Palkina Larissa;0;;;;0;;;;0
Kultuurimaja Rugodiv;8881810;61608170055;Fedoseeva Maria;47507183719;Fedoseeva Yana;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8882217;51302010197;Raljov Semjon;47212293746;Garenskihh Olga;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8882314;61403110200;Zapeka Valerija;48606242210;Zapeka Olga;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8882411;50610156028;Bojetski Ruslan;48602033713;Boetskaya Anastasia;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8883216;61109273717;Litvinenko Aleksandra;47401272220;Vavilova Tatjana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8883313;51310170129;Botšin Arseni;48808243713;Šerstkova Jevgenia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8883410;60206163712;Nejolova Akilina;47004173715;Nejolova Irina;-12,8;;;;0;;;;-12,8
Kultuurimaja Rugodiv;8883517;44505033728;Starõgina Valentina;44505033728;Starõgina Valentina;4;5;;;5;4;;;5
Kultuurimaja Rugodiv;8883614;51410220082;Litvinenko Platon;47108062216;Eliseeva Elena;10;13;;;13;;;;23
Kultuurimaja Rugodiv;8883711;60303133723;Gribova Viktorija;48101293736;Gribova Irina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8883818;50703233738;Roshchin Vitali;48108102237;Roshchina Elena;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8883915;60702163718;Treumova Polina;48009213739;Vernikova Svetlana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8884011;61402210136;Nagornaya Nicoletta;48005313769;Nagornaya Natalia;-22,65;13;;;13;;;;-9,65
Kultuurimaja Rugodiv;8884312;60212103710;Tüvi Vlada;44906063711;Žolobova Valentina;-12;;;;0;;;;-12
Kultuurimaja Rugodiv;8884419;61003123731;Gusseva Margarita;38001073748;Gussev Anton;-12,2;;;;0;;;;-12,2
Kultuurimaja Rugodiv;8884516;61209173714;Iljina Viktoria;48712173710;Iljina Zanna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8884710;60901263725;Beloglazova Evelina;48103232217;Beloglazova Anna;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8884817;61402070275;Alekseenkova Darja;48405172214;Alekseenkova Svetlana;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8885214;60703173723;Popova Anastasia;38206153740;Popov Aleksandr;0;;;;0;;;;0
Kultuurimaja Rugodiv;8885612;60503113748;Lätt Marily;37909022249;Lätt Ainar;0;;;;0;;;;0
Kultuurimaja Rugodiv;8886116;47603302237;Matrosova Alla;47603302237;Matrosova Alla;-2,65;;;;0;;;;-2,65
Kultuurimaja Rugodiv;8886213;61306280267;Trifonova Nika;48804223712;Nazarova Ekaterina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8886417;47507193726;Pavlova Tatjana;47507193726;Pavlova Tatjana;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8886514;60805213718;Dehant Aleksandra;47507174219;Dehant Natalja;6;13;;;13;;;;19
Kultuurimaja Rugodiv;8886912;47402143729;Smirnova Marina;47402143729;Smirnova Marina;11;13;;;13;24;;;0
Kultuurimaja Rugodiv;8887513;50912223716;Dobrovolkiy Taras;48012233733;Toropova Irina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8887717;61401220062;Deysner Aleksandra;47505282250;Deysner Zhanna;0;13;;;13;25;;;-12
Kultuurimaja Rugodiv;8887911;60107283712;Jelissejeva Alina;46705153714;Jelissejeva  Natalja;-4,65;;;;0;;;;-4,65
Kultuurimaja Rugodiv;8888211;37309202218;Lobin Aleksei ;37309202218;Lobin Aleksei ;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8889113;50610033714;Markov Vladislav;48206283735;Markova Jevgenia;-1,35;;;;0;;;;-1,35
Kultuurimaja Rugodiv;8889919;61002073711;Markova Maria;48206283735;Markova Jevgenia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8890018;60610063714;Zerkalova Uljana;48206093730;Zerkalova Svetlana;0;;;;0;;;;0
Kultuurimaja Rugodiv;8890416;60705143721;Andreeva Lydia;47702113739;Mirošnikova Olga;0;;;;0;;;;0
Kultuurimaja Rugodiv;8890610;60802263727;Barch Charlotte;48303222253;Barch Liina;-20;;;;0;;;;-20
Kultuurimaja Rugodiv;8890717;61508170270;Semykina Alena;48811110109;Srmykina Vera;0;;;;0;;;;0
Kultuurimaja Rugodiv;8890814;61005273716;Popova Viktoria;47909272215;Popova Nadežda;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8890911;61209013721;Vinogradova Anastasia;48705203711;Vinogradova Jekaterina;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8891017;61503300219;Kharlamova Elizaveta ;47804253720;Poltorukho Tatiana;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8891114;61612060060;Juhkov Nikole;49007073717;Juhkov Viktoria;0;;;;0;;;;0
Kultuurimaja Rugodiv;8891211;60610313731;Plesneva Polina;48309213726;Plesneva Rimma;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8891318;61111302740;Ankudinova Olga;47909122212;Beloborodova Lilia;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8891415;61606060239;Varaksina Linda;48810253717;Varaksina Anna;0;;;;0;;;;0
Kultuurimaja Rugodiv;8891619;60709223742;Savina Adelina;48902223727;Karpunina Anastassia;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8891716;47003243717;Ulanova Tatjana ;47003243717;Ulanova Tatjana ;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8891813;60707097027;Terekhova Anastasija;48111063718;Terekhova Irina;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8891910;61301230120;Mel Polina;49010073719;Mel Aleksandra;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8892016;61604260143;Begunova Emilia;48805173713;Bolšunova Julia;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8892113;61510200017;Kurdina Polina;47910093723;Zimina Natalja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8892210;51310250067;Salikov Nikita;48306052237;Salikova Irina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8892317;61512080147;Volina Alisa ;47609077010;Volina Jekaterina;0;;;;0;;;;0
Kultuurimaja Rugodiv;8892414;61608290097;Pestova Alina;38502153729;Pestov Igor;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8892511;61608290086;Pestova Karina;38502153729;Pestov Igor;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8892715;51602180205;Arsentjev Jaroslava;48601142289;Arsentjevva Valentina;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8892812;60506153736;Timonina Angelina;36804203715;Nevskiy Alexander;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8892919;51608200055;Ossinkin Emil;49511233712;Odar Indra;10,94;13;;;13;10,94;;;13
Kultuurimaja Rugodiv;8893112;61601140032;Izmestjeva Sofija;49702133724;Gorjatševa Aliini;0;;;;0;;;;0
Kultuurimaja Rugodiv;8893219;61402080129;Kuttanen Viktoria;48602222220;Kuttanen Jekaterina;0;13;;;13;24;;;-11
Kultuurimaja Rugodiv;8893316;60605153734;Loiko Karolina-Laura;48303113712;Loiko Janina;33;13;;;13;33;;;13
Kultuurimaja Rugodiv;8893413;50605253745;Malovanenko Arseni;44802172214;Igotti Toini;0;;;;0;;;;0
Kultuurimaja Rugodiv;8893510;61510010045;Chebykina Vera;48807023726;Chebykina Jekaterina;-8,5;13;;;13;14;;;-9,5
Kultuurimaja Rugodiv;8893617;61510010034;Chebykina Julia;48807023726;Chebykina Jekaterina;11;13;;;13;14;;;10
Kultuurimaja Rugodiv;8893714;61605060082;Missenjova Milana;48402253722;Missenjova Jelena;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8893811;61106263717;Matvejeva Polina;48402063717;Matvejeva Julia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8893918;61204083712;Moltšanova Karina;39008062216;Moltšanov Aleksei;0;13;;;13;44;;;-31
Kultuurimaja Rugodiv;8894014;60110243730;Matvejuk Irina;38206062210;Matvejuk Aleksei;0;;;;0;;;;0
Kultuurimaja Rugodiv;8894111;61502050046;Silina Ksenia;46710252223;Rulkova Leena ;0;;;;0;;;;0
Kultuurimaja Rugodiv;8894218;60004183721;Repp Ksenia;48101317010;Repp Olga;-6;;;;0;;;;-6
Kultuurimaja Rugodiv;8894412;60702013710;Sahharova Ksenija;36702213720;Sahharov  Nikolai;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8894519;61407210204;Dolinina Marella;48107073718;Dolinina Maria;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8894616;61101063746;Slobodjan Valeria;48902212211;Lissukova-Slobodjan Julia;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8894713;60711013753;Škinjova Arina;48411262241;Kaljurand Jevgenia;0;;;;0;;;;0
Kultuurimaja Rugodiv;8895110;60711103719;Anufrijeva Anfisa;47508062239;Anufrujeva Natalja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8895217;61512030145;Leontjeva Arina;49001033714;Leontjeva Albina;-0,7;;;;0;;;;-0,7
Kultuurimaja Rugodiv;8895314;60906287099;Saan Milena;48607192244;Saan Linda;-16;;;;0;;;;-16
Kultuurimaja Rugodiv;8895411;60802093714;Levanidova Evilina;47107282226;Levanidova  Julia;11;13;;;13;11;;;13
Kultuurimaja Rugodiv;8895518;37002143738;Kovalev Evgeny;37002143738;Kovaljov Jevgeni;-1,7;13;;;13;11;;;0,3
Kultuurimaja Rugodiv;8895615;46110122211;Baikova Marina;46110122211;Baikova Marina;-5,7;;;;0;;;;-5,7
Kultuurimaja Rugodiv;8895712;45504293713;Lavrukova Natalja;45504293713;Lavrukova Natalja;0;5;;;5;;;;5
Kultuurimaja Rugodiv;8895819;50505153719;Pavlov Kirill;47507193726;Pavlova Tatjana;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8895916;50601263726;Goncharov Maksim;48110253729;Concharova Olga;0;;;;0;;;;0
Kultuurimaja Rugodiv;8896012;61509130040;Baranova Maria;47206142234;Baranova Olga ;-1,35;;;;0;;;;-1,35
Kultuurimaja Rugodiv;8896119;61306280310;Lovaris Jasmine Raphaella;48909193717;Smirnova Irina;-12;13;;;13;;;;1
Kultuurimaja Rugodiv;8896216;61708050114;Zubkova Valeria;48710083723;Zubkova Olga;0;;;;0;;;;0
Kultuurimaja Rugodiv;8896313;61502130169;Kljutšenkova Ksenia;48704172785;Kljutšenkova Darja;0;;;;0;;;;0
Kultuurimaja Rugodiv;8896410;60811083728;Šelehhova Margarita;48110093733;Shelehhov Dmitri;22;13;;;13;33;;;2
Kultuurimaja Rugodiv;8896711;60709162244;Pavlova Diana;38807153719;Pavlov Dmitri;11;13;;;13;;;;24
Kultuurimaja Rugodiv;8896818;61009193722;Lobina Sofia;48110143716;Voitik Marina;-65;13;;;13;;;;-52
Kultuurimaja Rugodiv;8896915;36807143719;Bassov Andrei;36807143719;Bassov Andrei;0;;;;0;;;;0
Kultuurimaja Rugodiv;8897011;60711063755;Iis Nelly;48603293717;Iis Marija;0;;;;0;;;;0
Kultuurimaja Rugodiv;8897118;60406013710;Sussi Eleonora;47909137019;Sussi Maria;-14,7;;;;0;;;;-14,7
Kultuurimaja Rugodiv;8897215;60910173725;Kornijenko Varvara;44705273730;Nekrassova Ljudmila;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8897516;60811203717;Sukhikh Zlata;47110012211;Sukhikh Svetlana;0;13;;;13;2;;;11
Kultuurimaja Rugodiv;8897710;36704206028;Siim Jaanus;36704206028;Siim Jaanus;0;;;;0;;;;0
Kultuurimaja Rugodiv;8898816;35601013717;Smirnov Valery;35601013717;Smirnov Valery;0;5;;;5;4;;;1
Kultuurimaja Rugodiv;8898913;60609100011;Zhuravskaya Daria;46609290011;Zhuravskaya Elena;0;;;;0;;;;0
Kultuurimaja Rugodiv;8899019;61107243719;Andreeva Amalia;47702113739;Mirošnikova Olga;0;13;;;13;;;;13
Kultuurimaja Rugodiv;8899213;60108143716;Starostina Elina;36708063736;Starostin Vsevolod;-12,8;;;;0;;;;-12,8
Narva Muusikakool;8104225;51306150196;Kruhlov Diemid;47811040111;Kruhlova Olena;0;;;;0;;;;0
Narva Muusikakool;8104827;50704233712;Kossorotov Vladislav;48112113727;Kossorotova Nadezda;-4,06;;;;0;;;;-4,06
Narva Muusikakool;8105127;51207160117;Aletko Daniel;48208263712;Aletko Jelizaveta;1,3;1,3;;;1,3;1,3;;;1,3
Narva Muusikakool;8105428;51511270179;Babi Veniamin;49407153721;Babi Jelena;-40;1,05;;;1,05;;;;-38,95
Narva Muusikakool;8106621;51301020166;Ivanov Artur;48411263717;Ivanova Elvira;3,98;3,98;;;3,98;3,98;;;3,98
Narva Muusikakool;8107426;51505270151;Laukonen Adrian;47807243717;Tabakova Irina;1,22;1,22;;;1,22;;;;2,44
Narva Muusikakool;8109123;51103270140;Pomaznev Andrei;47503250018;Pomazneva Galina;5,75;5,75;;;5,75;5,75;;;5,75
Narva Muusikakool;8111027;51509170089;Tšurbakov Martin;48603073713;Tšurbakova Veronika;5,88;5,88;;;5,88;5,88;;;5,88
Narva Muusikakool;8134826;50007123726;Leonovitš Mark;47004050018;Leonovich Irina;0;;;;0;;;;0
Narva Muusikakool;8135223;50402123713;Lutška Leonid;47411062249;Lutška Olga;0;;;;0;;;;0
Narva Muusikakool;8141327;39607153737;Gruljov Juri;47109122766;Gruljova Jelena;0;;;;0;;;;0
Narva Muusikakool;8142520;60501142762;Ivleva Polina;47209147016;Ivleva Oksana;0;;;;0;;;;0
Narva Muusikakool;8152125;51208143720;Lazarev Daniil;48903103712;Lazareva Kristina;-17,65;2,88;;;2,88;;;;-14,77
Narva Muusikakool;8152222;51305030138;Botšenkov Daniil;48901223711;Botšenkova Jekaterina;2,25;2,25;;;2,25;2,25;;;2,25
Narva Muusikakool;8153027;51203153724;Parts Georg;36208213724;Parts Ilmar;2,25;2,25;;;2,25;2,25;;;2,25
Narva Muusikakool;8153328;51301290128;Poluektov Ustin;47609253728;Poluektova Elena;3,88;3,88;;;3,88;3,88;;;3,88
Narva Muusikakool;8153823;61012213735;Romanova Olga;47610223721;Romanova Galina;1,68;1,68;;;1,68;1,68;;;1,68
Narva Muusikakool;8168025;50712113730;Terentjev Pavel;47705243715;Terentjeva Natalja;0;;;;0;;;;0
Narva Muusikakool;8170628;50611263728;Zaika Markus;47412173732;Zaika Natalja;0;;;;0;;;;0
Narva Muusikakool;8178523;60809212730;Savtšukova Aylin;47904200033;Ismailova Nil;-9,76;;;;0;;;;-9,76
Narva Muusikakool;8182328;50410190906;Gordejev Vjatšeslav;47511022235;Butkevitš Anželika;3,75;3,75;;;3,75;3,75;;;3,75
Narva Muusikakool;8327824;61001053714;Tšurbakova Vanessa;48603073713;Tšurbakova Veronika;1,34;1,34;;;1,34;1,34;;;1,34
Narva Muusikakool;8405225;39203223767;Suhhovei Georgi;39203223767;Suhhovei Georgi;-0,03;;;;0;;;;-0,03
Narva Muusikakool;8406428;60903293712;Nikitina Anastasia;48301172224;Nikitina Veronika;0;2,25;;;2,25;;;;2,25
Narva Muusikakool;8409522;50309183721;Vaganov Ivan;48112273713;Vaganova Anna;-16,84;;;;0;;;;-16,84
Narva Muusikakool;8409726;50609053774;Vasilenko Timofei;37108059514;Vassilenko Aleksandr;0;;;;0;;;;0
Narva Muusikakool;8411222;51007233722;Vesselko Kristian;48107103728;Veselko Irina;0;;;;0;;;;0
Narva Muusikakool;8413220;51612090047;Kordontšuk Mihhail;48309302238;Kordontšuk Aljona;1,13;1,13;;;1,13;;;;2,26
Narva Muusikakool;8413327;39809203713;Assafatov Ilja;45910143745;Sokolova Tatjana;0;;;;0;;;;0
Narva Muusikakool;8414821;51102263729;Baranov Artjom;49003113716;Babi Inna;2,4;2,4;;;2,4;2,4;;;2,4
Narva Muusikakool;8415121;50704103729;Jemeljanov Artjom;47306123710;Jemeljanova Tatjana;0;;;;0;;;;0
Narva Muusikakool;8416227;60404073720;Lanbert Vlada;47706163740;Lanbert Irina;0;;;;0;;;;0
Narva Muusikakool;8418720;60808083715;Rodionova Lilia;37511223711;Rodionov Aleksandr;0;;;;0;;;;0
Narva Muusikakool;8419923;50503213731;Egorov Erik;46905312239;Egorova Natalia;4,8;2,4;;;2,4;7,2;;;0
Narva Muusikakool;8420022;61001213718;Krasavina Sofia;47511203714;Marina Krasavina;8,48;4,24;;;4,24;8,48;;;4,24
Narva Muusikakool;8421021;50906224729;Ivanichenko Gleb;48203172211;Ivanichenko Irina;0;;;;0;;;;0
Narva Muusikakool;8421225;61002153725;Lazareva Melissa;48903103712;Lazareva Kristina;0;;;;0;;;;0
Narva Muusikakool;8422321;50605203759;Gusev Artur Owenta;47411023719;Guseva Tatiana;-33,13;;;;0;;;;-33,13
Narva Muusikakool;8422525;50708193735;Nikitin Maik-Matvei;48301252216;Nukitina Maria;0;;;;0;;;;0
Narva Muusikakool;8423029;50905107013;Lugovski  Nikita;47703110222;Tamberg-Lugovskaja Ilona;3,75;3,75;;;3,75;;;;7,5
Narva Muusikakool;8424523;50301153715;Volotšinkov Maksim;50301153715;Volotšinkov Maksim;0;;;;0;;;;0
Narva Muusikakool;8426327;50405133713;Moissejev Dmitri;47803243720;Tjantova Marina;0;;;;0;;;;0
Narva Muusikakool;8426628;50903163739;Moskaljov Roman;47206242229;Moskaleva Nadezda;18,84;;;;0;;;;18,84
Narva Muusikakool;8426725;50705232753;Voronin Stepan;48502193736;Voronina Irina;0;;;;0;;;;0
Narva Muusikakool;8437727;61103233769;Peussa Vasilisa;48105283738;Peussa Ljudmila;0;;;;0;;;;0
Narva Muusikakool;8438221;50603103710;Gavrilov Ivan;46612042211;Gavrilova Tatjana;0;;;;0;;;;0
Narva Muusikakool;8442220;50903183742;Kuznetsov Daniil;48701173712;Farafonova Anna;0;;;;0;;;;0
Narva Muusikakool;8442628;50806053716;Matvejev Andrei;48304033747;Miller Anatsassia;2,26;;;;0;;;;2,26
Narva Muusikakool;8442725;50612042745;Šadrin Kirill;37403142213;Šadrin Aleksei;0;;;;0;;;;0
Narva Muusikakool;8442929;48606270041;Tikka Nadežda;48606270041;Tikka Nadežda;-20;;;;0;;;;-20
Narva Muusikakool;8443122;50908192766;Mihhailov Jan;36501223716;Mihhailov Vassili;11,25;11,25;;;11,25;11,25;;;11,25
Narva Muusikakool;8443423;50707063714;Cheremisinov Artem;45401013737;Tarassova Svetlana;0;;;;0;;;;0
Narva Muusikakool;8452029;51211103727;Reinol Filipp;47407153717;Reinol Jelena;6,74;6,74;;;6,74;6,74;;;6,74
Narva Muusikakool;8452621;51005153728;Jarmuhhamedov Tamir;47808073710;Jarmuhhamedova Marina;0;;;;0;;;;0
Narva Muusikakool;8453329;51006143715;Belov Ustin;48211153753;Belova Jekaterina;-18,96;;;;0;;;;-18,96
Narva Muusikakool;8454124;50612093711;Brindas Konstantin Mihai;44809052262;Gavrilova Ljudmila;0;;;;0;;;;0
Narva Muusikakool;8458625;50801233711;Smirnov Georgi;47503232257;Smirnova Yulia;0;;;;0;;;;0
Narva Muusikakool;8464428;61002113719;Ivanova Elina;48411263717;Ivanova Elvira;0;;;;0;;;;0
Narva Muusikakool;8464525;50801273717;Zaugarov Nikita;47903293724;Linnik Anna;0;;;;0;;;;0
Narva Muusikakool;8466824;51209120132;Lisjenko Boriss;48108100101;Lebedeva Nadežda;5,88;5,88;;;5,88;;;;11,76
Narva Muusikakool;8468521;50806263713;Chikin Arseni;48304012224;Kostištšina Natalja;2,83;2,83;;;2,83;8,49;;;-2,83
Narva Muusikakool;8470027;50708253713;Jelissejev Aleksei;46705153714;Jelissejeva  Natalja;0;;;;0;;;;0
Narva Muusikakool;8474625;49011203719;Lukso Viktoria;45405023720;Lukso Svetlana;-15,98;;;;0;;;;-15,98
Narva Muusikakool;8474829;50609093710;Gurõljov Anton;47805152210;Hozjainova Margarita;0;;;;0;;;;0
Narva Muusikakool;8478223;51110263712;Denisov Daniel;48601122264;Denisova Olesja;0;;;;0;;;;0
Narva Muusikakool;8485229;51108023719;Vassiltšenko Nazar;48003193726;Vassiltšenko Anna;0,04;1,68;;;1,68;;;;1,72
Narva Muusikakool;8485627;51112113725;Koževin Demid;46807273714;Koževina Irina;0;;;;0;;;;0
Narva Muusikakool;8489225;51204053723;Antipenkov Dmitri;49112123758;Antipenkova Jelena;0;;;;0;;;;0
Narva Muusikakool;8490120;61001183752;Veremi Isabelle;47410043728;Veremi Liilia;3,74;3,74;;;3,74;;;;7,48
Narva Muusikakool;8495028;60607313745;Vesselko Lilian;38105022229;Vesselko Sergei;0;;;;0;;;;0
Narva Muusikakool;8495727;50810203711;Veselko Artjom;38105022229;Vesselko Sergei;0;;;;0;;;;0
NNMK;8728229;36712052220;Denisenko Fedor;36712052220;Denissenko Fedor;0;;;;0;;;;0
NNMK;8728326;37705053717;Nesterenko Aleksandr;37705053717;Nesterenko Aleksandr;0;;;;0;;;;0$$, '\n') AS l) t;
*/


DROP TABLE IF EXISTS tmp_vordlemine;

CREATE TABLE IF NOT EXISTS tmp_vordlemine (
--    asutus          TEXT,
    ik              TEXT,
--    vn              TEXT,
--    maksja_ik       TEXT,
    arv             BOOLEAN,
    soodustus       BOOLEAN,
    laekumised      BOOLEAN,
    umberarvestatud BOOLEAN,
    algsaldo        BOOLEAN,
--    arv_isik        BOOLEAN,
    lopp_saldo      BOOLEAN,
    arv_diff NUMERIC,
    soodustus_diff NUMERIC,
    laekumised_diff NUMERIC,
    umber_diff NUMERIC,
    alg_diff NUMERIC,
    lopp_diff NUMERIC,
    IK_vale BOOLEAN
);

/*CREATE TABLE IF NOT EXISTS tmp_kaived (
        id              BIGINT,
        period          DATE,
        kulastatavus    TEXT,
        lapse_nimi      TEXT,
        lapse_isikukood TEXT,
        viitenumber     TEXT,
        alg_saldo       NUMERIC(14, 2),
        arvestatud      NUMERIC(14, 2),
        umberarvestus   NUMERIC(14, 2),
        soodustus       NUMERIC(14, 2),
        laekumised      NUMERIC(14, 2),
        mahakantud      NUMERIC(14, 2),
        tagastused      NUMERIC(14, 2),
        jaak            NUMERIC(14, 2),
        rekvid          INTEGER
    );

INSERT into tmp_kaived (id, period, kulastatavus, lapse_nimi, lapse_isikukood, viitenumber, alg_saldo, arvestatud, umberarvestus, soodustus, laekumised, mahakantud, tagastused, jaak, rekvid)
select * from lapsed.kaive_aruanne(119,
                                   '2023-01-01'::DATE,
                                   '2023-01-31':: DATE)

*/

DROP FUNCTION IF EXISTS lapsed.arvete_vordlemine();

CREATE FUNCTION lapsed.arvete_vordlemine()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_vn          RECORD;
    l_count       INTEGER = 0;
    l_rekv_id     INTEGER;
    l_prev_ik     TEXT    = '';
    l_vn          TEXT    = '';
    l_maksja      TEXT    = '';
    l_arv         NUMERIC = 0;
    v_kaived      RECORD;
    l_asutus      TEXT;
    l_soodustused NUMERIC = 0;
    l_laek        NUMERIC = 0 ;
    l_umber       NUMERIC = 0;
    l_alg         NUMERIC = 0;
    l_lopp        NUMERIC = 0;
    l_isik        TEXT    = '';
    l_isik_id     INTEGER = 0;
    l_lopp_saldo  NUMERIC = 0;
    l_laps_ik     TEXT;
    l_vale_ik boolean;
BEGIN
    -- Эти VN необходимо присвоить только имеющим слуги детям в своих учреждениях.
-- Если ребенка в указанном учрежд. нет, то такого надо игнорировать и не сохранять его нигде в базе не создавая мусора.
-- Если ребенок есть (имеет услуги), то присваиваем ему старый ВН
-- Если ребенок есть (имеет услуги) и имеет какой-то, ранее присвоенный ВН, то просто добавляем ему еще один ВН

    -- делаем отчет и сохраняем его данные

    FOR v_vn IN
        SELECT sum(regexp_replace(arvestatud, ',', '.')::NUMERIC)      AS arvestatud,
               sum(regexp_replace(alg_salod, ',', '.')::NUMERIC)       AS alg_salod,
               sum(regexp_replace(umberarvestatud, ',', '.')::NUMERIC) AS umberarvestatud,
               sum(regexp_replace(soodustus, ',', '.')::NUMERIC)       AS soodustus,
               sum(regexp_replace(laekumised, ',', '.')::NUMERIC)      AS laekumised,
               sum(regexp_replace(lopp_saldo, ',', '.')::NUMERIC)      AS lopp_saldo,
               sum(regexp_replace(tagastatud, ',', '.')::NUMERIC)      AS tagastatud,
               ik
        FROM (
                 SELECT a.asutus,
                        CASE WHEN empty(a.alg_salod) THEN '0' ELSE alg_salod END             AS alg_salod,
                        CASE WHEN empty(a.umberarvestatud) THEN '0' ELSE umberarvestatud END AS umberarvestatud,
                        CASE WHEN empty(a.laekumised) THEN '0' ELSE laekumised END           AS laekumised,
                        CASE WHEN empty(a.soodustus) THEN '0' ELSE soodustus END             AS soodustus,
                        CASE WHEN empty(a.arvestatud) THEN '0' ELSE arvestatud END           AS arvestatud,
                        CASE WHEN empty(a.lopp_saldo) THEN '0' ELSE lopp_saldo END           AS lopp_saldo,
                        CASE WHEN empty(a.tagastatud) THEN '0' ELSE tagastatud END           AS tagastatud,
                        a.arv_kokku,
                        a.asutus,
                        a.maksja_ik,
                        a.maksja,
                        a.vn,
                        a.nimi,
                        a.ik
                        --regexp_replace(vn, E'(^[\\n\\r]+)|([\\n\\r]+$)', '', 'g')         AS vn,
                        --regexp_replace(arv_ik, E'(^[\\n\\r]+)|([\\n\\r]+$)', '', 'g')     AS arv_ik,
                        --regexp_replace(esindus_ik, E'(^[\\n\\r]+)|([\\n\\r]+$)', '', 'g') AS esindus_ik
                 FROM tmp_arved a
--                 WHERE                        left(a.asutus, 3) in ('071', '073','077')
             ) qry
        GROUP BY ik
        ORDER BY ik
    --WHERE vn IS NOT NULL
--          AND vn = '9389337'
        LOOP

            SELECT sum(alg_saldo)     AS alg_saldo,
                   sum(arvestatud)    AS arvestatud,
                   sum(umberarvestus) AS umberarvestus,
                   sum(soodustus)     AS soodustus,
                   sum(laekumised)    AS laekumised,
                   sum(mahakantud)    AS mahakantud,
                   sum(tagastused)    AS tagastused,
                   sum(jaak)          AS jaak
            INTO v_kaived
            FROM tmp_kaived
            WHERE lapse_isikukood = v_vn.ik;
--            and rekvid in (71, 73, 77, 69, 66, 67, 72);

            l_lopp_saldo = ((coalesce(v_kaived.alg_saldo, 0) + coalesce(v_kaived.arvestatud, 0)
                - coalesce(v_kaived.soodustus, 0) - coalesce(v_kaived.laekumised, 0)) +
                            coalesce(v_kaived.umberarvestus, 0) + coalesce(v_kaived.tagastused, 0)) ;

            l_vale_ik = case when v_kaived.alg_saldo is null then true else false end;

            RAISE NOTICE 'l_arv %,v_kaived.arvestatud %, l_soodustused %, v_kaived.soodustus %, l_lopp_saldo %, l_lopp %',l_arv,v_kaived.arvestatud, l_soodustused, v_kaived.soodustus, l_lopp_saldo, l_lopp;

            INSERT INTO tmp_vordlemine (ik, arv, soodustus, laekumised, umberarvestatud,
                                        algsaldo, lopp_saldo, arv_diff, soodustus_diff, laekumised_diff, umber_diff, alg_diff, lopp_diff, IK_vale)
            VALUES (v_vn.ik,
                    (v_vn.arvestatud = coalesce(v_kaived.arvestatud, 0)),
                    (v_vn.soodustus = -1 * coalesce(v_kaived.soodustus, 0)),
                    (v_vn.laekumised = coalesce(v_kaived.laekumised, 0)),
                    (v_vn.umberarvestatud = coalesce(v_kaived.umberarvestus, 0)),
                    (v_vn.alg_salod = coalesce(v_kaived.alg_saldo, 0)),
                    (v_vn.lopp_saldo = l_lopp_saldo),
                        v_vn.arvestatud - coalesce(v_kaived.arvestatud, 0),
                    v_vn.soodustus - (-1 * coalesce(v_kaived.soodustus, 0)),
                    v_vn.laekumised - coalesce(v_kaived.laekumised, 0),
                    v_vn.umberarvestatud - coalesce(v_kaived.umberarvestus, 0),
                    v_vn.alg_salod - coalesce(v_kaived.alg_saldo, 0),
                    v_vn.lopp_saldo - l_lopp_saldo,
                    l_vale_ik
                    );


            l_count = l_count + 1;

        END LOOP;
    RETURN l_count;

END;
$$;

SELECT lapsed.arvete_vordlemine();

--DROP FUNCTION IF EXISTS lapsed.arvete_vordlemine();

--DROP TABLE IF EXISTS tmp_esindajad;
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

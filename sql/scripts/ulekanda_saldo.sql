/*
drop table if exists tmp_lib;
create table if not EXISTS tmp_lib (kood text, nimetus text, palgamaar text, summa text);

insert into  tmp_lib(kood, nimetus, palgamaar, summa)
SELECT
    t.f[1]::text AS kood
    ,t.f[2]::text AS nimetus
    ,t.f[3]::text AS palgamaar
    ,t.f[4]::text AS summa

FROM (
         SELECT regexp_split_to_array(l, ';') AS f
         FROM regexp_split_to_table(
                      $$AJ;Ametnikud - Juhid;17;1876
AJ;Ametnikud - Juhid;18;2097
AJ;Ametnikud - Juhid;19;2223
AJ;Ametnikud - Juhid;20;2351
AJ;Ametnikud - Juhid;21;2669
AJ;Ametnikud - Juhid;22;2779
AJ;Ametnikud - Juhid;23;2938
AJ;Ametnikud - Juhid;24;3202
ATS;Ametnikud - Tippspetsialistid;11;1063
ATS;Ametnikud - Tippspetsialistid;12;1029
ATS;Ametnikud - Tippspetsialistid;13;1196
ATS;Ametnikud - Tippspetsialistid;14;1359
ATS;Ametnikud - Tippspetsialistid;15;1552
ATS;Ametnikud - Tippspetsialistid;16;1682
ATS;Ametnikud - Tippspetsialistid;17;1876
ATS;Ametnikud - Tippspetsialistid;18;2097
ATS;Ametnikud - Tippspetsialistid;19;2223
ATS;Ametnikud - Tippspetsialistid;20;2351
ATS;Ametnikud - Tippspetsialistid;21;2669
AKS;Ametnikud - Keskastme spetsialistid;9;886
AKS;Ametnikud - Keskastme spetsialistid;10;930
AKS;Ametnikud - Keskastme spetsialistid;11;1063
AKS;Ametnikud - Keskastme spetsialistid;12;1129
AKS;Ametnikud - Keskastme spetsialistid;13;1196
AKS;Ametnikud - Keskastme spetsialistid;14;1359
AKS;Ametnikud - Keskastme spetsialistid;15;1552
AKS;Ametnikud - Keskastme spetsialistid;16;1682
AKS;Ametnikud - Keskastme spetsialistid;17;1876
AKS;Ametnikud - Keskastme spetsialistid;18;2097
ANS;Ametnikud - Nooremspetsialistid;0;0
TJ(A);Juhid - töölepingu alusel linna ametiasutustes;16;1682
TJ(A);Juhid - töölepingu alusel linna ametiasutustes;17;1876
TJ(A);Juhid - töölepingu alusel linna ametiasutustes;18;2097
TJ(A);Juhid - töölepingu alusel linna ametiasutustes;19;2223
TJ(A);Juhid - töölepingu alusel linna ametiasutustes;20;2351
TJ(A);Juhid - töölepingu alusel linna ametiasutustes;21;2669
TJ(A);Juhid - töölepingu alusel linna ametiasutustes;22;2779
TJ(A);Juhid - töölepingu alusel linna ametiasutustes;23;2938
TTS(A);Tippspetsialistid - töölepingu alusel linna ametiasutustes;11;1063
TTS(A);Tippspetsialistid - töölepingu alusel linna ametiasutustes;12;1129
TTS(A);Tippspetsialistid - töölepingu alusel linna ametiasutustes;13;1196
TTS(A);Tippspetsialistid - töölepingu alusel linna ametiasutustes;14;1359
TTS(A);Tippspetsialistid - töölepingu alusel linna ametiasutustes;15;1552
TTS(A);Tippspetsialistid - töölepingu alusel linna ametiasutustes;16;1682
TTS(A);Tippspetsialistid - töölepingu alusel linna ametiasutustes;17;1876
TTS(A);Tippspetsialistid - töölepingu alusel linna ametiasutustes;18;2097
TTS(A);Tippspetsialistid - töölepingu alusel linna ametiasutustes;19;2223
TTS(A);Tippspetsialistid - töölepingu alusel linna ametiasutustes;20;2351
TTS(A);Tippspetsialistid - töölepingu alusel linna ametiasutustes;21;2669
TKS(A);Keskastme spetsialistid - töölepingu alusel linna ametiasutustes;10;930
TKS(A);Keskastme spetsialistid - töölepingu alusel linna ametiasutustes;11;1063
TKS(A);Keskastme spetsialistid - töölepingu alusel linna ametiasutustes;12;1129
TKS(A);Keskastme spetsialistid - töölepingu alusel linna ametiasutustes;13;1196
TKS(A);Keskastme spetsialistid - töölepingu alusel linna ametiasutustes;14;1359
TKS(A);Keskastme spetsialistid - töölepingu alusel linna ametiasutustes;15;1552
TKS(A);Keskastme spetsialistid - töölepingu alusel linna ametiasutustes;16;1682
TKS(A);Keskastme spetsialistid - töölepingu alusel linna ametiasutustes;17;1876
TKS(A);Keskastme spetsialistid - töölepingu alusel linna ametiasutustes;18;2097
TNS(A);Nooremspetsialistid - töölepingu alusel linna ametiasutustes;7;886
TNS(A);Nooremspetsialistid - töölepingu alusel linna ametiasutustes;8;886
TNS(A);Nooremspetsialistid - töölepingu alusel linna ametiasutustes;9;886
TNS(A);Nooremspetsialistid - töölepingu alusel linna ametiasutustes;10;930
TNS(A);Nooremspetsialistid - töölepingu alusel linna ametiasutustes;11;1063
TNS(A);Nooremspetsialistid - töölepingu alusel linna ametiasutustes;12;1029
TNS(A);Nooremspetsialistid - töölepingu alusel linna ametiasutustes;13;1196
TNS(A);Nooremspetsialistid - töölepingu alusel linna ametiasutustes;14;1359
TT(A);Töötajad töölepingu alusel linna ametiasutustes;1;886
TT(A);Töötajad töölepingu alusel linna ametiasutustes;2;886
TT(A);Töötajad töölepingu alusel linna ametiasutustes;3;886
TT(A);Töötajad töölepingu alusel linna ametiasutustes;4;886
TT(A);Töötajad töölepingu alusel linna ametiasutustes;5;886
TT(A);Töötajad töölepingu alusel linna ametiasutustes;6;886
TT(A);Töötajad töölepingu alusel linna ametiasutustes;7;886
TT(A);Töötajad töölepingu alusel linna ametiasutustes;8;886
TT(A);Töötajad töölepingu alusel linna ametiasutustes;9;886
TT(A);Töötajad töölepingu alusel linna ametiasutustes;10;930
TT(A);Töötajad töölepingu alusel linna ametiasutustes;11;1063
TT(A);Töötajad töölepingu alusel linna ametiasutustes;12;1129
TJ1;Juhid I alagrupp - töölepingu alusel;17;1130
TJ1;Juhid I alagrupp - töölepingu alusel;18;1249
TJ1;Juhid I alagrupp - töölepingu alusel;19;1400
TJ1;Juhid I alagrupp - töölepingu alusel;20;1500
TJ1;Juhid I alagrupp - töölepingu alusel;21;1623
TJ1;Juhid I alagrupp - töölepingu alusel;22;1700
TJ1;Juhid I alagrupp - töölepingu alusel;23;1802
TJ1;Juhid I alagrupp - töölepingu alusel;24;1984
TJ2;Juhid II alagrupp - töölepingu alusel;20;1500
TJ2;Juhid II alagrupp - töölepingu alusel;21;1623
TJ2;Juhid II alagrupp - töölepingu alusel;22;1700
TJ2;Juhid II alagrupp - töölepingu alusel;23;1802
TJ2;Juhid II alagrupp - töölepingu alusel;24;1984
TJ2;Juhid II alagrupp - töölepingu alusel;25;2100
TJ2;Juhid II alagrupp - töölepingu alusel;26;2204
TTS;Tippspetsialistid - töölepingu alusel;14;961
TTS;Tippspetsialistid - töölepingu alusel;15;1042
TTS;Tippspetsialistid - töölepingu alusel;16;1084
TTS;Tippspetsialistid - töölepingu alusel;17;1130
TTS;Tippspetsialistid - töölepingu alusel;18;1249
TTS;Tippspetsialistid - töölepingu alusel;19;1400
TTS;Tippspetsialistid - töölepingu alusel;20;1500
TTS;Tippspetsialistid - töölepingu alusel;21;1623
TTS;Tippspetsialistid - töölepingu alusel;22;1700
TTS;Tippspetsialistid - töölepingu alusel;23;1802
TKS;Keskastme spetsialistid - töölepingu alusel ;12;886
TKS;Keskastme spetsialistid - töölepingu alusel ;13;890
TKS;Keskastme spetsialistid - töölepingu alusel ;14;961
TKS;Keskastme spetsialistid - töölepingu alusel ;15;1042
TKS;Keskastme spetsialistid - töölepingu alusel ;16;1084
TKS;Keskastme spetsialistid - töölepingu alusel ;17;1130
TKS;Keskastme spetsialistid - töölepingu alusel ;18;1249
TKS;Keskastme spetsialistid - töölepingu alusel ;19;1400
TKS;Keskastme spetsialistid - töölepingu alusel ;20;1500
TNS;Nooremspetsialistid - töölepingu alusel ;10;886
TNS;Nooremspetsialistid - töölepingu alusel ;11;886
TNS;Nooremspetsialistid - töölepingu alusel ;12;886
TNS;Nooremspetsialistid - töölepingu alusel ;13;890
TNS;Nooremspetsialistid - töölepingu alusel ;14;961
TNS;Nooremspetsialistid - töölepingu alusel ;15;1042
TNS;Nooremspetsialistid - töölepingu alusel ;16;1084
TNS;Nooremspetsialistid - töölepingu alusel ;17;1130
TT;Töötajad - töölepingu alusel;10;886
TT;Töötajad - töölepingu alusel;11;886
TT;Töötajad - töölepingu alusel;12;886
TT;Töötajad - töölepingu alusel;13;890
TT;Töötajad - töölepingu alusel;14;961
LJ2V;Lasteaedade juhid (direktor) nõuetele vastav;1;1920
LJ2V;Lasteaedade juhid (direktor) nõuetele vastav;2;1985
LJ2V;Lasteaedade juhid (direktor) nõuetele vastav;3;2030
LJ2V;Lasteaedade juhid (direktor) nõuetele vastav;4;2075
LJ2V;Lasteaedade juhid (direktor) nõuetele vastav;5;2120
LJ2V;Lasteaedade juhid (direktor) nõuetele vastav;6;2165
LJ2V;Lasteaedade juhid (direktor) nõuetele vastav;7;2210
LJ2V;Lasteaedade juhid (direktor) nõuetele vastav;8;2255
LJ2V;Lasteaedade juhid (direktor) nõuetele vastav;9;2300
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;1;1649
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;2;1688
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;3;1726
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;4;1746
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;5;1764
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;6;1787
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;7;1802
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;8;1827
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;9;1841
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;10;1843
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;11;1868
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;12;1879
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;13;1886
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;14;1908
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;15;1917
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;16;1929
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;17;1949
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;18;1955
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;19;1972
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;20;1989
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;21;2014
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;22;2030
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;23;2057
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;24;2070
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;25;2100
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;26;2143
LJ1V;Lasteaedade juhid (õppealajuhataja) nõuetele vastav;27;2185
LJ2MV;Lasteaedade juhid (direktor) nõuetele mittevastav;1;1515
LJ2MV;Lasteaedade juhid (direktor) nõuetele mittevastav;2;1550
LJ2MV;Lasteaedade juhid (direktor) nõuetele mittevastav;3;1585
LJ2MV;Lasteaedade juhid (direktor) nõuetele mittevastav;4;1620
LJ2MV;Lasteaedade juhid (direktor) nõuetele mittevastav;5;1655
LJ2MV;Lasteaedade juhid (direktor) nõuetele mittevastav;6;1690
LJ2MV;Lasteaedade juhid (direktor) nõuetele mittevastav;7;1725
LJ2MV;Lasteaedade juhid (direktor) nõuetele mittevastav;8;1760
LJ2MV;Lasteaedade juhid (direktor) nõuetele mittevastav;9;1795
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;1;1288
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;2;1318
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;3;1347
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;4;1364
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;5;1377
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;6;1395
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;7;1407
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;8;1427
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;9;1437
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;10;1439
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;11;1458
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;12;1466
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;13;1473
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;14;1490
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;15;1496
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;16;1506
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;17;1521
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;18;1526
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;19;1539
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;20;1553
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;21;1572
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;22;1584
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;23;1606
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;24;1616
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;25;1639
LJ1MV;Lasteaedade juhid (õppealajuhataja) nõuetele mittevastav;26;1672
LMV;Lasteaedade õpetaja magistrikraadiga nõuetele vastav;1;1820
LBV;Lasteaedade õpetaja bakalaureusekraadiga nõuetele vastav;1;1638
LMMV;Lasteaedade õpetaja magistrikraadiga nõuetele mittevastav;1;1600
LBMV;Lasteaedade õpetaja bakalaureusekraadiga nõuetele mittevastav;1;1412
KJ2-RE-JAH;Koolide nõuetele vastavad juhid (direktor), riigieelarve vahendid RE-HKJ;1;1940
KJ2-RE-JAH;Koolide nõuetele vastavad juhid (direktor), riigieelarve vahendid RE-HKJ;2;2265
KJ2-RE-JAH;Koolide nõuetele vastavad juhid (direktor), riigieelarve vahendid RE-HKJ;3;2425
KJ2-RE-JAH;Koolide nõuetele vastavad juhid (direktor), riigieelarve vahendid RE-HKJ;4;2985
KJ1-RE-JAH;Koolide nõuetele vastavad juhid (õppealajuhataja), riigieelarve vahendid RE-HKJ;1;1843
KJ1-RE-JAH;Koolide nõuetele vastavad juhid (õppealajuhataja), riigieelarve vahendid RE-HKJ;2;1925
KJ1-RE-JAH;Koolide nõuetele vastavad juhid (õppealajuhataja), riigieelarve vahendid RE-HKJ;3;2062
KJ1-RE-JAH;Koolide nõuetele vastavad juhid (õppealajuhataja), riigieelarve vahendid RE-HKJ;4;2152
KJ1-RE-JAH;Koolide nõuetele vastavad juhid (õppealajuhataja), riigieelarve vahendid RE-HKJ;5;2460
HKP-JAH;Koolide põhikooliastme õpetajad nõuetele vastavad, riigieelarve vahendid RE-HKP;1;1820
HKP-EI;Koolide põhikooliastme õpetajad nõuetele mittevastavad, riigieelarve vahendid RE-HKP;1;1820
HKG-JAH;Koolide  gümnaasiumi astme õpetajad nõuetele vastavad, riigieelarve vahendid RE-HKG;1;1820
HKG-EI;Koolide gümnaasiumi õpetajad nõuetele mittevastavad, riigieelarve vahendid RE-HKG;1;1820
LEP-JAH;Koolide põhikooliastme õpetajad nõuetele vastavad, linna põhielarve vahendid LE-P;1;1400
LEP-EI;Koolide põhikooliastme õpetajad nõuetele mittevastavad, linna põhielarve vahendid LE-P;1;1400
LEG-JAH;Koolide  gümnaasiumi astme õpetajad nõuetele vastavad, linna põhielarve vahendid LE-P;1;1400
LEG-EI;Koolide gümnaasiumi õpetajad nõuetele mittevastavad, linna põhielarve vahendid LE-P;1;1400
TS-JAH;Koolide tugispetsialistid nõuetele vastavad, linna põhieelarve vahendid LE-P;1;1803
TS-JAH;Koolide tugispetsialistid nõuetele vastavad, linna põhieelarve vahendid LE-P;2;1820
TS-EI;Koolide tugispetsialistid nõuetele mittevastavad, linna põhieelarve vahendid LE-P;1;1803
TS-EI;Koolide tugispetsialistid nõuetele mittevastavad, linna põhieelarve vahendid LE-P;2;1820
KK;Koolide keskharidusega huvijuhid, ringijuhid ja kasvatajad, linna põhielarve vahendid LE-P;1;1400
KKE;Koolide keskeriharidusega huvijuhid, ringijuhid ja kasvatajad, linna põhielarve vahendid LE-P;1;1400
KB;Koolide bakalaureusekraadiga huvijuhid, ringijuhid ja kasvatajad, linna põhielarve vahendid LE-P;1;1400
KM;Koolide magistrikraadiga huvijuhid, ringijuhid ja kasvatajad, linna põhielarve vahendid LE-P;1;1400
HJ2V;Huvikoolide juhid (direktor) nõuetele vastav;1;1690
HJ2V;Huvikoolide juhid (direktor) nõuetele vastav;2;1810
HJ2V;Huvikoolide juhid (direktor) nõuetele vastav;3;1881
HJ2V;Huvikoolide juhid (direktor) nõuetele vastav;4;2001
HJ1V;Huvikoolide juhid (õppealajuhataja) nõuetele vastav;1;1437
HJ1V;Huvikoolide juhid (õppealajuhataja) nõuetele vastav;2;1521
HJ1V;Huvikoolide juhid (õppealajuhataja) nõuetele vastav;3;1539
HJ1V;Huvikoolide juhid (õppealajuhataja) nõuetele vastav;4;1599
HJ1V;Huvikoolide juhid (õppealajuhataja) nõuetele vastav;5;1606
HJ1V;Huvikoolide juhid (õppealajuhataja) nõuetele vastav;6;1629
HJ1V;Huvikoolide juhid (õppealajuhataja) nõuetele vastav;7;1693
HJ1V;Huvikoolide juhid (õppealajuhataja) nõuetele vastav;8;1701
HJ1V;Huvikoolide juhid (õppealajuhataja) nõuetele vastav;9;1720
HJ1V;Huvikoolide juhid (õppealajuhataja) nõuetele vastav;10;1787
HJ1V;Huvikoolide juhid (õppealajuhataja) nõuetele vastav;11;1801
HJ1V;Huvikoolide juhid (õppealajuhataja) nõuetele vastav;12;1901
HJ2MV;Huvikoolide juhid (direktor) nõuetele mittevastav;1;1363
HJ2MV;Huvikoolide juhid (direktor) nõuetele mittevastav;2;1460
HJ2MV;Huvikoolide juhid (direktor) nõuetele mittevastav;3;1517
HJ2MV;Huvikoolide juhid (direktor) nõuetele mittevastav;4;1614
HJ1MV;Huvikoolide juhid (õppealajuhataja) nõuetele mittevastav;1;1159
HJ1MV;Huvikoolide juhid (õppealajuhataja) nõuetele mittevastav;2;1227
HJ1MV;Huvikoolide juhid (õppealajuhataja) nõuetele mittevastav;3;1241
HJ1MV;Huvikoolide juhid (õppealajuhataja) nõuetele mittevastav;4;1290
HJ1MV;Huvikoolide juhid (õppealajuhataja) nõuetele mittevastav;5;1295
HJ1MV;Huvikoolide juhid (õppealajuhataja) nõuetele mittevastav;6;1314
HJ1MV;Huvikoolide juhid (õppealajuhataja) nõuetele mittevastav;7;1366
HJ1MV;Huvikoolide juhid (õppealajuhataja) nõuetele mittevastav;8;1372
HJ1MV;Huvikoolide juhid (õppealajuhataja) nõuetele mittevastav;9;1387
HJ1MV;Huvikoolide juhid (õppealajuhataja) nõuetele mittevastav;10;1442
HJ1MV;Huvikoolide juhid (õppealajuhataja) nõuetele mittevastav;11;1453
HJ1MV;Huvikoolide juhid (õppealajuhataja) nõuetele mittevastav;12;1534
HK;Huvikoolide keskharidusega õpetajad;1;1400
HKE;Huvikoolide keskeriharidusega õpetajad;1;1400
HB;Huvikoolide bakalaureusekraadiga õpetajad;1;1400
HM;Huvikoolide magistrikraadiga õpetajad;1;1400
HK3;Spordikoolide treenirid keskharidusega, kutsetase 3;1;1400
HK4;Spordikoolide treenirid keskharidusega, kutsetase 4;1;1400
HK5;Spordikoolide treenirid keskharidusega, kutsetase 5;1;1400
HK6;Spordikoolide treenirid keskharidusega, kutsetase 6;1;1400
HK7;Spordikoolide treenirid keskharidusega, kutsetase 7;1;1400
HKE3;Spordikoolide treenirid keskeriharidusega, kutsetase 3;1;1400
HKE4;Spordikoolide treenirid keskeriharidusega, kutsetase 4;1;1400
HKE5;Spordikoolide treenirid keskeriharidusega, kutsetase 5;1;1400
HKE6;Spordikoolide treenirid keskeriharidusega, kutsetase 6;1;1400
HKE7;Spordikoolide treenirid keskeriharidusega, kutsetase 7;1;1400
HB3;Spordikoolide treenirid bakalaureusekraadiga, kutsetase 3;1;1400
HB4;Spordikoolide treenirid bakalaureusekraadiga, kutsetase 4;1;1400
HB5;Spordikoolide treenirid bakalaureusekraadiga, kutsetase 5;1;1400
HB6;Spordikoolide treenirid bakalaureusekraadiga, kutsetase 6;1;1400
HB7;Spordikoolide treenirid bakalaureusekraadiga, kutsetase 7;1;1400
HM3;Spordikoolide treenirid magistrikraadiga, kutsetase 3;1;1400
HM4;Spordikoolide treenirid magistrikraadiga, kutsetase 4;1;1400
HM5;Spordikoolide treenirid magistrikraadiga, kutsetase 5;1;1400
HM6;Spordikoolide treenirid magistrikraadiga, kutsetase 6;1;1400
HM7;Spordikoolide treenirid magistrikraadiga, kutsetase 7;1;1400$$, '\n') AS l) t;
*/
DROP FUNCTION IF EXISTS lapsed.ulekanda_saldo();

CREATE FUNCTION lapsed.ulekanda_saldo()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_saldo     RECORD;
    v_vanem     record;
    l_count     INTEGER = 0;
    l_isik_from integer;
    l_isik_to   integer;
    l_user_id   integer;
BEGIN
    for v_saldo in
        select distinct
            s.lapse_ik,
            s.id_asutus,
            l.id as laps_id
        from
            tmp_saldo                  s
                inner join lapsed.laps l on l.isikukood = s.lapse_ik and l.staatus < 3

        where
            lapse_ik is not null
--        and lapse_ik = '61311130151'
        loop
            l_user_id = (
                            select id from ou.userid where rekvid = v_saldo.id_asutus::integer and kasutaja = 'vlad' limit 1
                        );

            for v_vanem in
                with
                    qry as (
                               select
                                   id_vanem,
                                   vanem_ik,
                                   saldo,
                                   (
                                       select
                                           arveldus as kas_arveldus
                                       from
                                           lapsed.vanem_arveldus      va
                                               inner join lapsed.laps l on l.id = va.parentid
                                       where
                                             va.asutusid = s.id_vanem::integer
                                         and l.isikukood = v_saldo.lapse_ik
                                         and va.rekvid = s.id_asutus::integer
                                   ) as kas_arveldus
                               from
                                   tmp_saldo s
                               where
                                     lapse_ik = v_saldo.lapse_ik
                                 and id_asutus = v_saldo.id_asutus
                    )
                select *
                from
                    qry
                order by kas_arveldus desc
                loop
                    if v_vanem.kas_arveldus then
                        l_isik_to = v_vanem.id_vanem::integer ;
                    else
                        l_isik_from = v_vanem.id_vanem::integer;
                    end if;
--                    raise notice 'v_vanem.kas_arveldus %, v_vanem.saldo %, v_vanem.vanem_ik %, l_isik_to %, l_isik_from %', v_vanem.kas_arveldus,v_vanem.saldo, v_vanem.vanem_ik, l_isik_to, l_isik_from;

                    if l_isik_to is not null and l_isik_from is not null then
                        perform docs.saldo_ulekanne_lausend(l_user_id:: INTEGER, l_isik_from:: INTEGER,
                                                            l_isik_to:: INTEGER,
                                                            '2024-12-31':: DATE,
                                                            v_saldo.laps_id);
                    end if;

                    l_count = l_count + 1;
                end loop;
            if l_isik_to is null then
                raise notice 'Vigane lapse_ik %, id_asutus %',v_saldo.lapse_ik, id_asutus;
            end if;
            l_isik_to = null;
            l_isik_from = null;


        end loop;

    RETURN l_count;

END;
$$;

SELECT lapsed.ulekanda_saldo();

DROP FUNCTION IF EXISTS lapsed.ulekanda_saldo();
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

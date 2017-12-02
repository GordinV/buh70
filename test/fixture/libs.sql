-- rekv
insert into ou.rekv (id, parentid, regkood, nimetus )
select 1 as id, 0 as parentid, '10000' as regkood, 'test asutus' as nimetus  
	where (select count(id) from ou.rekv) = 0;

SELECT setval('ou.rekv_id_seq', (select max(id) from ou.rekv), true);

-- userid
insert into ou.userid (id, rekvid, kasutaja, ametnik, kasutaja_, peakasutaja_, parool )
select 1 as id, 1 as rekvid, 'vlad' as kasutaja, 'test user' as ametnik, 1 as  kasutaja_, 1 as peakasutaja_ , '51a52a6bfba5178293dc18f683619c99d6a01101' as parool
	where (select count(id) from ou.userid) = 0;

SELECT setval('ou.userid_id_seq', (select max(id) from ou.userid), true);

-- aa
insert into ou.aa (id, parentid, arve, nimetus, kassa, pank, konto )
select 1 as id, 1 as parentid, 'kassa1' as arve, 'Kassa1' as nimetus, 1 as  kassa, 0 as pank , '111' as konto
	where (select count(id) from ou.aa) = 0;

SELECT setval('ou.aa_id_seq', (select max(id) from ou.aa), true);

	
-- delete all libs

delete from libs.library where library in ('DOK','STATUS', 'PVGRUPP','KONTOD','PROJ','TUNNUS');

-- insert doks

insert into libs.library (id, rekvid, kood, nimetus, library) values (1, 1, 'DOK', 'Dokumendid','DOK');
insert into libs.library (id, rekvid, kood, nimetus, library) values (2, 1, 'ARV', 'Arved', 'DOK');
insert into libs.library (id, rekvid, kood, nimetus, library) values (3, 1, 'JOURNAL', 'Lausendid', 'DOK');
--insert into libs.library (id, rekvid, kood, nimetus, library) values (4, 1, 'PALK', 'Palk', 'DOK');
--insert into libs.library (id, rekvid, kood, nimetus, library) values (5, 1, 'TAABEL', 'Tööaja taabel', 'DOK');
--insert into libs.library (id, rekvid, kood, nimetus, library) values (6, 1, 'PVGRUPP', 'Grupp nimetus', 'DOK');
--insert into libs.library (id, rekvid, kood, nimetus, library) values (7, 1, 'PVOPER', 'PV tehingud', 'DOK');
insert into libs.library (id, rekvid, kood, nimetus, library) values (8, 1, 'SORDER', 'Sissemakse kassaorder', 'DOK');
insert into libs.library (id, rekvid, kood, nimetus, library) values (9, 1, 'VORDER', 'Väljamakse kassaorder', 'DOK');

SELECT setval('libs.library_id_seq', 9, true);

-- status
insert into libs.library (rekvid, kood, nimetus, library) values (1, '0', 'Черновик', 'STATUS');
insert into libs.library (rekvid, kood, nimetus, library) values (1, '1', 'Активный', 'STATUS');
insert into libs.library (rekvid, kood, nimetus, library) values (1, '2', 'Проведен', 'STATUS');
insert into libs.library (rekvid, kood, nimetus, library) values (1, '3', 'Удален', 'STATUS');


-- SORDER NOMS
--delete from libs.nomenklatuur where dok in ('SORDER');
--insert into libs.nomenklatuur (rekvid, dok, kood, nimetus, hind)
--	values (1, 'SORDER', 'PANK', 'Raha pankarvele', 10);

-- VORDER NOMS
--delete from libs.nomenklatuur where dok in ('SORDER');
--insert into libs.nomenklatuur (rekvid, dok, kood, nimetus, hind)
--	values (1, 'VORDER', 'PANK', 'Raha pankarvelt', 10);

-- proj
insert into libs.library (rekvid, kood, nimetus, library) values (1, 'test', 'Projekt test', 'PROJ');

-- tunnus
insert into libs.library (rekvid, kood, nimetus, library) values (1, 'tunnus', 'Tunnus test', 'TUNNUS');

-- kontod

INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '590', 'Muud tegevuskulud', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '560', 'Lähetuskulud', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '570', 'Kulum', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '6033', 'Puhkus (abipersonal)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '5010', 'Telefon (kontor)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '5012', 'Mob. telefonid (EE)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '5011', 'Mob. telefonid (VG)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '5019', 'Internet', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '5020', 'Rent (kontor)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '5030', 'Arvutid (rent)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '5031', 'Arvutid (hooldus ja remont)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '5040', 'Kantselei kulud', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '520', 'Koolituskulud', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '330', 'Kasum transpordi kasutamist', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '510', 'Tellitud teenustööd ', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '531', 'Transpordikulud (kütus)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '540', 'Kindlustus', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '551', 'Raamatupidamise kulud', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '552', 'Audiitoriteenus', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '450', 'Tehnoloogilise kütuse kulu', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '460', 'Tootmise elektrienergia kulu', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '470', 'Kaupade kulu', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '610', 'Puhkusetasu reserv', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '620', 'Sotsiaalmaks töötasult', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '6010', 'Palgakulud (Juhid)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '6020', 'Palgakulud (spetsialistid)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '6030', 'Palgakulud (abi personal)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '6011', 'Preemiad (juhid)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '6021', 'Preemiad (spetsialistid)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '6031', 'Preemiad (abi personal)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '6013', 'Puhkus (juhid)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '6023', 'Puhkus (spetsialistid)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '3210', 'Realisatsioon 0% käibemaksuga', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '340', 'Kasum ristvara rendist', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '3220', 'Kasum konsulatasiooni teenuste müügist', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '3510', 'Kasum põhivara müügist', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '352', 'Kasum valuutakursi muutusest', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '353', 'Saadud leppetrahvid', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '354', 'Kasum kinnisvarainvesteeringu ümberhindlusest', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '359', 'Ümardamised', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '365', 'Muud interssid ja finantstulud', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '366', 'Kasum valuutakursi muutusest', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '3221', 'Kasum konsulatasiooni teenuste (AS Medisoft) müügist', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '3230', 'Kasum hooldus teenuste müügist', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '3511', 'Kasum ristvara (Esitlustehhnika) müügist', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '3512', 'Kasum ristvara (Arvutitehhnika) müügist', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '401', 'Tooraine kulu', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '410', 'Põhimaterjalide kulu', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '420', 'Abimaterjalide kulu', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '430', 'Valimstoodangu kulu', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '440', 'Pooltoodete ja detailide kulu', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '270', 'Lühiajalised eraldised', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '272', 'Muud tulevaste perioodide ettemakstud tulud', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '281', 'Pikaajalised võlakohustused', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '282', 'Laenud, võlakirjad ja kapitalirendi kohustused', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '283', 'Konventeeritavad võlakohustused', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '284', 'Muud pikaajalised võlad', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '287', 'Pikaajalised eraldised', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '289', 'Muud eraldised', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '791', 'tulud/kulud', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '292', 'Ülekurss', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '293', 'Oma osad (miinus)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '294', 'Reservid', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '297', 'Eelmiste perioodide jaotamata kasum (kahjum)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '298', 'Aruandeaasta kasum (kahjum)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '3201', 'Kasum oma tarkvara müügist', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '3202', 'Kasum Datel tarkvara müügist', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '2510', 'Müügi käibemaks', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '2511', 'Sisendkäibemaks', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '2512', 'Käibemaksu tasumine', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '2513', 'Käibemaksu viivised', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '2514', 'Käibemaks tollis', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '2519', 'Käibemaksu parandused', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '231', 'Võlad tarnijatele', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '2522', 'Sotsiaalmaksu viivised', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '2530', 'Isiku tulumaksu võlg ', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '2533', 'Isiku tulumaksu viivised', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '2540', 'Töötuskindlustusmakse võlg ', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '2544', 'Töötuskindlustusmakse viivised', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '2550', 'Kogumispensionimakse võlg ', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '2555', 'Kogumispensionimakse viivised', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '2610', 'Palgad töövõtjatele', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '2611', 'Puhkusetasu reserv', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '262', 'Dividendivõlad', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '263', 'Intressivõlad', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '2641', 'Arvestatud renditasu', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '2642', 'Arvestatud lähetuskulu', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '163', 'Valmistoodang', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '164', 'Müügiks ostetud kaubad', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '165', 'Ettemaksed tarnijatele', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '170', 'Pikajalised finantsinvesteeringud', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '180', 'Kinnisvarainvesteeringud', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '181', 'Maa ja ehitised', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '183', 'Muu materiaalne põhivara', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '185', 'Lõpetamata ehitised', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '186', 'Ettemaksed põhivara eest', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '191', 'Arenguväljaminekud', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '192', 'Patendid, litsentsid, kaubamärgid ja muu immateriaalne põhivara', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '193', 'Firmaväärtus', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '194', 'Ettamaksed immateriaalse põhivara eest', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '210', 'Lühiajalised laenud ja võlakirjad', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '211', 'Pikajaliste võlakohustuste tagasimaksed järgmisel perioodil', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '220', 'Ostjate ettemaksed', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '113', 'Pank (EEK)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '232', 'Võlad tarnijatele(EURO)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '243', 'Muud lühiajalised võlad', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '111', 'Kassa', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '115', 'Pank (EURO)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '136', 'lahetuskulud', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '122', 'Deebitorid (EEK)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '123', 'Deebitorid (EURO)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '135', 'Kreedit kaart', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '166', 'Kulum (inventaar)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '190', 'Immaterriaalne põhivara', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '161', 'Tooraine ja materjal', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '162', 'Lõpetamata toodang', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '114', 'parandus', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '182', 'Masinad ja seadmed', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (2, '184', 'Põhivara akumuleeritud kulum (-)', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '2520', 'Sotsiaalmaksu võlg ', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '291', 'Osakapital  nimiväärtuses', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '630', 'Töökindlustus kulu', 'KONTOD');
INSERT INTO libs.library (rekvid, kood, nimetus, library) VALUES (1, '500', 'kulud', 'KONTOD');


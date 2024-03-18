INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'LAPS'                                    AS kood,
       'Lapsed'                                  AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'LAPS');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'VANEM'                                   AS kood,
       'Vanemate register'                       AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'VANEM');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'LAPSE_KAART'                             AS kood,
       'Teenused lastele'                        AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'LAPSE_KAART');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'LAPSE_TAABEL'                            AS kood,
       'Teenuste taabel lastele'                 AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'LAPSE_TAABEL');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'LAPSE_GRUPP'                             AS kood,
       'Lastegruppid'                            AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'LAPSE_GRUPP');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'INF3'                                                         AS kood,
       'INF3 Füüsiliste isikute tasutud koolituskulude deklaratsioon' AS nimetus,
       'DOK'                                                          AS library,
       '{"type":"aruanne", "module":["Lapsed"]}'                      AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'INF3');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'REKV'                                     AS kood,
       'Oma asutuse andmed'                       AS nimetus,
       'DOK'                                      AS library,
       '{"type":"settings", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'REKV');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'CONFIG'                                   AS kood,
       'Konfiguratsioon'                          AS nimetus,
       'DOK'                                      AS library,
       '{"type":"settings", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'CONFIG');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'USERID'                                   AS kood,
       'Kasutaja andmed'                          AS nimetus,
       'DOK'                                      AS library,
       '{"type":"settings", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'USERID');


INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'LAPS_KOKKUVOTTE'                         AS kood,
       'Lapse kokkuvõtte seis'                   AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'LAPS_KOKKUVOTTE');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'LAPS_KV_KAIBED'                          AS kood,
       'Lapse kokkuvõtte seis (Käibed)'          AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'LAPS_KV_KAIBED');


INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'ARVED_KOODI_JARGI'                       AS kood,
       'Arved koodi järgi'                       AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'ARVED_KOODI_JARGI');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'SALDO_JA_KAIVE'                          AS kood,
       'Saldo ja käive aruanne'                  AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'SALDO_JA_KAIVE');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'KAIVE_ARUANNE'                           AS kood,
       'Saldo ja käive (rühmainfota) aruanne'    AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'KAIVE_ARUANNE');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'SENT_DOCS'                               AS kood,
       'Saadetud dokumendid'                     AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'SENT_DOCS');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'CHILD_AGE'                               AS kood,
       'Laste vanus'                             AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'CHILD_AGE');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'SOODUSTUSED'                             AS kood,
       'Soodustused '                            AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'SOODUSTUSED');


INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'STATISTIKA'                              AS kood,
       'Laste statistika '                       AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'STATISTIKA');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'EBATOENAOLISED'                          AS kood,
       'Ebatõenäolised nõuded '                  AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'EBATOENAOLISED');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'KONDARVE'                                AS kood,
       'Kondarve '                               AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'KONDARVED');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'AASTA_NAITAJAD'                          AS kood,
       'Aasta näitajad'                          AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'AASTA_NAITAJAD');


INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'TEATIS'                                   AS kood,
       'Teatised'                                 AS nimetus,
       'DOK'                                      AS library,
       '{"type":"document", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'TEATIS');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties, status)
SELECT 1::INTEGER,
       'ASUTUSE_LIIK'                            AS kood,
       'Asutuse liik'                            AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties,
       1
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'ASUTUSE_LIIK');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties, status)
SELECT 1::INTEGER,
       'KOOLITUSE_TYYP'                          AS kood,
       'Koolituse tüüp'                          AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties,
       1
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'KOOLITUSE_TYYP');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties, status)
SELECT 1::INTEGER,
       'KOOLITUSE_LIIK'                          AS kood,
       'Koolituse liik'                          AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties,
       1
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'KOOLITUSE_LIIK');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties, status)
SELECT 1::INTEGER,
       'PAEVA_TAABEL'                            AS kood,
       'Päeva taabel'                            AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties,
       1
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'PAEVA_TAABEL');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'KUU_TAABEL'                              AS kood,
       'Asutuse kuu taabel'                      AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'KUU_TAABEL');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'YKSUSE_TAABEL'                           AS kood,
       'Asutuse kuu taabel üksuse järgi'         AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'YKSUSE_TAABEL');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'KOHALOLEKU_ARUANNE'                      AS kood,
       'Kohaloleku aruanne'                      AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'KOHALOLEKU_ARUANNE');


INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'TOPELTMAKSD'                             AS kood,
       'Topeltmaksud aruanne'                    AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'TOPELTMAKSD');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'KUUTABELI_ARUANNE'                       AS kood,
       'Kuutabeli aruanne'                       AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'KUUTABELI_ARUANNE');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'VIITENR'                         AS kood,
       'Vana viitenumbrid'               AS nimetus,
       'DOK'                             AS library,
       '{"type":"library", "module":[]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'VIITENR');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'SALDO_JA_KAIBEANDMIK'                    AS kood,
       'Saldo ja käibeandmik'                    AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'SALDO_JA_KAIBEANDMIK');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'SALDO_JA_KA_KOKKU'                       AS kood,
       'Saldo ja käibeandmik (kokkuvõte)'        AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'SALDO_JA_KA_KOKKU');


INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'KAIVE_ARUANNE_KOKKU'                     AS kood,
       'Saldo ja käive aruanne (kokkuvõte)'      AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'KAIVE_ARUANNE_KOKKU');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'SELGEMATA_MAKSED'                        AS kood,
       'Selgitamata pangamaksete analüüs'        AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'SELGEMATA_MAKSED');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'PANK_EARVE'                              AS kood,
       'Arved, e-arve esitamiseks'               AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'PANK_EARVE');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'SALDOD_ASUTUSTES'                                          AS kood,
       'Laste saldod asutustes'                                    AS nimetus,
       'DOK'                                                       AS library,
       '{"type":"aruanne", "module":["Lapsed"], "rekv_ids":[119]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'SALDOD_ASUTUSTES');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'ASENDUS_TAABEL'                          AS kood,
       'Asendus taabel lastele'                  AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'ASENDUS_TAABEL');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'INF3_ANALUUS'                            AS kood,
       'INF3 ANALÜÜS'                            AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'INF3_ANALUUS');


INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'AASTA_NAITAJAD_TYYP'                     AS kood,
       'Aasta näitajad (koolituse tüüp)'         AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'AASTA_NAITAJAD_TYYP');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'ARVED_EMAILIGA'                     AS kood,
       'Saadetud arved emailiga'         AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'ARVED_EMAILIGA');

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
       'LAPS_KOKKUVOTTE'                                                         AS kood,
       'Lapse kokkuvõtte seis' AS nimetus,
       'DOK'                                                          AS library,
       '{"type":"aruanne", "module":["Lapsed"]}'                      AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'LAPS_KOKKUVOTTE');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'ARVED_KOODI_JARGI'                                                         AS kood,
       'Arved koodi järgi' AS nimetus,
       'DOK'                                                          AS library,
       '{"type":"aruanne", "module":["Lapsed"]}'                      AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'ARVED_KOODI_JARGI');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'SALDO_JA_KAIVE'                                                         AS kood,
       'Saldo ja käive aruanne' AS nimetus,
       'DOK'                                                          AS library,
       '{"type":"aruanne", "module":["Lapsed"]}'                      AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'SALDO_JA_KAIVE');


INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'SENT_DOCS'                                                         AS kood,
       'Saadetud dokumendid' AS nimetus,
       'DOK'                                                          AS library,
       '{"type":"aruanne", "module":["Lapsed"]}'                      AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'SENT_DOCS');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'CHILD_AGE'                                                         AS kood,
       'Laste vanus' AS nimetus,
       'DOK'                                                          AS library,
       '{"type":"aruanne", "module":["Lapsed"]}'                      AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'CHILD_AGE');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'SOODUSTUSED'                                                         AS kood,
       'Soodustused ' AS nimetus,
       'DOK'                                                          AS library,
       '{"type":"aruanne", "module":["Lapsed"]}'                      AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'SOODUSTUSED');


INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'STATISTIKA'                                                         AS kood,
       'Laste statistika ' AS nimetus,
       'DOK'                                                          AS library,
       '{"type":"aruanne", "module":["Lapsed"]}'                      AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'STATISTIKA');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'EBATOENAOLISED'                                                         AS kood,
       'Ebatõenäolised nõuded ' AS nimetus,
       'DOK'                                                          AS library,
       '{"type":"aruanne", "module":["Lapsed"]}'                      AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'EBATOENAOLISED');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'KONDARVE'                                                         AS kood,
       'Kondarve ' AS nimetus,
       'DOK'                                                          AS library,
       '{"type":"aruanne", "module":["Lapsed"]}'                      AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'KONDARVED');


INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'AASTA_NAITAJAD'                                                         AS kood,
       'Aasta näitajad' AS nimetus,
       'DOK'                                                          AS library,
       '{"type":"aruanne", "module":["Lapsed"]}'                      AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'AASTA_NAITAJAD');


INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'TEATIS'                                    AS kood,
       'Teatised'                                  AS nimetus,
       'DOK'                                     AS library,
       '{"type":"document", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'TEATIS');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties, status)
SELECT 1::INTEGER,
       'ASUTUSE_LIIK'                                    AS kood,
       'Asutuse liik'                                  AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties,
       1
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'ASUTUSE_LIIK');


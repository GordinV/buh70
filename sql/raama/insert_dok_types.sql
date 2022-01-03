
INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'KONTOASUTUS_TUN_TT'                  AS kood,
       'Kontoasutusandmik tunnus ja tegevusala järgi' AS nimetus,
       'DOK'                                          AS library,
       '{"type":"aruanne", "module":["Aruanne"]}'     AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'KONTOASUTUSANDMIK_TUNNUS_TT');

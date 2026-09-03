INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'ARVETE_SAATMINE'                                    AS kood,
       'Arvete saatmine'                                  AS nimetus,
       'DOK'                                     AS library,
       '{"type":"settings", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'ARVETE_SAATMINE');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'ETTEMAKSETE_ARUANNE'                                    AS kood,
       'Ettemaksete aruanne'                                  AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'ETTEMAKSETE_ARUANNE');


INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'ETTEMAKS_KONTROL'                                    AS kood,
       'Puhkuse ettemaksu kontrol'                                  AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["palk"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'ETTEMAKS_KONTROL');

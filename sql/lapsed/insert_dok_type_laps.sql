INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'LAPS'                                    AS kood,
       'Lapsed'                                  AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'LAPS');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'VANEM'                                    AS kood,
       'Vanemate register'                                  AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'VANEM');
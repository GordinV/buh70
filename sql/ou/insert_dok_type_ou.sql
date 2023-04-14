INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'ARVETE_SAATMINE'                                    AS kood,
       'Arvete saatmine'                                  AS nimetus,
       'DOK'                                     AS library,
       '{"type":"settings", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'ARVETE_SAATMINE');

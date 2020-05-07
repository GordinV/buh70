
INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'LISA_9'                              AS kood,
       'Lisa 9'                      AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Eelarve"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'LISA_9');

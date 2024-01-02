INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'HOOLEPING'                                   AS kood,
       'Hooldekodu lepingud'                         AS nimetus,
       'DOK'                                         AS library,
       '{"type":"library", "module":["Hooldekodu"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'HOOLEPING');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'HOO_KAIBEANDMIK'                                   AS kood,
       'Hooldekodu kaibeandmik'                         AS nimetus,
       'DOK'                                         AS library,
       '{"type":"aruanne", "module":["Hooldekodu"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'HOO_KAIBEANDMIK');


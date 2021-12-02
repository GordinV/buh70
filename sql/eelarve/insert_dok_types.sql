
INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'LISA_9'                              AS kood,
       'Lisa 9'                      AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Eelarve"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'LISA_9');


INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'TULUD_ALL_ART'                              AS kood,
       'Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)'                      AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Eelarve"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'TULUD_ALL_ART');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'VOETUD_KOHUSTISED'                       AS kood,
       'VÕETUD KOHUSTISED'                       AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Eelarve"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'VOETUD_KOHUSTISED');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'TULUD_EELNOU'                       AS kood,
       'Tulude eelarve eelnõu'                       AS nimetus,
       'DOK'                                     AS library,
       '{"type":"aruanne", "module":["Eelarve"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'TULUD_EELNOU');

INSERT INTO docs.doklausheader (id, rekvid, dok, proc_, selg, muud, status, userid)
  SELECT
    id,
    rekvid,
    dok,
    proc_,
    selg,
    muud,
    1,
    1
  FROM doklausheader
  WHERE rekvid IN (SELECT id
                   FROM rekv
                   WHERE parentid < 999);

SELECT pg_catalog.setval('docs.doklausheader_id_seq', 6645, TRUE);


INSERT INTO docs.doklausend (id, parentid, summa, muud, kood1, kood2, kood3, kood4, kood5, deebet, kreedit, lisa_d, lisa_k)
  SELECT d.id, d.parentid, d.summa, d.muud, d.kood1, d.kood2, d.kood3, d.kood4, d.kood5, d.deebet, d.kreedit, d.lisa_d, d.lisa_k
  FROM doklausend d
    INNER JOIN doklausheader h ON h.id = d.parentid
  WHERE h.rekvid IN (SELECT id
                     FROM rekv
                     WHERE parentid < 999);

SELECT pg_catalog.setval('docs.doklausend_id_seq', 17410, TRUE);

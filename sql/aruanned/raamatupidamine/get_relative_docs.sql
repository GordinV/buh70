DROP FUNCTION IF EXISTS docs.get_relative_docs(INTEGER);

CREATE OR REPLACE FUNCTION docs.get_relative_docs(l_doc_id INTEGER)
    RETURNS TABLE (
        id            INTEGER,
        kpv           DATE,
        number        VARCHAR(20),
        selg          VARCHAR(254),
        muud          TEXT,
        form          VARCHAR(20),
        koostatud     VARCHAR(20),
        doc_type      VARCHAR(20),
        doc_type_name VARCHAR(120)
    )
AS
$BODY$
WITH docs AS (
    SELECT rd.id,
           trim(l.kood)    AS doc_type,
           trim(l.nimetus) AS name,
           d.created       AS koostatud
    FROM docs.doc d
             INNER JOIN docs.doc rd ON ARRAY [rd.id] <@ d.docs_ids
             LEFT OUTER JOIN libs.library l ON rd.doc_type_id = l.id
    WHERE d.id = l_doc_id :: INTEGER
),
     lausendid AS
         (SELECT j.parentid                 AS id,
                 j.kpv,
                 jid.number::VARCHAR(20),
                 j.selg,
                 j.muud,
                 'operatsioon'::VARCHAR(20) AS form
          FROM docs d
                   INNER JOIN docs.journal j ON j.parentid = d.id
                   INNER JOIN docs.journalid jid ON j.id = jid.journalid
          WHERE j.parentid IN (SELECT id FROM docs)
            AND d.doc_type IN ('JOURNAL')
         ),
     maksed AS (
         SELECT mk.parentid                                                     AS id,
                mk.kpv                                                          AS kpv,
                mk.number::VARCHAR(20)                                          AS number,
                mk.selg,
                mk.muud                                                         AS muud,
                CASE WHEN mk.opt = 2 THEN 'mksisse' ELSE 'mk' END ::VARCHAR(20) AS form
         FROM docs.mk mk
                  INNER JOIN docs d ON d.id = mk.parentid
         WHERE d.doc_type IN ('SMK', 'MK', 'VMK')
     ),
     arved AS (
         SELECT a.parentid                                                         AS id,
                a.kpv                                                              AS kpv,
                a.number::VARCHAR(20)                                              AS number,
                a.lisa                                                             AS selg,
                a.muud                                                             AS muud,
                CASE WHEN a.liik = 0 THEN 'arve' ELSE 'arvesise' END ::VARCHAR(20) AS form
         FROM docs.arv a
                  INNER JOIN docs d ON d.id = a.parentid
         WHERE d.doc_type IN ('ARV')
     ),
     kassa AS (
         SELECT k.parentid                                           AS id,
                k.kpv                                                AS kpv,
                k.number::VARCHAR(20)                                AS number,
                k.alus                                               AS selg,
                k.muud                                               AS muud,
                CASE WHEN k.tyyp = 1 THEN 'sOrder' ELSE 'vOrder' END AS form
         FROM docs.korder1 k
                  INNER JOIN docs d ON d.id = k.parentid
         WHERE d.doc_type IN ('KORDER', 'SORDER', 'VORDER')
     ),
     palk AS (
         SELECT p.parentid      AS id,
                p.kpv           AS kpv,
                ''::VARCHAR(20) AS number,
                l.nimetus       AS selg,
                p.muud          AS muud,
                'palk_oper'     AS form
         FROM palk.palk_oper p
                  INNER JOIN docs d ON d.id = p.parentid
                  INNER JOIN LIBS.library l ON l.id = p.libid
         WHERE d.doc_type IN ('PALK_OPER')
     ),
     pv AS (
         SELECT p.parentid      AS id,
                p.kpv           AS kpv,
                ''::VARCHAR(20) AS number,
                l.nimetus       AS selg,
                p.muud          AS muud,
                'pv_oper'       AS form
         FROM docs.pv_oper p
                  INNER JOIN docs d ON d.id = p.parentid
                  INNER JOIN (
             SELECT 1 AS id, 'Arvelevõit' AS nimetus
             UNION ALL
             SELECT 2 AS id, 'Kulum ja allahindlustus' AS nimetus
             UNION ALL
             SELECT 3 AS id, 'Parendused ' AS nimetus
             UNION ALL
             SELECT 4 AS id, 'Väljakandmine' AS nimetus
             UNION ALL
             SELECT 5 AS id, 'Ümberhindlus' AS nimetus
             UNION ALL
             SELECT 6 AS id, 'Üleviimine' AS nimetus
         ) l ON l.id = p.liik
         WHERE d.doc_type IN ('PV_OPER')
     )


SELECT j.id:: INTEGER,
       j.kpv:: DATE,
       j.number:: VARCHAR(20),
       j.selg:: VARCHAR(254),
       j.muud:: TEXT,
       j.form::varchar(20),
       d.koostatud:: VARCHAR(20),
       d.doc_type:: VARCHAR(20),
       d.name::VARCHAR(120) AS doc_type_name
FROM lausendid j
         INNER JOIN docs d ON d.id = j.id
UNION ALL
SELECT mk.*,
       d.koostatud:: VARCHAR(20),
       d.doc_type:: VARCHAR(20),
       d.name::VARCHAR(120) AS doc_type_name
FROM maksed mk
         INNER JOIN docs d ON d.id = mk.id
UNION ALL
SELECT arv.*,
       d.koostatud:: VARCHAR(20),
       d.doc_type:: VARCHAR(20),
       d.name::VARCHAR(120) AS doc_type_name
FROM ARVED ARV
         INNER JOIN docs d ON d.id = arv.id
UNION ALL
SELECT k.*,
       d.koostatud:: VARCHAR(20),
       d.doc_type:: VARCHAR(20),
       d.name::VARCHAR(120) AS doc_type_name
FROM kassa k
         INNER JOIN docs d ON d.id = k.id
UNION ALL
SELECT p.*,
       d.koostatud:: VARCHAR(20),
       d.doc_type:: VARCHAR(20),
       d.name::VARCHAR(120) AS doc_type_name
FROM palk p
         INNER JOIN docs d ON d.id = p.id
UNION ALL
SELECT p.*,
       d.koostatud:: VARCHAR(20),
       d.doc_type:: VARCHAR(20),
       d.name::VARCHAR(120) AS doc_type_name
FROM pv p
         INNER JOIN docs d ON d.id = p.id

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION docs.get_relative_docs(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.get_relative_docs(INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.get_relative_docs(INTEGER) TO dbvaatleja;


/*
SELECT *
FROM docs.get_relative_docs(6388561)

*/

drop view if exists com_objekt;

CREATE VIEW com_objekt AS SELECT qry.id,
                            qry.kood,
                            qry.nimetus,
                            qry.rekvid
                          FROM ( SELECT 0 AS id,
                                        ''::character varying(20) AS kood,
                                        ''::character varying(20) AS nimetus,
                                        NULL::integer AS rekvid
                                 UNION
                                 SELECT l.id,
                                   l.kood,
                                   l.nimetus,
                                   l.rekvid
                                 FROM libs.library l
                                 WHERE ((l.library = 'OBJEKT'::bpchar) AND (l.status <> 3))) qry
                          ORDER BY qry.kood;

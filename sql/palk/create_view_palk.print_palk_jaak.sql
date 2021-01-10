DROP VIEW IF EXISTS palk.print_palk_jaak;

CREATE VIEW palk.print_palk_jaak AS
SELECT j.jaak,
       j.kuu,
       j.aasta,
       coalesce(p.arv, 0)::NUMERIC(12, 2)   AS arv,
       coalesce(p.tasu, 0)::NUMERIC(12, 2)  AS tasu,
       coalesce(p.tka, 0)::NUMERIC(12, 2)   AS tka,
       coalesce(p.tki, 0)::NUMERIC(12, 2)   AS tki,
       coalesce(p.pm, 0)::NUMERIC(12, 2)    AS pm,
       coalesce(p.tm, 0)::NUMERIC(12, 2)    AS tm,
       coalesce(p.sm, 0)::NUMERIC(12, 2)    AS sm,
       coalesce(p.muud, 0)::NUMERIC(12, 2)  AS muud,
       coalesce(p.kinni, 0)::NUMERIC(12, 2) AS kinni,
       p.lepingid,
       t.rekvid,
       a.id                                 AS isikid,
       a.regkood                            AS isikukood,
       a.nimetus                            AS isik,
       o.kood                               AS osakond,
       o.nimetus                            AS osakonna_nimetus,
       coalesce(p.status, 2)                AS status
FROM palk.palk_jaak j
         LEFT OUTER JOIN (
    SELECT month(p.kpv)                                                          AS kuu,
           year(p.kpv)                                                           AS aasta,
           sum(p.summa)
               FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER = 1) AS arv,
           sum(p.summa)
               FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER = 6) AS tasu,
           sum(p.summa)
               FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER = 2) AS kinni,
           sum(p.summa)
               FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER = 3) AS muud,
           sum(p.pensmaks)                                                       AS pm,
           sum(p.summa)
               FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER = 5) AS sm,
           sum(p.tulubaas)                                                       AS mvt,
           sum(p.tka)                                                            AS tka,
           sum(p.tootumaks)                                                      AS tki,
           sum(p.tulumaks)                                                       AS tm,
           p.lepingid,
           t.status
    FROM docs.doc d
             INNER JOIN palk.palk_oper p ON p.parentid = d.id
             INNER JOIN libs.library lib ON p.libid = lib.id AND lib.library = 'PALK'
             INNER JOIN palk.tooleping t ON p.lepingid = t.id
    GROUP BY month(p.kpv), year(p.kpv), p.lepingid, t.status) p
                         ON p.lepingid = j.lepingid AND p.kuu = j.kuu AND p.aasta = j.aasta
         INNER JOIN palk.tooleping t ON t.id = j.lepingid
         INNER JOIN libs.asutus a ON a.id = t.parentid
         INNER JOIN libs.library o ON o.id = t.osakondid;


GRANT SELECT ON TABLE palk.print_palk_jaak TO dbkasutaja;
GRANT SELECT ON TABLE palk.print_palk_jaak TO dbpeakasutaja;
GRANT SELECT ON TABLE palk.print_palk_jaak TO dbvaatleja;
GRANT SELECT ON TABLE palk.print_palk_jaak TO taabel;
GRANT ALL ON TABLE palk.print_palk_jaak TO vlad;

/*
select * from palk.print_palk_jaak where aasta = 2020 and kuu = 2  and isik ilike '%Repina%' and rekvid = 3
 */
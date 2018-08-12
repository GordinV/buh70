DROP VIEW IF EXISTS palk.print_palk_jaak;

CREATE VIEW palk.print_palk_jaak AS
SELECT
  j.jaak,
  j.kuu,
  j.aasta,
  coalesce(p.arv,0)::numeric(12,2) as arv,
  coalesce(p.tasu,0)::numeric(12,2) as tasu,
  coalesce(p.tka,0)::numeric(12,2) as tka,
  coalesce(p.tki,0)::numeric(12,2) as tki,
  coalesce(p.pm,0)::NUMERIC(12,2) as pm,
  coalesce(p.tm,0)::NUMERIC(12,2) as tm,
  coalesce(p.sm,0)::NUMERIC(12,2) as sm,
  coalesce(p.muud,0)::NUMERIC(12,2) as muud,
  coalesce(p.kinni,0)::NUMERIC(12,2) as kinni,
  p.lepingid,
  t.rekvid,
  a.id as isikid,
  a.regkood AS isikukood,
  a.nimetus AS isik,
  o.kood    AS osakond
FROM palk.palk_jaak j
  LEFT OUTER JOIN (
               SELECT
                 month(p.kpv)                                                        AS kuu,
                 year(p.kpv)                                                         AS aasta,
                 sum(p.summa)
                   FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER = 1) AS arv,
                 sum(p.summa)
                   FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER = 6) AS tasu,
                 sum(p.summa)
                   FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER = 2) AS kinni,
                 sum(p.summa)
                   FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER = 3) AS muud,
                 sum(p.pensmaks)                                                     AS pm,
                 sum(p.sotsmaks)                                                     AS sm,
                 sum(p.tulubaas)                                                     AS mvt,
                 sum(p.tka)                                                          AS tka,
                 sum(p.tootumaks)                                                    AS tki,
                 sum(p.tulumaks)                                                     AS tm,
                 p.lepingid
               FROM docs.doc d
                 INNER JOIN palk.palk_oper p ON p.parentid = d.id
                 INNER JOIN libs.library lib ON p.libid = lib.id AND lib.library = 'PALK'
                 INNER JOIN palk.tooleping t ON p.lepingid = t.id
               GROUP BY month(p.kpv), year(p.kpv), p.lepingid) p
    ON p.lepingid = j.lepingid AND p.kuu = j.kuu AND p.aasta = j.aasta
  INNER JOIN palk.tooleping t ON t.id = j.lepingid
  INNER JOIN libs.asutus a ON a.id = t.parentid
  INNER JOIN libs.library o ON o.id = t.osakondid;


/*
select * from palk.print_palk_jaak where aasta = 2018
 */

DROP VIEW if exists public.cur_ladu_jaak;

CREATE OR REPLACE VIEW public.cur_ladu_jaak AS
  SELECT n.id,
    n.kood,
    n.nimetus,
    sum(j.jaak) AS jaak,
    j.hind,
    j.rekvid,
    j.laduid,
    l.kood AS ladu,
    g.nimetus as grupp
  FROM libs.ladu_jaak j
    JOIN libs.nomenklatuur n ON n.id = j.nomid
    INNER JOIN libs.library g ON g.id =  ((n.properties::JSONB ->> 'gruppid')::integer)
    LEFT JOIN libs.library l ON l.id = j.laduid
  WHERE n.status <> 3
  GROUP BY n.id, n.kood, j.rekvid, j.laduid, j.hind, l.kood, g.nimetus;

GRANT ALL ON TABLE public.cur_ladu_jaak TO dbadmin;
GRANT SELECT ON TABLE public.cur_ladu_jaak TO dbkasutaja;
GRANT SELECT ON TABLE public.cur_ladu_jaak TO dbvaatleja;
GRANT SELECT ON TABLE public.cur_ladu_jaak TO dbpeakasutaja;

DROP VIEW if exists public.com_asutused;

CREATE OR REPLACE VIEW public.com_asutused AS
  SELECT qry.id,
    qry.regkood,
    qry.nimetus,
    qry.kehtivus
  FROM ( SELECT 0 AS id,
                ''::character varying(20) AS regkood,
                ''::character varying(254) AS nimetus,
                date() AS kehtivus
         UNION
         SELECT asutus.id,
           btrim(asutus.regkood::text) AS regkood,
           btrim(asutus.nimetus::text)::character varying(254) AS nimetus,
           coalesce((asutus.properties ->> 'kehtivus'::text)::date, date()) AS kehtivus
         FROM libs.asutus
         WHERE asutus.staatus <> 3) qry
  ORDER BY qry.nimetus;

GRANT SELECT ON TABLE public.com_asutused TO dbkasutaja;
GRANT SELECT ON TABLE public.com_asutused TO dbvaatleja;
GRANT SELECT ON TABLE public.com_asutused TO dbpeakasutaja;


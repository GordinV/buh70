DROP VIEW IF EXISTS public.com_asutused;

CREATE OR REPLACE VIEW public.com_asutused AS
SELECT qry.id,
       qry.regkood,
       qry.nimetus,
       qry.tp,
       qry.email,
       qry.kehtivus,
       qry.aadress,
       qry.kontakt,
       qry.tel,
       qry.omvorm,
       qry.pank
FROM (SELECT 0                            AS id,
             ''::CHARACTER VARYING(20)    AS regkood,
             ''::CHARACTER VARYING(254)   AS nimetus,
             ''::VARCHAR(20)              AS tp,
             ''::VARCHAR(254)             AS email,
             date() + INTERVAL '100 year' AS kehtivus,
             ''::TEXT                     AS aadress,
             ''::TEXT                     AS kontakt,
             ''::VARCHAR(120)             AS tel,
             ''::VARCHAR(20)              AS omvorm,
             ''::VARCHAR(20)              AS pank

      UNION
      SELECT asutus.id,
             btrim(asutus.regkood::TEXT)                                                           AS regkood,
             btrim(asutus.nimetus::TEXT)::CHARACTER VARYING(254)                                   AS nimetus,
             asutus.tp,
             asutus.email,
             coalesce((asutus.properties ->> 'kehtivus'::TEXT)::DATE, date() + INTERVAL '10 year') AS kehtivus,
             asutus.aadress,
             asutus.kontakt,
             asutus.tel,
             asutus.omvorm,
             (properties -> 'asutus_aa' -> 0 ->> 'aa')::VARCHAR(20)                                AS pank

      FROM libs.asutus asutus
      WHERE asutus.staatus <> 3) qry
ORDER BY qry.nimetus;

GRANT SELECT ON TABLE public.com_asutused TO dbkasutaja;
GRANT SELECT ON TABLE public.com_asutused TO dbvaatleja;
GRANT SELECT ON TABLE public.com_asutused TO dbpeakasutaja;


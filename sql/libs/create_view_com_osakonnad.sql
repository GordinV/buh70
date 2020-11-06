-- View: public.com_osakonnad

DROP VIEW IF EXISTS com_osakonnad;

CREATE OR REPLACE VIEW public.com_osakonnad AS
SELECT qry.id,
       qry.kood,
       qry.nimetus,
       qry.rekvid,
       qry.valid
FROM (SELECT 0                         AS id,
             ''::CHARACTER VARYING(20) AS kood,
             ''::CHARACTER VARYING(20) AS nimetus,
             NULL::INTEGER             AS rekvid,
             NULL::DATE                AS valid
      UNION
      SELECT l.id,
             l.kood,
             l.nimetus,
             l.rekvid,
             (l.properties::JSONB ->> 'valid')::DATE AS valid
      FROM libs.library l
      WHERE l.library = 'OSAKOND'::BPCHAR
        AND l.status <> 3) qry
ORDER BY qry.kood;

GRANT SELECT ON TABLE public.com_osakonnad TO dbkasutaja;
GRANT SELECT ON TABLE public.com_osakonnad TO dbpeakasutaja;
GRANT SELECT ON TABLE public.com_osakonnad TO dbvaatleja;
GRANT SELECT ON TABLE public.com_osakonnad TO taabel;

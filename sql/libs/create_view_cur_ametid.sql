-- View: public.cur_ametid

DROP VIEW IF EXISTS cur_ametid;

CREATE OR REPLACE VIEW cur_ametid AS
SELECT a.id,
       a.nimetus                                                         AS amet,
       o.nimetus                                                         AS osakond,
       a.rekvid,
       coalesce((a.properties::JSONB ->> 'kogus'::TEXT)::NUMERIC, 0)     AS kogus,
       coalesce((a.properties::JSONB ->> 'vaba'::TEXT)::NUMERIC, 0)      AS vaba,
       coalesce((a.properties::JSONB ->> 'palgamaar'::TEXT)::INTEGER, 0) AS palgamaar,
       (a.properties::JSONB ->> 'valid')::DATE                           AS valid
FROM libs.library a
         JOIN libs.library o ON ((a.properties::JSONB ->> 'osakondid'::TEXT)::INTEGER) = o.id
WHERE a.status <> 3;


GRANT ALL ON TABLE public.cur_ametid TO dbadmin;
GRANT SELECT ON TABLE public.cur_ametid TO dbkasutaja;
GRANT SELECT ON TABLE public.cur_ametid TO dbpeakasutaja;
GRANT SELECT ON TABLE public.cur_ametid TO dbvaatleja;
GRANT SELECT ON TABLE public.cur_ametid TO taabel;

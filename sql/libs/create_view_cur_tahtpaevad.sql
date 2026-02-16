DROP VIEW IF EXISTS cur_tahtpaevad;

--tahtpaevad
CREATE VIEW cur_tahtpaevad AS
SELECT
    l.id,
    l.nimetus,
    null::integer                                       as rekvid,
    (l.properties :: JSONB ->> 'paev') :: INTEGER       AS paev,
    (l.properties :: JSONB ->> 'kuu') :: INTEGER        AS kuu,
    (l.properties :: JSONB ->> 'aasta') :: INTEGER      AS aasta,
    (l.properties::jsonb ->> 'luhipaev'::text)::integer AS luhipaev
FROM
    libs.library l
WHERE
      l.library = 'TAHTPAEV'
  AND l.rekvid = 63 -- только фин. департамент
  AND l.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted');


GRANT ALL ON TABLE public.cur_tahtpaevad TO dbadmin;
GRANT SELECT ON TABLE public.cur_tahtpaevad TO dbkasutaja;
GRANT SELECT ON TABLE public.cur_tahtpaevad TO dbpeakasutaja;
GRANT SELECT ON TABLE public.cur_tahtpaevad TO dbvaatleja;
GRANT SELECT ON TABLE public.cur_tahtpaevad TO taabel;

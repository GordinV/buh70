insert into libs.library (rekvid, kood, nimetus, library, properties)
select
--    l.properties,
qry.rekv_id,
l.kood,
l.nimetus,
l.library,
l.properties

from
    (
        with
            paevad as (
                          SELECT
                              l.id                                           as id,
--                              l.rekvid                                       as rekvid,
                              l.kood,
                              l.nimetus,
                              (l.properties :: JSONB ->> 'paev') :: INTEGER  AS paev,
                              (l.properties :: JSONB ->> 'kuu') :: INTEGER   AS kuu,
                              (l.properties :: JSONB ->> 'aasta') :: INTEGER AS aasta
                          FROM
                              libs.library l
                          WHERE
                                l.library = 'TAHTPAEV'
                            and l.rekvid = 63
                            AND l.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted')
                            and (l.properties :: JSONB ->> 'aasta') :: INTEGER = 2026
            )
        select
            exists
            (
                select
                    l.id
                from
                    libs.library l
                WHERE
                      l.library = 'TAHTPAEV'
                  and l.rekvid = r.id
                  and (l.properties :: JSONB ->> 'paev') :: INTEGER = p.paev
                  and (l.properties :: JSONB ->> 'kuu') :: INTEGER = p.kuu
                  and (l.properties :: JSONB ->> 'aasta') :: INTEGER = p.aasta
            ) as kas_exists,
            r.id as rekv_id,
            p.*

        from
            paevad  p,
            ou.rekv r
        where
            r.parentid < 999
    ) qry
        inner join libs.library l on l.id = qry.id
where not kas_exists
order by rekv_id, make_date(aasta, kuu, paev)
;
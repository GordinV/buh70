DROP VIEW IF EXISTS palk.cur_toolepingud;

CREATE VIEW palk.cur_toolepingud AS
SELECT
    t.id,
    t.rekvid,
    t.lopp,
    t.ametid,
    t.osakondid,
    t.muud,
    t.parentid,
    t.algab,
    t.ametnik,
    t.koormus,
    t.palgamaar,
--    t.palk,
    case
        when t.palgamaar is not null and t.properties ->> 'ameti_klassif' is not null
            and len(t.properties ->> 'ameti_klassif') > 1 then
            palk.get_isiku_pohipalk(jsonb_build_object('ameti_klassif', t.properties ->> 'ameti_klassif',
                                                       'palgamaar', t.palgamaar))
        else t.palk
        end::numeric(12, 2)                                     as palk,

    t.pohikoht,
    t.resident,
    t.riik,
    t.toend,
    t.toopaev,
    (enum_range(NULL :: PALK_TASU_LIIK))[t.tasuliik] :: TEXT    AS tasu_liik,
    osakond.kood                                                AS osakond,
    amet.kood                                                   AS amet,
    coalesce(t.properties ->> 'ameti_klassif', '')::varchar(20) as ameti_klassif,
    coalesce(v.valuuta, 'EUR') :: VARCHAR                       AS valuuta,
    coalesce(v.kuurs, 1) :: NUMERIC                             AS kuurs
FROM
    palk.tooleping                       t
        INNER JOIN      libs.library     osakond ON osakond.id = t.osakondid
        INNER JOIN      libs.library     amet ON amet.id = t.ametid
        LEFT OUTER JOIN docs.dokvaluuta1 v
                        ON (v.dokid = t.id AND
                            v.dokliik = array_position((enum_range(NULL :: DOK_VALUUTA)), 'tooleping'))
WHERE
    t.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted');


GRANT SELECT ON TABLE palk.cur_toolepingud TO dbkasutaja;
GRANT SELECT ON TABLE palk.cur_toolepingud TO dbvaatleja;
GRANT SELECT ON TABLE palk.cur_toolepingud TO dbpeakasutaja;

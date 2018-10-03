DROP VIEW IF EXISTS cur_eelproj;

CREATE VIEW cur_eelproj AS
  SELECT
    e.id,
    e.rekvid,
    e.aasta,
    e.kuu,
    e.status,
    (enum_range(NULL :: DOK_STATUS)) [e.status] :: TEXT AS dok_status,
    e.muud :: VARCHAR(254)                              AS muud,
    Rekv.regkood,
    Rekv.parentid,
    Rekv.nimetus::varchar(254)                                        AS asutus,
    coalesce(u.ametnik, space(254)) :: VARCHAR(254)     AS kinnitaja,
    l.nimetus                                           AS cstaatus
  FROM eelarve.eelproj e
    INNER JOIN ou.rekv rekv ON e.rekvid = Rekv.id
    LEFT OUTER JOIN libs.library l ON l.kood::text = e.status::text and l.library = 'STATUS'
    LEFT OUTER JOIN ou.userid u ON e.kinnitaja = u.id;

GRANT SELECT ON TABLE cur_eelproj TO eelaktsepterja;

/*
select * from cur_eelproj

select * from libs.library where library = 'STATUS'

update libs.library set nimetus = 'Kinnitatud'  where id = 11


*/
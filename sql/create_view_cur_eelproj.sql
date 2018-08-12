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
    Rekv.nimetus                                        AS asutus,
    coalesce(u.ametnik, space(254)) :: VARCHAR(254)     AS kinnitaja,
    l.nimetus                                           AS cstaatus
  FROM eelarve.eelproj e
    INNER JOIN ou.rekv rekv ON e.rekvid = Rekv.id
    LEFT OUTER JOIN libs.library l ON l.kood::text = e.status::text and l.library = 'STATUS'
    LEFT OUTER JOIN ou.userid u ON e.kinnitaja = u.id;

GRANT SELECT ON TABLE cur_eelproj TO eelaktsepterja;

/*
select * from libs.library where library = 'STATUS'
		SELECT *  from (SELECT                          d.*                        FROM cur_eelproj d
		WHERE d.rekvId in (select rekv_id from get_asutuse_struktuur(1))                                 ) qry
		WHERE 	asutus ilike '%'
	and aasta = 2018
	and kuu >= 0
	and kuu <= 12
	and muud ilike '%'
	and kinnitaja ilike '%'
	and status = 1


*/
DROP VIEW IF EXISTS palk.cur_tootajad;

CREATE OR REPLACE VIEW palk.cur_tootajad AS
SELECT a.id,
       btrim(a.regkood :: TEXT) :: CHARACTER VARYING(20) AS isikukood,
--    btrim(encode(a.nimetus::BYTEA, 'escape')) :: CHARACTER VARYING(254) AS nimetus,
       btrim(a.nimetus) :: CHARACTER VARYING(254)        AS nimetus,
       btrim(a.properties ->> 'palk_email')              AS email,
       osakond.kood                                      AS osakond,
       amet.kood                                         AS amet,
       amet.kood                                         AS kood,
       t.lopp,
       t.rekvid,
       t.ametid,
       t.osakondid,
       t.id                                              AS lepingid,
       t.koormus,
       t.toopaev,
       t.algab,
       t.palk,
       t.tasuliik
FROM libs.asutus a
         LEFT OUTER JOIN palk.tooleping t ON a.id = t.parentid
         LEFT OUTER JOIN libs.library osakond ON osakond.id = t.osakondid
         LEFT OUTER JOIN libs.library amet ON amet.id = t.ametid
WHERE coalesce((a.properties ->> 'is_tootaja') :: BOOLEAN, FALSE)
  AND a.staatus <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted')
  AND NOT empty(t.ametid)
  AND t.status < 3
ORDER BY a.nimetus, osakond.kood, amet.kood;

GRANT SELECT ON TABLE palk.cur_tootajad TO dbkasutaja;
GRANT SELECT ON TABLE palk.cur_tootajad TO dbvaatleja;
GRANT SELECT ON TABLE palk.cur_tootajad TO dbpeakasutaja;

/*
select * from palk.cur_tootajad
*/

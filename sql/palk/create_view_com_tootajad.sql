DROP VIEW IF EXISTS palk.com_tootajad;

CREATE OR REPLACE VIEW palk.com_tootajad AS
  SELECT
    qry.id,
    qry.isikukood,
    qry.nimetus,
    qry.tp,
    qry.osakond,
    qry.amet,
    qry.lopp,
    qry.rekvid,
    qry.osakondid,
    qry.ametid,
    qry.lepingid
  FROM (SELECT
          0                            AS id,
          '' :: CHARACTER VARYING(20)  AS isikukood,
          '' :: CHARACTER VARYING(254) AS nimetus,
          '800699' :: VARCHAR(20)      AS tp,
          '' :: VARCHAR(254)           AS osakond,
          '' :: VARCHAR(254)           AS amet,
          NULL :: DATE                 AS lopp,
          NULL :: INTEGER              AS rekvid,
          TRUE :: BOOLEAN              AS is_tootaja,
          0 :: INTEGER                 AS osakondid,
          0 :: INTEGER                 AS ametid,
          0 :: INTEGER                 AS lepingid
        UNION
        SELECT
          a.id,
          btrim(a.regkood :: TEXT) :: CHARACTER VARYING(20)  AS isikukood,
          btrim(a.nimetus :: TEXT) :: CHARACTER VARYING(254) AS nimetus,
          '800699'                                           AS tp,
          osakond.kood                                       AS osakond,
          amet.kood                                          AS amet,
          t.lopp,
          t.rekvid,
          TRUE                                               AS is_tootaja,
          t.osakondid,
          t.ametid,
          t.id                                               AS lepingid
        FROM libs.asutus a
          LEFT OUTER JOIN palk.tooleping t ON a.id = t.parentid
          LEFT OUTER JOIN libs.library osakond ON osakond.id = t.osakondid
          LEFT OUTER JOIN libs.library amet ON amet.id = t.ametid
        WHERE coalesce((a.properties ->> 'is_tootaja') :: BOOLEAN, FALSE)
              AND a.staatus <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted')
       ) qry
  ORDER BY qry.nimetus;

GRANT SELECT ON TABLE palk.com_tootajad TO dbkasutaja;
GRANT SELECT ON TABLE palk.com_tootajad TO dbvaatleja;
GRANT SELECT ON TABLE palk.com_tootajad TO dbpeakasutaja;

/*
select * from palk.com_tootajad
*/

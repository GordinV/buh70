DROP FUNCTION IF EXISTS get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN );
DROP FUNCTION IF EXISTS get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN, params JSON );

CREATE FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN, params JSON)
  RETURNS TABLE(kuu   INT, aasta INT, rekvid INT, asutus VARCHAR(254), parentid INT, tunnus VARCHAR(20), summa NUMERIC(12, 2), artikkel VARCHAR(20),
                tegev VARCHAR(20), allikas VARCHAR(20), nimetus VARCHAR(254)) AS $$
DECLARE
  doc_artikkel TEXT = params ->> 'artikkel';
  doc_asutus   TEXT = params ->> 'asutus';
  doc_tegev    TEXT = params ->> 'tegev';
  doc_allikas  TEXT = params ->> 'allikas';
  doc_nimetus  TEXT = params ->> 'nimetus';
  doc_tunnus   TEXT = params ->> 'tunnus';
  doc_valuuta  TEXT = params ->> 'valuuta';
  doc_summa1   NUMERIC(12, 2) = params ->> 'summa1';
  doc_summa2   NUMERIC(12, 2) = params ->> 'summa2';
  doc_kuu1     INTEGER = params ->> 'kuu1';
  doc_kuu2     INTEGER = params ->> 'kuu2';
  doc_aasta1   INTEGER = params ->> 'aasta1';
  doc_aasta2   INTEGER = params ->> 'aasta2';

  l_sql        TEXT = 'SELECT
                d.kuu :: INTEGER          AS kuu,
                d.aasta :: INTEGER        AS aasta,
                d.rekvid :: INTEGER       AS rekvid,
                d.asutus :: VARCHAR(254)  AS asutus,
                d.parentid :: INTEGER     AS parentid,
                d.tunnus :: VARCHAR(20)   AS tunnus,
                d.summa :: NUMERIC(12, 2) AS summa,
                d.artikkel :: VARCHAR(20) AS artikkel,
                d.tegev :: VARCHAR(20)    AS tegev,
                d.allikas :: VARCHAR(20)  AS allikas,
                d.nimetus :: VARCHAR(254) AS nimetus
              FROM ';
  l_table      TEXT = 'cur_kulude_taitmine d';
  l_rekvid     INTEGER = (SELECT rekv.id
                          FROM ou.rekv rekv
                          WHERE rekv.parentid = 0
                          LIMIT 1);

  l_where      TEXT = ' where d.rekvid in (select rekv_id from get_asutuse_struktuur(' || l_rekvid :: TEXT || '))' ||
                      CASE WHEN params IS NOT NULL
                        THEN
                          ' and artikkel ilike ' || quote_literal(doc_artikkel) ||
                          ' and asutus ilike ' || quote_literal(doc_asutus) ||
                          ' and tegev ilike ' || quote_literal(doc_tegev) ||
                          ' and allikas ilike ' || quote_literal(doc_allikas) ||
                          ' and nimetus ilike ' || quote_literal(doc_nimetus) ||
                          ' and tunnus ilike ' || quote_ident(doc_tunnus) ||
                          ' and doc_valuuta ilike ' || quote_ident(doc_valuuta) ||
                          ' and summa >= ' || doc_summa1 :: TEXT ||
                          ' and summa <= ' || doc_summa2 :: TEXT ||
                          ' kuu >= ' || doc_kuu1 :: TEXT ||
                          ' kuu <= ' || doc_kuu2 :: TEXT ||
                          ' aasta >= ' || doc_aasta1 :: TEXT ||
                          ' aasta <= ' || doc_aasta2 :: TEXT

                      ELSE '' END;
BEGIN
  CASE WHEN NOT is_kassa AND NOT is_arhiiv AND is_kulud
    THEN
      l_table = 'cur_kulude_taitmine d';
      l_sql = l_sql || l_table;
    WHEN NOT is_kassa AND NOT is_arhiiv AND NOT is_kulud
    THEN
      l_table = 'cur_tulude_taitmine d';
      l_sql = l_sql || l_table;
    WHEN is_kassa AND NOT is_arhiiv AND is_kulud
    THEN
      l_table = 'cur_kulude_kassa_taitmine d';
      l_sql = l_sql || l_table;
    WHEN is_kassa AND NOT is_arhiiv AND NOT is_kulud
    THEN
      l_table = 'cur_tulude_kassa_taitmine d';
      l_sql = l_sql || l_table;
    WHEN is_arhiiv AND NOT is_kulud
    THEN
      l_table = 'cur_eelarve_taitmine_arhiiv d';
      l_sql = l_sql || l_table;
      l_where = l_where || 'and d.is_kulud = false';
    WHEN is_arhiiv AND is_kulud
    THEN
      l_table = 'cur_eelarve_taitmine_arhiiv d';
      l_sql = l_sql || l_table;
      l_where = l_where || ' and d.is_kulud = true';
  ELSE
    l_table = 'cur_tulude_taitmine d';
    l_sql = l_sql || l_table;
  END CASE;
  l_sql = l_sql || l_where;

  RAISE NOTICE 'l_sql %', l_sql;
  RETURN QUERY EXECUTE l_sql;
END;
$$
LANGUAGE plpgsql;


GRANT EXECUTE ON FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN,
                                               params   JSON) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN,
                                                        JSON) TO dbkasutaja;
GRANT ALL ON FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN, JSON) TO dbadmin;
GRANT EXECUTE ON FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN,
                                                        JSON) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN,
                                                        JSON) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN,
                                               is_kulud BOOLEAN, JSON) TO eelallkirjastaja;
GRANT EXECUTE ON FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN,
                                                        JSON) TO eelesitaja;
GRANT EXECUTE ON FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN,
                                                        JSON) TO eelkoostaja;


SELECT *
FROM get_eelarve_taitmine(FALSE, FALSE, FALSE, NULL)
UNION ALL
SELECT *
FROM get_eelarve_taitmine(FALSE, FALSE, TRUE, NULL)
UNION ALL
SELECT *
FROM get_eelarve_taitmine(TRUE, FALSE, TRUE, NULL)
UNION ALL
SELECT *
FROM get_eelarve_taitmine(TRUE, FALSE, FALSE, NULL)
UNION ALL
SELECT *
FROM get_eelarve_taitmine(TRUE, TRUE, FALSE, NULL)
UNION ALL
SELECT *
FROM get_eelarve_taitmine(TRUE, TRUE, TRUE, NULL);


/*


CREATE VIEW cur_asutuse_struktuur
  as
with RECURSIVE chield_rekv(id, parentid) as (
  select id, parentid from ou.rekv
  UNION
  select rekv.id, rekv.parentid
  from chield_rekv, ou.rekv rekv
  where rekv.parentid = chield_rekv.id

)
select id, parentid from chield_rekv;
*/

/*

select * from cur_asutuse_struktuur
where

select * from ou.rekv

update ou.rekv set parentid = 3 where id = 4
 */
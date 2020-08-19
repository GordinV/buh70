DROP FUNCTION IF EXISTS get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN);
DROP FUNCTION IF EXISTS get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN, params JSON);
DROP FUNCTION IF EXISTS get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN, params JSON, INTEGER);

CREATE FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN, params JSON,
                                     user_id INTEGER)
    RETURNS TABLE (
        ids      TEXT,
        kuu      INT,
        aasta    INT,
        rekvid   INT,
        asutus   VARCHAR(254),
        parentid INT,
        tunnus   VARCHAR(20),
        summa    NUMERIC(12, 2),
        artikkel VARCHAR(20),
        tegev    VARCHAR(20),
        allikas  VARCHAR(20),
        nimetus  VARCHAR(254)
    ) AS
$$
DECLARE
    doc_artikkel TEXT           = params ->> 'artikkel';
    doc_asutus   TEXT           = params ->> 'asutus';
    doc_tegev    TEXT           = params ->> 'tegev';
    doc_allikas  TEXT           = params ->> 'allikas';
    doc_nimetus  TEXT           = params ->> 'nimetus';
    doc_tunnus   TEXT           = params ->> 'tunnus';
    doc_summa1   NUMERIC(12, 2) = params ->> 'summa1';
    doc_summa2   NUMERIC(12, 2) = params ->> 'summa2';
    doc_kuu1     INTEGER        = coalesce((params ->> 'kuu1')::INTEGER, 1);
    doc_kuu2     INTEGER        = coalesce((params ->> 'kuu2')::INTEGER, month(current_date));
    doc_aasta1   INTEGER        = coalesce((params ->> 'aasta1')::INTEGER, year(current_date));
    doc_aasta2   INTEGER        = coalesce((params ->> 'aasta2')::INTEGER, year(current_date));
    is_kassa     BOOLEAN        = coalesce((params ->> 'is_kassa') :: BOOLEAN, TRUE);
    l_kpv1       DATE           = make_date(doc_aasta1, doc_kuu1, 1);
    l_kpv2       DATE           = (make_date(doc_aasta2, doc_kuu2, 1) + INTERVAL '1 month')::DATE - 1;

    l_rekvid     INTEGER        = (SELECT rekv.id
                                   FROM ou.rekv rekv
                                   WHERE id IN (SELECT u.rekvid
                                                FROM ou.userid u
                                                WHERE id = user_id)
                                   LIMIT 1);

    l_params     TEXT           = quote_literal(l_kpv1::TEXT) || '::DATE,' || quote_literal(l_kpv2::TEXT) ||
                                  '::DATE,' ||
                                  l_rekvid::TEXT || '::INTEGER, 1::INTEGER';
    l_rekv_nimi  TEXT           = ' inner join ou.rekv r on r.id = d.rekv_id';
    l_lib_nimi   TEXT           = ' inner join com_artikkel l on l.kood = d.artikkel';
    l_sql        TEXT           = 'SELECT
                 array_to_string(d.docs_ids,'','',''0'') as ids,
                d.kuu :: INTEGER          AS kuu,
                d.aasta :: INTEGER        AS aasta,
                d.rekv_id :: INTEGER       AS rekvid,
                r.nimetus :: VARCHAR(254)  AS asutus,
                r.parentid :: INTEGER     AS parentid,
                coalesce(tunnus,'''') :: VARCHAR(20)   AS tunnus,
                d.summa :: NUMERIC(12, 2) AS summa,
                d.artikkel :: VARCHAR(20) AS artikkel,
                d.tegev :: VARCHAR(20)    AS tegev,
                d.allikas :: VARCHAR(20)  AS allikas,
                l.nimetus :: VARCHAR(254) AS nimetus
              FROM ';

    l_table      TEXT           = 'eelarve.tulu_taitmine(' || l_params || ') d';

    l_where      TEXT           = ' where 1=1 ' ||
                                  CASE
                                      WHEN params IS NOT NULL
                                          THEN
                                              ' and d.artikkel like ' || quote_literal(doc_artikkel) ||
                                              ' and r.nimetus like ' || quote_literal(doc_asutus) ||
                                              ' and d.tegev like ' || quote_literal(doc_tegev) ||
                                              ' and d.allikas like ' || quote_literal(doc_allikas) ||
                                              ' and fix_text(l.nimetus::text) ilike ' || quote_literal(doc_nimetus) ||
                                              ' and fix_text(coalesce(d.tunnus,'''')::text) ilike ' ||
                                              quote_literal(doc_tunnus) ||
                                              ' and d.summa >= ' || doc_summa1 :: TEXT ||
                                              ' and d.summa <= ' || doc_summa2 :: TEXT ||
                                              ' and d.kuu >= ' || doc_kuu1 :: TEXT ||
                                              ' and d.kuu <= ' || doc_kuu2 :: TEXT ||
                                              ' and d.aasta >= ' || doc_aasta1 :: TEXT ||
                                              ' and d.aasta <= ' || doc_aasta2 :: TEXT

                                      ELSE '' END;
BEGIN

    CASE WHEN NOT is_kassa AND NOT is_arhiiv AND is_kulud
        THEN
            l_table = 'eelarve.kulu_taitmine(' || l_params || ') d';
            l_sql = l_sql || l_table || l_rekv_nimi || l_lib_nimi || l_where;
        WHEN NOT is_kassa AND NOT is_arhiiv AND NOT is_kulud
            THEN
                l_table = 'eelarve.tulu_taitmine(' || l_params || ') d';
                l_sql = l_sql || l_table || l_rekv_nimi || l_lib_nimi  || l_where;
        WHEN is_kassa AND NOT is_arhiiv AND is_kulud
            THEN
                l_table = 'eelarve.uus_kassa_taitmine(' || l_params || ') d';
                l_sql = l_sql || l_table || l_rekv_nimi || l_lib_nimi  || l_where;
        WHEN is_kassa AND NOT is_arhiiv AND NOT is_kulud
            THEN
                l_table = 'eelarve.uus_kassa_taitmine(' || l_params || ') d';
                l_sql = l_sql || l_table || l_rekv_nimi || l_lib_nimi  || l_where;
        WHEN is_arhiiv AND NOT is_kulud
            THEN
                l_table = 'cur_eelarve_taitmine_arhiiv d';
                l_where = l_where || 'and d.is_kulud = false';
                l_sql = l_sql || l_table || l_where;
        WHEN is_arhiiv AND is_kulud
            THEN
                l_table = 'cur_eelarve_taitmine_arhiiv d';
                l_where = l_where || ' and d.is_kulud = true';
                l_sql = l_sql || l_table || l_where;
        ELSE
            l_table = 'eelarve.tulu_taitmine(' || l_params || ') d';
            l_sql = l_sql || l_table || l_rekv_nimi || l_lib_nimi  || l_where;
        END CASE;
--    l_sql = l_sql || l_where;

    RAISE NOTICE 'l_sql %', l_sql;
    RETURN QUERY EXECUTE l_sql;
END;
$$
    LANGUAGE plpgsql;


GRANT EXECUTE ON FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN,
    params JSON, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN,
    JSON, INTEGER) TO dbkasutaja;
GRANT ALL ON FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN, JSON,
    INTEGER) TO dbadmin;
GRANT EXECUTE ON FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN,
    JSON, INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN,
    JSON, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN,
    is_kulud BOOLEAN, JSON, INTEGER) TO eelallkirjastaja;
GRANT EXECUTE ON FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN,
    JSON, INTEGER) TO eelesitaja;
GRANT EXECUTE ON FUNCTION get_eelarve_taitmine(is_kassa BOOLEAN, is_arhiiv BOOLEAN, is_kulud BOOLEAN,
    JSON, INTEGER) TO eelkoostaja;

SELECT *
FROM get_eelarve_taitmine(FALSE, FALSE, FALSE, NULL::JSON, 70)
UNION ALL
SELECT *
FROM get_eelarve_taitmine(FALSE, FALSE, TRUE, NULL::JSON, 70)
UNION ALL
SELECT *
FROM get_eelarve_taitmine(TRUE, FALSE, TRUE, NULL::JSON, 70)
UNION ALL
SELECT *
FROM get_eelarve_taitmine(TRUE, FALSE, FALSE, '{"aasta1":2020,"aasta2":2020,"allikas":"%","artikkel":"%","asutus":"Narva Linna Arenduse ja Okonoomika Amet T2%","is_arhiiv":false,"is_kassa":true,"kuu1":8,"kuu2":8,"nimetus":"%%","summa1":-999999999,"summa2":999999999.99,"tegev":"%","tunnus":"%"}'::JSON, 70)

/*


select * from ou.userid where rekvid = 63 and kasutaja = 'temp'

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
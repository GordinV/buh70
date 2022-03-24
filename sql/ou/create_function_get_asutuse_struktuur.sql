DROP VIEW IF EXISTS cur_asutuse_struktuur;
DROP FUNCTION IF EXISTS get_asutuse_struktuur(INTEGER);
DROP FUNCTION IF EXISTS get_asutuse_struktuur(INTEGER, DATE);

CREATE FUNCTION get_asutuse_struktuur(INTEGER, DATE DEFAULT current_date)
    RETURNS TABLE (
        rekv_id   INTEGER,
        parent_id INTEGER
    )
AS
$$
WITH RECURSIVE chield_rekv(id, parentid) AS (
    SELECT id,
           CASE
               WHEN $2::DATE <= '2020-12-31'::DATE AND rekv.parentid >= 9999 AND
                    rekv.id IN (90) THEN 119
               ELSE rekv.parentid END AS parentid
    FROM ou.rekv
    WHERE id = $1
    UNION
    SELECT rekv.id,
           rekv.parentid
    FROM chield_rekv,
         ou.rekv rekv
    WHERE 
          CASE
              WHEN $2::DATE <= '2020-12-31'::DATE AND rekv.parentid >= 9999 AND
                   rekv.id IN (90) THEN 119
              ELSE rekv.parentid END = chield_rekv.id
)
SELECT id,
       parentid
FROM chield_rekv;

$$
    LANGUAGE SQL;


GRANT EXECUTE ON FUNCTION get_asutuse_struktuur(INTEGER,DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION get_asutuse_struktuur(INTEGER,DATE) TO dbkasutaja;
GRANT ALL ON FUNCTION get_asutuse_struktuur(INTEGER,DATE) TO dbadmin;
GRANT EXECUTE ON FUNCTION get_asutuse_struktuur(INTEGER,DATE) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION get_asutuse_struktuur(INTEGER,DATE) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION get_asutuse_struktuur(INTEGER,DATE) TO eelallkirjastaja;
GRANT EXECUTE ON FUNCTION get_asutuse_struktuur(INTEGER,DATE) TO eelesitaja;
GRANT EXECUTE ON FUNCTION get_asutuse_struktuur(INTEGER,DATE) TO eelkoostaja;


/*
select * from get_asutuse_struktuur(119,'2020-12-31')
order by rekv_id
 */
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

select * from ou.rekv where id = 90

update ou.rekv set parentid = 3 where id = 4
 */
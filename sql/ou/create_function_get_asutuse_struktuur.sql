DROP VIEW IF EXISTS cur_asutuse_struktuur;
DROP FUNCTION IF EXISTS get_asutuse_struktuur(INTEGER);

CREATE FUNCTION get_asutuse_struktuur(INTEGER)
    RETURNS TABLE (
        rekv_id   INTEGER,
        parent_id INTEGER
    ) AS
$$
WITH RECURSIVE chield_rekv(id, parentid) AS (
    SELECT id,
           parentid
    FROM ou.rekv
    WHERE id = $1
    UNION
    SELECT rekv.id,
           rekv.parentid
    FROM chield_rekv,
         ou.rekv rekv
    WHERE rekv.parentid = chield_rekv.id
)
SELECT id,
       parentid
FROM chield_rekv;

$$
    LANGUAGE SQL;


GRANT EXECUTE ON FUNCTION get_asutuse_struktuur(INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION get_asutuse_struktuur(INTEGER) TO dbkasutaja;
GRANT ALL ON FUNCTION get_asutuse_struktuur(INTEGER) TO dbadmin;
GRANT EXECUTE ON FUNCTION get_asutuse_struktuur(INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION get_asutuse_struktuur(INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION get_asutuse_struktuur(INTEGER) TO eelallkirjastaja;
GRANT EXECUTE ON FUNCTION get_asutuse_struktuur(INTEGER) TO eelesitaja;
GRANT EXECUTE ON FUNCTION get_asutuse_struktuur(INTEGER) TO eelkoostaja;


/*
select * from get_asutuse_struktuur(3)
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
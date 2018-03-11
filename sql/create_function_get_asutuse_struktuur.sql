DROP VIEW if exists cur_asutuse_struktuur;
drop function if exists get_asutuse_struktuur(integer);

CREATE FUNCTION get_asutuse_struktuur(INTEGER)
 returns table (rekv_id integer, parent_id integer ) AS $$
WITH RECURSIVE chield_rekv(id, parentid) AS (
  SELECT
    id,
    parentid
  FROM ou.rekv
    where id = $1
  UNION
  SELECT
    rekv.id,
    rekv.parentid
  FROM chield_rekv, ou.rekv rekv
  WHERE rekv.parentid = chield_rekv.id

)
SELECT
  id,
  parentid
FROM chield_rekv;

$$ LANGUAGE SQL;


GRANT execute ON FUNCTION get_asutuse_struktuur(INTEGER) TO dbpeakasutaja;
GRANT execute ON FUNCTION get_asutuse_struktuur(INTEGER) TO dbkasutaja;
GRANT all ON FUNCTION get_asutuse_struktuur(INTEGER) TO dbadmin;
GRANT execute ON FUNCTION get_asutuse_struktuur(INTEGER) TO dbvaatleja;
GRANT execute ON FUNCTION get_asutuse_struktuur(INTEGER)  TO eelaktsepterja;
GRANT execute ON FUNCTION get_asutuse_struktuur(INTEGER)  TO eelallkirjastaja;
GRANT execute ON FUNCTION get_asutuse_struktuur(INTEGER) TO eelesitaja;
GRANT execute ON FUNCTION get_asutuse_struktuur(INTEGER) TO eelkoostaja;



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
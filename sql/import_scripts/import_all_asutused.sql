DROP FUNCTION IF EXISTS import_all_asutused();

DROP FOREIGN TABLE IF EXISTS remote_all_asutused;

CREATE FOREIGN TABLE remote_all_asutused(
  id SERIAL NOT NULL,
  parentid INTEGER NOT NULL,
  childid INTEGER NOT NULL)
  SERVER db_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'all_asutused');


CREATE OR REPLACE FUNCTION import_all_asutused()
  RETURNS INTEGER AS
$BODY$
DECLARE
  l_count INTEGER = 0;
BEGIN

  DELETE FROM libs.all_asutused;

  INSERT INTO libs.all_asutused (parentid, childid)
  SELECT parentid, childid
  FROM remote_all_asutused;

  SELECT count(id) INTO l_count FROM libs.all_asutused;

  RETURN l_count;

  EXCEPTION
  WHEN OTHERS
    THEN
      RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
      RETURN 0;

END;
$BODY$
  LANGUAGE plpgsql
  VOLATILE
  COST 100;

SELECT import_all_asutused()


/*

select * from luba order by id desc limit 10

SELECT import_toiming(id) from toiming limit all


*/

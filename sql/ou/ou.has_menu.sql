DROP FUNCTION IF EXISTS ou.get_menu(in_modules TEXT );
DROP FUNCTION IF EXISTS ou.get_menu(in_modules TEXT [] );
DROP FUNCTION IF EXISTS ou.get_menu(in_modules TEXT [], in_groups TEXT [] );

CREATE FUNCTION ou.get_menu(in_modules TEXT [], in_groups TEXT [])
  RETURNS
    TABLE(id INTEGER)
LANGUAGE SQL
AS $$

SELECT id
FROM ou.cur_menu
WHERE modules :: JSONB ?| in_modules
      AND groups :: JSONB ?| in_groups
$$;

SELECT *
FROM ou.get_menu(ARRAY ['EELARVE', 'RAAMA'], ARRAY['KASUTAJA','PEAKASUTAJA'])
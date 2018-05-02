DROP FUNCTION IF EXISTS is_defined( TEXT );

CREATE FUNCTION is_defined(l_var TEXT)
  RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  l_sql     TEXT = 'select ' || l_var || '::text';
  l_tulemus TEXT;
BEGIN
  EXECUTE
  l_sql
  USING l_var
  INTO l_tulemus;

  IF l_tulemus IS NOT NULL
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN FALSE;
END;
$$;


SELECT is_defined('1');
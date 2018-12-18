DROP FUNCTION IF EXISTS get_menu(in_modules TEXT [], in_groups TEXT [] );

CREATE FUNCTION get_menu(in_modules TEXT [], in_groups TEXT [])
  RETURNS TABLE(id INTEGER, pad varchar(120), bar varchar(120), idx INTEGER, name varchar(254), eesti varchar(254), vene varchar(254), proc TEXT, groups TEXT, modules TEXT, level TEXT, message varchar(254), keyshortcut TEXT)
LANGUAGE SQL
AS $$
SELECT id , pad , bar , idx , name, eesti, vene, proc , groups, modules, level, message, keyshortcut
FROM ou.cur_menu
WHERE modules :: JSONB ?| in_modules
      AND groups :: JSONB ?| in_groups
$$;


/*
select * from ou.cur_menu

 */
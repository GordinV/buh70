DROP FUNCTION IF EXISTS get_menu(in_modules TEXT[], in_groups TEXT[]);

CREATE FUNCTION get_menu(in_modules TEXT[], in_groups TEXT[])
    RETURNS TABLE (
        id          INTEGER,
        pad         VARCHAR(120),
        bar         VARCHAR(120),
        idx         INTEGER,
        name        VARCHAR(254),
        eesti       VARCHAR(254),
        vene        VARCHAR(254),
        proc        TEXT,
        groups      TEXT,
        modules     TEXT,
        level       TEXT,
        message     VARCHAR(254),
        keyshortcut TEXT,
        submenu TEXT
    )
    LANGUAGE SQL
AS
$$
SELECT id,
       pad,
       bar,
       idx,
       name,
       eesti,
       vene,
       proc,
       groups,
       modules,
       level,
       message,
       keyshortcut,
       submenu
FROM ou.cur_menu
WHERE modules :: JSONB ?| in_modules
      AND groups :: JSONB ?| in_groups
$$;


/*
select * from ou.cur_menu

 */
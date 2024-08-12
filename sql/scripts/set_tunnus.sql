DROP FUNCTION IF EXISTS set_tunnus();

CREATE FUNCTION set_tunnus()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_eelarve RECORD;
    l_count INTEGER = 0;
    v_arv   RECORD;
    l_tahtaeg date;
BEGIN

    FOR v_eelarve IN
        select t1.tunnus as t_tunnus, 
               e.*
        from eelarve.taotlus t
                 INNER JOIN eelarve.taotlus1 t1 on t1.parentid = t.id
                 INNER JOIN     eelarve.eelarve e on t1.eelarveid = e.id
        where  e.aasta = 2024
          and e.rekvid = 130
          and e.tunnus <> t1.tunnus

        LOOP
            update eelarve.eelarve
            set tunnus = v_eelarve.t_tunnus
            where id = v_eelarve.id;

        END LOOP;
    RETURN l_count;
END;
$$;

SELECT set_tunnus();

DROP FUNCTION IF EXISTS set_tunnus();


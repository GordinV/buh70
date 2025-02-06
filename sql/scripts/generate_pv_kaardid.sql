DROP FUNCTION IF EXISTS generate_pv_kaardid();

CREATE FUNCTION generate_pv_kaardid()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_pv_kaart RECORD;
    l_last_id  integer = 0;
    i          integer = 0;
    l_rekv_id  integer = 3;
    l_user_id  integer = (
                             select
                                 id
                             from
                                 ou.userid
                             where
                                   rekvid = l_rekv_id
                               and kasutaja = 'vlad'
                             limit 1
                         );
    l_kood     text    = '004677';
BEGIN
    select
        id
    into v_pv_kaart
    from
        cur_pohivara
    where
          rekvid = 3
      and kood = l_kood;

    FOR i IN 1..17 BY 1
        LOOP
            l_last_id = (
                            select docs.sp_kooperi_pv_kaart(l_user_id, v_pv_kaart.id, l_last_id)
                        );
            RAISE NOTICE 'Counter: %, l_last_id %', i, l_last_id;
        END LOOP;
    RETURN i;
END;
$$;

SELECT generate_pv_kaardid();

DROP FUNCTION IF EXISTS generate_pv_kaardid();

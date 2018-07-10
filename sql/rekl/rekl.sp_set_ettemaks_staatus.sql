DROP FUNCTION IF EXISTS rekl.sp_set_ettemaks_staatus( INTEGER );

CREATE FUNCTION rekl.sp_set_ettemaks_staatus(l_asutus_id INTEGER)
  RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  l_result   INTEGER = 0;

BEGIN
  IF (SELECT sum(summa)
      FROM rekl.ettemaksud e
      WHERE staatus = 'active' AND asutusid = l_asutus_id) = 0
  THEN

    UPDATE rekl.ettemaksud
    SET staatus = 'closed'
    WHERE asutusid = l_asutus_id
          AND staatus = 'active';
    l_result = 1;

  END IF;

  RETURN l_result;
END;
$$;

/*
select * from rekl.ettemaksud

select rekl.sp_set_ettemaks_staatus(1)
 */
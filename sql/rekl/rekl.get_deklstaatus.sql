DROP FUNCTION IF EXISTS rekl.get_deklstaatus( INTEGER );
DROP FUNCTION IF EXISTS rekl.get_deklstaatus( INTEGER, DATE );

CREATE FUNCTION rekl.get_deklstaatus(l_dekl_id INTEGER, l_saadetud DATE)
  RETURNS DOK_STATUS
LANGUAGE plpgsql
AS $$
DECLARE
  v_toiming RECORD;
BEGIN

  SELECT
    CASE WHEN l_saadetud IS NULL
      THEN t.saadetud
    ELSE l_saadetud END            AS saadetud,
    t.staatus,
    t.summa,
    rekl.fnc_dekl_jaak(t.parentid) AS jaak
  INTO v_toiming
  FROM rekl.toiming t
  WHERE parentid = l_dekl_id;

  IF empty(v_toiming.saadetud)
  THEN
    -- tasud but nor deklared
    RETURN 'active';
  END IF;

  IF NOT empty(v_toiming.saadetud) AND v_toiming.jaak <> v_toiming.summa
  THEN
    RETURN 'closed';
  ELSE
    RETURN v_toiming.staatus;
  END IF;
END;
$$;


/*
select rekl.get_deklstaatus(parentid, '2018-06-30') from rekl.toiming
 */
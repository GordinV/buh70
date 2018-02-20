DROP FUNCTION IF EXISTS docs.get_new_number( TEXT, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION docs.get_new_number(
  dok_type TEXT,
  t_rekvId INTEGER,
  aasta    INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  l_max_number INTEGER = 0;
  l_new_number INTEGER = 0;
BEGIN
  -- SORDER
  CASE WHEN dok_type = 'SORDER'
    THEN
      l_new_number = ((SELECT max(val(k.number))
                       FROM docs.korder1 k
                       WHERE k.tyyp = 1
                             AND k.rekvid = t_rekvId
                             AND (year(k.kpv) = aasta OR aasta IS NULL)
                      ) :: INTEGER + 1) :: VARCHAR(20);
      -- VORDER
    WHEN dok_type = 'VORDER'
    THEN
      l_new_number = ((SELECT max(val(k.number))
                       FROM docs.korder1 k
                       WHERE k.tyyp = 2
                             AND k.rekvid = t_rekvId
                             AND (year(k.kpv) = aasta OR aasta IS NULL)
                      ) :: INTEGER + 1) :: VARCHAR(20);
      if l_new_number is null THEN
        l_new_number = 1;
      END IF;
  END CASE;
  RETURN l_new_number;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION docs.sp_get_number(INTEGER, TEXT, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_get_number(INTEGER, TEXT, INTEGER, INTEGER) TO dbkasutaja;


/*

select docs.get_new_number('VORDER', 1, null);

SELECT *
                       FROM docs.korder1 k
                       WHERE k.tyyp = 1
                             AND k.rekvid = 1
                             order by number desc
                             AND (year(k.kpv) = aasta OR aasta IS NULL)
 */
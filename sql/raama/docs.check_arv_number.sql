DROP FUNCTION IF EXISTS docs.check_arv_number(l_rekv_id INTEGER, l_params JSON);

CREATE FUNCTION docs.check_arv_number(l_rekv_id INTEGER, l_params JSON)
  RETURNS BOOLEAN
  LANGUAGE plpgsql
AS
$$
DECLARE
  l_valid       BOOLEAN = TRUE;
  l_arve_tyyp   INTEGER = coalesce((l_params ->> 'tyyp')::INTEGER, 0);
  l_arve_number TEXT    = l_params ->> 'number';
  l_aasta       INTEGER = coalesce((l_params ->> 'aasta')::INTEGER, year(current_date));
  l_asutus      INTEGER = l_params ->> 'asutus';
BEGIN
  CASE
    WHEN l_arve_tyyp = 0 -- tulud
      THEN
        l_valid =
            NOT exists(SELECT 1
                       FROM docs.arv a
                       WHERE rekvid = l_rekv_id
                         AND year(a.kpv) = l_aasta
                         AND liik = l_arve_tyyp
                         AND a.number = l_arve_number);
    ELSE
      l_valid =
          NOT exists(SELECT 1
                     FROM docs.arv a
                     WHERE rekvid = l_rekv_id
                       AND liik = l_arve_tyyp
                       AND asutusid = l_asutus
                       AND a.number = l_arve_number);
    END CASE;

  RETURN l_valid;
END;
$$;



/*
select docs.check_arv_number(63::INTEGER, '{"tyyp":0, "number":"10"}'::JSON)

select * from docs.arv where  number = '10'
5155
 */
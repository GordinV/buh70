CREATE OR REPLACE FUNCTION jsonb_array_diff(p_new jsonb, p_old jsonb)
    RETURNS jsonb
    LANGUAGE sql
    IMMUTABLE
AS
$$
SELECT jsonb_build_object(
               'added', (SELECT coalesce(jsonb_agg(a.value), '[]'::jsonb)
                         FROM (SELECT value
                               FROM jsonb_array_elements(p_new)
                               EXCEPT
                               SELECT value
                               FROM jsonb_array_elements(p_old)) a),
               'removed', (SELECT coalesce(jsonb_agg(r.value), '[]'::jsonb)
                           FROM (SELECT value
                                 FROM jsonb_array_elements(p_old)
                                 EXCEPT
                                 SELECT value
                                 FROM jsonb_array_elements(p_new)) r)
       );
$$;

GRANT EXECUTE ON FUNCTION jsonb_array_diff(p_new jsonb, p_old jsonb) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION jsonb_array_diff(p_new jsonb, p_old jsonb) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION jsonb_array_diff(p_new jsonb, p_old jsonb) TO dbkasutaja;
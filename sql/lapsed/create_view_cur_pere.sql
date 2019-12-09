DROP VIEW IF EXISTS lapsed.cur_pere;

CREATE OR REPLACE VIEW lapsed.cur_pere AS
    WITH v_lapsed AS (
        SELECT l.id, array_agg(v.asutusid) AS vanemad
        FROM lapsed.laps l
                 INNER JOIN lapsed.vanemad v ON v.parentid = l.id
        GROUP BY l.id
    )
    SELECT array_agg(v.parentid)
    FROM lapsed.vanemad v
             INNER JOIN v_lapsed ON v_lapsed.vanemad @> ARRAY [v.asutusid]
    GROUP BY v.asutusid
    HAVING count(*) > 1;


GRANT SELECT ON TABLE lapsed.cur_pere TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_pere TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_pere TO dbpeakasutaja;

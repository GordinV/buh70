DROP VIEW IF EXISTS hooldekodu.cur_hooleleping;
DROP VIEW IF EXISTS hooldekodu.cur_hooleping;

CREATE VIEW hooldekodu.cur_hooleping AS
    WITH h AS (
        SELECT summa
        FROM hooldekodu.hoo_config
        WHERE library = 'RIIGI_TOETUS'
          AND status < 3
        ORDER BY kpv DESC
        LIMIT 1
    ),
         report AS (
             SELECT hl.id,
                    hl.rekvid,
                    hl.isikid,
                    hl.hooldekoduid,
                    hk.nimetus                                                          AS hooldekodu,
                    hl.number,
                    hl.omavalitsusid,
                    hl.omavalitsus                                                      AS omavalitsus,
                    hl.algkpv,
                    coalesce(hl.loppkpv, make_date(2099, 12, 31))::DATE                 AS LOPPKPV,
                    hl.jaak,
                    hl.summa,
                    hl.muud::VARCHAR(254)                                               AS selg,
                    hl.muud,
                    hl.osa,
                    coalesce(hl.sugulane_osa, 0)                                        AS sugulane_osa,
                    a.regkood                                                           AS isikukood,
                    a.nimetus                                                           AS nimi,
                    coalesce(s.regkood, '')                                             AS sugulane_kood,
                    coalesce(s.nimetus, '')                                             AS sugulane,
                    CASE
                        WHEN hl.hoolduskulud IS NULL OR hl.hoolduskulud = 0 THEN h.summa
                        ELSE hl.hoolduskulud END                                        AS hoolduskulud,
                    hl.summa - (CASE
                                    WHEN hl.hoolduskulud IS NULL OR hl.hoolduskulud = 0 THEN h.summa
                                    ELSE hl.hoolduskulud END)                           AS Isiku_poolt_tasutavad_kulud,
                    hl.bruttosissetulek                                                 AS bruttosissetulek,
                    hl.netosissetulek                                                   AS netosissetulek,
                    -- 7-8 (но не более чем 9)-11-12
                    CASE
                        WHEN (hl.summa - coalesce(hl.hoolduskulud, h.summa)) - hl.netosissetulek -
                             coalesce(hl.sugulane_osa, 0) >
                             (hl.summa - coalesce(hl.hoolduskulud, h.summa))
                            THEN hl.summa - coalesce(hl.hoolduskulud, h.summa)
                        ELSE (hl.summa - coalesce(hl.hoolduskulud, h.summa)) - hl.netosissetulek -
                             coalesce(hl.sugulane_osa, 0) END                           AS kov_osa,
                    hl.netosissetulek * (100 - coalesce(hl.osa, 0)) * 0.01              AS taskuraha,
                    hl.netosissetulek - (hl.summa - coalesce(hl.hoolduskulud, h.summa)) AS Taskuraha_oma_osa,
                    (hl.netosissetulek * (100 - coalesce(hl.osa, 0)) * 0.01) -
                    CASE
                        WHEN (hl.netosissetulek - (hl.summa - coalesce(hl.hoolduskulud, h.summa))) > 0
                            THEN (hl.netosissetulek - (hl.summa - coalesce(hl.hoolduskulud, h.summa)))
                        ELSE 0 END                                                      AS taskuraha_kov
             FROM hooldekodu.hooleping hl
                      INNER JOIN libs.asutus a ON a.id = hl.isikid
                      LEFT OUTER JOIN libs.asutus s ON s.id = hl.sugulane_id
                      LEFT OUTER JOIN libs.asutus hk ON hk.id = hl.hooldekoduid,
                  h
             WHERE hl.status < 3)
    SELECT id,
           rekvid,
           isikid,
           hooldekoduid,
           hooldekodu,
           number,
           omavalitsusid,
           omavalitsus                                                                 AS omavalitsus,
           algkpv,
           loppkpv,
           jaak,
           summa,
           selg::VARCHAR(254)                                                          AS selg,
           muud,
           osa,
           sugulane_osa,
           isikukood,
           nimi,
           sugulane_kood,
           sugulane,
           hoolduskulud,
           Isiku_poolt_tasutavad_kulud,
           bruttosissetulek,
           netosissetulek                                                              AS netosissetulek,
           CASE WHEN kov_osa > 0 THEN kov_osa ELSE 0 END                               AS kov_osa,
           round(taskuraha, 2)                                                         AS taskuraha,
           CASE WHEN Taskuraha_oma_osa < 0 THEN 0 ELSE round(Taskuraha_oma_osa, 2) END AS Taskuraha_oma_osa,
           round(CASE WHEN taskuraha_kov > 0 THEN taskuraha_kov ELSE 0 END, 2)         AS taskuraha_kov
    FROM report
ORDER BY nimi
;

GRANT SELECT ON TABLE hooldekodu.cur_hooleping TO hkametnik;
GRANT SELECT ON TABLE hooldekodu.cur_hooleping TO soametnik;


SELECT *
FROM hooldekodu.cur_hooleping
WHERE nimi = 'ALEKSANDRA MIHHAILOVA'
ORDER BY summa DESC
LIMIT 10
;

'use strict';
const PalkJaak = {
    select: [],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px"},
            {id: "kpv", name: "Kuupäev", width: "100px"},
            {id: "summa", name: "Summa", width: "100px"},
            {id: "nimetus", name: "Nimetus", width: "100px"},
            {id: "liik", name: "Liik", width: "100px"},
            {id: "journalid", name: "Lausend", width: "100px"},
            {id: "created", name: "Lisatud", width: "150px"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px"},
            {id: "status", name: "Status", width: "100px"}
        ],
        sqlString: `SELECT p.*,
                           $2 AS user_id
                    FROM palk.cur_palk_jaak p
                    WHERE p.rekvId IN (SELECT rekv_id FROM get_asutuse_struktuur($1::INTEGER))`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPalkJaak'
    },
    returnData: {
        row: {},
        relations: []
    },
    print: [
        {
            sql: `SELECT p.*,
                         $2 AS user_id
                  FROM (SELECT CASE
                                   WHEN $3::TEXT IS NULL THEN j.jaak
                                   ELSE palk.get_projekt_jaak(j.lepingid,
                                                              (gomonth(make_date(j.aasta, j.kuu, 01), 1) - 1)::DATE,
                                                              $3::TEXT) END::NUMERIC(12, 2) AS jaak,
                               j.kuu,
                               j.aasta,
                               coalesce(p.arv, 0)::NUMERIC(12, 2)                           AS arv,
                               coalesce(p.tasu, 0)::NUMERIC(12, 2)                          AS tasu,
                               coalesce(p.tka, 0)::NUMERIC(12, 2)                           AS tka,
                               coalesce(p.tki, 0)::NUMERIC(12, 2)                           AS tki,
                               coalesce(p.pm, 0)::NUMERIC(12, 2)                            AS pm,
                               coalesce(p.tm, 0)::NUMERIC(12, 2)                            AS tm,
                               coalesce(p.sm, 0)::NUMERIC(12, 2)                            AS sm,
                               coalesce(p.muud, 0)::NUMERIC(12, 2)                          AS muud,
                               coalesce(p.kinni, 0)::NUMERIC(12, 2)                         AS kinni,
                               p.lepingid,
                               t.rekvid,
                               a.id                                                         AS isikid,
                               a.regkood                                                    AS isikukood,
                               a.nimetus                                                    AS isik,
                               o.kood                                                       AS osakond,
                               o.nimetus                                                    AS osakonna_nimetus,
                               coalesce(p.status, 2)                                        AS status
                        FROM palk.palk_jaak j
                                 LEFT OUTER JOIN (
                            SELECT month(p.kpv)                                                         AS kuu,
                                   year(p.kpv)                                                          AS aasta,
                                   sum(p.summa)
                                   FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER = 1)    AS arv,
                                   sum(p.summa)
                                   FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER = 6)    AS tasu,
                                   sum(p.summa)
                                   FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER = 2)    AS kinni,
                                   sum(p.summa)
                                   FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER = 3)    AS muud,
                                   sum(p.pensmaks)
                                   FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER <> 6)   AS pm,
                                   sum(p.summa)
                                   FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER = 5)    AS sm,
                                   sum(p.tulubaas)                                                      AS mvt,
                                   sum(p.tka)
                                   FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER <> 6 AND
                                                 (lib.properties :: JSON ->> 'liik') :: INTEGER IN (1)) AS tka,
                                   sum(p.tootumaks)
                                   FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER <> 6 AND
                                                 (lib.properties :: JSON ->> 'liik') :: INTEGER IN (1)) AS tki,
                                   sum(p.tulumaks)
                                   FILTER (WHERE (lib.properties :: JSON ->> 'liik') :: INTEGER <> 6)   AS tm,
                                   p.lepingid,
                                   t.status
                            FROM docs.doc d
                                     INNER JOIN palk.palk_oper p ON p.parentid = d.id
                                     INNER JOIN libs.library lib ON p.libid = lib.id AND lib.library = 'PALK'
                                     INNER JOIN palk.tooleping t ON p.lepingid = t.id
                            WHERE p.lepingid IS NOT NULL
                              AND d.doc_type_id IN
                                  (SELECT id FROM libs.library l WHERE l.library = 'DOK' AND l.kood = 'PALK_OPER')
                              AND d.status <> 3
                              AND lib.status <> 3
                              AND t.status <> 3
                              AND d.rekvId = $1::INTEGER
                              AND ($3::TEXT IS NULL OR p.proj ILIKE $3::TEXT)
                            GROUP BY month(p.kpv)
                                    , year(p.kpv)
                                    , p.lepingid
                                    , t.status) p
                                                 ON p.lepingid = j.lepingid AND p.kuu = j.kuu AND p.aasta = j.aasta
                                 INNER JOIN palk.tooleping t ON t.id = j.lepingid
                                 INNER JOIN libs.asutus a ON a.id = t.parentid
                                 INNER JOIN libs.library o ON o.id = t.osakondid) p
                  WHERE p.rekvId = $1::INTEGER
                    AND p.lepingId IS NOT NULL
            `,     // $1 всегда ид учреждения $2 - всегда ид пользователя, %3 - proj
            alias: 'printPalkJaak'

        }
    ],
    saveDoc: null,
    deleteDoc: null,
    requiredFields: [],
    executeCommand: {
        command: `select palk.sp_calc_palgajaak($1::integer, $2::JSON)::integer as result`, //$1- userId, $2 - params
        type: 'sql',
        alias: 'executeTask'
    },

};

module.exports = PalkJaak;

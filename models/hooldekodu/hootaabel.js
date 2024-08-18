module.exports = {
    select: [{
        sql: `SELECT h.id,
                     h.isikid,
                     a.nimetus                            AS isik,
                     h.kpv,
                     h.nomid,
                     h.kogus,
                     h.hind,
                     h.soodustus,
                     h.arvid,
                     h.lepingid,
                     h.sugulane_arv_id,
                     CASE
                         WHEN UPPER(n.uhik) = 'KUU' THEN h.alus_hind::NUMERIC(12, 2)
                         ELSE h.summa END::NUMERIC(12, 2) AS summa,
                     (h.summa)                            AS arv_summa,
                     h.muud,
                     h.rekvid,
                     n.kood,
                     coalesce(a_isik.allikas_85, 0)       AS allikas_85,
                     coalesce(a_isik.allikas_muud, 0)     AS allikas_muud,
                     coalesce(a_isik.allikas_vara, 0)     AS allikas_vara,
                     coalesce(a_isik.omavalitsuse_osa, 0) AS omavalitsus_osa,
                     coalesce(a_isik.sugulane_osa, 0)     AS sugulane_osa,
                     $2::INTEGER                          AS user_id
              FROM hooldekodu.hootaabel h
                       INNER JOIN libs.asutus a ON a.id = h.isikid
                       INNER JOIN libs.nomenklatuur n ON n.id = h.nomid
                       LEFT OUTER JOIN (
                  SELECT d.id,
                         sum(coalesce((a1.properties ->> 'allikas_85')::NUMERIC, 0))       AS allikas_85,
                         sum(coalesce((a1.properties ->> 'allikas_muud')::NUMERIC, 0))     AS allikas_muud,
                         sum(coalesce((a1.properties ->> 'allikas_vara')::NUMERIC, 0))     AS allikas_vara,
                         sum(coalesce((a1.properties ->> 'omavalitsuse_osa')::NUMERIC, 0)) AS omavalitsuse_osa,
                         sum(coalesce((a1.properties ->> 'sugulane_osa')::NUMERIC, 0))     AS sugulane_osa
                  FROM docs.doc d
                           INNER JOIN docs.arv a ON d.id = a.parentid
                           LEFT JOIN docs.arv1 a1 ON a1.parentid = a.id
                  WHERE a.properties ->> 'tyyp' = 'HOOLDEKODU_ISIKU_OSA'
                    AND a.asutusid = $1
                    AND d.rekvid IN (SELECT rekvid FROM ou.userid WHERE id = $2)
                  GROUP BY d.id
              ) a_isik ON a_isik.id = h.arvid

              WHERE h.isikid = $1
                AND h.rekvid IN (SELECT rekvid FROM ou.userid WHERE id = $2)
                AND h.kpv = $3::DATE
                AND h.status < 3`,
        sqlAsNew: `SELECT $1::INTEGER                                          AS id,
                          'HOOTEHINGUD'                                        AS doc_type_id,
                          0::INTEGER                                           AS isikid,
                          0::INTEGER                                           AS lepingid,
                          NULL::VARCHAR(20)                                    AS kood,
                          ''::VARCHAR(254)                                     AS isik,
                          current_date::DATE                                   AS kpv,
                          0                                                    AS hind,
                          0                                                    AS kogus,
                          0                                                    AS soodustus,
                          NULL::INTEGER                                        AS arvId,
                          NULL::INTEGER                                        AS sugulane_arv_id,
                          0                                                    AS summa,
                          (SELECT rekvid FROM ou.userid WHERE id = $2 LIMIT 1) AS rekvid,
                          0                                                    AS allikas_85,
                          0                                                    AS allikas_muud,
                          0                                                    AS allikas_vara,
                          0                                                    AS sugulune_summa,
                          NULL::TEXT                                           AS muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }, {
        sql: `SELECT ht.nomid,
                     n.kood,
                     0                                 AS kogus,
                     n.hind                            AS hind,
                     0                                 AS summa,
                     0                                 AS soodustus,
                     ht.lepingid,
                     hl.isikid,
                     public.get_last_day(current_date) AS kpv
              FROM hooldekodu.hooteenused ht
                       INNER JOIN hooldekodu.hooleping hl ON ht.lepingid = hl.id
                       INNER JOIN libs.nomenklatuur n ON n.id = ht.nomid
              WHERE kehtivus IS NULL
                 OR kehtivus >= current_date
                  AND lepingid IN (SELECT id
                                   FROM hooldekodu.hooleping
                                   WHERE rekvid IN (SELECT rekvid FROM ou.userid WHERE id = $2::INTEGER)
                                     AND isikid = $1::INTEGER
                                     AND loppkpv >= $3::DATE)`, // $1 = IsikId, $2 userid, $3 - kpv
        query: null,
        multiple: true,
        alias: 'teenused',
        data: []
    }
    ],
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'isikid', type: 'I'}
    ],
    saveDoc: `select hooldekodu.sp_salvesta_hootaabel($1::jsonb, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM hooldekodu.sp_delete_hootaabel($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "regkood", name: "Reg.kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "omvorm", name: "Om.vorm", width: "20%"},
            {id: "aadress", name: "Aadress", width: "25%"},
            {id: "valid", name: "Kehtivus", width: "10%", type: 'date', show: false},
        ],
        sqlString: `SELECT t.*,
                           $2::INTEGER                           AS userId,
                           a.regkood                             AS isikukood,
                           a.nimetus                             AS nimi,
                           coalesce(h.regkood, '')::VARCHAR(20)  AS regkood,
                           coalesce(h.nimetus, '')::VARCHAR(254) AS hooldekodu 
                    FROM hooldekodu.cur_hootaabel t
                             INNER JOIN libs.asutus a ON a.id = t.isikid
                             LEFT OUTER JOIN hooldekodu.hooleping hl ON t.lepingid = hl.id
                             LEFT OUTER JOIN libs.asutus h ON h.id = hl.hooldekoduid
                    WHERE t.rekvid = $1
                    ORDER BY a.nimetus`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curHooTaabel'
    },

    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()              AS id,
                         (ajalugu ->> 'user')::VARCHAR(20) AS kasutaja,
                         coalesce(to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)         AS koostatud,
                         coalesce(to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)         AS muudatud,
                         coalesce(to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)         AS prinditud,
                         coalesce(to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)         AS kustutatud

                  FROM (
                           SELECT jsonb_array_elements('[]'::JSONB || d.ajalugu::JSONB) AS ajalugu, d.id
                           FROM libs.asutus d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry
                  WHERE (ajalugu ->> 'user') IS NOT NULL`,
        type: "sql",
        alias: "getLogs"
    },

};
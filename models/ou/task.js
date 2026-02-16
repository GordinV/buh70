module.exports = {
    select: [{
        sql: `SELECT
                  'TASK'                                                          AS doc_type_id,
                  $2::INTEGER                                                       AS userid,
                  t.*
              FROM
                  ou.task t,
                  ou.userid u
              WHERE
                    t.id = $1
                AND u.id = $2`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER         AS id,
                      $2 :: INTEGER         AS userid,
                      'TASK'              AS doc_type_id,
                      null::text as sql,
                      null::text as nimetus
                      `,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `select * from ou.tuhista_task_staatus($1::INTEGER , $2::jsonb)`, //$2 params, $1 user_id
            query: null,
            multiple: true,
            alias: 'tuhistaTaskStaatus',
            data: [],
            not_initial_load: true

        }

    ],
    returnData: {
        row: {},
        details: []
    },
    requiredFields: [],
    saveDoc: `select ou.sp_salvesta_task($1::text, $2::text, $3::integer) as id`, // $1 - sql text, $2 -task nimi, $3 -user_id
    deleteDoc: null, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "regkood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"}
        ],
        sqlString: `SELECT
                        $2                                                                      AS user_id,
                        $1                                                                      as rekv_id,
                        u.kasutaja,
                        t.id,
                        to_char(t.created, 'DD.MM.YYYY HH24:MI:SS')::varchar(20)                AS created,
                        coalesce(to_char(t.finished, 'DD.MM.YYYY HH24:MI:SS'), '')::varchar(20) AS finished,
                        t.tulemused                                                             as viga,
                        t.nimetus::varchar(254)                                                 as nimetus,
                        case
                            when t.status = 0 then 'Ootel'
                            when t.status = 1 then 'Edukalt'
                            when t.status = 2 then 'Vigane'
                            else
                                ''
                            end::varchar(20)                                                    as status
                    from
                        ou.task                  t
                            inner join ou.userid u on u.id = t.user_id
                    where
                          u.rekvid = $1
                      and t.status <> 3
                    order by
                        id desc`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curTask'
    },

};

DROP FUNCTION IF EXISTS docs.get_arve_kinnitaja(INTEGER);

CREATE OR REPLACE FUNCTION docs.get_arve_kinnitaja(l_log_id integer)
    RETURNS TABLE
            (
                arved     jsonb,
                email     TEXT,
                smtp      text,
                smtp_port text,
                smtp_pass text,
                smtp_user text
            )
AS
$BODY$

WITH
    log_data AS (
        SELECT
            l.id,
            l.rekvid,
            l.user_id,
            -- Безопасное определение временного диапазона импорта с буфером 5 минут для защиты от рассинхронизации транзакций
            coalesce(
                (l.propertis ->> 'exec_start')::timestamptz,
                clock_timestamp()
            ) - interval '5 minutes' AS time_start,
            coalesce(
                (l.propertis ->> 'exec_end')::timestamptz,
                clock_timestamp()
            ) + interval '5 minutes' AS time_end
        FROM ou.logs l
        WHERE l.id = l_log_id
          AND l.propertis ->> 'flow' = 'docs.sp_loe_earved'
        LIMIT 1
    ),
    arved AS (
        SELECT
            d.created,
            coalesce(d.rekvid, a.rekvid)                          AS rekvid,
            ltrim(rtrim(d.bpm -> 'omniva' -> -1 ->> 'isik'))::text AS raamatupidaja,
            ltrim(rtrim(a.number))                                AS number,
            ltrim(rtrim(k.nimetus))                               AS kontr_agent,
            ld.user_id                                            AS log_user_id
        FROM
            log_data ld
            INNER JOIN docs.arv a ON TRUE
            INNER JOIN docs.doc d ON d.id = a.parentid
            INNER JOIN libs.asutus k ON k.id = a.asutusid
        WHERE
            -- Проверка попадания времени создания документа в диапазон импорта
            (
                d.created >= ld.time_start
                AND d.created <= ld.time_end
            )
    )
SELECT
    jsonb_agg(
        jsonb_build_object(
            'number', arved.number,
            'kontr_agent', arved.kontr_agent,
            'asutus', ltrim(rtrim(r.nimetus))
        )
    ) AS arved,
    -- Приоритет email: 1) бухгалтер из BPM, 2) пользователь запустивший импорт, 3) робот учреждения, 4) учреждение
    coalesce(
        u.email,
        log_u.email,
        smtp.email,
        r.properties ->> 'email'
    )::text AS email,
    smtp.smtp,
    smtp.smtp_port,
    smtp.smtp_pass,
    coalesce(smtp.smtp_user, 'palk')::text AS smtp_user

FROM
    arved
    INNER JOIN ou.rekv r ON r.id = arved.rekvid

    -- Поиск бухгалтера / согласующего (u) с приоритетом по rekvid счета, затем глобально
    LEFT JOIN LATERAL (
        SELECT
            u_inner.properties ->> 'email' AS email
        FROM ou.userid u_inner
        WHERE arved.raamatupidaja IS NOT NULL
          AND arved.raamatupidaja <> ''
          AND upper(rtrim(ltrim(u_inner.ametnik))) = upper(ltrim(rtrim(arved.raamatupidaja)))
          AND u_inner.status < 3
          AND coalesce(u_inner.properties ->> 'email', '') <> ''
        ORDER BY (CASE WHEN u_inner.rekvid = arved.rekvid THEN 1 ELSE 2 END)
        LIMIT 1
    ) u ON TRUE

    -- Пользователь, запустивший задачу импорта (fallback получатель)
    LEFT JOIN LATERAL (
        SELECT
            lu.properties ->> 'email' AS email
        FROM ou.userid lu
        WHERE lu.id = arved.log_user_id
          AND lu.status < 3
          AND coalesce(lu.properties ->> 'email', '') <> ''
        LIMIT 1
    ) log_u ON TRUE

    -- Настройки SMTP через робота Earved robot (приоритет rekvid счета, затем главное учреждение 63)
    LEFT JOIN LATERAL (
        SELECT
            s.properties ->> 'smtp'                         AS smtp,
            s.properties ->> 'port'                         AS smtp_port,
            s.properties ->> 'pass'                         AS smtp_pass,
            coalesce(s.properties ->> 'user', 'palk')::text AS smtp_user,
            s.properties ->> 'email'                        AS email
        FROM ou.userid s
        WHERE s.kasutaja = 'Earved robot'
          AND s.status < 3
          AND (s.rekvid = arved.rekvid OR s.rekvid = 63)
        ORDER BY (CASE WHEN s.rekvid = arved.rekvid THEN 1 ELSE 2 END)
        LIMIT 1
    ) smtp ON TRUE

GROUP BY
    coalesce(
        u.email,
        log_u.email,
        smtp.email,
        r.properties ->> 'email'
    ),
    smtp.smtp,
    smtp.smtp_port,
    smtp.smtp_pass,
    coalesce(smtp.smtp_user, 'palk')
;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.get_arve_kinnitaja(INTEGER) TO dbadmin;
GRANT EXECUTE ON FUNCTION docs.get_arve_kinnitaja(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.get_arve_kinnitaja(INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.get_arve_kinnitaja(INTEGER) TO dbvaatleja;


/*

SELECT *
FROM docs.get_arve_kinnitaja(8129348)

*/

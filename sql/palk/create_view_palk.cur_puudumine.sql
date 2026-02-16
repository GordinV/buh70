DROP VIEW IF EXISTS palk.cur_puudumine;
DROP VIEW IF EXISTS palk.cur_puudumine_;

CREATE OR REPLACE VIEW palk.cur_puudumine AS
SELECT
    p.id,
    p.lepingid,
    p.kpv1,
    p.kpv2,
    p.paevad,
    p.summa,
    p.puudumiste_liik :: VARCHAR(20)                             AS pohjus,
    p.tyyp,
    amet.kood                                                    AS ameti_kood,
    amet.nimetus                                                 AS amet,
    t.rekvid,
    a.regkood                                                    AS isikukood,
    a.nimetus                                                    AS isik,
    tyyp.eesti :: VARCHAR(20)                                    AS liik,

    -- Логика определения, влияет ли отсутствие на календарные дни
    -- (различные типы отпусков и больничных обрабатываются по-разному)
    CASE
        WHEN p.puudumiste_liik = 'PUHKUS' AND p.tyyp <= 3 THEN TRUE
        WHEN p.puudumiste_liik = 'PUHKUS' AND p.tyyp > 4 THEN TRUE
        WHEN p.puudumiste_liik = 'HAIGUS' THEN TRUE
        ELSE FALSE
        END                                                          AS kas_muutab_kalendripäevad,

    -- Формирование строкового представления периода (начало - конец) из JSON массива 'pk'.
    -- Берем дату из первого элемента (0) и дату из последнего элемента (length - 1).
    -- Добавлена проверка типа, чтобы избежать ошибок, если 'pk' не является массивом.
    CASE
        WHEN jsonb_typeof(p.properties -> 'pk') = 'array' THEN
            COALESCE(
                    TO_CHAR((p.properties -> 'pk' -> 0 ->> 'kpv1')::DATE, 'DD.MM.YYYY') || '-' ||
                    TO_CHAR((p.properties -> 'pk' -> (jsonb_array_length(p.properties -> 'pk') - 1) ->> 'kpv2')::DATE, 'DD.MM.YYYY'),
                    '')::VARCHAR(25)
        ELSE ''
        END::VARCHAR(25)                                             AS katkestuse_period,

    -- Использование предварительно вычисленных сумм из LATERAL JOIN (см. ниже).
    -- Это быстрее, чем вызывать агрегатные функции внутри SELECT.
    COALESCE(pk_agg.sum_paevad, 0)::INTEGER                      AS katkestuse_paevad,
    COALESCE(pk_agg.sum_toopaevad, 0)::INTEGER                   AS katkestuse_toopaevad,

    -- Получение кода отсутствия. Если он не задан в свойствах, берем список кодов из типа отсутствия.
    CASE
        WHEN p.properties ->> 'puudumiste_kood' IS NULL THEN array_to_string(tyyp.vs_kooded, ',')
        ELSE p.properties ->> 'puudumiste_kood'
        END::VARCHAR(10)                                             AS puudumiste_kood

FROM
    palk.puudumine                          p
        INNER JOIN palk.tooleping           t ON p.lepingid = t.id
        INNER JOIN libs.library             amet ON t.ametid = amet.id
        INNER JOIN libs.asutus              a ON t.parentid = a.id
        INNER JOIN palk.com_puudumiste_tyyp tyyp ON tyyp.liik = p.puudumiste_liik AND p.tyyp = tyyp.id

                       -- ОПТИМИЗАЦИЯ (LATERAL JOIN):
                       -- Используется для однократного разбора JSON-массива 'pk' для каждой строки.
                       -- Это позволяет вычислить суммы дней и рабочих дней за один проход,
                       -- вместо того чтобы делать это дважды в блоке SELECT.
        LEFT JOIN LATERAL (
                       SELECT
                           SUM(x.paevad) as sum_paevad,
                           SUM(x.toopaevad) as sum_toopaevad
                       FROM jsonb_to_recordset(
                                -- БЕЗОПАСНОСТЬ ТИПОВ:
                                -- Проверяем, является ли поле 'pk' валидным JSON-массивом.
                                -- Если там NULL, объект или скалярное значение, подставляем пустой массив '[]',
                                -- чтобы функция jsonb_to_recordset не вызвала ошибку SQL.
                                    CASE
                                        WHEN jsonb_typeof(p.properties -> 'pk') = 'array' THEN p.properties -> 'pk'
                                        ELSE '[]'::jsonb
                                        END
                            ) AS x(paevad int, toopaevad int)
                       ) pk_agg ON TRUE
WHERE
    p.status <> 'deleted';

GRANT SELECT ON TABLE palk.cur_puudumine TO dbpeakasutaja;
GRANT SELECT ON TABLE palk.cur_puudumine TO dbkasutaja;
GRANT ALL ON TABLE palk.cur_puudumine TO dbadmin;
GRANT SELECT ON TABLE palk.cur_puudumine TO dbvaatleja;
GRANT ALL ON TABLE palk.cur_puudumine TO taabel;

/*
select *
--count(id)
from palk.cur_puudumine
limit 1000
execution: 1 s 125 ms, fetching: 368 ms, 121672
select * from palk.cur_puudumine limit 1000
(execution: 594 ms, fetching: 252 ms)
*/

DROP VIEW IF EXISTS palk.com_puudumiste_tyyp cascade;
-- cur_puudumine

CREATE OR REPLACE VIEW palk.com_puudumiste_tyyp AS
select
    liik,
    id,
    eesti || '(' || array_to_string(VS_kooded, ',') || ')' as eesti,
    vene,
    VS_kooded,
    protsenti,
    kas_ametnik,
    kas_kehtiv,
    kas_luba_allikad
from
    (
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
            1                             AS id,
            'Korraline puhkus'            AS eesti,
            'Основная часть'              AS vene,
            array ['P']::text[]           as VS_kooded,
            null::numeric                 as protsenti,
            null::boolean                 as kas_ametnik,
            true::boolean                 as kas_kehtiv,
            false::boolean                as kas_luba_allikad
        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
            2                             AS id,
            'Lisa osa staazi eest'        AS eesti,
            'За стаж'                     AS vene,
            null::text[]                  as VS_kooded,
            null::numeric                 as protsenti,
            null::boolean                 as kas_ametnik,
            false::boolean                as kas_kehtiv,
            false::boolean                as kas_luda_allikad
        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
            3                             AS id,
            'Täiendav lapsepuhkus'        AS eesti,
            'Детсткий отпуск'             AS vene,
            array ['LP']::text[]          as VS_kooded,
            null::numeric                 as protsenti,
            null::boolean                 as kas_ametnik,
            true::boolean                 as kas_kehtiv,
            false::boolean                as kas_luda_allikad
        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
            4                             AS id,
            'Tasustamata puhkus'          AS eesti,
            'За свой счет'                AS vene,
            array ['A','TP']::text[]      as VS_kooded,
            null::numeric                 as protsenti,
            null::boolean                 as kas_ametnik,
            true::boolean                 as kas_kehtiv,
            false::boolean                as kas_luda_allikad
        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID  AS liik,
            5                              AS id,
            'Õppepuhkus  (keskmine)'       AS eesti,
            'Учебный отпуск (по среднему)' AS vene,
            array ['ÕP']::text[]           as VS_kooded,
            null::numeric                  as protsenti,
            null::boolean                  as kas_ametnik,
            true::boolean                  as kas_kehtiv,
            false::boolean                 as kas_luda_allikad

        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID     AS liik,
            50                                AS id,
            'Õppepuhkus  (alammäär)'          AS eesti,
            'Учебный отпуск (минимальная ЗП)' AS vene,
            array ['ÕP']::text[]              as VS_kooded,
            null::numeric                     as protsenti,
            null::boolean                     as kas_ametnik,
            true::boolean                     as kas_kehtiv,
            false::boolean                    as kas_luda_allikad

        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
            51                            AS id,
            'Õppepuhkus  (tasutamata)'    AS eesti,
            'Учебный отпуск (без оплаты)' AS vene,
            array ['ÕP']::text[]          as VS_kooded,
            null::numeric                 as protsenti,
            null::boolean                 as kas_ametnik,
            true::boolean                 as kas_kehtiv,
            false::boolean                as kas_luda_allikad
        UNION ALL

        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
            6                             AS id,
            'Lisa puhkus'                 AS eesti,
            'Дополнительный отпуск'       AS vene,
            null::text[]                  as VS_kooded,
            null::numeric                 as protsenti,
            null::boolean                 as kas_ametnik,
            false::boolean                as kas_kehtiv,
            false::boolean                as kas_luda_allikad
        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID        AS liik,
            7                                    AS id,
            'Täiendav puhkus alaealistele'       AS eesti,
            'Доп. Отпуск для несовершеннолетних' AS vene,
            array ['AP']::text[]                 as VS_kooded,
            null::numeric                        as protsenti,
            null::boolean                        as kas_ametnik,
            true::boolean                        as kas_kehtiv,
            false::boolean                       as kas_luda_allikad
        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
            71                            AS id,
            'Emapuhkus'                   AS eesti,
            'Материнский отпуск'          AS vene,
            array ['EMP']::text[]         as VS_kooded,
            null::numeric                 as protsenti,
            null::boolean                 as kas_ametnik,
            true::boolean                 as kas_kehtiv,
            false::boolean                as kas_luda_allikad

        UNION ALL

        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID                             AS liik,
            8                                                         AS id,
            'Osaliselt tasustatav puhkus tööandja initsiatiivil'      AS eesti,
            'Частично оплачиваемый отпуск по инициативе работодателя' AS vene,
            array ['AT']::text[]                                      as VS_kooded,
            null::numeric                                             as protsenti,
            null::boolean                                             as kas_ametnik,
            true::boolean                                             as kas_kehtiv,
            false::boolean                                            as kas_luda_allikad

        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID       AS liik,
            9                                   AS id,
            'Täiendav invaliidsuspuhkus'        AS eesti,
            'Доп. отпуск по нетрудоспособности' AS vene,
            array ['IP']::text[]                as VS_kooded,
            null::numeric                       as protsenti,
            null::boolean                       as kas_ametnik,
            true::boolean                       as kas_kehtiv,
            false::boolean                      as kas_luda_allikad

        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID  AS liik,
            10                             AS id,
            'Muu tasuline vabapäev'        AS eesti,
            'Прочий оплачиваемый выходной' AS vene,
            array ['IP']::text[]           as VS_kooded,
            null::numeric                  as protsenti,
            true::boolean                  as kas_ametnik,
            true::boolean                  as kas_kehtiv,
            false::boolean                 as kas_luda_allikad

        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID              AS liik,
            11                                         AS id,
            'Puudega täisealise isiku hooldaja puhkus' AS eesti,
            'Отпуск для ухода за инвалидом'            AS vene,
            array ['PIH']::text[]                      as VS_kooded,
            null::numeric                              as protsenti,
            true::boolean                              as kas_ametnik,
            true::boolean                              as kas_kehtiv,
            false::boolean                             as kas_luda_allikad

        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID                                   AS liik,
            120                                                             AS id,
            'Lisapuhkusetasu ametiühingutega kollektiivlepingu alusel'      AS eesti,
            'Доп. отпуск на основании коллективного договора с профсоюзами' AS vene,
            array ['PL','LPA']::text[]                                      as VS_kooded,
            null::numeric                                                   as protsenti,
            true::boolean                                                   as kas_ametnik,
            true::boolean                                                   as kas_kehtiv,
            false::boolean                                                  as kas_luda_allikad

        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
            12                            AS id,
            'Puhkus'                      AS eesti,
            'Отпуск'                      AS vene,
            array ['S']::text[]           as VS_kooded,
            null::numeric                 as protsenti,
            true::boolean                 as kas_ametnik,
            true::boolean                 as kas_kehtiv,
            false::boolean                as kas_luda_allikad

        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
            13                            AS id,
            'Tervisepäev'                 AS eesti,
            'День здоровья'               AS vene,
            array ['TE']::text[]          as VS_kooded,
            null::numeric                 as protsenti,
            true::boolean                 as kas_ametnik,
            true::boolean                 as kas_kehtiv,
            false::boolean                as kas_luda_allikad

        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID                                                               AS liik,
            14                                                                                          AS id,
            'Töötasu säilimisega vaba päev (doonoripäev, EKV arstlik komisjon vms)'                     AS eesti,
            'Выходной день с сохранением заработной платы (день донора, врачебная комиссия ЕКВ и т.п.)' AS vene,
            array ['V']::text[]                                                                         as VS_kooded,
            null::numeric                                                                               as protsenti,
            true::boolean                                                                               as kas_ametnik,
            true::boolean                                                                               as kas_kehtiv,
            false::boolean                                                                              as kas_luda_allikad

        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID                AS liik,
            15                                           AS id,
            'Keskmisega palgaga vaba päev tööandja loal' AS eesti,
            'Выходной день с с разрешения работодателя'  AS vene,
            array ['VK']::text[]                         as VS_kooded,
            null::numeric                                as protsenti,
            true::boolean                                as kas_ametnik,
            true::boolean                                as kas_kehtiv,
            false::boolean                               as kas_luda_allikad

        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
            16                            AS id,
            'Vanemapuhkus'                AS eesti,
            'Родительский отпуск'         AS vene,
            array ['LHP']::text[]         as VS_kooded,
            null::numeric                 as protsenti,
            true::boolean                 as kas_ametnik,
            true::boolean                 as kas_kehtiv,
            false::boolean                as kas_luda_allikad

        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID              AS liik,
            17                                         AS id,
            'Puudega lapse vanema 1 vaba päev kuus'    AS eesti,
            '1 выходной для родителей детей инвалидов' AS vene,
            array ['PLP']::text[]                      as VS_kooded,
            null::numeric                              as protsenti,
            true::boolean                              as kas_ametnik,
            true::boolean                              as kas_kehtiv,
            false::boolean                             as kas_luda_allikad

        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID                 AS liik,
            18                                            AS id,
            'Täiendav lapsepuhkus (isale)'                AS eesti,
            'Доп. отпуск по уходу за ребенков (для отца)' AS vene,
            array ['VP']::text[]                          as VS_kooded,
            null::numeric                                 as protsenti,
            true::boolean                                 as kas_ametnik,
            true::boolean                                 as kas_kehtiv,
            false::boolean                                as kas_luda_allikad

        UNION ALL
        SELECT
            'PUHKUS' :: PUUDUMISTE_LIIGID     AS liik,
            19                                AS id,
            'Tasustamata lapsepuhkus'         AS eesti,
            'Не оплачиваемый детский отпуск ' AS vene,
            array ['TLP']::text[]             as VS_kooded,
            null::numeric                     as protsenti,
            true::boolean                     as kas_ametnik,
            true::boolean                     as kas_kehtiv,
            false::boolean                    as kas_luda_allikad


        UNION ALL
        SELECT
            'HAIGUS' :: PUUDUMISTE_LIIGID AS liik,
            1                             AS id,
            'Haigus'                      AS eesti,
            'Больничный'                  AS vene,
            array ['H']::text[]           as VS_kooded,
            70::numeric                   as protsenti,
            null::boolean                 as kas_ametnik,
            true::boolean                 as kas_kehtiv,
            true::boolean                 as kas_luda_allikad

        UNION ALL
-- töölt puudumine sünnituslehe alusel
        SELECT
            'HAIGUS' :: PUUDUMISTE_LIIGID         AS liik,
            2                                     AS id,
            'Töölt puudumine sünnituslehe alusel' AS eesti,
            'Больничный по родам'                 AS vene,
            array ['HD']::text[]                  as VS_kooded,
            0::numeric                            as protsenti,
            null::boolean                         as kas_ametnik,
            true::boolean                         as kas_kehtiv,
            false::boolean                        as kas_luda_allikad
        UNION ALL
-- töölt puudumise hoolduslehe alusel
        SELECT
            'HAIGUS' :: PUUDUMISTE_LIIGID        AS liik,
            3                                    AS id,
            'Töölt puudumise hoolduslehe alusel' AS eesti,
            'Больничный по профилактике'         AS vene,
            array ['HL']::text[]                 as VS_kooded,
            0::numeric                           as protsenti,
            null::boolean                        as kas_ametnik,
            true::boolean                        as kas_kehtiv,
            false::boolean                       as kas_luda_allikad

        UNION ALL
        SELECT
            'HAIGUS' :: PUUDUMISTE_LIIGID                   AS liik,
            4                                               AS id,
            'Tööõnnetuse tõttu haiguslehel'                 AS eesti,
            'Больничный из-за несчастного случая на работе' AS vene,
            array ['HP']::text[]                            as VS_kooded,
            100::numeric                                    as protsenti,
            null::boolean                                   as kas_ametnik,
            true::boolean                                   as kas_kehtiv,
            false::boolean                                  as kas_luda_allikad

        UNION ALL
        SELECT
            'HAIGUS' :: PUUDUMISTE_LIIGID AS liik,
            100                           AS id,
            'Avatud haigusleht'           AS eesti,
            'Открытый больничный'         AS vene,
            array ['AH']::text[]          as VS_kooded,
            0::numeric                    as protsenti,
            null::boolean                 as kas_ametnik,
            true::boolean                 as kas_kehtiv,
            false::boolean                as kas_luda_allikad

        UNION ALL
        SELECT
            'HAIGUS' :: PUUDUMISTE_LIIGID AS liik,
            101                           AS id,
            'Puudumisest teatatud'        AS eesti,
            'Извещение о болезни'         AS vene,
            array ['PH']::text[]          as VS_kooded,
            0::numeric                    as protsenti,
            null::boolean                 as kas_ametnik,
            true::boolean                 as kas_kehtiv,
            false::boolean                as kas_luda_allikad

        UNION ALL
        SELECT
            'KOMANDEERING' :: PUUDUMISTE_LIIGID AS liik,
            1                                   AS id,
            'Töölähetus'                        AS eesti,
            'Командировка'                      AS vene,
            array ['TL']::text[]                as VS_kooded,
            null::numeric                       as protsenti,
            null::boolean                       as kas_ametnik,
            true::boolean                       as kas_kehtiv,
            false::boolean                      as kas_luda_allikad

        UNION ALL
        SELECT
            'KOOLITUS' :: PUUDUMISTE_LIIGID AS liik,
            1                               AS id,
            'Koolitus'                      AS eesti,
            'Обучение'                      AS vene,
            array ['K']::text[]             as VS_kooded,
            null::numeric                   as protsenti,
            null::boolean                   as kas_ametnik,
            true::boolean                   as kas_kehtiv,
            false::boolean                  as kas_luda_allikad


        UNION ALL
        SELECT
            'MUU' :: PUUDUMISTE_LIIGID          AS liik,
            1                                   AS id,
            'Muud seadusega lubatud puudumised' AS eesti,
            'Прочее'                            AS vene,
            array ['M']::text[]                 as VS_kooded,
            null::numeric                       as protsenti,
            null::boolean                       as kas_ametnik,
            true::boolean                       as kas_kehtiv,
            false::boolean                      as kas_luda_allikad

        UNION ALL
        SELECT
            'MUU' :: PUUDUMISTE_LIIGID AS liik,
            2                          AS id,
            'Vaba päev'                AS eesti,
            'Свободный день'           AS vene,
            null::text[]               as VS_kooded,
            null::numeric              as protsenti,
            null::boolean              as kas_ametnik,
            false::boolean             as kas_kehtiv,
            false::boolean             as kas_luda_allikad

        UNION ALL
        SELECT
            'MUU' :: PUUDUMISTE_LIIGID AS liik,
            4                          AS id,
            'Streik'                   AS eesti,
            'Забастовка'               AS vene,
            array ['STR']::text[]      as VS_kooded,
            null::numeric              as protsenti,
            null::boolean              as kas_ametnik,
            true::boolean              as kas_kehtiv,
            false::boolean             as kas_luda_allikad

        UNION ALL
        SELECT
            'MUU' :: PUUDUMISTE_LIIGID AS liik,
            5                          AS id,
            'Õppekogunemine'           AS eesti,
            'Сборы'                    AS vene,
            array ['EKK']::text[]      as VS_kooded,
            null::numeric              as protsenti,
            null::boolean              as kas_ametnik,
            true::boolean              as kas_kehtiv,
            false::boolean             as kas_luda_allikad


        UNION ALL
        SELECT
            'MUU' :: PUUDUMISTE_LIIGID AS liik,
            3                          AS id,
            'Tööluus'                  AS eesti,
            'Прогул'                   AS vene,
            array ['L']::text[]        as VS_kooded,
            null::numeric              as protsenti,
            null::boolean              as kas_ametnik,
            true::boolean              as kas_kehtiv,
            false::boolean             as kas_luba_allikad
    ) pd;

GRANT SELECT ON TABLE palk.com_puudumiste_tyyp TO dbkasutaja;
GRANT SELECT ON TABLE palk.com_puudumiste_tyyp TO dbvaatleja;
GRANT SELECT ON TABLE palk.com_puudumiste_tyyp TO dbpeakasutaja;

SELECT *
FROM
    palk.com_puudumiste_tyyp;


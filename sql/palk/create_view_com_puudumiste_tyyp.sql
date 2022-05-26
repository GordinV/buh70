--DROP VIEW IF EXISTS palk.com_puudumiste_tyyp;

CREATE OR REPLACE VIEW palk.com_puudumiste_tyyp AS
    SELECT 'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
           1                             AS id,
           'Põhi osa'                    AS eesti,
           'Основная часть'              AS vene
    UNION ALL
    SELECT 'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
           2                             AS id,
           'Lisa osa staazi eest'        AS eesti,
           'За стаж'                     AS vene
    UNION ALL
    SELECT 'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
           3                             AS id,
           'Lapse puhkus'                AS eesti,
           'Детсткий отпуск'             AS vene
    UNION ALL
    SELECT 'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
           4                             AS id,
           'Oma arvelt'                  AS eesti,
           'За свой счет'                AS vene
    UNION ALL
    SELECT 'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
           5                             AS id,
           'Õppepuhkus'                  AS eesti,
           'Учебный отпуск'              AS vene
    UNION ALL
    SELECT 'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
           6                             AS id,
           'Lisa puhkus'                 AS eesti,
           'Дополнительный отпуск'       AS vene
    UNION ALL
    SELECT 'PUHKUS' :: PUUDUMISTE_LIIGID AS liik,
           7                             AS id,
           'Ema puhkus'                  AS eesti,
           'Материнский отпуск'          AS vene
    UNION ALL
    SELECT 'HAIGUS' :: PUUDUMISTE_LIIGID AS liik,
           1                             AS id,
           'Haigus'                      AS eesti,
           'Больничный'                  AS vene
    UNION ALL
    SELECT 'KOMANDEERING' :: PUUDUMISTE_LIIGID AS liik,
           1                                   AS id,
           'Komandeering'                      AS eesti,
           'Командировка'                      AS vene
    UNION ALL
    SELECT 'MUU' :: PUUDUMISTE_LIIGID AS liik,
           1                          AS id,
           'Muu'                      AS eesti,
           'Прочее'                   AS vene
    UNION ALL
    SELECT 'MUU' :: PUUDUMISTE_LIIGID AS liik,
           2                          AS id,
           'Vaba päev'                AS eesti,
           'Свободный день'           AS vene
    UNION ALL
    SELECT 'MUU' :: PUUDUMISTE_LIIGID AS liik,
           3                          AS id,
           'Popitegemine'             AS eesti,
           'Прогул'                   AS vene;

SELECT *
FROM palk.com_puudumiste_tyyp



GRANT SELECT ON TABLE palk.com_puudumiste_tyyp TO dbkasutaja;
GRANT SELECT ON TABLE palk.com_puudumiste_tyyp TO dbvaatleja;
GRANT SELECT ON TABLE palk.com_puudumiste_tyyp TO dbpeakasutaja;

DROP FUNCTION IF EXISTS palk.tsd_lisa_2026(DATE, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION palk.tsd_lisa_2026(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER DEFAULT 0)
    RETURNS TABLE
            (
                sektsioon       VARCHAR(20),
                tululiik        VARCHAR(20),
                vana_tululiik   VARCHAR(50),
                isikukood       VARCHAR(20),
                isik            VARCHAR(254),
                summa           NUMERIC(14, 2),
                tm              NUMERIC(14, 2),
                sm              NUMERIC(14, 2),
                tki             NUMERIC(14, 2),
                pm              NUMERIC(14, 2),
                tka             NUMERIC(14, 2),
                tulubaas        NUMERIC(14, 2),
                mvt_kood        VARCHAR(20),
                sm_arv          INTEGER,
                arv_min_sots    NUMERIC(14, 2),
                min_sots_alus   NUMERIC(14, 2),
                kas_pensionar   INTEGER,
                vm_summa        NUMERIC(14, 2), -- сумма к выплате
                tagasimakse_kpv DATE,           -- дата исходной выплаты прошлого периода для TSD02
                smvmsk          NUMERIC(14, 2)  -- TSD_SMVMSK (сохранение минимального соцналога)
            )
AS
$BODY$
WITH
    params AS (
                  SELECT
                      l_kpv1::DATE    AS kpv1,
                      l_kpv2::DATE    AS kpv2,
                      l_kond::INTEGER AS kond,
                      l_rekvid        AS rekvid
              ),
    rekv_ids AS (
                  SELECT
                      r.rekv_id
                  FROM
                      params,
                      public.get_asutuse_struktuur(params.rekvid) r
                  WHERE
                      r.rekv_id = CASE
                                      WHEN params.kond IS NULL OR params.kond = 1
                                          THEN r.rekv_id
                                      ELSE params.rekvid
                          END
              ),
    -- Матрица сопоставления видов выплат TSD в секции APA-TSD и коды VALJAMLIIK2023ap
    valjamakseliigid_map (vana_kood, apa_kood, sektsioon) AS (
                  VALUES
                      -- EE0201001: Труд, заработная плата, VÕS, больничные работодателя
                      ('10', '10', 'EE0201001'),
                      ('11', '10', 'EE0201001'),
                      ('12', '10', 'EE0201001'),
                      ('13', '13', 'EE0201001'),
                      ('14', '14', 'EE0201001'),
                      ('15', '15', 'EE0201001'),
                      ('16', '16', 'EE0201001'),
                      ('17', '17', 'EE0201001'),
                      ('18', '18', 'EE0201001'),
                      ('19', '17', 'EE0201001'),
                      ('20', '17', 'EE0201001'),
                      ('21', '21', 'EE0201001'),
                      ('22', '21', 'EE0201001'),
                      ('23', '21', 'EE0201001'),
                      ('24', '24', 'EE0201001'),
                      ('25', '25', 'EE0201001'),
                      ('26', '25', 'EE0201001'),
                      ('28', '28', 'EE0201001'),
                      ('29', '29', 'EE0201001'),
                      ('30', '29', 'EE0201001'),
                      ('31', '29', 'EE0201001'),
                      ('33', '33', 'EE0201001'),
                      ('34', '33', 'EE0201001'),
                      ('35', '33', 'EE0201001'),
                      ('36', '36', 'EE0201001'),
                      ('51', '51', 'EE0201001'),
                      ('52', '52', 'EE0201001'),
                      -- Нерезиденты (трудовые выплаты)
                      ('120', '120', 'EE0201001'),
                      ('121', '120', 'EE0201001'),
                      ('122', '120', 'EE0201001'),
                      ('123', '123', 'EE0201001'),
                      ('124', '123', 'EE0201001'),
                      ('125', '123', 'EE0201001'),
                      ('126', '126', 'EE0201001'),
                      ('127', '126', 'EE0201001'),
                      ('128', '126', 'EE0201001'),
                      ('129', '129', 'EE0201001'),
                      ('130', '130', 'EE0201001'),
                      ('132', '132', 'EE0201001'),
                      ('133', '132', 'EE0201001'),
                      ('134', '132', 'EE0201001'),
                      ('135', '135', 'EE0201001'),
                      ('137', '135', 'EE0201001'),
                      ('138', '138', 'EE0201001'),
                      ('139', '138', 'EE0201001'),
                      ('140', '138', 'EE0201001'),
                      ('141', '141', 'EE0201001'),
                      ('142', '141', 'EE0201001'),
                      ('143', '141', 'EE0201001'),
                      ('144', '144', 'EE0201001'),
                      ('145', '144', 'EE0201001'),
                      ('146', '144', 'EE0201001'),
                      ('147', '147', 'EE0201001'),
                      ('148', '147', 'EE0201001'),
                      ('149', '147', 'EE0201001'),
                      ('150', '150', 'EE0201001'),
                      ('151', '150', 'EE0201001'),
                      ('152', '152', 'EE0201001'),
                      ('153', '152', 'EE0201001'),
                      ('154', '150', 'EE0201001'),
                      ('156', '156', 'EE0201001'),
                      ('157', '156', 'EE0201001'),
                      ('158', '158', 'EE0201001'),
                      ('159', '158', 'EE0201001'),
                      ('164', '164', 'EE0201001'),
                      ('177', '177', 'EE0201001'),
                      -- EE0201002: Пособия, компенсации, рента, стипендии
                      ('27', '25', 'EE0201002'),
                      ('32', '32', 'EE0201002'),
                      ('40', '40', 'EE0201002'),
                      ('41', '41', 'EE0201002'),
                      ('42', '42', 'EE0201002'),
                      ('43', '43', 'EE0201002'),
                      ('44', '44', 'EE0201002'),
                      ('47', '47', 'EE0201002'),
                      ('48', '48', 'EE0201002'),
                      ('49', '49', 'EE0201002'),
                      ('50', '50', 'EE0201002'),
                      ('53', '53', 'EE0201002'),
                      ('54', '54', 'EE0201002'),
                      ('55', '55', 'EE0201002'),
                      ('56', '56', 'EE0201002'),
                      ('57', '57', 'EE0201002'),
                      ('58', '58', 'EE0201002'),
                      ('59', '59', 'EE0201002'),
                      ('131', '131', 'EE0201002'),
                      ('160', '160', 'EE0201002'),
                      ('162', '162', 'EE0201002'),
                      ('165', '164', 'EE0201002'),
                      ('166', '166', 'EE0201002'),
                      ('171', '171', 'EE0201002'),
                      ('172', '172', 'EE0201002'),
                      ('173', '173', 'EE0201002'),
                      ('174', '174', 'EE0201002'),
                      ('175', '175', 'EE0201002'),
                      ('176', '176', 'EE0201002'),
                      ('178', '178', 'EE0201002'),
                      ('179', '179', 'EE0201002'),
                      ('180', '180', 'EE0201002'),
                      ('181', '181', 'EE0201002'),
                      ('182', '182', 'EE0201002'),
                      ('183', '183', 'EE0201002'),
                      ('184', '184', 'EE0201002'),
                      ('185', '185', 'EE0201002'),
                      ('186', '186', 'EE0201002'),
                      ('187', '187', 'EE0201002'),
                      ('188', '188', 'EE0201002'),
                      ('189', '189', 'EE0201002'),
                      ('190', '190', 'EE0201002'),
                      ('191', '191', 'EE0201002'),
                      ('192', '192', 'EE0201002'),
                      ('193', '193', 'EE0201002'),
                      ('194', '194', 'EE0201002'),
                      ('196', '196', 'EE0201002'),
                      ('197', '197', 'EE0201002'),
                      ('198', '198', 'EE0201002'),
                      ('199', '199', 'EE0201002'),
                      ('201', '201', 'EE0201002'),
                      ('202', '202', 'EE0201002'),
                      ('203', '203', 'EE0201002'),
                      ('205', '205', 'EE0201002'),
                      ('207', '207', 'EE0201002')
              ),
    -- Расчет минимального социального налога (доплата до минимальной базы)
    qryMinSots AS (
                  SELECT
                      po.lepingid,
                      po.rekvid,
                      sum(po.summa)::NUMERIC(14, 2)    AS arv_min_sots,
                      sum(po.sotsmaks)::NUMERIC(14, 2) AS min_sots_alus
                  FROM
                      params,
                      palk.palk_oper po
                          INNER JOIN com_palklib pl ON pl.id = po.libid AND pl.liik = 5 AND po.sotsmaks <> 0
                  WHERE
                        (
                            (po.properties ->> 'maksekpv' IS NULL AND po.kpv >= params.kpv1 AND po.kpv <= params.kpv2)
                                OR
                            (po.properties ->> 'maksekpv' IS NOT NULL
                                AND (po.properties ->> 'maksekpv')::date >= params.kpv1
                                AND (po.properties ->> 'maksekpv')::date <= params.kpv2)
                            )
                    AND po.period IS NULL
                    AND po.rekvid IN (
                                         SELECT
                                             rekv_id
                                         FROM
                                             rekv_ids
                                     )
                  GROUP BY
                      po.lepingid, po.rekvid
              ),
    -- Поток 1: Основные начисления и положительные корректировки (без TSD02)
    qryPoIds_Regular AS (
                  SELECT
                      po.lepingid,
                      po.tululiik,
                      sum(po.summa)::NUMERIC(14, 2)     AS summa,
                      sum(po.tulumaks)::NUMERIC(14, 2)  AS tm,
                      sum(po.sotsmaks)::NUMERIC(14, 2)  AS sm,
                      sum(po.tootumaks)::NUMERIC(14, 2) AS tki,
                      sum(po.pensmaks)::NUMERIC(14, 2)  AS pm,
                      sum(po.tka)::NUMERIC(14, 2)       AS tka,
                      sum(po.tulubaas)::NUMERIC(14, 2)  AS tulubaas,
                      NULL::DATE                        AS tagasimakse_kpv,
                      0::NUMERIC(14, 2)                 AS smvmsk
                  FROM
                      params,
                      docs.doc d
                          INNER JOIN palk.palk_oper po ON po.parentid = d.id
                          INNER JOIN com_palklib pl ON pl.id = po.libid AND pl.liik = 1
                  WHERE
                        d.status <> 3
                    AND d.rekvid IN (
                                        SELECT
                                            rekv_id
                                        FROM
                                            rekv_ids
                                    )
                    AND (po.period IS NULL OR po.summa >= 0)
                    AND (
                            (po.properties ->> 'maksekpv' IS NULL AND po.kpv >= params.kpv1 AND po.kpv <= params.kpv2)
                                OR
                            (po.properties ->> 'maksekpv' IS NOT NULL
                                AND (po.properties ->> 'maksekpv')::date >= params.kpv1
                                AND (po.properties ->> 'maksekpv')::date <= params.kpv2)
                            )
                  GROUP BY
                      po.lepingid, po.tululiik
              ),
    -- Поток 2: Отрицательные корректировки выплат прошлых периодов (возвраты / удержания с TSD02)
    qryPoIds_Refund AS (
                  SELECT
                      po.lepingid,
                      po.tululiik,
                      -abs(sum(po.summa))::NUMERIC(14, 2)     AS summa,
                      -abs(sum(po.tulumaks))::NUMERIC(14, 2)  AS tm,
                      -abs(sum(po.sotsmaks))::NUMERIC(14, 2)  AS sm,
                      -abs(sum(po.tootumaks))::NUMERIC(14, 2) AS tki,
                      -abs(sum(po.pensmaks))::NUMERIC(14, 2)  AS pm,
                      -abs(sum(po.tka))::NUMERIC(14, 2)       AS tka,
                      -abs(sum(po.tulubaas))::NUMERIC(14, 2)  AS tulubaas,
                      COALESCE(po.period, params.kpv1)::DATE  AS tagasimakse_kpv,
                      coalesce((SELECT sum(p_min.sotsmaks)
                                FROM palk.palk_oper p_min
                                         INNER JOIN libs.library pl_min ON pl_min.id = p_min.libId
                                WHERE YEAR(p_min.kpv) = year(po.period)
                                  AND MONTH(p_min.kpv) = month(po.period)
                                  AND p_min.lepingid = po.lepingid
                                  AND pl_min.properties::JSONB ->> 'liik' = '5'), 0)::NUMERIC(14, 2) AS smvmsk
                  FROM
                      params,
                      docs.doc d
                          INNER JOIN palk.palk_oper po ON po.parentid = d.id
                          INNER JOIN com_palklib pl ON pl.id = po.libid AND pl.liik = 1
                  WHERE
                        d.status <> 3
                    AND d.rekvid IN (
                                        SELECT
                                            rekv_id
                                        FROM
                                            rekv_ids
                                    )
                    AND po.period IS NOT NULL
                    AND po.summa < 0
                    AND (
                            (po.properties ->> 'maksekpv' IS NULL AND po.kpv >= params.kpv1 AND po.kpv <= params.kpv2)
                                OR
                            (po.properties ->> 'maksekpv' IS NOT NULL
                                AND (po.properties ->> 'maksekpv')::date >= params.kpv1
                                AND (po.properties ->> 'maksekpv')::date <= params.kpv2)
                            )
                  GROUP BY
                      po.lepingid, po.tululiik, po.period, params.kpv1
              ),
    qryPoIds AS (
                  SELECT * FROM qryPoIds_Regular
                  UNION ALL
                  SELECT * FROM qryPoIds_Refund
              ),
    -- Данные по сотрудникам с начислениями
    qryPo AS (
                  SELECT
                      t.parentid                                                AS isik_id,
                      a.regkood                                                 AS isikukood,
                      a.nimetus                                                 AS isik,
                      po.tululiik                                               AS vana_tululiik,
                      COALESCE(m.apa_kood, po.tululiik)                         AS tululiik,
                      COALESCE(
                              m.sektsioon,
                              CASE
                                  WHEN po.tululiik ~ '^[678][0-9]{2,3}$' THEN 'EE0201003'
                                  ELSE 'EE0201001'
                                  END
                      )                                                         AS sektsioon,
                      po.summa,
                      po.tm,
                      po.sm,
                      po.tki,
                      po.pm,
                      po.tka,
                      po.tulubaas,
                      COALESCE(l.tun2, 0)::INTEGER                              AS sm_arv,
                      -- Мин. соцналог относится к основным видам дохода (10, 13, 15, 17) и только к обычным строкам (не возвратам)
                      CASE
                          WHEN po.tagasimakse_kpv IS NULL
                               AND COALESCE(m.apa_kood, po.tululiik) IN ('10', '13', '15', '17')
                              THEN COALESCE(ms.arv_min_sots, 0)
                          ELSE 0
                          END::NUMERIC(14, 2)                                   AS arv_min_sots,
                      CASE
                          WHEN po.tagasimakse_kpv IS NULL
                               AND COALESCE(m.apa_kood, po.tululiik) IN ('10', '13', '15', '17')
                              THEN COALESCE(ms.min_sots_alus, 0)
                          ELSE 0
                          END::NUMERIC(14, 2)                                   AS min_sots_alus,
                      coalesce((t.properties ->> 'varem_pensioon')::integer, 0) as varem_pensioon,
                      po.tagasimakse_kpv,
                      -- smvmsk разрешен только для видов выплат с kuumäär (10, 13, 15, 17) по правилу KR_SM_14
                      CASE
                          WHEN po.tagasimakse_kpv IS NOT NULL
                               AND COALESCE(m.apa_kood, po.tululiik) IN ('10', '13', '15', '17')
                              THEN po.smvmsk
                          ELSE 0
                          END::NUMERIC(14, 2)                                   AS smvmsk
                  FROM
                      palk.tooleping                           t
                          INNER JOIN      libs.asutus          a ON a.id = t.parentid
                          INNER JOIN      qryPoIds             po ON po.lepingid = t.id
                          LEFT OUTER JOIN valjamakseliigid_map m ON m.vana_kood = po.tululiik
                          LEFT OUTER JOIN libs.library         l
                                          ON l.kood = po.tululiik AND l.library = 'MAKSUKOOD' AND l.status < 3
                          LEFT OUTER JOIN qryMinSots           ms ON ms.lepingid = t.id AND ms.rekvid = t.rekvid
                  WHERE
                        t.resident = 1
                    AND t.rekvid IN (
                                        SELECT
                                            rekv_id
                                        FROM
                                            rekv_ids
                                    )
              ),
    -- Сотрудники с договором без выплат в отчетном периоде, но с обязанностью по мин. соцналогу
    qryZeroSalaryMinSots AS (
                  SELECT
                      t.parentid                                                AS isik_id,
                      a.regkood                                                 AS isikukood,
                      a.nimetus                                                 AS isik,
                      '10'::VARCHAR(20)                                         AS vana_tululiik,
                      '10'::VARCHAR(20)                                         AS tululiik,
                      'EE0201001'::VARCHAR(20)                                  AS sektsioon,
                      0::NUMERIC(14, 2)                                         AS summa,
                      0::NUMERIC(14, 2)                                         AS tm,
                      0::NUMERIC(14, 2)                                         AS sm,
                      0::NUMERIC(14, 2)                                         AS tki,
                      0::NUMERIC(14, 2)                                         AS pm,
                      0::NUMERIC(14, 2)                                         AS tka,
                      0::NUMERIC(14, 2)                                         AS tulubaas,
                      1::INTEGER                                                AS sm_arv,
                      ms.arv_min_sots,
                      ms.min_sots_alus,
                      coalesce((t.properties ->> 'varem_pensioon')::integer, 0) as varem_pensioon,
                      NULL::DATE                                                AS tagasimakse_kpv,
                      0::NUMERIC(14, 2)                                         AS smvmsk

                  FROM
                      qryMinSots                    ms
                          INNER JOIN palk.tooleping t ON t.id = ms.lepingid
                          INNER JOIN libs.asutus    a ON a.id = t.parentid
                  WHERE
                        t.resident = 1
                    AND t.rekvid IN (
                                        SELECT
                                            rekv_id
                                        FROM
                                            rekv_ids
                                    )
                    AND ms.lepingid NOT IN (
                                               SELECT
                                                   lepingid
                                               FROM
                                                   qryPoIds
                                           )
              ),
    all_rows AS (
                  SELECT *
                  FROM
                      qryPo
                  UNION ALL
                  SELECT *
                  FROM
                      qryZeroSalaryMinSots
              )
SELECT
    r.sektsioon::VARCHAR(20),
    r.tululiik::VARCHAR(20),
    string_agg(DISTINCT r.vana_tululiik, ',')::VARCHAR(50) AS vana_tululiik,
    r.isikukood::VARCHAR(20),
    r.isik::VARCHAR(254),
    COALESCE(sum(r.summa), 0)::NUMERIC(14, 2)              AS summa,
    COALESCE(sum(r.tm), 0)::NUMERIC(14, 2)                 AS tm,
    COALESCE(sum(r.sm), 0)::NUMERIC(14, 2)                 AS sm,
    COALESCE(sum(r.tki), 0)::NUMERIC(14, 2)                AS tki,
    COALESCE(sum(r.pm), 0)::NUMERIC(14, 2)                 AS pm,
    COALESCE(sum(r.tka), 0)::NUMERIC(14, 2)                AS tka,
    COALESCE(sum(r.tulubaas), 0)::NUMERIC(14, 2)           AS tulubaas,
    CASE
        WHEN COALESCE(sum(r.tulubaas), 0) <> 0 THEN
            CASE
                when (r.varem_pensioon)::boolean then 'MVT_650'
                WHEN palk.kas_soodustus_mvt(r.isikukood, (
                                                             SELECT
                                                                 kpv1
                                                             FROM
                                                                 params
                                                         )) THEN 'MVT_650'
                ELSE 'MVT_610'
                END
        ELSE NULL
        END::VARCHAR(20)                                   AS mvt_kood,
    COALESCE(max(r.sm_arv), 0)::INTEGER                    AS sm_arv,
    COALESCE(max(r.arv_min_sots), 0)::NUMERIC(14, 2)       AS arv_min_sots,
    COALESCE(max(r.min_sots_alus), 0)::NUMERIC(14, 2)      AS min_sots_alus,
    CASE
        WHEN palk.kas_soodustus_mvt(r.isikukood, (
                                                     SELECT
                                                         kpv1
                                                     FROM
                                                         params
                                                 )) THEN 1
        ELSE 0
        END::INTEGER                                       AS kas_pensionar,
    (COALESCE(sum(r.summa), 0) - COALESCE(sum(r.tm), 0) - COALESCE(sum(r.pm), 0) -
     COALESCE(sum(r.tki), 0))::NUMERIC(14, 2)              AS vm_summa,
    r.tagasimakse_kpv,
    COALESCE(max(r.smvmsk), 0)::NUMERIC(14, 2)             AS smvmsk
FROM
    all_rows r
GROUP BY
    r.sektsioon, r.tululiik, r.isikukood, r.isik, r.varem_pensioon, r.tagasimakse_kpv
ORDER BY
    r.sektsioon, r.isikukood, r.tululiik, r.tagasimakse_kpv NULLS FIRST;
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.tsd_lisa_2026( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.tsd_lisa_2026( DATE, DATE, INTEGER, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.tsd_lisa_2026( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;

/*
-- Тестовый вызов функции:
SELECT *
FROM palk.tsd_lisa_2026('2026-10-01'::DATE, '2026-10-31'::DATE, 108, 0)
where isikukood = '46109023722'

;
*/
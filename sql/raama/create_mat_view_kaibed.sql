DROP MATERIALIZED VIEW IF EXISTS docs.kaibed;

CREATE MATERIALIZED VIEW docs.kaibed AS
SELECT
    array_agg(d.id)          as docs_id,
    d.rekvid,
    make_date(2025, 12, 31)  as kpv,
    trim(j1.deebet)          as deebet,
    trim(j1.kreedit)         as kreedit,
    sum(j1.summa)            as summa,
    j1.tunnus,
    j1.proj,
    j1.kood1,
    j1.kood2,
    j1.kood3,
    j1.kood4,
    j1.kood5,
    j1.objekt
FROM
    docs.doc                           d
        INNER JOIN      docs.journal   j ON j.parentid = d.id
        INNER JOIN      docs.journal1  j1 ON j1.parentid = j.id
        LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id and a.kpv = '2025-12-31'::date

WHERE
      d.status < 3 -- Исключаем удаленные документы
  AND d.doc_type_id = 57 -- Только проводки (JOURNAL)
  and coalesce(a.kpv, j.kpv) < make_date(2026, 01, 01)

group by
    d.rekvid, j1.deebet, j1.kreedit, j1.tunnus, j1.proj, j1.kood1, j1.kood2, j1.kood3, j1.kood4, j1.kood5, j1.objekt
WITH DATA;

-- Индексы для ускорения поиска

-- Основной композитный индекс: Учреждение + Дата (самый частый фильтр)
CREATE INDEX idx_kaibed_rekvid_kpv ON docs.kaibed (rekvid);

-- Индексы по счетам (для поиска по дебету и кредиту)
CREATE INDEX idx_kaibed_deebet ON docs.kaibed (deebet);
CREATE INDEX idx_kaibed_kreedit ON docs.kaibed (kreedit);

-- Индексы по аналитике (используем COALESCE в запросах или частичные индексы, если много NULL)
CREATE INDEX idx_kaibed_tunnus ON docs.kaibed (tunnus) WHERE tunnus IS NOT NULL AND tunnus <> '';
CREATE INDEX idx_kaibed_proj ON docs.kaibed (proj) WHERE proj IS NOT NULL AND proj <> '';
CREATE INDEX idx_kaibed_kood2 ON docs.kaibed (kood2) WHERE kood2 IS NOT NULL AND kood2 <> ''; -- Allikas
CREATE INDEX idx_kaibed_kood4 ON docs.kaibed (kood4) WHERE kood4 IS NOT NULL AND kood4 <> '';
-- Uritus

-- Права доступа
GRANT SELECT ON TABLE docs.kaibed TO dbpeakasutaja;
GRANT SELECT ON TABLE docs.kaibed TO dbvaatleja;
GRANT SELECT ON TABLE docs.kaibed TO dbkasutaja;
GRANT execute ON TABLE docs.kaibed TO dbkasutaja;

/*
-- Пример обновления данных (нужно выполнять периодически или триггером)
REFRESH MATERIALIZED VIEW CONCURRENTLY docs.kaibed;
*/
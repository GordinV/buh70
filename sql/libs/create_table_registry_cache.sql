-- Кэш ответов платного API Inforegister (libs/inforegister.js). Без таблицы агент работает, но каждый запуск тратит лимит.
CREATE TABLE IF NOT EXISTS libs.registry_cache
(
    cache_key  TEXT PRIMARY KEY,
    payload    JSONB,
    negative   BOOLEAN                  NOT NULL DEFAULT FALSE, -- «данных нет» (404), тоже кэшируется
    fetched_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE ON libs.registry_cache TO dbkasutaja;
GRANT SELECT, INSERT, UPDATE, DELETE ON libs.registry_cache TO dbpeakasutaja;

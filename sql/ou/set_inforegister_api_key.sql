-- Ключ платного API Inforegister хранится в конфигурации учреждения (читается моделью config, поле inforegister_api_key).
-- Подставьте ключ вместо <КЛЮЧ> и выполните; ключ в репозиторий не коммитить.
UPDATE ou.config
SET
    properties = coalesce(properties, '{}'::jsonb) || jsonb_build_object('INFOREGISTER_API_KEY', '<КЛЮЧ>')
WHERE
    rekvid = 3;

-- проверка (без вывода самого ключа)
-- SELECT rekvid, (properties ->> 'INFOREGISTER_API_KEY') IS NOT NULL AS has_key FROM ou.config WHERE rekvid = 3;

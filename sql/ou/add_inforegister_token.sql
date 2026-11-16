-- Управление hash-токенами доступа к маршрутам Inforegister (/task/getInforegister/ и /task/inforegisterLookup/).
-- В БД хранится только SHA-256 от токена; исходный секретный токен генерируется вне БД:
--   openssl rand -hex 32
--   printf '%s' '<ТОКЕН>' | sha256sum
--
-- ВАЖНО для ai_task:
--   user_id токена агента ДОЛЖЕН совпадать с params.userId в inforegister/config.json (11770),
--   иначе лог создастся под другим пользователем и logs_watcher его не найдёт.
--   Пример для ai_task:
--     token_sha256: '<SHA256_HEX>'
--     user_id: 11770
--     rekv_id: 63
--     label: 'ai_task'
--     scopes: '["batch", "lookup"]'

-- 1. Добавление (или замена по label) активного токена
UPDATE ou.config
SET
    properties = coalesce(properties, '{}'::jsonb) || jsonb_build_object(
        'INFOREGISTER_TOKENS',
        coalesce(
            (
                SELECT jsonb_agg(elem)
                FROM jsonb_array_elements(coalesce(properties -> 'INFOREGISTER_TOKENS', '[]'::jsonb)) AS elem
                WHERE elem ->> 'label' IS DISTINCT FROM 'ai_task'
            ),
            '[]'::jsonb
        ) || jsonb_build_array(
            jsonb_build_object(
                'token_sha256', '<SHA256_HEX>',
                'user_id', 11770,
                'rekv_id', 63,
                'label', 'ai_task',
                'scopes', '["batch", "lookup"]'::jsonb,
                'active', true
            )
        )
    )
WHERE
    rekvid = 3;

-- 2. Отзыв токена по label (перевод active = false)
-- UPDATE ou.config
-- SET
--     properties = jsonb_set(
--         properties,
--         '{INFOREGISTER_TOKENS}',
--         coalesce(
--             (
--                 SELECT jsonb_agg(
--                     CASE
--                         WHEN elem ->> 'label' = 'ai_task' THEN elem || '{"active": false}'::jsonb
--                         ELSE elem
--                     END
--                 )
--                 FROM jsonb_array_elements(coalesce(properties -> 'INFOREGISTER_TOKENS', '[]'::jsonb)) AS elem
--             ),
--             '[]'::jsonb
--         )
--     )
-- WHERE
--     rekvid = 3;

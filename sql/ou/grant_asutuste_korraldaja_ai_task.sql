-- Идемпотентная выдача роли is_asutuste_korraldaja сервисному пользователю ai_task (id = 11770)
UPDATE ou.userid
SET roles = coalesce(roles, '{}'::jsonb) || '{"is_asutuste_korraldaja": true}'::jsonb
WHERE id = 11770
  AND coalesce((roles ->> 'is_asutuste_korraldaja')::boolean, false) IS DISTINCT FROM true;

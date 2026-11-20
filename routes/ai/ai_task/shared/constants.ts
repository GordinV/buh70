/**
 * Единый сервисный пользователь (userId) для всех агентов и оркестратора ai_task в buh70.
 * Специально созданный сервисный аккаунт, чтобы все регламентные запуски в ou.logs и документах
 * выполнялись от его имени без привязки к персональному аккаунту администратора.
 */
export const AI_TASK_SERVICE_USER_ID = 11770;

/**
 * Алиас обратной совместимости для цепочки FinBit (использует единого сервисного пользователя AI_TASK_SERVICE_USER_ID).
 */
export const FINBIT_SERVICE_USER_ID = AI_TASK_SERVICE_USER_ID;

/**
 * Выделенный userId для агента saldoandmik (eelarve.sp_koosta_saldoandmik).
 */
export const SALDOANDMIK_USER_ID = 2477;

/**
 * Список ключей субагентов цепочки FinBit.
 */
export const FINBIT_AGENT_KEYS = [
  'getEarved',
  'check_asutus',
  'inforegister',
  'import_earved',
  'sendFinBitReport',
] as const;

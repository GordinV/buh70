/**
 * Базовый набор служебных каталогов модуля ai_task, которые никогда не являются агентами:
 * исключаются и при построении реестра манифестов (shared/agent_registry.ts),
 * и при сканировании конфигураций задач DAG (orchestrator/state.manager.ts).
 * Каталоги, начинающиеся с точки, отсекаются отдельной проверкой в местах сканирования.
 */
export const EXCLUDED_SERVICE_DIRS: readonly string[] = ['node_modules', 'dist', 'state', 'shared', 'logs_watcher'];

/**
 * Каталоги, которые дополнительно исключаются только из графа задач DAG (state.tasks).
 * В реестр манифестов они попадать могут (например, schedule_monitor вызывается оркестратором напрямую).
 */
export const EXCLUDED_DAG_ONLY_DIRS: readonly string[] = ['orchestrator', 'schedule_monitor'];

/**
 * Полный набор каталогов, не являющихся расчетными задачами DAG: базовый набор + расширение для DAG
 */
export const EXCLUDED_NON_DAG_DIRS: ReadonlySet<string> = new Set([
  ...EXCLUDED_SERVICE_DIRS,
  ...EXCLUDED_DAG_ONLY_DIRS,
]);

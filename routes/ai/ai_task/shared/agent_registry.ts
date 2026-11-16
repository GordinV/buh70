import * as fs from 'fs';
import * as path from 'path';
import { ApiClient } from './api_client';
import { OrchestratorState, TaskState } from '../orchestrator/orchestrator.schemas';
import { resolveAiTaskRootDir } from '../orchestrator/state.manager';
import { ReportStepDetail } from '../reporter/schemas';
import { EXCLUDED_SERVICE_DIRS } from './excluded_dirs';

/**
 * Контекст, передаваемый в manifest.dispatch() при запуске или повторе задачи
 */
export interface AgentDispatchContext {
  key: string;
  userId: number;
  rekvId: number;
  kond: number;
  params: Record<string, unknown>;
  apiClient: ApiClient;
}

/**
 * Манифест субагента — контракт между агентом и оркестратором
 */
export interface AgentManifest {
  /**
   * Неблокирующий запуск задачи (POST на бэкенд). Должен вернуть log_id
   * либо выбросить исключение (оркестратор сам обработает retry/FAILED).
   */
  dispatch: (ctx: AgentDispatchContext) => Promise<number | null>;

  /**
   * Опционально: вычисление дополнительных параметров запуска на основе
   * состояния других задач графа (Parent Context Forwarding).
   * Чистая функция без побочных эффектов. При отсутствии данных возвращает {}.
   */
  resolveParentParams?: (state: OrchestratorState) => Record<string, unknown>;

  /**
   * Опционально: проверка специфических предусловий агента перед запуском
   * (например, наличие log_id родительской задачи).
   * Возвращает строку причины пропуска (SKIP), если предусловие не выполнено, иначе null.
   */
  validatePrerequisites?: (state: OrchestratorState) => string | null;

  /**
   * Опционально: обогащение данных шага для итогового отчета reporter
   * на основе записи из ou.logs и состояния задачи (без модификации ядра оркестратора).
   */
  enrichReportStep?: (
    stepLog: Record<string, unknown> | null,
    task: TaskState
  ) => Partial<ReportStepDetail>;
}

/**
 * Собирает имена подкаталогов агентов из указанной директории, исключая служебные и скрытые.
 */
function collectAgentDirs(dirPath: string, target: Set<string>): void {
  if (!fs.existsSync(dirPath)) return;
  try {
    const entries = fs.readdirSync(dirPath, { withFileTypes: true });
    for (const entry of entries) {
      if (
        entry.isDirectory() &&
        !entry.name.startsWith('.') &&
        !EXCLUDED_SERVICE_DIRS.includes(entry.name)
      ) {
        target.add(entry.name);
      }
    }
  } catch {
    // Игнорируем ошибки доступа к файловой системе
  }
}

/**
 * Строит реестр манифестов агентов динамическим сканированием каталогов модулей агентов.
 * Поддерживает overrides словаря манифестов для тестов.
 */
export function buildAgentRegistry(
  rootDir?: string,
  overrides?: Record<string, AgentManifest>
): Record<string, AgentManifest> {
  const registry: Record<string, AgentManifest> = {};
  const root = resolveAiTaskRootDir(rootDir);

  // Динамически сканируем root (и root/dist для Docker-сборки, где каталоги без config.json лежат только в dist/)
  const candidateDirs = new Set<string>();
  collectAgentDirs(root, candidateDirs);
  collectAgentDirs(path.join(root, 'dist'), candidateDirs);

  for (const agentName of candidateDirs) {
    const absTs = path.join(root, agentName, 'agent.ts');
    const absJs = path.join(root, agentName, 'agent.js');
    const distJs = path.join(root, 'dist', agentName, 'agent.js');

    // Определяем путь к модулю агента отдельно от его загрузки, чтобы различать
    // «файла нет» (молча пропускаем) и «файл есть, но не загрузился» (предупреждение)
    let modulePath: string | null = [absTs, absJs, distJs].find((p) => fs.existsSync(p)) ?? null;
    if (!modulePath) {
      try {
        // Резервный относительный require
        modulePath = require.resolve(`../${agentName}/agent`);
      } catch {
        // Игнорируем отсутствие файла (например, в изолированном тестовом окружении)
        continue;
      }
    }

    try {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const agentMod: any = require(modulePath);
      if (agentMod && agentMod.manifest) {
        registry[agentName] = agentMod.manifest;
      }
    } catch (err) {
      // Файл агента существует, но его загрузка упала — не глотаем ошибку молча
      const errMsg = err instanceof Error ? err.message : String(err);
      console.warn(`[agent-registry] Hoiatus: agendi "${agentName}" laadimine ebaõnnestus (${modulePath}): ${errMsg}`);
    }
  }

  if (overrides) {
    Object.assign(registry, overrides);
  }

  return registry;
}

import * as fs from 'fs';
import * as path from 'path';
import { ApiClient } from './api_client';
import { OrchestratorState } from '../orchestrator/orchestrator.schemas';
import { resolveAiTaskRootDir } from '../orchestrator/state.manager';

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
}

/**
 * Известные статические поддиректории агентов (базовый набор)
 */
export const KNOWN_SUBAGENTS = [
  'saldoandmik',
  'calc_arv_jaak',
  'getEarved',
  'sendFinBitReport',
  'lisa1_lisa5',
  'schedule_monitor',
];

/**
 * Строит реестр манифестов агентов.
 * Поддерживает как прямую передачу словаря манифестов (для тестов),
 * так и динамическое сканирование каталогов модулей агентов.
 */
export function buildAgentRegistry(
  rootDir?: string,
  overrides?: Record<string, AgentManifest>
): Record<string, AgentManifest> {
  const registry: Record<string, AgentManifest> = {};
  const root = resolveAiTaskRootDir(rootDir);

  // Собираем список каталогов для поиска агентов:
  const candidateDirs = new Set<string>(KNOWN_SUBAGENTS);
  if (fs.existsSync(root)) {
    try {
      const entries = fs.readdirSync(root, { withFileTypes: true });
      for (const entry of entries) {
        if (
          entry.isDirectory() &&
          !entry.name.startsWith('.') &&
          entry.name !== 'node_modules' &&
          entry.name !== 'dist' &&
          entry.name !== 'state' &&
          entry.name !== 'shared' &&
          entry.name !== 'logs_watcher'
        ) {
          candidateDirs.add(entry.name);
        }
      }
    } catch {
      // Игнорируем ошибки доступа к файловой системе
    }
  }

  for (const agentName of candidateDirs) {
    try {
      const absTs = path.join(root, agentName, 'agent.ts');
      const absJs = path.join(root, agentName, 'agent.js');
      const distJs = path.join(root, 'dist', agentName, 'agent.js');

      let agentMod: any = null;
      if (fs.existsSync(absTs)) {
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        agentMod = require(absTs);
      } else if (fs.existsSync(absJs)) {
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        agentMod = require(absJs);
      } else if (fs.existsSync(distJs)) {
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        agentMod = require(distJs);
      } else {
        // Резервный относительный require
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        agentMod = require(`../${agentName}/agent`);
      }

      if (agentMod && agentMod.manifest) {
        registry[agentName] = agentMod.manifest;
      }
    } catch {
      // Игнорируем отсутствие файла (например, в изолированном тестовом окружении)
    }
  }

  if (overrides) {
    Object.assign(registry, overrides);
  }

  return registry;
}

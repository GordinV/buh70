import { z } from 'zod';
import { AsyncTaskStartResponseSchema } from '../shared/types';

export const TASK_FLOW_GET_EARVED = 'docs.sp_loe_earved';

/**
 * Возвращает дату за вчерашний день в локальном формате YYYY-MM-DD
 */
export function getDefaultDateQueryFrom(date: Date = new Date()): string {
  const d = new Date(date);
  d.setDate(d.getDate() - 1);
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * Расписание запуска субагента getEarved по умолчанию
 */
export const DEFAULT_GET_EARVED_SCHEDULE = {
  time: '12:30',
} as const;

/**
 * Входные параметры для запуска импорта счетов FinBit
 */
export const StartGetEarvedInputSchema = z.object({
  userId: z.number().optional().default(2477).describe('ID пользователя (Earved robot)'),
  rekvId: z.number().optional().default(63).describe('ID учреждения'),
  dateQueryFrom: z
    .string()
    .optional()
    .default(() => getDefaultDateQueryFrom())
    .describe('Дата выборки счетов из FinBit в формате YYYY-MM-DD (по умолчанию текущая дата минус 1 день)'),
  schedule: z
    .object({
      time: z.string().default('12:30').describe('Время ежедневного запуска (HH:mm)'),
      day: z.number().int().min(1).max(31).optional().describe('День месяца (1-31)'),
      month: z.number().int().min(1).max(12).optional().describe('Месяц (1-12)'),
    })
    .optional()
    .default(DEFAULT_GET_EARVED_SCHEDULE)
    .describe('Индивидуальное расписание запуска агента (по умолчанию 12:30)'),
});

/**
 * Схема ответа бэкенда при вызове POST /task/getEarved/
 */
export const StartGetEarvedResponseSchema = AsyncTaskStartResponseSchema;

/**
 * Агрегированный результат работы субагента импорта счетов FinBit
 */
export const GetEarvedResultSchema = z.object({
  flow: z.string(),
  logId: z.number(),
  status: z.enum(['success', 'failed', 'timeout']),
  execStart: z.string().optional(),
  execEnd: z.string().optional(),
  durationMs: z.number().optional(),
  error: z.string().optional(),
});

export type StartGetEarvedInput = z.input<typeof StartGetEarvedInputSchema>;
export type StartGetEarvedResponse = z.infer<typeof StartGetEarvedResponseSchema>;
export type GetEarvedResult = z.infer<typeof GetEarvedResultSchema>;

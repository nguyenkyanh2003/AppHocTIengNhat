import { z } from 'zod';

import { DATE_KEY, GOAL_TYPES } from '../../../model/LearningGoal.js';
import { objectId } from '../../shared/http/schemas.js';

export const TITLE_MAX = 120;
export const TARGET_MAX = 100000;

const target = z
  .number({ error: 'Số cần đạt phải là số nguyên dương.' })
  .int('Số cần đạt phải là số nguyên dương.')
  .min(1, 'Số cần đạt phải là số nguyên dương.')
  .max(TARGET_MAX);

/** Ngày có thật trên lịch, dạng YYYY-MM-DD (2026-02-30 bị từ chối). */
const deadline = z
  .string()
  .regex(DATE_KEY, 'Hạn phải có dạng YYYY-MM-DD.')
  .refine((value) => {
    const date = new Date(`${value}T00:00:00Z`);
    return !Number.isNaN(date.getTime()) && date.toISOString().startsWith(value);
  }, 'Hạn không phải một ngày có thật.');

export const idParams = z.object({ id: objectId });

/** `strict`: trường lạ (kể cả `current_value` của bản mẫu cũ) là 400, không bị lờ đi. */
export const createBody = z.strictObject({
  type: z.enum(GOAL_TYPES),
  target,
  // Tên trống coi như không đặt; service tự đặt "Đạt N từ vựng".
  title: z.string().trim().max(TITLE_MAX).optional().transform((value) => value || undefined),
  deadline: deadline.nullable().default(null),
});

/** Không đổi được `type`: tiến độ của loại cũ sẽ mất nghĩa. */
export const updateBody = z
  .strictObject({
    title: z.string().trim().min(1, 'Vui lòng nhập tên mục tiêu.').max(TITLE_MAX).optional(),
    target: target.optional(),
    deadline: deadline.nullable().optional(),
  })
  .refine((changes) => Object.keys(changes).length > 0, 'Không có gì để cập nhật.');

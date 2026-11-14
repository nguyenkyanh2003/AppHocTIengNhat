import { z } from 'zod';

/** Khớp enum trong `model/User.js` (`settings.language`, `settings.theme`). */
export const LANGUAGES = ['vi', 'en', 'ja'];
export const THEMES = ['light', 'dark', 'auto'];

/**
 * Lưu là ghi **đủ** năm cài đặt; thiếu trường là 400. Trước đây trường thiếu
 * bị đặt lại về mặc định, nên một client gửi thiếu sẽ xoá mất lựa chọn cũ.
 */
export const settingsBody = z.object({
  notificationsEnabled: z.boolean(),
  soundEnabled: z.boolean(),
  vibrateEnabled: z.boolean(),
  language: z.enum(LANGUAGES),
  theme: z.enum(THEMES),
});

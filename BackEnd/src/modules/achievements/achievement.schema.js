import { z } from 'zod';

const CATEGORIES = ['vocabulary', 'grammar', 'kanji', 'lesson', 'streak', 'xp', 'practice'];
const REQUIREMENT_TYPES = ['count', 'streak', 'xp', 'completion'];
const RARITIES = ['common', 'rare', 'epic', 'legendary'];

const text = z.string().trim().min(1);

export const categoryParams = z.object({ category: z.enum(CATEGORIES) });

export const idParams = z.object({ id: z.string().regex(/^[a-f0-9]{24}$/i, 'ID không hợp lệ.') });

/**
 * Định nghĩa huy hiệu do admin nhập. Ngưỡng và XP là số nguyên dương có trần:
 * chúng đi thẳng vào phép xét tiêu chí và vào XP ghi vĩnh viễn vào lịch sử.
 */
const definition = {
  name: text,
  name_vi: text,
  description: text,
  description_vi: text,
  icon: text,
  category: z.enum(CATEGORIES),
  requirement_type: z.enum(REQUIREMENT_TYPES),
  requirement_value: z.coerce.number().int().min(1).max(1_000_000),
  xp_reward: z.coerce.number().int().min(0).max(100_000),
  rarity: z.enum(RARITIES),
  is_active: z.boolean(),
};

export const createBody = z.object({
  ...definition,
  xp_reward: definition.xp_reward.default(100),
  rarity: definition.rarity.default('common'),
  is_active: definition.is_active.default(true),
});

export const updateBody = z.object(definition).partial();

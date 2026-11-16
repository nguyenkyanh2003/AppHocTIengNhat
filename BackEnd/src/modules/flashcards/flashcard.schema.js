import { z } from 'zod';

import { paginationQuery } from '../../shared/http/pagination.js';
import { objectId } from '../../shared/http/schemas.js';

/** Khớp enum trong `model/FlashcardDeck.js`. */
export const DECK_CATEGORIES = ['vocabulary', 'kanji', 'grammar', 'custom', 'other'];
export const DECK_LEVELS = ['N5', 'N4', 'N3', 'N2', 'N1', 'beginner', 'intermediate', 'advanced', 'other'];

const required = (label, max) => z.string().trim().min(1, `Vui lòng nhập ${label}.`).max(max);

/** Phụ đề gửi `null` nghĩa là xoá phụ đề đang có. */
const subtext = z.string().trim().max(300).nullable();

const deckFields = {
  title: required('tiêu đề bộ thẻ', 100),
  description: z.string().trim().max(300),
  is_public: z.boolean(),
  category: z.enum(DECK_CATEGORIES),
  level: z.enum(DECK_LEVELS),
};

const cardFields = {
  front: required('mặt trước', 200),
  back: required('mặt sau', 200),
  front_subtext: subtext,
  back_subtext: subtext,
};

const nonEmpty = (schema) => schema.refine((changes) => Object.keys(changes).length > 0, 'Không có gì để cập nhật.');

export const listQuery = paginationQuery;

export const deckParams = z.object({ id: objectId });

export const cardParams = z.object({ deckId: objectId, cardId: objectId });

/** Chủ bộ thẻ do server đặt; trường lạ trong body (kể cả `user`) bị bỏ. */
export const createDeckBody = z.object({
  title: deckFields.title,
  description: deckFields.description.optional(),
  is_public: deckFields.is_public.default(false),
  category: deckFields.category.default('custom'),
  level: deckFields.level.optional(),
});

/** Sửa chỉ ghi trường được gửi, nên không có `.default()` ở đây. */
export const updateDeckBody = nonEmpty(z.object(deckFields).partial());

export const cardBody = z.object({
  front: cardFields.front,
  back: cardFields.back,
  front_subtext: cardFields.front_subtext.optional(),
  back_subtext: cardFields.back_subtext.optional(),
});

export const updateCardBody = nonEmpty(z.object(cardFields).partial());

import { ApiError } from '../../shared/http/api-error.js';
import { toSkip } from '../../shared/http/pagination.js';
import { flashcardRepository } from './flashcard.repository.js';

/** Bộ riêng của người khác cũng là "không tìm thấy": không lộ việc id đó có tồn tại. */
const deckNotFound = () => ApiError.notFound('Không tìm thấy bộ thẻ.');

const found = (deck) => {
  if (!deck) throw deckNotFound();
  return deck;
};

/**
 * Bộ thẻ tự tạo kiểu Quizlet: chỉ chủ bộ được sửa; bộ công khai thì ai cũng
 * xem và học được.
 */
export const createFlashcardService = ({ repository }) => {
  /** Lệnh trên thẻ không khớp gì: báo đúng là thiếu bộ hay thiếu thẻ. */
  const cardMissing = async ({ deckId, userId }) => {
    if (!(await repository.findOwned({ id: deckId, userId }))) throw deckNotFound();
    throw ApiError.notFound('Không tìm thấy thẻ.');
  };

  return {
    async listMine({ userId, page, limit }) {
      const filter = { user: userId };
      const [items, total] = await Promise.all([
        repository.findPage({ filter, skip: toSkip({ page, limit }), limit }),
        repository.count(filter),
      ]);
      return { items, total, page, limit };
    },

    async detail({ userId, id }) {
      return found(await repository.findVisible({ id, userId }));
    },

    createDeck({ userId, input }) {
      return repository.create({ ...input, user: userId });
    },

    async updateDeck({ userId, id, changes }) {
      return found(await repository.updateOwned({ id, userId, set: changes }));
    },

    async removeDeck({ userId, id }) {
      found(await repository.deleteOwned({ id, userId }));
    },

    async addCard({ userId, deckId, card }) {
      return found(await repository.pushCard({ id: deckId, userId, card }));
    },

    async updateCard({ userId, deckId, cardId, changes }) {
      return (await repository.updateCard({ id: deckId, userId, cardId, changes })) ?? cardMissing({ deckId, userId });
    },

    async removeCard({ userId, deckId, cardId }) {
      return (await repository.pullCard({ id: deckId, userId, cardId })) ?? cardMissing({ deckId, userId });
    },

    async recordStudy({ userId, id }) {
      const { study_count: studyCount } = found(await repository.countStudy({ id, userId }));
      return { study_count: studyCount };
    },
  };
};

export const flashcardService = createFlashcardService({ repository: flashcardRepository });

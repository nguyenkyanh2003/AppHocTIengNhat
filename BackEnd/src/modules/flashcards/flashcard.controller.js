import { created, ok, paginated } from '../../shared/http/respond.js';

/**
 * Chủ bộ thẻ luôn lấy từ phiên đăng nhập (`req.user`), không bao giờ từ body.
 * Thao tác trên thẻ trả lại cả bộ sau khi đổi để màn chi tiết vẽ lại một lần.
 */
export const createFlashcardController = (service) => {
  const deckKey = (req) => ({ userId: req.user._id, id: req.valid.params.id });
  const cardKey = (req) => ({ userId: req.user._id, ...req.valid.params });

  return {
    async listMine(req, res) {
      return paginated(res, await service.listMine({ userId: req.user._id, ...req.valid.query }));
    },

    async detail(req, res) {
      return ok(res, await service.detail(deckKey(req)));
    },

    async createDeck(req, res) {
      const deck = await service.createDeck({ userId: req.user._id, input: req.valid.body });
      return created(res, deck, { message: 'Tạo bộ thẻ thành công.' });
    },

    async updateDeck(req, res) {
      const deck = await service.updateDeck({ ...deckKey(req), changes: req.valid.body });
      return ok(res, deck, { message: 'Cập nhật bộ thẻ thành công.' });
    },

    async removeDeck(req, res) {
      await service.removeDeck(deckKey(req));
      return ok(res, { deleted: true }, { message: 'Xóa bộ thẻ thành công.' });
    },

    async addCard(req, res) {
      const deck = await service.addCard({ userId: req.user._id, deckId: req.valid.params.id, card: req.valid.body });
      return created(res, deck, { message: 'Thêm thẻ thành công.' });
    },

    async updateCard(req, res) {
      const deck = await service.updateCard({ ...cardKey(req), changes: req.valid.body });
      return ok(res, deck, { message: 'Cập nhật thẻ thành công.' });
    },

    async removeCard(req, res) {
      return ok(res, await service.removeCard(cardKey(req)), { message: 'Xóa thẻ thành công.' });
    },

    async recordStudy(req, res) {
      return ok(res, await service.recordStudy(deckKey(req)));
    },
  };
};

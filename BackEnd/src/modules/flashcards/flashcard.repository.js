import FlashcardDeck from '../../../model/FlashcardDeck.js';

const RECENT_FIRST = { updated_at: -1, _id: -1 };
const AFTER_UPDATE = { new: true, runValidators: true };

/** Bộ thẻ người dùng sửa được: chỉ bộ của chính họ. */
const owned = ({ id, userId }) => ({ _id: id, user: userId });

/** Bộ thẻ người dùng xem được: của mình, hoặc bộ người khác để công khai. */
const visible = ({ id, userId }) => ({ _id: id, $or: [{ user: userId }, { is_public: true }] });

/** Mọi truy vấn Mongoose của bộ thẻ. Thẻ là mảng con, sửa bằng lệnh nguyên tử trên cả bộ. */
export const createFlashcardRepository = ({ FlashcardDeck: model }) => ({
  findPage({ filter, skip, limit }) {
    return model.find(filter).sort(RECENT_FIRST).skip(skip).limit(limit).lean();
  },

  count(filter) {
    return model.countDocuments(filter);
  },

  findVisible(key) {
    return model.findOne(visible(key)).lean();
  },

  findOwned(key) {
    return model.findOne(owned(key)).lean();
  },

  async create(doc) {
    return (await model.create(doc)).toObject();
  },

  updateOwned({ set, ...key }) {
    return model.findOneAndUpdate(owned(key), { $set: set }, AFTER_UPDATE).lean();
  },

  deleteOwned(key) {
    return model.findOneAndDelete(owned(key)).lean();
  },

  /** `total_cards` tăng cùng lệnh thêm thẻ, nên không lệch dù hai lần thêm chạy cùng lúc. */
  pushCard({ card, ...key }) {
    return model
      .findOneAndUpdate(owned(key), { $push: { cards: card }, $inc: { total_cards: 1 } }, AFTER_UPDATE)
      .lean();
  },

  /** `null` khi bộ không phải của người dùng hoặc không có thẻ đó. */
  updateCard({ cardId, changes, ...key }) {
    const set = Object.fromEntries(Object.entries(changes).map(([field, value]) => [`cards.$.${field}`, value]));
    return model.findOneAndUpdate({ ...owned(key), 'cards._id': cardId }, { $set: set }, AFTER_UPDATE).lean();
  },

  pullCard({ cardId, ...key }) {
    return model
      .findOneAndUpdate(
        { ...owned(key), 'cards._id': cardId },
        { $pull: { cards: { _id: cardId } }, $inc: { total_cards: -1 } },
        { new: true },
      )
      .lean();
  },

  countStudy(key) {
    return model
      .findOneAndUpdate(visible(key), { $inc: { study_count: 1 } }, { new: true })
      .select('study_count')
      .lean();
  },
});

export const flashcardRepository = createFlashcardRepository({ FlashcardDeck });

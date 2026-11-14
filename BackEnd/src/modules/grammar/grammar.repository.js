import Grammar from '../../../model/Grammar.js';

const LESSON_FIELDS = 'title level';
const RELATED_FIELDS = 'title structure level';

/** Mọi truy vấn Mongoose của ngữ pháp. */
export const createGrammarRepository = ({ Grammar: model }) => ({
  findPage({ filter, sort, skip, limit }) {
    return model.find(filter).populate('lesson_id', LESSON_FIELDS).sort(sort).skip(skip).limit(limit).lean();
  },

  count(filter) {
    return model.countDocuments(filter);
  },

  /**
   * Đọc chi tiết một ngữ pháp đang hoạt động và cộng một lượt xem trong cùng
   * một lệnh: hai người mở cùng lúc không làm mất lượt nào.
   */
  findActiveAndCountView(id) {
    return model
      .findOneAndUpdate({ _id: id, is_active: true }, { $inc: { view_count: 1 } }, { new: true })
      .populate('lesson_id', LESSON_FIELDS)
      .populate('related_grammar', RELATED_FIELDS)
      .lean();
  },

  /** Bật lại bản đã xoá mềm có đúng khoá tự nhiên `(level, title)`, ghi nội dung mới. */
  reviveInactive({ level, title, set }) {
    return model
      .findOneAndUpdate({ level, title, is_active: false }, { $set: { ...set, is_active: true } }, { new: true, runValidators: true })
      .lean();
  },

  async create(doc) {
    return (await model.create(doc)).toObject();
  },

  updateById({ id, set }) {
    return model.findByIdAndUpdate(id, { $set: set }, { new: true, runValidators: true }).lean();
  },

  deactivate(id) {
    return model.findByIdAndUpdate(id, { $set: { is_active: false } }, { new: true }).lean();
  },
});

export const grammarRepository = createGrammarRepository({ Grammar });

import News from '../../../model/News.js';

/** `_id` đi kèm để các bài cùng thời điểm luôn ra cùng một thứ tự giữa các trang. */
const NEWEST_FIRST = { createdAt: -1, _id: -1 };

/** Mọi truy vấn Mongoose của tin tức. */
export const createNewsRepository = ({ News: model }) => ({
  findPage({ filter, skip, limit }) {
    return model.find(filter).sort(NEWEST_FIRST).skip(skip).limit(limit).lean();
  },

  count(filter) {
    return model.countDocuments(filter);
  },

  /** Đọc một bài và cộng một lượt xem trong cùng một lệnh. */
  findAndCountView(id) {
    return model.findByIdAndUpdate(id, { $inc: { views: 1 } }, { new: true }).lean();
  },

  findLevel(id) {
    return model.findById(id).select('level').lean();
  },

  /** `level: null` khớp cả bài không có trường cấp độ. */
  findRelated({ excludeId, level, limit }) {
    return model.find({ _id: { $ne: excludeId }, level }).sort(NEWEST_FIRST).limit(limit).lean();
  },
});

export const newsRepository = createNewsRepository({ News });

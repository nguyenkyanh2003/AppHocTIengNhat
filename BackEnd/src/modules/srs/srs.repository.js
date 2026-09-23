import mongoose from 'mongoose';

import SRSProgress from '../../../model/SRSProgress.js';
import Vocabulary from '../../../model/Vocabulary.js';

/**
 * Truy cập dữ liệu tiến độ ôn tập.
 *
 * Các module khác (vocabulary, kanji) đi qua repository này thay vì tự query
 * `SRSProgress`, để hình dạng dữ liệu SRS chỉ được biết ở một chỗ. Ngoài
 * `SRSProgress`, repository chỉ đọc nội dung cần để vẽ hai mặt thẻ.
 *
 * Mọi truy vấn đều lọc theo `user`: không có hàm nào đọc hay ghi tiến độ chỉ
 * bằng `_id`, nên không đường nào chạm được thẻ của người khác.
 */

/** Nội dung mặt thẻ — đủ để vẽ, không kéo cả document. */
const CARD_FIELDS = 'word hiragana meaning hanviet level examples audio_url image_url usage_context';

const isDuplicateKey = (error) => error?.code === 11000;

/**
 * `aggregate` không ép kiểu như `find`: so `user` (ObjectId) với một chuỗi sẽ
 * không khớp dòng nào và thống kê ra toàn số 0, không lỗi gì.
 */
const toObjectId = (value) =>
  value instanceof mongoose.Types.ObjectId ? value : new mongoose.Types.ObjectId(String(value));

export const createSrsRepository = ({
  SRSProgress: model = SRSProgress,
  contentModels = { Vocabulary },
} = {}) => {
  const contentModel = (itemType) => {
    const content = contentModels[itemType];
    if (!content) throw new RangeError(`Chưa hỗ trợ nội dung SRS loại ${itemType}.`);
    return content;
  };

  const findProgress = ({ userId, itemId, itemType, session }) =>
    model.findOne({ user: userId, item_id: itemId, item_type: itemType }).session(session).lean();

  return {
    /** Danh sách id item mà user đã học, dạng chuỗi. */
    async findLearnedItemIds({ userId, itemType }) {
      const rows = await model
        .find({ user: userId, item_type: itemType })
        .select('item_id')
        .lean();

      return rows.map((row) => row.item_id.toString());
    },

    findProgress,

    /**
     * Tạo tiến độ nếu chưa có, trả tiến độ đã có nếu có — kể cả khi hai request
     * đánh dấu cùng lúc: bên thua unique index đọc lại đúng bản ghi bên thắng
     * vừa tạo thay vì báo lỗi (spec SRS §3.3).
     */
    async ensureProgress({ userId, itemId, itemType, initial }) {
      const existing = await findProgress({ userId, itemId, itemType });
      if (existing) return { progress: existing, created: false };

      try {
        const created = await model.create({
          user: userId,
          item_id: itemId,
          item_type: itemType,
          box: initial.box,
          next_review: initial.next_review,
          streak: initial.streak,
        });
        return { progress: created.toObject(), created: true };
      } catch (error) {
        if (!isDuplicateKey(error)) throw error;
        return { progress: await findProgress({ userId, itemId, itemType }), created: false };
      }
    },

    /**
     * Một đợt thẻ đến hạn, hạn sớm nhất trước.
     *
     * Loại trừ nằm **trong** truy vấn, trước sort/limit: lọc ở client sau khi
     * nhận thì N thẻ vừa bỏ qua có thể chiếm hết đợt và chặn mọi thẻ phía sau.
     * `_id` là khoá phụ để hai thẻ cùng hạn luôn ra cùng thứ tự (spec §3.4).
     */
    findDueBatch({ userId, itemType, now, excludeItemIds = [], limit }) {
      const filter = { user: userId, item_type: itemType, next_review: { $lte: now } };
      if (excludeItemIds.length > 0) filter.item_id = { $nin: excludeItemIds };

      return model.find(filter).sort({ next_review: 1, _id: 1 }).limit(limit).lean();
    },

    countDue({ userId, itemType, now }) {
      return model.countDocuments({ user: userId, item_type: itemType, next_review: { $lte: now } });
    },

    /** Số thẻ theo từng hộp, dạng `[{ _id: box, count }]`. */
    countByBox({ userId, itemType }) {
      return model.aggregate([
        { $match: { user: toObjectId(userId), item_type: itemType } },
        { $group: { _id: '$box', count: { $sum: 1 } } },
      ]);
    },

    /**
     * Ghi lịch mới **chỉ khi** thẻ vẫn đúng như lúc đọc. Trả `null` khi thua.
     *
     * So cả `box`, `streak` và `next_review` chứ không chỉ `_id`: đó là cách hai
     * lượt trả lời đồng thời, hay một lượt trả lời chạy đua với reset, không
     * thể cùng thắng. `dueBy` thêm điều kiện "vẫn đến hạn" cho lượt ôn; reset
     * không truyền vì reset được phép khi chưa đến hạn. Không upsert: thẻ vừa
     * bị xoá thì không được tạo lại ở đây (spec §3.5).
     */
    compareAndSet({ progress, expectedNextReview, dueBy, next, session }) {
      const filter = {
        _id: progress._id,
        user: progress.user,
        item_id: progress.item_id,
        item_type: progress.item_type,
        box: progress.box,
        streak: progress.streak,
        next_review: dueBy ? { $eq: expectedNextReview, $lte: dueBy } : expectedNextReview,
      };
      const update = {
        $set: { box: next.box, streak: next.streak, next_review: next.next_review },
      };

      return model.findOneAndUpdate(filter, update, {
        new: true,
        runValidators: true,
        lean: true,
        session,
      });
    },

    async deleteProgress({ userId, itemId, itemType }) {
      const result = await model.deleteOne({
        user: userId,
        item_id: itemId,
        item_type: itemType,
      });

      return result.deletedCount ?? 0;
    },

    /** Nội dung của nhiều thẻ trong **một** truy vấn, không `findById` trong vòng lặp. */
    async findContentByIds({ itemType, ids }) {
      if (ids.length === 0) return [];
      return contentModel(itemType).find({ _id: { $in: ids } }).select(CARD_FIELDS).lean();
    },

    async contentExists({ itemType, itemId, session }) {
      return Boolean(await contentModel(itemType).exists({ _id: itemId }).session(session));
    },
  };
};

export const srsRepository = createSrsRepository();

export default srsRepository;

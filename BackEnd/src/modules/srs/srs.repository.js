import SRSProgress from '../../../model/SRSProgress.js';

/**
 * Truy cập dữ liệu tiến độ ôn tập.
 *
 * Các module khác (vocabulary, kanji) đi qua repository này thay vì tự query
 * `SRSProgress`, để hình dạng dữ liệu SRS chỉ được biết ở một chỗ.
 */
export const createSrsRepository = ({ SRSProgress: model }) => ({
  /** Danh sách id item mà user đã học, dạng chuỗi. */
  async findLearnedItemIds({ userId, itemType }) {
    const rows = await model
      .find({ user: userId, item_type: itemType })
      .select('item_id')
      .lean();

    return rows.map((row) => row.item_id.toString());
  },

  findProgress({ userId, itemId, itemType }) {
    return model
      .findOne({ user: userId, item_id: itemId, item_type: itemType })
      .lean();
  },

  createProgress({ userId, itemId, itemType, box, nextReview, streak }) {
    return model.create({
      user: userId,
      item_id: itemId,
      item_type: itemType,
      box,
      next_review: nextReview,
      streak,
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
});

export const srsRepository = createSrsRepository({ SRSProgress });

export default srsRepository;

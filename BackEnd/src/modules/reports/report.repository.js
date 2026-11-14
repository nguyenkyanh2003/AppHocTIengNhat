import Report from '../../../model/Report.js';

/** Người gửi hiện trên màn quản trị (tên field tiếng Việt của model `User`). */
const USER_FIELDS = 'HoTen Email TenDangNhap';
const NEWEST_FIRST = { createdAt: -1, _id: -1 };

const countBy = (model, field) => model.aggregate([{ $group: { _id: `$${field}`, count: { $sum: 1 } } }]);

/** Mọi truy vấn Mongoose của báo cáo. */
export const createReportRepository = ({ Report: model }) => ({
  async create(doc) {
    return (await model.create(doc)).toObject();
  },

  findPage({ filter, skip, limit, withUser }) {
    const query = model.find(filter).sort(NEWEST_FIRST).skip(skip).limit(limit);
    return (withUser ? query.populate('user_id', USER_FIELDS) : query).lean();
  },

  count(filter) {
    return model.countDocuments(filter);
  },

  updateStatus({ id, set }) {
    return model
      .findByIdAndUpdate(id, { $set: set }, { new: true, runValidators: true })
      .populate('user_id', USER_FIELDS)
      .lean();
  },

  deleteById(id) {
    return model.findByIdAndDelete(id).lean();
  },

  /** Đếm theo trạng thái/loại/mức ưu tiên, 10 báo cáo mới nhất và thời gian xử lý trung bình (ms). */
  async stats() {
    const [total, byStatus, byType, byPriority, recentReports, resolution] = await Promise.all([
      model.countDocuments(),
      countBy(model, 'status'),
      countBy(model, 'type'),
      countBy(model, 'priority'),
      model.find().populate('user_id', USER_FIELDS).sort(NEWEST_FIRST).limit(10).lean(),
      model.aggregate([
        { $match: { status: 'resolved', resolved_at: { $ne: null } } },
        { $group: { _id: null, avgMs: { $avg: { $subtract: ['$resolved_at', '$createdAt'] } } } },
      ]),
    ]);
    return { total, byStatus, byType, byPriority, recentReports, avgResolutionMs: resolution[0]?.avgMs ?? null };
  },
});

export const reportRepository = createReportRepository({ Report });

import Transaction from '../../../model/Transaction.js';

/** Người giao dịch hiện trên màn quản trị (tên field tiếng Việt của model `User`). */
const USER_FIELDS = 'HoTen Email TenDangNhap';
const NEWEST_FIRST = { createdAt: -1, _id: -1 };

/** Mọi truy vấn Mongoose của giao dịch. */
export const createTransactionRepository = ({ Transaction: model }) => ({
  async create(doc) {
    return (await model.create(doc)).toObject();
  },

  findPage({ filter, skip, limit }) {
    return model.find(filter).populate('user', USER_FIELDS).sort(NEWEST_FIRST).skip(skip).limit(limit).lean();
  },

  count(filter) {
    return model.countDocuments(filter);
  },

  updateStatus({ id, set }) {
    return model
      .findByIdAndUpdate(id, { $set: set }, { new: true, runValidators: true })
      .populate('user', USER_FIELDS)
      .lean();
  },
});

export const transactionRepository = createTransactionRepository({ Transaction });

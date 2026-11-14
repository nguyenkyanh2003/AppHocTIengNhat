import NoteBook from '../../../model/NoteBook.js';

const NEWEST_FIRST = { createdAt: -1, _id: -1 };

/** Ghi chú luôn được tìm theo cặp (id, chủ sở hữu): không ai đọc hay sửa được sổ tay của người khác. */
const owned = ({ id, userId }) => ({ _id: id, user_id: userId });

/** Mọi truy vấn Mongoose của sổ tay. */
export const createNotebookRepository = ({ NoteBook: model }) => ({
  findPage({ filter, skip, limit }) {
    return model.find(filter).sort(NEWEST_FIRST).skip(skip).limit(limit).lean();
  },

  count(filter) {
    return model.countDocuments(filter);
  },

  findOwned(key) {
    return model.findOne(owned(key)).lean();
  },

  async create(doc) {
    return (await model.create(doc)).toObject();
  },

  updateOwned({ set, ...key }) {
    return model.findOneAndUpdate(owned(key), { $set: set }, { new: true, runValidators: true }).lean();
  },

  deleteOwned(key) {
    return model.findOneAndDelete(owned(key)).lean();
  },
});

export const notebookRepository = createNotebookRepository({ NoteBook });

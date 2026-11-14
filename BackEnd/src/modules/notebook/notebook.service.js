import { ApiError } from '../../shared/http/api-error.js';
import { toSkip } from '../../shared/http/pagination.js';
import { escapeRegExp } from '../../shared/utils/regexp.js';
import { notebookRepository } from './notebook.repository.js';

const SEARCHED_FIELDS = ['title', 'content'];

/** Ghi chú của người khác cũng là "không tìm thấy": không lộ việc id đó có tồn tại. */
const found = (note) => {
  if (!note) throw ApiError.notFound('Không tìm thấy ghi chú.');
  return note;
};

export const createNotebookService = ({ repository }) => ({
  /** Từ khoá khớp nguyên văn, không phân biệt hoa thường: `C++` không thành biểu thức. */
  async list({ userId, page, limit, type, search }) {
    const pattern = search && { $regex: escapeRegExp(search), $options: 'i' };
    const filter = {
      user_id: userId,
      ...(type && { type }),
      ...(pattern && { $or: SEARCHED_FIELDS.map((field) => ({ [field]: pattern })) }),
    };
    const [items, total] = await Promise.all([
      repository.findPage({ filter, skip: toSkip({ page, limit }), limit }),
      repository.count(filter),
    ]);
    return { items, total, page, limit };
  },

  async detail({ userId, id }) {
    return found(await repository.findOwned({ id, userId }));
  },

  create({ userId, input }) {
    return repository.create({ ...input, user_id: userId });
  },

  async update({ userId, id, changes }) {
    return found(await repository.updateOwned({ id, userId, set: changes }));
  },

  async remove({ userId, id }) {
    found(await repository.deleteOwned({ id, userId }));
  },
});

export const notebookService = createNotebookService({ repository: notebookRepository });

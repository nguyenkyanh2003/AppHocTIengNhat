import { isDuplicateKeyError } from '../../shared/db/duplicate-key.js';
import { ApiError } from '../../shared/http/api-error.js';
import { toSkip } from '../../shared/http/pagination.js';
import { withoutUndefined } from '../../shared/utils/object.js';
import { grammarRepository } from './grammar.repository.js';

/** `_id` đi kèm để hai ngữ pháp cùng tiêu đề/lượt xem luôn ra cùng một thứ tự giữa các trang. */
const SORTS = Object.freeze({
  title: { title: 1, _id: 1 },
  popular: { view_count: -1, _id: 1 },
  newest: { createdAt: -1, _id: -1 },
});

/**
 * Body của form quản trị dùng `lessonID` và `relatedGrammar`; model dùng
 * `lesson_id` và `related_grammar`. Trường không gửi bị bỏ hẳn: `$set` một giá
 * trị `undefined` là ghi đè nội dung cũ bằng khoảng trống.
 */
const toDocument = ({ lessonID, relatedGrammar, ...fields }) =>
  withoutUndefined({ ...fields, lesson_id: lessonID, related_grammar: relatedGrammar });

const NOT_FOUND = 'Ngữ pháp không tồn tại.';

/**
 * Khoá tự nhiên `(level, title)` là unique, và xoá chỉ là xoá mềm — nên bản đã
 * xoá vẫn giữ khoá. Trùng khoá là lỗi của người nhập (409), không phải lỗi máy chủ.
 */
const rethrowDuplicate = (error, message) => {
  if (isDuplicateKeyError(error)) throw ApiError.conflict(message, { code: 'DUPLICATE_GRAMMAR' });
  throw error;
};

export const createGrammarService = ({ repository }) => ({
  async list({ page, limit, level, search, sortBy = 'title' }) {
    const filter = {
      is_active: true,
      ...(level && { level }),
      ...(search && { $text: { $search: search } }),
    };
    const [items, total] = await Promise.all([
      repository.findPage({ filter, sort: SORTS[sortBy], skip: toSkip({ page, limit }), limit }),
      repository.count(filter),
    ]);
    return { items, total, page, limit };
  },

  async getDetail(id) {
    const grammar = await repository.findActiveAndCountView(id);
    if (!grammar) throw ApiError.notFound(NOT_FOUND);
    return grammar;
  },

  /**
   * Thêm mới; đúng khoá tự nhiên đang có một bản **đã xoá mềm** thì khôi phục bản
   * đó với nội dung mới. Không có nhánh này thì admin xoá một ngữ pháp rồi thêm
   * lại đúng tên đó sẽ bị chặn mãi, vì màn quản trị không hiện bản đã xoá. Khôi
   * phục giữ nguyên `_id`, nên tiến độ học đang trỏ vào ngữ pháp này nối lại đúng chỗ.
   */
  async create(input) {
    const document = toDocument(input);
    try {
      const revived = await repository.reviveInactive({ level: document.level, title: document.title, set: document });
      if (revived) return { grammar: revived, revived: true };
      return { grammar: await repository.create(document), revived: false };
    } catch (error) {
      return rethrowDuplicate(error, `Cấp ${document.level} đã có ngữ pháp "${document.title}". Hãy đặt tiêu đề khác.`);
    }
  },

  async update(id, changes) {
    try {
      const grammar = await repository.updateById({ id, set: toDocument(changes) });
      if (!grammar) throw ApiError.notFound(NOT_FOUND);
      return grammar;
    } catch (error) {
      return rethrowDuplicate(error, 'Cấp độ này đã có ngữ pháp khác cùng tiêu đề (kể cả bản đã xoá). Hãy đặt tiêu đề khác.');
    }
  },

  async remove(id) {
    const grammar = await repository.deactivate(id);
    if (!grammar) throw ApiError.notFound(NOT_FOUND);
  },
});

export const grammarService = createGrammarService({ repository: grammarRepository });

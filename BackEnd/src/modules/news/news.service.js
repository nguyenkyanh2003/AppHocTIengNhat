import { ApiError } from '../../shared/http/api-error.js';
import { toSkip } from '../../shared/http/pagination.js';
import { escapeRegExp } from '../../shared/utils/regexp.js';
import { newsRepository } from './news.repository.js';

const SEARCHED_FIELDS = ['title', 'description', 'content_html'];

const notFound = () => ApiError.notFound('Không tìm thấy tin tức.');

export const createNewsService = ({ repository }) => ({
  /** Từ khoá khớp nguyên văn, không phân biệt hoa thường: `C++` không thành biểu thức. */
  async list({ page, limit, level, search }) {
    const pattern = search && { $regex: escapeRegExp(search), $options: 'i' };
    const filter = {
      ...(level && { level }),
      ...(pattern && { $or: SEARCHED_FIELDS.map((field) => ({ [field]: pattern })) }),
    };
    const [items, total] = await Promise.all([
      repository.findPage({ filter, skip: toSkip({ page, limit }), limit }),
      repository.count(filter),
    ]);
    return { items, total, page, limit };
  },

  async getDetail(id) {
    const news = await repository.findAndCountView(id);
    if (!news) throw notFound();
    return news;
  },

  /** Bài mới nhất cùng cấp độ với bài đang đọc, trừ chính nó. */
  async related({ id, limit }) {
    const current = await repository.findLevel(id);
    if (!current) throw notFound();
    return repository.findRelated({ excludeId: id, level: current.level ?? null, limit });
  },
});

export const newsService = createNewsService({ repository: newsRepository });

import { MATCH, keywordPattern, matchKind, normalizeKeyword, readingPattern } from './search-match.js';
import { searchRepository } from './search.repository.js';

const LEVELS = ['N5', 'N4', 'N3', 'N2', 'N1'];

/** Trường âm Kun lưu kèm okurigana (`た(べる)`). */
const OKURIGANA_FIELDS = new Set(['kunyomi']);

/**
 * Năm nhóm nội dung theo thứ tự trả về. `groups` là các trường được tìm, chia
 * ba bậc ưu tiên: trường chính (từ, chữ, tiêu đề) → cách đọc/cấu trúc → nghĩa,
 * mô tả. `toResult` chọn trường hiển thị cho dạng kết quả chung.
 */
const TYPES = [
  {
    type: 'vocabulary',
    groups: [['word'], ['hiragana', 'hanviet'], ['meaning']],
    toResult: (doc) => ({ title: doc.word, subtitle: doc.hiragana, description: doc.meaning, image_url: doc.image_url }),
  },
  {
    type: 'kanji',
    groups: [['character'], ['hanviet', 'onyomi', 'kunyomi'], ['meaning']],
    toResult: (doc) => ({ title: doc.character, subtitle: doc.hanviet, description: doc.meaning }),
  },
  {
    type: 'lesson',
    groups: [['title'], [], ['description']],
    toResult: (doc) => ({ title: doc.title, description: doc.description }),
  },
  {
    type: 'grammar',
    groups: [['title'], ['structure'], ['meaning']],
    // Ngữ pháp bị ẩn (xoá mềm) không được hiện ra ở đâu, kể cả kết quả tìm kiếm.
    filter: { is_active: true },
    toResult: (doc) => ({ title: doc.title, subtitle: doc.structure, description: doc.meaning }),
  },
  {
    type: 'news',
    groups: [['title'], [], ['description']],
    toResult: (doc) => ({ title: doc.title, description: doc.description, image_url: doc.image_url }),
  },
];

/** Các trường được tìm của từng nhóm — test đối chiếu với model để không tìm trên trường không tồn tại. */
export const SEARCH_FIELDS = Object.freeze(
  Object.fromEntries(TYPES.map((spec) => [spec.type, spec.groups.flat()])),
);

const filterFor = (spec, keyword) => {
  const plain = keywordPattern(keyword);
  const reading = readingPattern(keyword);
  return {
    ...spec.filter,
    $or: spec.groups.flat().map((field) => ({ [field]: OKURIGANA_FIELDS.has(field) ? reading : plain })),
  };
};

/**
 * Điểm liên quan, nhỏ hơn là tốt hơn: mức khớp (trọn → đầu chuỗi → chứa) quyết
 * định trước, bậc trường quyết định sau. Bản ghi MongoDB đã khớp mà không tính
 * được mức khớp vẫn được giữ, xếp cuối.
 */
const scoreOf = (doc, spec, keyword) => {
  const groupCount = spec.groups.length;
  let best = MATCH.CONTAINS * groupCount + groupCount - 1;
  spec.groups.forEach((fields, group) => {
    for (const field of fields) {
      const kind = matchKind(doc[field], keyword);
      if (kind !== null) best = Math.min(best, kind * groupCount + group);
    }
  });
  return best;
};

const levelRank = (level) => {
  const index = LEVELS.indexOf(level);
  return index === -1 ? LEVELS.length : index;
};

/** Hoà điểm thì chữ ngắn hơn (月 trước 月曜日), rồi cấp dễ hơn, rồi thứ tự gốc. */
const rank = (docs, spec, keyword) => {
  const primary = spec.groups[0][0];
  return docs
    .map((doc, index) => ({
      doc,
      index,
      score: scoreOf(doc, spec, keyword),
      length: String(doc[primary] ?? '').length,
      level: levelRank(doc.level),
    }))
    .sort((a, b) => a.score - b.score || a.length - b.length || a.level - b.level || a.index - b.index)
    .map((entry) => entry.doc);
};

const toResult = (spec, doc) => {
  const shown = spec.toResult(doc);
  return {
    id: String(doc._id),
    type: spec.type,
    title: shown.title ?? '',
    subtitle: shown.subtitle ?? null,
    description: shown.description ?? null,
    image_url: shown.image_url ?? null,
    level: doc.level ?? null,
  };
};

/**
 * Tìm kiếm chung trên từ vựng, Kanji, bài học, ngữ pháp và tin tức.
 *
 * Service không biết `req`/`res` và không import model: truy vấn đi qua
 * repository được tiêm vào, nên test chỉ cần repository giả.
 */
export const createSearchService = ({ searchRepository: repository }) => ({
  /**
   * Xếp **mọi** bản ghi khớp của từng nhóm theo độ liên quan rồi mới cắt còn
   * [limitPerType], nối theo thứ tự nhóm cố định. Không nhóm nào khớp là mảng rỗng.
   */
  async search({ q, limitPerType }) {
    const keyword = normalizeKeyword(q);
    const groups = await Promise.all(
      TYPES.map(async (spec) => {
        const docs = await repository.findMatches(spec.type, filterFor(spec, keyword));
        return rank(docs, spec, keyword)
          .slice(0, limitPerType)
          .map((doc) => toResult(spec, doc));
      }),
    );
    return groups.flat();
  },
});

export const searchService = createSearchService({ searchRepository });

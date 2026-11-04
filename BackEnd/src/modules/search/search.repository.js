import Grammar from '../../../model/Grammar.js';
import Kanji from '../../../model/Kanji.js';
import Lesson from '../../../model/Lesson.js';
import News from '../../../model/News.js';
import Vocabulary from '../../../model/Vocabulary.js';

/**
 * Trường lấy về của từng nhóm: đủ để xếp hạng và dựng kết quả, không gồm nội
 * dung HTML, ví dụ hay lời thoại video — phần nặng mà màn tìm kiếm không dùng.
 */
export const SEARCH_PROJECTIONS = Object.freeze({
  vocabulary: 'word hiragana hanviet meaning level image_url',
  kanji: 'character hanviet onyomi kunyomi meaning level',
  lesson: 'title description level',
  grammar: 'title structure meaning level',
  news: 'title description image_url level',
});

/** Mọi truy vấn Mongoose của tìm kiếm chung. Service chỉ biết tên nhóm. */
export const createSearchRepository = (models) => {
  const modelOf = {
    vocabulary: models.Vocabulary,
    kanji: models.Kanji,
    lesson: models.Lesson,
    grammar: models.Grammar,
    news: models.News,
  };

  return {
    /**
     * **Mọi** bản ghi khớp [filter], theo `_id` để hoà điểm vẫn ra cùng thứ tự.
     * Không `limit`: cắt trước khi xếp hạng làm mất bản ghi khớp trọn nằm sau
     * (gõ か không ra trợ từ か). Trường lấy về đã gọn — tệ nhất là từ khoá
     * một ký tự như `a`, khoảng 1.500 từ vựng và 180 KB với dữ liệu 2026-11.
     */
    async findMatches(type, filter) {
      const model = modelOf[type];
      if (!model) throw new Error(`Nhóm tìm kiếm không hợp lệ: ${type}`);
      return model.find(filter).select(SEARCH_PROJECTIONS[type]).sort({ _id: 1 }).lean();
    },
  };
};

export const searchRepository = createSearchRepository({ Vocabulary, Kanji, Lesson, Grammar, News });

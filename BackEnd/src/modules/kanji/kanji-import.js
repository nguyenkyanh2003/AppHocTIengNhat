import { cellText } from '../../shared/excel/sheet.js';
import { JLPT_LEVELS } from '../../shared/http/schemas.js';
import { withoutUndefined } from '../../shared/utils/object.js';

/** Cột của file Excel Kanji (tên tiếng Việt theo mẫu file đang dùng) <-> field trong DB. */
export const SHEET_HEADERS = Object.freeze({
  lessonId: 'BaiHocID',
  character: 'KyTuKanji',
  hanviet: 'HanViet',
  onyomi: 'AmOn',
  kunyomi: 'AmKun',
  meaning: 'Nghia',
  level: 'CapDo',
  strokeOrderImage: 'HinhAnhNetViet',
});

/** Cùng bộ trường bắt buộc với form thêm chữ của quản trị; âm đọc có thể bỏ trống. */
export const REQUIRED_HEADERS = [SHEET_HEADERS.lessonId, SHEET_HEADERS.character, SHEET_HEADERS.meaning, SHEET_HEADERS.level];

const OBJECT_ID = /^[a-f0-9]{24}$/i;

/** Một ô có thể chứa nhiều cách đọc, ngăn bằng `,` `;` hoặc `、`. */
const readings = (text) =>
  text
    .split(/[,;、]/)
    .map((reading) => reading.trim())
    .filter(Boolean);

const toDocument = (row) => {
  const text = (field) => cellText(row[SHEET_HEADERS[field]]);
  return withoutUndefined({
    lessonId: text('lessonId'),
    character: text('character'),
    meaning: text('meaning'),
    level: text('level'),
    hanviet: text('hanviet') || undefined,
    onyomi: readings(text('onyomi')),
    kunyomi: readings(text('kunyomi')),
    strokeOrderImage: text('strokeOrderImage') || undefined,
  });
};

const problemOf = (doc, firstLineOf) => {
  if (!doc.lessonId || !doc.character || !doc.meaning || !doc.level) {
    return `thiếu ${REQUIRED_HEADERS.join(', ')}.`;
  }
  if (!OBJECT_ID.test(doc.lessonId)) return `${SHEET_HEADERS.lessonId} "${doc.lessonId}" không hợp lệ.`;
  if (!JLPT_LEVELS.includes(doc.level)) return `cấp độ "${doc.level}" không hợp lệ.`;
  if (firstLineOf.has(doc.character)) return `chữ ${doc.character} trùng với dòng ${firstLineOf.get(doc.character)}.`;
  return null;
};

/**
 * Hàm thuần: dòng Excel -> document Kanji, kèm lỗi của từng dòng sai.
 *
 * Số dòng tính như trên Excel (header là dòng 1) để người nhập tìm lại được.
 * Có lỗi nào thì người gọi bỏ cả file — nhập một nửa file còn khó sửa hơn.
 */
export const toKanjiDocuments = (sheetRows) => {
  const documents = [];
  const errors = [];
  const firstLineOf = new Map();

  sheetRows.forEach((row, index) => {
    const line = index + 2;
    const doc = toDocument(row);
    const problem = problemOf(doc, firstLineOf);
    if (problem) {
      errors.push({ path: `dòng ${line}`, message: `Dòng ${line}: ${problem}` });
      return;
    }
    firstLineOf.set(doc.character, line);
    documents.push(doc);
  });

  return { documents, errors };
};

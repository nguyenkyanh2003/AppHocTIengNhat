import { cellText, readSheetRows } from '../../shared/excel/sheet.js';

/** Header tiếng Việt dùng trong file Excel <-> field trong DB. */
export const EXCEL_HEADERS = Object.freeze({
  word: 'TuVung',
  hiragana: 'Hiragana',
  meaning: 'NghiaTV',
  level: 'CapDo',
  usage_context: 'TinhHuong',
  lesson: 'BaiHoc',
});

const REQUIRED_HEADERS = [
  EXCEL_HEADERS.word,
  EXCEL_HEADERS.hiragana,
  EXCEL_HEADERS.meaning,
];

/**
 * Chuyển các dòng đã đọc từ Excel thành document từ vựng.
 *
 * Hàm thuần: nhận mảng object theo header, trả về mảng sẵn sàng insert. Dòng
 * thiếu cột bắt buộc bị bỏ qua, đúng như hành vi trước đây.
 */
export const toVocabularyRows = (sheetRows, { lesson, level }) =>
  sheetRows
    .map((row) => ({
      word: cellText(row[EXCEL_HEADERS.word]),
      hiragana: cellText(row[EXCEL_HEADERS.hiragana]),
      meaning: cellText(row[EXCEL_HEADERS.meaning]),
      usage_context: cellText(row[EXCEL_HEADERS.usage_context]) || null,
    }))
    .filter((row) => row.word && row.hiragana && row.meaning)
    .map((row) => ({ ...row, lesson, level, examples: [] }));

/** Đọc sheet đầu tiên của file Excel thành mảng object theo header. */
export const readWorkbookRows = (buffer) => readSheetRows(buffer, { requiredHeaders: REQUIRED_HEADERS });

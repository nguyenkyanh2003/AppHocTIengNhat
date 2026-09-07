import Excel from 'exceljs';

import { ApiError } from '../../shared/http/api-error.js';

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

/** ExcelJS trả về chuỗi, số, hoặc object (rich text/công thức). Lấy phần chữ. */
const cellText = (value) => {
  if (value === null || value === undefined) return '';
  if (typeof value === 'object') {
    if (typeof value.text === 'string') return value.text.trim();
    if (value.result !== undefined) return String(value.result).trim();
    if (Array.isArray(value.richText)) {
      return value.richText.map((part) => part.text).join('').trim();
    }
    return '';
  }
  return String(value).trim();
};

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
export const readWorkbookRows = async (buffer) => {
  const workbook = new Excel.Workbook();
  await workbook.xlsx.load(buffer);
  const worksheet = workbook.getWorksheet(1);

  if (!worksheet) {
    throw ApiError.badRequest('Không tìm thấy sheet nào trong file.');
  }

  let headers = [];
  const rows = [];

  worksheet.eachRow({ includeEmpty: false }, (row, rowNumber) => {
    if (rowNumber === 1) {
      headers = row.values.map((header) => cellText(header));
      return;
    }

    const rowData = {};
    row.values.forEach((value, index) => {
      if (headers[index]) rowData[headers[index]] = value;
    });
    rows.push(rowData);
  });

  const missing = REQUIRED_HEADERS.filter((header) => !headers.includes(header));
  if (missing.length > 0) {
    throw ApiError.badRequest(
      `File Excel thiếu cột bắt buộc: ${missing.join(', ')}.`,
    );
  }

  return rows;
};

/** Tạo workbook xuất Excel với header tiếng Việt. */
export const buildExportWorkbook = (vocabularies) => {
  const workbook = new Excel.Workbook();
  const worksheet = workbook.addWorksheet('Tu Vung');

  worksheet.columns = [
    { header: EXCEL_HEADERS.word, key: 'word', width: 20 },
    { header: EXCEL_HEADERS.hiragana, key: 'hiragana', width: 20 },
    { header: EXCEL_HEADERS.meaning, key: 'meaning', width: 30 },
    { header: EXCEL_HEADERS.level, key: 'level', width: 10 },
    { header: EXCEL_HEADERS.usage_context, key: 'usage_context', width: 20 },
    { header: EXCEL_HEADERS.lesson, key: 'lessonName', width: 30 },
  ];

  vocabularies.forEach((vocabulary) => {
    worksheet.addRow({
      word: vocabulary.word,
      hiragana: vocabulary.hiragana,
      meaning: vocabulary.meaning,
      level: vocabulary.level,
      usage_context: vocabulary.usage_context || '',
      lessonName: vocabulary.lesson?.title || '',
    });
  });

  worksheet.getRow(1).font = { bold: true };

  return workbook;
};

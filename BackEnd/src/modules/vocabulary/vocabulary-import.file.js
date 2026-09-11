import Excel from 'exceljs';

/**
 * Đọc file dữ liệu thành `{ headers, rows }` — mảng mảng, chưa diễn giải gì.
 *
 * Tách khỏi phần kiểm tra (`vocabulary-import.review.js`) vì hai việc hỏng
 * theo hai kiểu khác nhau: file hỏng là lỗi của **file** (sai định dạng, sai
 * mã hoá), dữ liệu hỏng là lỗi của **từng dòng**. Gộp lại thì một file CSV
 * lưu sai encoding sẽ hiện ra dưới dạng 500 lỗi "cách đọc phải là kana".
 */

/**
 * Tách một dòng CSV, tôn trọng dấu nháy kép.
 *
 * Tự viết thay vì thêm thư viện: luật CSV cần cho việc này chỉ có ba điều —
 * dấu phẩy ngăn ô, nháy kép bọc ô có dấu phẩy, và `""` là một dấu nháy. Nghĩa
 * tiếng Việt rất hay chứa dấu phẩy ("học sinh, sinh viên") nên tách bằng
 * `split(',')` là hỏng ngay dòng đầu tiên.
 */
export const splitCsvLine = (line, delimiter = ',') => {
  const cells = [];
  let cell = '';
  let quoted = false;

  for (let index = 0; index < line.length; index += 1) {
    const char = line[index];

    if (quoted) {
      if (char !== '"') {
        cell += char;
      } else if (line[index + 1] === '"') {
        cell += '"';
        index += 1;
      } else {
        quoted = false;
      }
      continue;
    }

    if (char === '"') quoted = true;
    else if (char === delimiter) (cells.push(cell), (cell = ''));
    else cell += char;
  }

  cells.push(cell);
  return cells;
};

/**
 * Đoán ký tự ngăn ô từ dòng header.
 *
 * Excel bản tiếng Việt xuất CSV bằng dấu **chấm phẩy** (vì dấu phẩy đã là dấu
 * thập phân trong locale đó). Đoán sai thì cả file thành đúng một cột và
 * người dùng nhận về "thiếu cột bắt buộc" mà không hiểu vì sao.
 */
const detectDelimiter = (headerLine) => {
  const counts = [',', ';', '\t'].map((delimiter) => ({
    delimiter,
    count: splitCsvLine(headerLine, delimiter).length,
  }));
  return counts.sort((left, right) => right.count - left.count)[0].delimiter;
};

/** Đọc nội dung CSV/TSV đã ở dạng chuỗi. */
export const parseCsv = (text) => {
  // BOM của UTF-8 dính vào ô đầu tiên và làm header đầu không khớp alias nào.
  const clean = text.replace(/^﻿/, '').replace(/\r\n?/g, '\n');
  if (clean.trim() === '') return { headers: [], rows: [] };

  const lines = clean.split('\n').filter((line, index) => index === 0 || line.trim() !== '');

  const delimiter = detectDelimiter(lines[0]);
  const [headerLine, ...rest] = lines;
  return {
    headers: splitCsvLine(headerLine, delimiter).map((cell) => cell.trim()),
    rows: rest.map((line) => splitCsvLine(line, delimiter)),
  };
};

/** ExcelJS trả chuỗi, số, hoặc object (rich text/công thức). Lấy phần chữ. */
const cellText = (value) => {
  if (value === null || value === undefined) return '';
  if (typeof value === 'object') {
    if (typeof value.text === 'string') return value.text;
    if (value.result !== undefined) return String(value.result);
    if (Array.isArray(value.richText)) return value.richText.map((part) => part.text).join('');
    return '';
  }
  return String(value);
};

/** Đọc sheet đầu tiên của workbook thành `{ headers, rows }`. */
export const parseWorkbook = async (buffer) => {
  const workbook = new Excel.Workbook();
  await workbook.xlsx.load(buffer);
  const worksheet = workbook.getWorksheet(1);
  if (!worksheet) return { headers: [], rows: [] };

  let headers = [];
  const rows = [];

  worksheet.eachRow({ includeEmpty: false }, (row, rowNumber) => {
    // `row.values` của ExcelJS là mảng 1-based (phần tử 0 luôn trống), nên
    // `.slice(1)` để chỉ số cột khớp với thứ tự header người dùng nhìn thấy.
    const cells = row.values.slice(1).map(cellText);
    if (rowNumber === 1) headers = cells.map((cell) => cell.trim());
    else rows.push(cells);
  });

  return { headers, rows };
};

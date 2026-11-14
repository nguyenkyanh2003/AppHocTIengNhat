import Excel from 'exceljs';

import { ApiError } from '../http/api-error.js';

/** ExcelJS trả về chuỗi, số, hoặc object (rich text/công thức). Lấy phần chữ. */
export const cellText = (value) => {
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
 * Đọc sheet đầu tiên của file Excel thành mảng object theo header (dòng 1).
 *
 * File không đọc được hay thiếu cột bắt buộc là lỗi của người tải lên (400),
 * không phải lỗi máy chủ.
 */
export const readSheetRows = async (buffer, { requiredHeaders = [] } = {}) => {
  const workbook = new Excel.Workbook();
  try {
    await workbook.xlsx.load(buffer);
  } catch {
    throw ApiError.badRequest('Không đọc được file Excel. Hãy lưu file ở định dạng .xlsx rồi tải lên lại.');
  }

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

  const missing = requiredHeaders.filter((header) => !headers.includes(header));
  if (missing.length > 0) {
    throw ApiError.badRequest(`File Excel thiếu cột bắt buộc: ${missing.join(', ')}.`);
  }

  return rows;
};

/**
 * Kiểm và chuẩn hoá dữ liệu từ vựng **trước khi** chạm tới MongoDB.
 *
 * Hàm thuần, không đụng DB, không đọc file — nhận mảng dòng thô (đã đọc từ
 * CSV/Excel) và trả về một bản báo cáo: dòng nào ghi được, dòng nào sai và sai
 * ở đâu.
 *
 * Hai điều công cụ nhập cũ làm sai mà file này tồn tại để sửa:
 *
 * 1. **Bỏ qua im lặng.** `toVocabularyRows` lọc bỏ dòng thiếu cột bằng
 *    `.filter(...)`. Nhập 500 dòng, 40 dòng biến mất, không ai biết dòng nào —
 *    và người soạn đinh ninh dữ liệu đã vào đủ.
 * 2. **Không chuẩn hoá.** `ＡＢＣ`, `ｶﾞｸｾｲ`, `　学生　` là ba cách viết của
 *    những thứ vốn phải bằng nhau. Không chuẩn hoá thì unique index
 *    `(word, hiragana)` vô dụng: Mongo thấy chúng khác nhau.
 */

/** Các cấp độ JLPT hợp lệ, khớp enum trong `model/Vocabulary.js`. */
const LEVELS = new Set(['N5', 'N4', 'N3', 'N2', 'N1']);

/**
 * Tên cột chấp nhận được cho từng field, viết ở dạng đã rút gọn.
 *
 * Nhận nhiều cách gọi là có chủ đích: file thật đến từ nhiều nguồn (người
 * soạn tay, bản xuất từ web, file mẫu cũ). Bắt người dùng đổi header cho khớp
 * trước khi nhập được là cách chắc chắn nhất để họ sửa tay và sửa sai.
 */
const HEADER_ALIASES = Object.freeze({
  word: ['tuvung', 'tu', 'word', 'kanji', 'tuvungtiengnhat', 'matchu'],
  hiragana: ['hiragana', 'kana', 'cachdoc', 'doc', 'reading', 'phienam', 'yomikata'],
  meaning: ['nghiatv', 'nghia', 'nghiatiengviet', 'meaning', 'ynghia', 'dichnghia'],
  level: ['capdo', 'level', 'trinhdo', 'jlpt'],
  usage_context: ['tinhhuong', 'usagecontext', 'ngucanh', 'context', 'chude'],
  lesson: ['baihoc', 'lesson', 'bai', 'unit'],
  example_sentence: ['vidu', 'cauvidu', 'example', 'examplesentence'],
  example_meaning: ['nghiavidu', 'examplemeaning', 'dichvidu'],
});

const REQUIRED_FIELDS = ['word', 'hiragana', 'meaning'];

/**
 * Rút gọn một tên cột về dạng so khớp được: bỏ dấu tiếng Việt, bỏ mọi thứ
 * không phải chữ và số, hạ chữ thường. Nhờ vậy "Từ vựng", "TU_VUNG" và
 * "tuvung" đều về cùng một chuỗi.
 */
const headerKey = (text) =>
  String(text ?? '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '');

/**
 * Ghép danh sách header của file với các field trong DB.
 *
 * Trả về chỉ số cột của từng field, cộng `missing` liệt kê field bắt buộc
 * không tìm thấy. Thiếu cột là lỗi của **cả file**, không phải của từng dòng —
 * báo một lần rồi dừng, thay vì in ra 500 dòng lỗi giống hệt nhau.
 */
export const mapHeaders = (headers) => {
  const mapped = { missing: [] };
  const keys = (headers ?? []).map(headerKey);

  for (const [field, aliases] of Object.entries(HEADER_ALIASES)) {
    const index = keys.findIndex((key) => key && aliases.includes(key));
    if (index >= 0) mapped[field] = index;
  }

  mapped.missing = REQUIRED_FIELDS.filter((field) => mapped[field] === undefined);
  return mapped;
};

/**
 * Chuẩn hoá chữ Nhật: NFKC rồi bỏ mọi khoảng trắng.
 *
 * NFKC gộp các biến thể tương thích về một dạng — nửa-độ-rộng `ｶﾞ` thành `ガ`,
 * đầy-độ-rộng `Ａ` thành `A`. Bỏ khoảng trắng (kể cả U+3000 của tiếng Nhật) vì
 * trong một *từ* thì khoảng trắng luôn là rác định dạng, không mang nghĩa.
 */
export const normalizeJapanese = (text) =>
  String(text ?? '')
    .normalize('NFKC')
    .replace(/\s+/gu, '');

/**
 * Chuẩn hoá tiếng Việt: NFC, gộp khoảng trắng thừa, cắt hai đầu.
 *
 * NFC chứ không NFKC: dấu tiếng Việt có hai cách mã hoá (tổ hợp và dựng sẵn)
 * trông y hệt nhau nhưng khác byte, nên rà trùng sẽ trượt. Khoảng trắng **giữ
 * lại** vì nghĩa là một cụm từ nhiều chữ, không phải một token.
 */
export const normalizeVietnamese = (text) =>
  String(text ?? '')
    .normalize('NFC')
    .replace(/\s+/gu, ' ')
    .trim();

/**
 * Kana (hiragana, katakana, dấu trường âm, lặp âm) — không có chữ Hán, không
 * có chữ Latin.
 *
 * Katakana được chấp nhận chứ không phải chỉ hiragana: rất nhiều từ N5 là từ
 * mượn (コーヒー, テレビ) và cột "cách đọc" của mọi file thật đều ghi katakana
 * cho đúng những từ đó.
 */
const KANA_ONLY = /^[ぁ-ゟ゠-ヿー々〻]+$/u;

const readCell = (row, index) => {
  if (index === undefined || row === null || typeof row !== 'object') return '';
  const value = Array.isArray(row) ? row[index] : row[index];
  if (value === null || value === undefined) return '';
  if (typeof value === 'object') return '';
  return String(value);
};

/**
 * Đọc một dòng theo tên cột tiếng Việt mặc định (khi không truyền `columns`).
 *
 * Giữ đường này để các lời gọi cũ — và test dùng object có khoá `TuVung` —
 * vẫn chạy mà không phải dựng bảng chỉ số cột.
 */
const DEFAULT_KEYS = Object.freeze({
  word: 'TuVung',
  hiragana: 'Hiragana',
  meaning: 'NghiaTV',
  level: 'CapDo',
  usage_context: 'TinhHuong',
  lesson: 'BaiHoc',
  example_sentence: 'ViDu',
  example_meaning: 'NghiaViDu',
});

const valueOf = (row, field, columns) => {
  if (columns) return readCell(row, columns[field]);
  if (row === null || typeof row !== 'object') return '';
  const value = row[DEFAULT_KEYS[field]];
  if (value === null || value === undefined) return '';
  if (typeof value === 'object') return '';
  return String(value);
};

/**
 * Kiểm toàn bộ các dòng, trả về báo cáo đầy đủ.
 *
 * **Không bao giờ ném.** Một công cụ nhập ném giữa chừng để lại người dùng
 * không biết 499 dòng còn lại đúng hay sai; báo cáo đầy đủ mới là thứ dùng
 * được. Dữ liệu đầu vào có thể là bất cứ thứ gì Excel nhả ra, kể cả `null`.
 *
 * @param {Array} rawRows Dòng đã đọc từ file (không gồm dòng header).
 * @param {{level?: string, columns?: object, startLine?: number}} options
 *   `startLine` là số dòng của phần tử đầu tiên trong file gốc — mặc định 2 vì
 *   dòng 1 là header. Có nó thì thông báo lỗi chỉ đúng dòng người dùng thấy
 *   trong Excel.
 */
export const reviewRows = (rawRows, { level: defaultLevel = null, columns, startLine = 2 } = {}) => {
  const accepted = [];
  const errors = [];
  const seen = new Map();
  let skipped = 0;

  (rawRows ?? []).forEach((rawRow, index) => {
    const line = startLine + index;
    const fail = (field, message) => errors.push({ line, field, message });

    const word = normalizeJapanese(valueOf(rawRow, 'word', columns));
    const hiragana = normalizeJapanese(valueOf(rawRow, 'hiragana', columns));
    const meaning = normalizeVietnamese(valueOf(rawRow, 'meaning', columns));

    // Dòng trắng hoàn toàn: Excel gần như luôn kéo theo vài dòng như vậy ở
    // cuối sheet. Đó không phải lỗi của người soạn nên không báo lỗi, nhưng
    // vẫn đếm để tổng số dòng khớp với file.
    if (!word && !hiragana && !meaning) {
      skipped += 1;
      return;
    }

    let valid = true;
    if (!word) (fail('word', 'Cột từ vựng là bắt buộc.'), (valid = false));
    if (!hiragana) (fail('hiragana', 'Cột cách đọc là bắt buộc.'), (valid = false));
    if (!meaning) (fail('meaning', 'Cột nghĩa tiếng Việt là bắt buộc.'), (valid = false));

    if (hiragana && !KANA_ONLY.test(hiragana)) {
      fail('hiragana', 'Cách đọc phải viết bằng kana (hiragana hoặc katakana).');
      valid = false;
    }

    const rawLevel = normalizeJapanese(valueOf(rawRow, 'level', columns)).toUpperCase();
    const rowLevel = rawLevel || defaultLevel;
    if (rowLevel && !LEVELS.has(rowLevel)) {
      fail('level', `Cấp độ "${rawLevel}" không thuộc N5–N1.`);
      valid = false;
    }

    if (!valid) return;

    // Rà trùng **sau** chuẩn hoá: `　学生` và `学生` là cùng một từ, bắt được
    // ở đây thì unique index dưới DB không phải làm trọng tài.
    const key = `${word}|${hiragana}`;
    const firstLine = seen.get(key);
    if (firstLine !== undefined) {
      fail('word', `Trùng với dòng ${firstLine} (cùng từ và cùng cách đọc).`);
      return;
    }
    seen.set(key, line);

    const sentence = normalizeJapanese(valueOf(rawRow, 'example_sentence', columns));
    const exampleMeaning = normalizeVietnamese(valueOf(rawRow, 'example_meaning', columns));
    // Câu ví dụ không có nghĩa vẫn được giữ: người soạn đã bỏ công nhập nó, và
    // nghĩa có thể bổ sung sau. Bỏ đi là mất dữ liệu.
    const examples = sentence ? [{ sentence, meaning: exampleMeaning || null }] : [];

    accepted.push({
      line,
      word,
      hiragana,
      meaning,
      level: rowLevel,
      usage_context: normalizeVietnamese(valueOf(rawRow, 'usage_context', columns)) || null,
      lessonTitle: normalizeVietnamese(valueOf(rawRow, 'lesson', columns)) || null,
      examples,
    });
  });

  return { accepted, errors, skipped };
};

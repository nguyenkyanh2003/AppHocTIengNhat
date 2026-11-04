import { escapeRegExp } from '../../shared/utils/regexp.js';

/** Khoảng cách giữa một chữ hiragana và chữ katakana cùng âm trong bảng Unicode. */
const KANA_OFFSET = 0x60;

/**
 * Dấu tách các ý trong một trường: nghĩa "Mặt trăng, tháng", tiêu đề "Tình huống:
 * Đi tàu", phần tuỳ chọn trong ngoặc của từ vựng "[お]さら".
 */
const SEGMENT_SEPARATORS = /[,;:/()（）[\]［］「」、，：・~〜]+/;

/** Okurigana trong âm Kun: `た(べる)` hoặc `まな.ぶ`. */
const OKURIGANA_MARKS = /[().]/g;

const shiftKana = (pattern, offset) => (text) =>
  text.replace(pattern, (char) => String.fromCharCode(char.charCodeAt(0) + offset));

export const toKatakana = shiftKana(/[ぁ-ゖ]/g, KANA_OFFSET);
export const toHiragana = shiftKana(/[ァ-ヶ]/g, -KANA_OFFSET);

/**
 * Từ khoá chuẩn hoá NFC: có bộ gõ gửi chữ Việt ở dạng tổ hợp (NFD), còn dữ liệu
 * lưu dạng dựng sẵn — không chuẩn hoá thì "mặt trăng" nhìn giống mà không khớp.
 */
export const normalizeKeyword = (keyword) => keyword.normalize('NFC').trim();

/** Nguyên văn, bản hiragana và bản katakana — âm On lưu katakana, người học hay gõ hiragana. */
const variantsOf = (keyword) => [...new Set([keyword, toHiragana(keyword), toKatakana(keyword)])];

/** Khớp nguyên văn từ khoá, không phân biệt hoa thường và hiragana/katakana. */
export const keywordPattern = (keyword) =>
  new RegExp(variantsOf(keyword).map(escapeRegExp).join('|'), 'i');

/**
 * Như [keywordPattern] nhưng cho phép một dấu okurigana xen giữa hai ký tự, để
 * gõ `たべる` khớp âm Kun `た(べる)`. Chỉ dùng cho trường âm Kun.
 */
export const readingPattern = (keyword) =>
  new RegExp(
    variantsOf(keyword)
      .map((variant) => Array.from(variant).map(escapeRegExp).join('[().]?'))
      .join('|'),
    'i',
  );

export const MATCH = Object.freeze({ EXACT: 0, PREFIX: 1, CONTAINS: 2 });

/** Dạng đem so sánh: NFC, chữ thường, katakana về hiragana. */
const fold = (text) => toHiragana(String(text).normalize('NFC').toLowerCase()).trim();

/** Cả chuỗi, chuỗi đã bỏ okurigana, và từng ý tách theo dấu phân cách. */
const candidatesOf = (text) => [
  text,
  text.replace(OKURIGANA_MARKS, ''),
  ...text.split(SEGMENT_SEPARATORS).map((part) => part.trim()).filter(Boolean),
];

/**
 * Mức khớp tốt nhất của từ khoá với một giá trị (chuỗi hoặc mảng chuỗi):
 * [MATCH.EXACT], [MATCH.PREFIX], [MATCH.CONTAINS], hoặc `null` nếu không khớp.
 */
export const matchKind = (value, keyword) => {
  const target = fold(keyword);
  const candidates = [value]
    .flat()
    .filter((item) => item !== null && item !== undefined)
    .flatMap((item) => candidatesOf(fold(item)));

  if (candidates.some((text) => text === target)) return MATCH.EXACT;
  if (candidates.some((text) => text.startsWith(target))) return MATCH.PREFIX;
  if (candidates.some((text) => text.includes(target))) return MATCH.CONTAINS;
  return null;
};

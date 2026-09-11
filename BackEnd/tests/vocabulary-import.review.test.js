import assert from 'node:assert/strict';
import test from 'node:test';

import {
  mapHeaders,
  normalizeJapanese,
  normalizeVietnamese,
  reviewRows,
} from '../src/modules/vocabulary/vocabulary-import.review.js';

const row = (over = {}) => ({
  TuVung: '学生',
  Hiragana: 'がくせい',
  NghiaTV: 'học sinh',
  ...over,
});

// --- nhận diện cột --------------------------------------------------------

test('column names are matched regardless of case, accents or spacing', () => {
  // File thật đến từ nhiều nguồn: người này ghi "Từ vựng", người kia "TuVung",
  // bản xuất từ web ghi "Word". Bắt người dùng sửa header trước khi nhập được
  // là cách chắc chắn nhất để họ sửa tay rồi nhập sai.
  assert.equal(mapHeaders(['Từ vựng', 'Cách đọc', 'Nghĩa']).word, 0);
  assert.equal(mapHeaders(['Từ vựng', 'Cách đọc', 'Nghĩa']).hiragana, 1);
  assert.equal(mapHeaders(['TU VUNG', 'HIRAGANA', 'NGHIA TV']).meaning, 2);
  assert.equal(mapHeaders(['Word', 'Reading', 'Meaning']).word, 0);
});

test('a file without the three required columns is rejected as a file, not row by row', () => {
  const mapped = mapHeaders(['Kanji', 'Âm Hán Việt']);
  assert.deepEqual(mapped.missing, ['hiragana', 'meaning']);
});

test('optional columns are recognised but never required', () => {
  const mapped = mapHeaders(['Từ vựng', 'Hiragana', 'Nghĩa', 'Cấp độ', 'Bài học', 'Ví dụ']);
  assert.equal(mapped.level, 3);
  assert.equal(mapped.lesson, 4);
  assert.equal(mapped.example_sentence, 5);
  assert.deepEqual(mapped.missing, []);
});

// --- chuẩn hoá ------------------------------------------------------------

test('Japanese text is normalized so the same word never lands twice', () => {
  // Nửa-độ-rộng, đầy-độ-rộng và khoảng trắng U+3000 là ba cách viết khác nhau
  // của cùng một từ. Không chuẩn hoá thì unique index vô dụng: ｶﾞｸｾｲ và がくせい
  // là hai bản ghi khác nhau với Mongo.
  assert.equal(normalizeJapanese('　学生　'), '学生');
  assert.equal(normalizeJapanese('ｶﾞｸｾｲ'), 'ガクセイ');
  assert.equal(normalizeJapanese('ＡＢＣ'), 'ABC');
  assert.equal(normalizeJapanese('がく　せい'), 'がくせい');
});

test('Vietnamese diacritics are composed so equal strings compare equal', () => {
  // Dấu tiếng Việt có hai cách mã hoá: tổ hợp (NFD) và dựng sẵn (NFC). Chuỗi
  // trông y hệt nhau trên màn hình nhưng khác byte, nên rà trùng sẽ trượt.
  const decomposed = 'học sinh'; // "học" viết bằng o + dấu nặng rời
  assert.notEqual(decomposed.length, 'học sinh'.length, 'hai dạng phải khác byte');
  assert.equal(normalizeVietnamese(decomposed), 'học sinh');
  assert.equal(normalizeVietnamese('  học   sinh  '), 'học sinh');
});

// --- kiểm từng dòng -------------------------------------------------------

test('a clean row becomes a document ready to write', () => {
  const { accepted, errors } = reviewRows([row()], { level: 'N5' });

  assert.deepEqual(errors, []);
  assert.deepEqual(accepted, [
    {
      line: 2,
      word: '学生',
      hiragana: 'がくせい',
      meaning: 'học sinh',
      level: 'N5',
      usage_context: null,
      lessonTitle: null,
      examples: [],
    },
  ]);
});

test('a row missing a required field is reported with its line number', () => {
  // Bỏ qua im lặng là hành vi của công cụ cũ: người nhập 500 dòng, 40 dòng
  // biến mất, không ai biết dòng nào.
  const { accepted, errors } = reviewRows([row(), row({ Hiragana: '' })], { level: 'N5' });

  assert.equal(accepted.length, 1);
  assert.equal(errors.length, 1);
  assert.equal(errors[0].line, 3);
  assert.equal(errors[0].field, 'hiragana');
  assert.match(errors[0].message, /bắt buộc/i);
});

test('a reading written in the wrong script is caught, not stored', () => {
  const { errors } = reviewRows([row({ Hiragana: 'gakusei' })], { level: 'N5' });
  assert.equal(errors[0].field, 'hiragana');
  assert.match(errors[0].message, /kana/i);
});

test('katakana is a valid reading, not an error', () => {
  // Rất nhiều từ N5 là từ mượn: コーヒー, テレビ. Cột "hiragana" của các file
  // thật thường chứa katakana cho đúng những từ đó.
  const { accepted, errors } = reviewRows(
    [row({ TuVung: 'コーヒー', Hiragana: 'コーヒー', NghiaTV: 'cà phê' })],
    { level: 'N5' },
  );
  assert.deepEqual(errors, []);
  assert.equal(accepted[0].hiragana, 'コーヒー');
});

test('a word with no kanji may repeat its reading', () => {
  const { errors } = reviewRows([row({ TuVung: 'ここ', Hiragana: 'ここ', NghiaTV: 'ở đây' })], {
    level: 'N5',
  });
  assert.deepEqual(errors, []);
});

test('an unknown level is refused instead of being written as free text', () => {
  const { errors } = reviewRows([row({ CapDo: 'N6' })], { level: 'N5' });
  assert.equal(errors[0].field, 'level');
});

test('the level column wins over the command-line default', () => {
  const { accepted } = reviewRows([row({ CapDo: 'N4' })], { level: 'N5' });
  assert.equal(accepted[0].level, 'N4');
});

test('an example is kept only when it has both halves', () => {
  const { accepted } = reviewRows(
    [row({ ViDu: '私は学生です', NghiaViDu: 'Tôi là học sinh' }), row({ TuVung: '本', Hiragana: 'ほん', NghiaTV: 'sách', ViDu: '本を読む' })],
    { level: 'N5' },
  );
  assert.deepEqual(accepted[0].examples, [
    { sentence: '私は学生です', meaning: 'Tôi là học sinh' },
  ]);
  // Ví dụ không có nghĩa thì vẫn giữ câu, nghĩa để trống — mất câu ví dụ là
  // mất dữ liệu người soạn đã bỏ công nhập.
  assert.deepEqual(accepted[1].examples, [{ sentence: '本を読む', meaning: null }]);
});

// --- trùng trong cùng một file --------------------------------------------

test('the same word twice in one file is an error naming both lines', () => {
  const { accepted, errors } = reviewRows([row(), row({ NghiaTV: 'sinh viên' })], { level: 'N5' });

  assert.equal(accepted.length, 1, 'chỉ giữ dòng đầu');
  assert.equal(errors.length, 1);
  assert.equal(errors[0].line, 3);
  assert.match(errors[0].message, /dòng 2/);
});

test('a homograph with a different reading is not a duplicate', () => {
  const { accepted, errors } = reviewRows(
    [
      { TuVung: '今日', Hiragana: 'きょう', NghiaTV: 'hôm nay' },
      { TuVung: '今日', Hiragana: 'こんにち', NghiaTV: 'thời nay' },
    ],
    { level: 'N5' },
  );
  assert.deepEqual(errors, []);
  assert.equal(accepted.length, 2);
});

test('duplicates are detected after normalization, not before', () => {
  const { errors } = reviewRows(
    [row(), row({ TuVung: '　学生', Hiragana: 'がく　せい' })],
    { level: 'N5' },
  );
  assert.equal(errors.length, 1, 'hai cách viết cùng một từ phải bị bắt là trùng');
});

// --- dòng rỗng -------------------------------------------------------------

test('blank rows are skipped silently but counted', () => {
  // Excel thường kéo theo vài dòng trắng ở cuối. Đó không phải lỗi của người
  // nhập, nên không báo lỗi — nhưng vẫn phải đếm để tổng số khớp.
  const { accepted, errors, skipped } = reviewRows(
    [row(), { TuVung: '', Hiragana: '', NghiaTV: '' }, {}],
    { level: 'N5' },
  );
  assert.equal(accepted.length, 1);
  assert.deepEqual(errors, []);
  assert.equal(skipped, 2);
});

test('nothing in the input can make review throw', () => {
  // Công cụ nhập phải luôn trả về một bản báo cáo. Ném giữa chừng nghĩa là
  // người dùng không biết được 499 dòng còn lại có đúng hay không.
  const nasty = [null, undefined, { TuVung: 123, Hiragana: true, NghiaTV: [] }];
  const { errors } = reviewRows(nasty, { level: 'N5' });
  assert.ok(Array.isArray(errors));
});

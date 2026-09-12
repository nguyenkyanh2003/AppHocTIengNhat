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
      hanviet: null,
      verb_group: null,
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

// --- chú thích trong dữ liệu thật ------------------------------------------

test('a column named "Kanji (Chữ Hán)" is still the word column', () => {
  // File thật hay đặt tên cột kèm chú thích trong ngoặc. So khớp cả phần
  // trước dấu ngoặc thì không phải liệt kê vô hạn biến thể.
  const mapped = mapHeaders(['STT', 'Kanji (Chữ Hán)', 'Hiragana', 'Hán Việt', 'Nghĩa Tiếng Việt']);
  assert.equal(mapped.word, 1);
  assert.equal(mapped.hanviet, 3);
  assert.equal(mapped.meaning, 4);
  assert.deepEqual(mapped.missing, []);
});

test('the verb group is lifted out of the reading, not left inside it', () => {
  // "おしえます (II)" không phải một cách đọc. Để nguyên thì thẻ ôn hiện cả
  // dấu ngoặc và giọng đọc sau này đọc thành "hai".
  const { accepted } = reviewRows([row({ TuVung: '教えます', Hiragana: 'おしえます (II)' })], {});
  assert.equal(accepted[0].hiragana, 'おしえます');
  assert.equal(accepted[0].verb_group, 2);
});

test('all three verb groups are understood', () => {
  const readings = ['かきます (I)', 'たべます (II)', 'きます (III)'];
  const { accepted } = reviewRows(
    readings.map((r, i) => ({ TuVung: `語${i}`, Hiragana: r, NghiaTV: 'x' })),
    {},
  );
  assert.deepEqual(accepted.map((a) => a.verb_group), [1, 2, 3]);
});

test('a word with no verb group gets none rather than a guess', () => {
  const { accepted } = reviewRows([row()], {});
  assert.equal(accepted[0].verb_group, null);
});

test('textbook annotations in a reading are kept, not rejected', () => {
  // `[な]` đánh dấu tính từ đuôi na, `~` đánh dấu tiếp đầu/tiếp vĩ ngữ,
  // `(電話を~)` là gợi ý kết hợp. Tất cả đều là dữ liệu người soạn cố ý ghi.
  const samples = [
    ['きれい[な]', 'đẹp'],
    ['~じん', 'người nước ~'],
    ['こちらは~です。', 'đây là ~'],
    ['おなまえは?', 'tên bạn là gì?'],
    ['かけます(電話を~)', 'gọi điện'],
    ['[お]しごと', 'công việc'],
  ];
  const { accepted, errors } = reviewRows(
    samples.map(([reading, meaning], index) => ({
      TuVung: `語${index}`,
      Hiragana: reading,
      NghiaTV: meaning,
    })),
    {},
  );
  assert.deepEqual(errors, [], JSON.stringify(errors));
  assert.equal(accepted.length, samples.length);
});

test('romaji is still rejected even though annotations are allowed', () => {
  // Nới luật cho chú thích không được biến thành nới cho mọi thứ: cột cách
  // đọc ghi bằng chữ Latin vẫn là lỗi nhập liệu thật.
  const { errors } = reviewRows([row({ Hiragana: 'gakusei' })], {});
  assert.equal(errors[0].field, 'hiragana');
});

test('kanji leaking into the reading is rejected, except inside a bracketed hint', () => {
  const bad = reviewRows([row({ Hiragana: 'がく生' })], {});
  assert.equal(bad.errors.length, 1);
  const good = reviewRows([row({ TuVung: 'かけます', Hiragana: 'かけます(電話を~)' })], {});
  assert.deepEqual(good.errors, []);
});

test('the Hán-Việt reading is carried through when the file has it', () => {
  const { accepted } = reviewRows([row({ HanViet: 'HỌC SINH' })], {});
  assert.equal(accepted[0].hanviet, 'HỌC SINH');
});

test('a missing Hán-Việt column is not an error', () => {
  const { accepted, errors } = reviewRows([row()], {});
  assert.deepEqual(errors, []);
  assert.equal(accepted[0].hanviet, null);
});

test('a word with no level stays without one instead of being guessed', () => {
  // File 1021 từ của người dùng không có cột cấp độ và trộn cả N5 lẫn N4.
  // Gán bừa N5 cho tất cả là bịa dữ liệu.
  const { accepted, errors } = reviewRows([row()], {});
  assert.deepEqual(errors, []);
  assert.equal(accepted[0].level, null);
});

test('quote marks around a whole reading are stripped, not treated as a container', () => {
  // 「ともだちに~」 là trích dẫn bọc quanh cả cụm. Xoá cả cụm thì không còn gì
  // để kiểm và một cách đọc hợp lệ bị báo là rỗng.
  const { accepted, errors } = reviewRows(
    [{ TuVung: '「友達に~」', Hiragana: '「ともだちに~」', NghiaTV: 'với bạn' }],
    {},
  );
  assert.deepEqual(errors, []);
  assert.equal(accepted.length, 1);
});

test('an ellipsis in a set phrase is punctuation, not a broken reading', () => {
  const { errors } = reviewRows(
    [{ TuVung: '[~は]ちょっと….', Hiragana: '[~は]ちょっと….', NghiaTV: '… thì hơi…' }],
    {},
  );
  assert.deepEqual(errors, []);
});

test('kanji left behind in a reading is still caught', () => {
  // Đây là lỗi thật trong file nguồn: cột cách đọc của 一回 ghi "一かい" thay
  // vì "いっかい". Nới luật cho chú thích không được che mất lỗi này.
  const { errors } = reviewRows([{ TuVung: '一回', Hiragana: '一かい', NghiaTV: 'một lần' }], {});
  assert.equal(errors.length, 1);
  assert.equal(errors[0].field, 'hiragana');
});

// --- từ không có dạng chữ Hán ---------------------------------------------

test('a word with no kanji form uses its reading as the headword', () => {
  // 297/1136 dòng của file N4 để trống cột Kanji: やります, ずいぶん, いつでも
  // vốn không có dạng chữ Hán. Bắt buộc phải có Kanji thì mất một phần tư file.
  const { accepted, errors } = reviewRows(
    [{ TuVung: '', Hiragana: 'やります', NghiaTV: 'làm' }],
    {},
  );
  assert.deepEqual(errors, []);
  assert.equal(accepted[0].word, 'やります');
  assert.equal(accepted[0].hiragana, 'やります');
});

test('a row with neither a word nor a reading is still an error', () => {
  const { errors } = reviewRows([{ TuVung: '', Hiragana: '', NghiaTV: 'gì đó' }], {});
  assert.ok(errors.some((error) => error.field === 'hiragana'));
});

test('the fallback keeps the annotation out of the headword', () => {
  // Cột cách đọc mang chú thích `[じかんに~]`; dùng nó làm từ thì từ khoá có
  // cả dấu ngoặc vuông.
  const { accepted } = reviewRows(
    [{ TuVung: '', Hiragana: 'おくれます[じかんに~]', NghiaTV: 'muộn' }],
    {},
  );
  assert.equal(accepted[0].word, 'おくれます');
  assert.equal(accepted[0].hiragana, 'おくれます[じかんに~]');
});

// --- một ô chứa nhiều dạng viết -------------------------------------------

test('a cell holding two spellings is reported instead of becoming one headword', () => {
  // 見ます、診ます là hai từ khác nghĩa dùng chung cách đọc. Ghi nguyên cả cụm
  // thành một từ khoá là dữ liệu sai; tách hộ thì gán nhầm nghĩa cho cả hai.
  const { accepted, errors } = reviewRows(
    [{ TuVung: '見ます、診ます', Hiragana: 'みます', NghiaTV: 'xem, khám bệnh' }],
    {},
  );
  assert.equal(accepted.length, 0);
  assert.equal(errors[0].field, 'word');
  assert.match(errors[0].message, /nhiều dạng/i);
});

test('a slash inside a bracket is part of the word, not a separator', () => {
  // 4分の1（1/4） là một từ duy nhất.
  const { errors } = reviewRows(
    [{ TuVung: '4分の1（1/4）', Hiragana: 'よんぶんのいち', NghiaTV: 'một phần tư' }],
    {},
  );
  assert.deepEqual(errors, []);
});

// --- nhãn bài trong giáo trình --------------------------------------------

test('the textbook lesson label is carried through', () => {
  const { accepted } = reviewRows([row({ BaiHoc: 'Bài 26' })], {});
  assert.equal(accepted[0].lessonTitle, 'Bài 26');
});

test('the N4 file layout is understood as it is, without editing the file', () => {
  // Cột xếp khác thứ tự (Hiragana trước Kanji) và tên khác ("Nghĩa từ vựng").
  const mapped = mapHeaders(['#', 'Hiragana', 'Kanji', 'Hán Việt', 'Nghĩa từ vựng', 'Bài']);
  assert.deepEqual(mapped.missing, []);
  assert.equal(mapped.hiragana, 1);
  assert.equal(mapped.word, 2);
  assert.equal(mapped.hanviet, 3);
  assert.equal(mapped.meaning, 4);
  assert.equal(mapped.lesson, 5);
});

test('a column called "Nghĩa ví dụ" is not mistaken for the meaning column', () => {
  // So khớp theo tiền tố sẽ khiến cột này chiếm chỗ cột nghĩa khi file không
  // có cột "Nghĩa" trần — nên danh sách alias phải khớp chính xác.
  const mapped = mapHeaders(['Từ vựng', 'Hiragana', 'Nghĩa ví dụ']);
  assert.deepEqual(mapped.missing, ['meaning']);
  assert.equal(mapped.example_meaning, 2);
});

test('annotations in the kanji column stay out of the headword', () => {
  const { accepted } = reviewRows(
    [{ TuVung: '遅れます[時間に~]', Hiragana: 'おくれます[じかんに~]', NghiaTV: 'muộn' }],
    {},
  );
  assert.equal(accepted[0].word, '遅れます');
  // Chú thích không bị mất — nó vẫn ở cột cách đọc.
  assert.equal(accepted[0].hiragana, 'おくれます[じかんに~]');
});

test('a kanji cell that is only an annotation falls back to the reading', () => {
  // `[子供が~]` không phải một từ; từ thật là います, nằm ở cột cách đọc.
  const { accepted } = reviewRows(
    [{ TuVung: '[子供が~]', Hiragana: 'います[こどもが~]', NghiaTV: 'có (con)' }],
    {},
  );
  assert.equal(accepted[0].word, 'います');
});

test('a verb group left in the kanji column does not become part of the key', () => {
  const { accepted } = reviewRows([{ TuVung: 'あげます(II)', Hiragana: 'あげます', NghiaTV: 'cho' }], {});
  assert.equal(accepted[0].word, 'あげます');
  assert.equal(accepted[0].verb_group, null, 'nhóm động từ chỉ đọc từ cột cách đọc');
});

// --- từ vốn không có dạng chữ Hán, cột kanji ghi thẳng kana ----------------

test('an empty reading column falls back to a kana-only word column', () => {
  // File N3: 185/882 dòng để cột "cách đọc" trống vì từ vốn không có dạng
  // chữ Hán — cột "Kanji" ghi thẳng けが, おしゃべり... Bắt buộc phải có cột
  // cách đọc riêng sẽ loại hơn 1/5 file dù dữ liệu hoàn toàn hợp lệ.
  const { accepted, errors } = reviewRows(
    [{ TuVung: 'けが', Hiragana: '', NghiaTV: 'vết thương' }],
    {},
  );
  assert.deepEqual(errors, []);
  assert.equal(accepted[0].word, 'けが');
  assert.equal(accepted[0].hiragana, 'けが');
});

test('an empty reading column with real kanji in the word column is still an error', () => {
  // Không được suy diễn cách đọc từ chữ Hán — chỉ dùng fallback khi cột từ
  // đã là kana thuần, tức tự nó đã là cách đọc.
  const { errors } = reviewRows([{ TuVung: '学生', Hiragana: '', NghiaTV: 'học sinh' }], {});
  assert.equal(errors[0].field, 'hiragana');
});

// --- nhiều dạng viết ngăn bằng dấu gạch chéo -------------------------------

test('a slash separating two spellings is a multi-form cell, not a fraction', () => {
  // 周り/回り là hai cách viết của cùng một từ, không phải một phân số.
  const { accepted, errors } = reviewRows(
    [{ TuVung: '周り/回り', Hiragana: 'まわり', NghiaTV: 'xung quanh' }],
    {},
  );
  assert.equal(accepted.length, 0);
  assert.equal(errors[0].field, 'word');
  assert.match(errors[0].message, /nhiều dạng/i);
});

test('a full-width slash in both the word and the reading is one error, not silently kept', () => {
  // 済ませる／済ます: cả từ lẫn cách đọc đều mang hai dạng, dùng dấu gạch chéo
  // toàn độ rộng. Trước đây điều này lọt qua kiểm từ khoá rồi mới bị bắt bởi
  // luật kana — đúng nhưng vì lý do sai (báo "không phải kana" thay vì "nhiều
  // dạng viết"), nên người sửa file không hiểu vì sao.
  const { errors } = reviewRows(
    [{ TuVung: '済ませる／済ます', Hiragana: 'すませる／すます', NghiaTV: 'kết thúc' }],
    {},
  );
  assert.equal(errors.length, 1);
  assert.equal(errors[0].field, 'word');
  assert.match(errors[0].message, /nhiều dạng/i);
});

test('a fraction in parentheses is still not mistaken for multi-form after the slash widens', () => {
  const { errors } = reviewRows(
    [{ TuVung: '4分の1（1/4）', Hiragana: 'よんぶんのいち', NghiaTV: 'một phần tư' }],
    {},
  );
  assert.deepEqual(errors, []);
});

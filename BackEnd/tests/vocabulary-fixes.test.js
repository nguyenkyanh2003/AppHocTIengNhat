import assert from 'node:assert/strict';
import fs from 'node:fs';
import test from 'node:test';

import { planFixes, reviewFixes } from '../src/modules/vocabulary/vocabulary-fixes.js';
import { reviewTagRows, tagKey } from '../src/modules/vocabulary/vocabulary-tags.review.js';

const add = (over = {}) => ({
  source: 'N4:3',
  action: 'add',
  word: '探します',
  hiragana: 'さがします',
  meaning: 'Tìm (thứ mình muốn có)',
  hanviet: 'THÁM',
  level: 'N4',
  source_lesson: 'Bài 26',
  ...over,
});

const setMeaning = (over = {}) => ({
  source: 'N5:803',
  action: 'set-meaning',
  word: '先生',
  hiragana: 'せんせい',
  from: 'Thầy/ cô',
  to: 'Thầy/ cô; bác sĩ (cách gọi bác sĩ)',
  ...over,
});

const rename = (over = {}) => ({
  source: 'gạch đầu dòng',
  action: 'rename',
  from: { word: '一冊', hiragana: 'ーさつ' },
  to: { word: '~冊', hiragana: '~さつ' },
  ...over,
});

const remove = (over = {}) => ({
  source: 'dấu - thừa',
  action: 'remove',
  word: 'おもちです-',
  hiragana: 'おもちです',
  meaning: 'Có (tôn kính ngữ)',
  keep: { word: 'お持ちです', hiragana: 'おもちです' },
  reason: 'Bản sao của お持ちです.',
  ...over,
});

const merge = (over = {}) => ({
  source: 'bài học trùng',
  action: 'merge',
  word: '便利',
  hiragana: 'べんり',
  meaning: 'tiện lợi',
  into: { word: '便利', hiragana: 'べんり[な]' },
  reason: 'Từ của bài học trùng từ giáo trình.',
  ...over,
});

const setHanviet = (over = {}) => ({
  source: 'soát Hán Việt',
  action: 'set-hanviet',
  word: '韓国',
  hiragana: 'かんこく',
  from: 'QUỐC',
  to: 'HÀN QUỐC',
  ...over,
});

const skip = (over = {}) => ({
  source: 'N5:454',
  action: 'skip',
  word: '主人',
  hiragana: 'しゅじん',
  reason: 'Đã có ở N2.',
  ...over,
});

/** DB giả: Map khoá `(word, hiragana)` → bản ghi, như script dựng từ MongoDB. */
const existing = (...docs) => new Map(docs.map((doc) => [tagKey(doc), doc]));

const reviewed = (fixes) => {
  const { accepted, errors } = reviewFixes(fixes);
  assert.deepEqual(errors, []);
  return accepted;
};

// --- kiểm file sửa ---------------------------------------------------------

test('dòng thêm được chuẩn hoá đúng như công cụ nhập từ vựng', () => {
  // Cùng một luật chuẩn hoá với `import-vocabulary.js`, nếu không khoá
  // `(word, hiragana)` của từ thêm ở đây sẽ lệch với từ đã nhập trước đó.
  const [row] = reviewed([
    add({ word: '　教えます ', hiragana: 'おしえます (II)', meaning: '  Dạy   học ', level: 'n4' }),
  ]);

  assert.equal(row.word, '教えます');
  assert.equal(row.hiragana, 'おしえます');
  assert.equal(row.verb_group, 2);
  assert.equal(row.meaning, 'Dạy học');
  assert.equal(row.level, 'N4');
  assert.equal(row.source_lesson, 'Bài 26');
});

test('chú thích cách dùng trong cột từ được gỡ khỏi khoá, giữ ở cách đọc', () => {
  const [row] = reviewed([
    add({ word: '[病気が~]治ります', hiragana: '[びょうきが~]なおります', meaning: 'Khỏi [bệnh]' }),
  ]);
  assert.equal(row.word, '治ります');
  assert.equal(row.hiragana, '[びょうきが~]なおります');
});

test('dòng sai bị báo kèm nguồn, không bị lọc bỏ trong im lặng', () => {
  const { accepted, errors } = reviewFixes([
    add({ hiragana: '一にん', source: 'N5:538' }),
    add({ level: undefined, source: 'N5:539' }),
    add({ source: '' }),
    { source: 'N1:1', action: 'replace' },
    setMeaning({ to: '' }),
    rename({ to: { word: '~冊' } }),
    skip({ reason: '' }),
  ]);

  assert.equal(accepted.length, 0);
  assert.equal(errors.length, 7);
  assert.deepEqual(errors.slice(0, 2).map((error) => error.source), ['N5:538', 'N5:539']);
  assert.match(errors[0].messages.join(' '), /kana/);
  assert.match(errors[3].messages.join(' '), /replace/);
});

test('hai dòng thêm cùng khoá, hoặc đổi khoá trùng một dòng thêm, đều là lỗi', () => {
  const { errors } = reviewFixes([
    add(),
    add({ source: 'N4:4', meaning: 'Tìm' }),
    add({ word: '~冊', hiragana: '~さつ', meaning: '- Quyển', source: 'N4:9' }),
    rename(),
  ]);
  assert.equal(errors.length, 2);
  assert.match(errors[0].messages.join(' '), /Trùng/);
  assert.match(errors[1].messages.join(' '), /~冊/);
});

test('dòng bỏ qua được viện dẫn một từ đang sửa nghĩa, nhưng không được viện dẫn từ sẽ biến mất', () => {
  // Sửa nghĩa không làm từ biến mất, nên "từ đã có" vẫn đúng; đổi khoá hay xoá thì không.
  assert.deepEqual(reviewFixes([
    skip({ word: '先生', hiragana: 'せんせい' }),
    setMeaning(),
    skip({ word: '先生', hiragana: 'せんせい', source: 'N5:12' }),
  ]).errors, []);

  const { errors } = reviewFixes([
    rename(),
    skip({ word: '一冊', hiragana: 'ーさつ' }),
    remove(),
    skip({ word: 'おもちです-', hiragana: 'おもちです' }),
    setMeaning(),
    setMeaning({ source: 'N5:999' }),
  ]);
  assert.deepEqual(errors.map((error) => error.index), [1, 3, 5]);
});

test('file không phải mảng thì báo một lỗi, không ném', () => {
  assert.deepEqual(reviewFixes({}).accepted, []);
  assert.equal(reviewFixes(null).errors.length, 1);
});

// --- tính việc cần ghi -------------------------------------------------------

test('thêm từ chưa có: một lệnh insert đủ trường; từ đã có y hệt thì coi như đã xong', () => {
  const fixes = reviewed([add()]);

  const fresh = planFixes(fixes, existing());
  assert.deepEqual(fresh.outcomes.map((outcome) => outcome.status), ['apply']);
  assert.deepEqual(fresh.operations, [{
    insertOne: {
      document: {
        word: '探します',
        hiragana: 'さがします',
        meaning: 'Tìm (thứ mình muốn có)',
        level: 'N4',
        hanviet: 'THÁM',
        source_lesson: 'Bài 26',
      },
    },
  }]);

  const again = planFixes(fixes, existing({ _id: 'v1', word: '探します', hiragana: 'さがします', meaning: 'Tìm (thứ mình muốn có)', level: 'N4' }));
  assert.deepEqual(again.outcomes.map((outcome) => outcome.status), ['done']);
  assert.deepEqual(again.operations, []);
});

test('thêm một khoá đã có với nội dung khác là xung đột, không ghi đè', () => {
  const plan = planFixes(reviewed([add()]), existing({ _id: 'v1', word: '探します', hiragana: 'さがします', meaning: 'Tìm', level: 'N5' }));
  assert.deepEqual(plan.outcomes.map((outcome) => outcome.status), ['conflict']);
  assert.deepEqual(plan.operations, []);
});

test('sửa nghĩa chỉ ghi khi nghĩa trong DB đúng là nghĩa cũ đã soát', () => {
  const fixes = reviewed([setMeaning()]);
  const doc = (meaning) => existing({ _id: 'v9', word: '先生', hiragana: 'せんせい', meaning, level: 'N5' });

  const plan = planFixes(fixes, doc('Thầy/ cô'));
  assert.deepEqual(plan.outcomes.map((outcome) => outcome.status), ['apply']);
  // Điều kiện kèm nghĩa cũ: ai đó sửa tay giữa lúc soát và lúc ghi thì lệnh không khớp gì.
  assert.deepEqual(plan.operations, [{
    updateOne: {
      filter: { _id: 'v9', meaning: 'Thầy/ cô' },
      update: { $set: { meaning: 'Thầy/ cô; bác sĩ (cách gọi bác sĩ)' } },
    },
  }]);

  assert.equal(planFixes(fixes, doc('Thầy/ cô; bác sĩ (cách gọi bác sĩ)')).outcomes[0].status, 'done');
  assert.equal(planFixes(fixes, doc('Giáo viên')).outcomes[0].status, 'conflict');
  assert.equal(planFixes(fixes, existing()).outcomes[0].status, 'missing');
});

test('đổi khoá giữ nguyên bản ghi (cùng _id) để không mất tiến độ ôn tập', () => {
  const fixes = reviewed([rename()]);
  const oldDoc = { _id: 'v3', word: '一冊', hiragana: 'ーさつ', meaning: 'Quyển', level: 'N4' };
  const newDoc = { ...oldDoc, word: '~冊', hiragana: '~さつ' };

  const plan = planFixes(fixes, existing(oldDoc));
  assert.equal(plan.outcomes[0].status, 'apply');
  assert.deepEqual(plan.operations, [{
    updateOne: {
      filter: { _id: 'v3', word: '一冊', hiragana: 'ーさつ' },
      update: { $set: { word: '~冊', hiragana: '~さつ' } },
    },
  }]);

  assert.equal(planFixes(fixes, existing(newDoc)).outcomes[0].status, 'done');
  assert.equal(planFixes(fixes, existing(oldDoc, { ...newDoc, _id: 'v4' })).outcomes[0].status, 'conflict');
  assert.equal(planFixes(fixes, existing()).outcomes[0].status, 'missing');
});

test('sửa Hán Việt chỉ ghi khi DB đúng là bản cũ đã soát; bản mới trống thì bỏ hẳn trường', () => {
  const doc = (hanviet) => existing({ _id: 'v5', word: '韓国', hiragana: 'かんこく', meaning: 'Hàn Quốc', hanviet });
  const fixes = reviewed([setHanviet()]);

  assert.deepEqual(planFixes(fixes, doc('QUỐC')).operations, [{
    updateOne: { filter: { _id: 'v5', hanviet: 'QUỐC' }, update: { $set: { hanviet: 'HÀN QUỐC' } } },
  }]);
  assert.equal(planFixes(fixes, doc('HÀN QUỐC')).outcomes[0].status, 'done');
  assert.equal(planFixes(fixes, doc('HÀN')).outcomes[0].status, 'conflict');

  // Từ viết toàn kana không có âm Hán Việt: file gốc ghi nhầm thì bỏ trường đi.
  const cleared = reviewed([setHanviet({ word: 'やります', hiragana: 'やります', from: 'THAM GIA', to: '' })]);
  const kana = (hanviet) => existing({ _id: 'v6', word: 'やります', hiragana: 'やります', meaning: 'Làm', hanviet });
  assert.deepEqual(planFixes(cleared, kana('THAM GIA')).operations, [{
    updateOne: { filter: { _id: 'v6', hanviet: 'THAM GIA' }, update: { $unset: { hanviet: '' } } },
  }]);
  assert.equal(planFixes(cleared, kana(undefined)).outcomes[0].status, 'done');

  // Điền Hán Việt còn thiếu: điều kiện là trường đang trống.
  const filled = reviewed([setHanviet({ word: '鍵', hiragana: 'かぎ', from: '', to: 'KIỆN' })]);
  const key = existing({ _id: 'v8', word: '鍵', hiragana: 'かぎ', meaning: 'Chìa khóa' });
  assert.deepEqual(planFixes(filled, key).operations, [{
    updateOne: { filter: { _id: 'v8', hanviet: { $in: [null, ''] } }, update: { $set: { hanviet: 'KIỆN' } } },
  }]);
});

test('sửa nghĩa và sửa Hán Việt cùng một từ được, hai dòng sửa cùng một trường thì không', () => {
  assert.deepEqual(reviewFixes([setHanviet(), setMeaning({ word: '韓国', hiragana: 'かんこく' })]).errors, []);
  const { errors } = reviewFixes([setHanviet(), setHanviet({ source: 'lần hai', to: 'HÀN' }), setHanviet({ to: 'QUỐC' })]);
  assert.match(errors[0].messages.join(' '), /Trùng/);
  assert.match(errors[1].messages.join(' '), /giống hệt/);
});

const split = (over = {}) => rename({
  source: 'ô nhiều dạng viết từ lần nhập cũ',
  from: { word: '暑い、熱い', hiragana: 'あつい', meaning: 'Nóng' },
  to: { word: '暑い', hiragana: 'あつい', meaning: 'Nóng (thời tiết)', hanviet: 'THỬ' },
  ...over,
});

test('tách ô nhiều dạng viết đã lỡ vào DB: đổi khoá kèm nghĩa và Hán Việt của dạng giữ lại', () => {
  const fixes = reviewed([split()]);
  const oldDoc = { _id: 'v7', word: '暑い、熱い', hiragana: 'あつい', meaning: 'Nóng', hanviet: 'THỬ NHIỆT', level: 'N5' };

  const plan = planFixes(fixes, existing(oldDoc));
  assert.equal(plan.outcomes[0].status, 'apply');
  assert.deepEqual(plan.operations, [{
    updateOne: {
      filter: { _id: 'v7', word: '暑い、熱い', hiragana: 'あつい', meaning: 'Nóng' },
      update: { $set: { word: '暑い', hiragana: 'あつい', meaning: 'Nóng (thời tiết)', hanviet: 'THỬ' } },
    },
  }]);

  assert.equal(planFixes(fixes, existing({ ...oldDoc, meaning: 'Nóng bức' })).outcomes[0].status, 'conflict');
  const renamed = { ...oldDoc, word: '暑い', meaning: 'Nóng (thời tiết)', hanviet: 'THỬ' };
  assert.equal(planFixes(fixes, existing(renamed)).outcomes[0].status, 'done');
});

test('đổi nghĩa khi đổi khoá phải kèm nghĩa cũ; khoá mới phải nhập lại được bằng công cụ nhập', () => {
  const { errors } = reviewFixes([
    split({ from: { word: '暑い、熱い', hiragana: 'あつい' } }),
    split({ source: 'khoá mới vẫn nhiều dạng', to: { word: '早く、速く', hiragana: 'はやく' } }),
  ]);
  assert.equal(errors.length, 2);
  assert.match(errors[0].messages.join(' '), /nghĩa cũ/);
  assert.match(errors[1].messages.join(' '), /nhiều dạng/);
});

test('xoá bản sao chỉ khi bản giữ lại còn đó và nghĩa đúng như lúc soát', () => {
  const fixes = reviewed([remove()]);
  const copy = { _id: 'v7', word: 'おもちです-', hiragana: 'おもちです', meaning: 'Có (tôn kính ngữ)', level: 'N4' };
  const kept = { _id: 'v8', word: 'お持ちです', hiragana: 'おもちです', meaning: 'Có (tôn kính ngữ)', level: 'N4' };

  const plan = planFixes(fixes, existing(copy, kept));
  assert.equal(plan.outcomes[0].status, 'apply');
  assert.deepEqual(plan.operations, [{
    deleteOne: { filter: { _id: 'v7', word: 'おもちです-', hiragana: 'おもちです', meaning: 'Có (tôn kính ngữ)' } },
  }]);

  assert.equal(planFixes(fixes, existing(kept)).outcomes[0].status, 'done');
  assert.equal(planFixes(fixes, existing(copy, { ...kept, _id: 'v9' })).operations.length, 1);
  assert.equal(planFixes(fixes, existing({ ...copy, meaning: 'Khác' }, kept)).outcomes[0].status, 'conflict');
  // Không bao giờ xoá bản ghi cuối cùng của một từ.
  assert.equal(planFixes(fixes, existing(copy)).outcomes[0].status, 'missing');
});

test('xoá phải có bản giữ lại khác chính nó, nghĩa cũ và lý do', () => {
  assert.deepEqual(reviewFixes([remove()]).errors, []);
  const { errors } = reviewFixes([
    remove({ keep: { word: 'おもちです-', hiragana: 'おもちです' } }),
    remove({ meaning: '' }),
    remove({ reason: undefined }),
    remove({ keep: undefined }),
  ]);
  assert.equal(errors.length, 4);
});

test('gộp bản sao vào bản giữ lại: kèm mã hai bản và bài học của bản sao', () => {
  const fixes = reviewed([merge()]);
  const copy = { _id: 'd1', word: '便利', hiragana: 'べんり', meaning: 'tiện lợi', level: 'N4', lesson: 'L7' };
  const kept = { _id: 'c1', word: '便利', hiragana: 'べんり[な]', meaning: 'Tiện lợi', level: 'N5' };

  const plan = planFixes(fixes, existing(copy, kept));
  assert.equal(plan.outcomes[0].status, 'apply');
  // Gộp đụng nhiều collection nên không đi qua bulkWrite của Vocabulary.
  assert.deepEqual(plan.operations, [{
    merge: {
      fromId: 'd1',
      intoId: 'c1',
      lesson: 'L7',
      filter: { _id: 'd1', word: '便利', hiragana: 'べんり', meaning: 'tiện lợi' },
    },
  }]);

  assert.equal(planFixes(fixes, existing(kept)).outcomes[0].status, 'done');
  assert.equal(planFixes(fixes, existing({ ...copy, meaning: 'khác' }, kept)).outcomes[0].status, 'conflict');
  assert.equal(planFixes(fixes, existing(copy)).outcomes[0].status, 'missing');
  assert.equal(planFixes(fixes, existing({ ...copy, lesson: undefined }, kept)).operations[0].merge.lesson, null);
});

test('gộp phải có bản giữ lại khác chính nó, nghĩa hiện tại và lý do; bản giữ lại còn sửa được nghĩa', () => {
  assert.deepEqual(reviewFixes([merge()]).errors, []);
  // Bản giữ lại không bị "chiếm": cùng file có thể sửa nghĩa của nó.
  assert.deepEqual(reviewFixes([
    merge(),
    setMeaning({ word: '便利', hiragana: 'べんり[な]', from: 'Tiện lợi', to: 'Tiện lợi, thuận tiện' }),
  ]).errors, []);

  const { errors } = reviewFixes([
    merge({ into: { word: '便利', hiragana: 'べんり' } }),
    merge({ meaning: ' ' }),
    merge({ reason: '' }),
    merge({ into: { word: '便利' } }),
  ]);
  assert.equal(errors.length, 4);
});

test('dòng bỏ qua phải trỏ tới một từ thật sự có trong DB', () => {
  const fixes = reviewed([skip()]);
  const present = planFixes(fixes, existing({ _id: 'v5', word: '主人', hiragana: 'しゅじん', meaning: 'Chồng', level: 'N2' }));
  assert.equal(present.outcomes[0].status, 'skip');
  assert.deepEqual(present.operations, []);
  assert.equal(planFixes(fixes, existing()).outcomes[0].status, 'missing');
});

// --- file dữ liệu thật -------------------------------------------------------

const readJson = (path) => JSON.parse(fs.readFileSync(new URL(path, import.meta.url), 'utf8'));

test('data/vocabulary-fixes.json hợp lệ toàn bộ', () => {
  const fixes = readJson('../data/vocabulary-fixes.json');
  const { accepted, errors } = reviewFixes(fixes);
  assert.deepEqual(errors, []);
  assert.equal(accepted.length, fixes.length);
});

test('mọi từ thêm và mọi khoá mới đều có nhãn chia bộ, khoá cũ không còn nhãn', () => {
  // Thiếu nhãn thì từ có trong kho nhưng không nằm trong bộ học nào — người học không thấy.
  const { accepted: fixes } = reviewFixes(readJson('../data/vocabulary-fixes.json'));
  const { accepted: tags } = reviewTagRows(readJson('../data/vocabulary-tags.json'));
  const levelByKey = new Map(tags.map((row) => [tagKey(row), row.level]));

  for (const fix of fixes) {
    if (fix.action === 'add') {
      assert.equal(levelByKey.get(tagKey(fix)), fix.level, `thiếu nhãn: ${fix.word} (${fix.hiragana})`);
    }
    if (fix.action === 'rename') {
      assert.ok(levelByKey.has(tagKey(fix.to)), `thiếu nhãn: ${fix.to.word} (${fix.to.hiragana})`);
      assert.ok(!levelByKey.has(tagKey(fix.from)), `còn nhãn khoá cũ: ${fix.from.word} (${fix.from.hiragana})`);
    }
    if (fix.action === 'remove' || fix.action === 'merge') {
      assert.ok(!levelByKey.has(tagKey(fix)), `còn nhãn của từ đã xoá: ${fix.word} (${fix.hiragana})`);
    }
  }
});

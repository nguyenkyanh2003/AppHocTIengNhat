import assert from 'node:assert/strict';
import test from 'node:test';

import { SEARCH_FIELDS, createSearchService } from '../src/modules/search/search.service.js';

/**
 * Repository giả: trả bản ghi dựng sẵn theo nhóm và ghi lại mọi truy vấn. Có
 * `limit` thì cắt như MongoDB thật — bỏ qua nó từng che mất lỗi bỏ sót kết quả.
 */
const fakeRepository = (docs = {}) => {
  const calls = [];
  return {
    calls,
    findMatches: async (type, filter, limit) => {
      calls.push({ type, filter, limit });
      return (docs[type] ?? []).slice(0, limit);
    },
  };
};

const search = (docs, query) => {
  const repository = fakeRepository(docs);
  const service = createSearchService({ searchRepository: repository });
  return { repository, results: service.search({ limitPerType: 5, ...query }) };
};

test('tìm cả năm nhóm, mỗi nhóm trên đúng các trường đã chốt', async () => {
  const { repository, results } = search({}, { q: '月' });
  await results;

  assert.deepEqual(repository.calls.map((call) => call.type), ['vocabulary', 'kanji', 'lesson', 'grammar', 'news']);
  for (const call of repository.calls) {
    const fields = call.filter.$or.map((condition) => Object.keys(condition)[0]);
    assert.deepEqual(fields, SEARCH_FIELDS[call.type]);
  }
  assert.deepEqual(SEARCH_FIELDS, {
    vocabulary: ['word', 'hiragana', 'hanviet', 'meaning'],
    kanji: ['character', 'hanviet', 'onyomi', 'kunyomi', 'meaning'],
    lesson: ['title', 'description'],
    grammar: ['title', 'structure', 'meaning'],
    news: ['title', 'description'],
  });
});

test('ngữ pháp chỉ lấy bài đang hiển thị; âm Kun khớp được okurigana', async () => {
  const { repository, results } = search({}, { q: 'たべる' });
  await results;

  const grammar = repository.calls.find((call) => call.type === 'grammar');
  assert.equal(grammar.filter.is_active, true);
  const kanji = repository.calls.find((call) => call.type === 'kanji');
  const kunyomi = kanji.filter.$or.find((condition) => 'kunyomi' in condition).kunyomi;
  const meaning = kanji.filter.$or.find((condition) => 'meaning' in condition).meaning;
  assert.ok(kunyomi.test('た(べる)'));
  assert.ok(!meaning.test('た(べる)'));
});

test('xếp độ liên quan trước rồi mới cắt theo giới hạn mỗi nhóm', async () => {
  const vocabulary = [
    { _id: 'v1', word: '今月', hiragana: 'こんげつ', meaning: 'Tháng này', level: 'N5' },
    { _id: 'v2', word: '月曜日', hiragana: 'げつようび', meaning: 'Thứ hai', level: 'N5' },
    { _id: 'v3', word: '月', hiragana: 'つき', meaning: 'Mặt trăng, trăng', level: 'N5' },
  ];
  const { results } = search({ vocabulary }, { q: '月', limitPerType: 2 });

  assert.deepEqual((await results).map((result) => result.title), ['月', '月曜日']);
});

test('bản ghi khớp trọn vẫn lên đầu khi nhóm có hơn 200 bản ghi khớp', async () => {
  const vocabulary = [
    ...Array.from({ length: 200 }, (_, index) => ({
      _id: `v${index}`, word: `日本${index}`, hiragana: 'にほん', meaning: 'Nhật Bản', level: 'N5',
    })),
    { _id: 'v200', word: '本', hiragana: 'ほん', meaning: 'Sách', level: 'N5' },
  ];
  const { results } = search({ vocabulary }, { q: '本' });

  assert.equal((await results)[0].id, 'v200');
});

test('khớp cách đọc trọn vẹn đứng trên khớp đầu chuỗi; hoà thì từ ngắn và cấp thấp trước', async () => {
  const vocabulary = [
    { _id: 'v1', word: '付き合う', hiragana: 'つきあう', meaning: 'Hẹn hò', level: 'N3' },
    { _id: 'v2', word: '突き', hiragana: 'つき', meaning: 'Cú đâm', level: 'N1' },
    { _id: 'v3', word: '月', hiragana: 'つき', meaning: 'Mặt trăng', level: 'N5' },
  ];
  const { results } = search({ vocabulary }, { q: 'つき' });

  assert.deepEqual((await results).map((result) => result.id), ['v3', 'v2', 'v1']);
});

test('gõ hiragana tìm được chữ Kanji qua âm On lưu bằng katakana', async () => {
  const kanji = [
    { _id: 'k2', character: '学', onyomi: ['ガク'], kunyomi: ['まな(ぶ)'], meaning: 'Học', level: 'N5' },
    { _id: 'k1', character: '月', hanviet: 'Nguyệt', onyomi: ['ゲツ', 'ガツ'], kunyomi: ['つき'], meaning: 'Mặt trăng, tháng', level: 'N5' },
  ];
  const { repository, results } = search({ kanji }, { q: 'げつ' });

  const onyomi = repository.calls.find((call) => call.type === 'kanji').filter.$or.find((condition) => 'onyomi' in condition).onyomi;
  assert.ok(onyomi.test('ゲツ'));
  assert.equal((await results)[0].title, '月');
});

test('mọi nhóm trả cùng một dạng kết quả, theo thứ tự nhóm cố định', async () => {
  const { results } = search(
    {
      news: [{ _id: { toString: () => 'n1' }, title: '月の話', description: 'Tin về trăng', image_url: 'https://img/n1.jpg', level: 'N4' }],
      grammar: [{ _id: 'g1', title: '〜月に', structure: 'N + に', meaning: 'Vào tháng', level: 'N5' }],
      lesson: [{ _id: 'l1', title: 'Tình huống: Ngắm trăng', description: 'Tháng 月', level: 'N4' }],
      kanji: [{ _id: 'k1', character: '月', hanviet: 'Nguyệt', onyomi: ['ゲツ'], kunyomi: ['つき'], meaning: 'Mặt trăng, tháng', level: 'N5' }],
      vocabulary: [{ _id: 'v1', word: '月', hiragana: 'つき', meaning: 'Mặt trăng', level: 'N5', image_url: null }],
    },
    { q: '月' },
  );

  assert.deepEqual(await results, [
    { id: 'v1', type: 'vocabulary', title: '月', subtitle: 'つき', description: 'Mặt trăng', image_url: null, level: 'N5' },
    { id: 'k1', type: 'kanji', title: '月', subtitle: 'Nguyệt', description: 'Mặt trăng, tháng', image_url: null, level: 'N5' },
    { id: 'l1', type: 'lesson', title: 'Tình huống: Ngắm trăng', subtitle: null, description: 'Tháng 月', image_url: null, level: 'N4' },
    { id: 'g1', type: 'grammar', title: '〜月に', subtitle: 'N + に', description: 'Vào tháng', image_url: null, level: 'N5' },
    { id: 'n1', type: 'news', title: '月の話', subtitle: null, description: 'Tin về trăng', image_url: 'https://img/n1.jpg', level: 'N4' },
  ]);
});

test('từ khoá được chuẩn hoá trước khi dựng truy vấn', async () => {
  const { repository, results } = search({}, { q: 'mặt trăng'.normalize('NFD') });
  await results;

  const meaning = repository.calls[0].filter.$or.find((condition) => 'meaning' in condition).meaning;
  assert.ok(meaning.test('Mặt trăng, trăng'));
});

test('không nhóm nào khớp thì trả mảng rỗng', async () => {
  const { results } = search({}, { q: 'không-tồn-tại' });
  assert.deepEqual(await results, []);
});

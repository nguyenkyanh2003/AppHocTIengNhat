import assert from 'node:assert/strict';
import test from 'node:test';

import Grammar from '../model/Grammar.js';
import Kanji from '../model/Kanji.js';
import Lesson from '../model/Lesson.js';
import News from '../model/News.js';
import Vocabulary from '../model/Vocabulary.js';
import { SEARCH_PROJECTIONS, createSearchRepository } from '../src/modules/search/search.repository.js';
import { SEARCH_FIELDS } from '../src/modules/search/search.service.js';

const MODELS = { vocabulary: Vocabulary, kanji: Kanji, lesson: Lesson, grammar: Grammar, news: News };

/** Model giả ghi lại chuỗi truy vấn Mongoose. */
const fakeModel = (name, calls) => ({
  find(filter) {
    calls.push([name, 'find', filter]);
    const chain = {
      select(fields) { calls.push([name, 'select', fields]); return chain; },
      sort(order) { calls.push([name, 'sort', order]); return chain; },
      limit(count) { calls.push([name, 'limit', count]); return chain; },
      lean: async () => [{ _id: `${name}-1` }],
    };
    return chain;
  },
});

test('lấy mọi bản ghi khớp của đúng model, chỉ trường cần hiển thị, thứ tự ổn định', async () => {
  const calls = [];
  const repository = createSearchRepository({
    Vocabulary: fakeModel('Vocabulary', calls),
    Kanji: fakeModel('Kanji', calls),
    Lesson: fakeModel('Lesson', calls),
    Grammar: fakeModel('Grammar', calls),
    News: fakeModel('News', calls),
  });
  const filter = { $or: [{ title: /月/i }] };

  const docs = await repository.findMatches('lesson', filter);

  assert.deepEqual(docs, [{ _id: 'Lesson-1' }]);
  // Không `limit`: cắt trước khi xếp hạng làm mất bản ghi khớp trọn nằm sau.
  assert.deepEqual(calls, [
    ['Lesson', 'find', filter],
    ['Lesson', 'select', SEARCH_PROJECTIONS.lesson],
    ['Lesson', 'sort', { _id: 1 }],
  ]);
});

test('không tải nội dung HTML hay lời thoại video vào kết quả tìm kiếm', () => {
  for (const projection of Object.values(SEARCH_PROJECTIONS)) {
    assert.doesNotMatch(projection, /content_html|videos|transcript|examples/);
  }
});

test('nhóm lạ là lỗi lập trình, không âm thầm trả rỗng', async () => {
  const repository = createSearchRepository({});
  await assert.rejects(() => repository.findMatches('users', {}), /users/);
});

test('mọi trường được tìm đều có trong model và được lấy về để xếp hạng', () => {
  for (const [type, fields] of Object.entries(SEARCH_FIELDS)) {
    const projected = SEARCH_PROJECTIONS[type].split(' ');
    for (const field of [...fields, 'level']) {
      assert.ok(MODELS[type].schema.path(field), `${type}.${field} không có trong model`);
      assert.ok(projected.includes(field), `${type}.${field} không được lấy về`);
    }
  }
});

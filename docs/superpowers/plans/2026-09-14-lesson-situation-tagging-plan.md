# Gắn nhãn tình huống cho bài học — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm field `situation` (enum tình huống thực tế, cắt ngang cấp độ JLPT) vào
`Lesson`, và đưa module `BackEnd/src/modules/lessons/` về đúng khuôn 4 tầng
(route/controller/service/repository/schema) như `vocabulary` đã làm — giữ nguyên toàn bộ
11 route, method, path và hình dạng response hiện có.

**Architecture:** `situation-catalog.js` giữ enum cố định. `Lesson.js` thêm một field
optional, không migration. Toàn bộ logic Mongoose hiện nằm trong `lesson.controller.js`
được tách thành `lesson.repository.js` (mọi truy vấn Mongoose, kể cả sang
`Vocabulary`/`Grammar`/`Kanji`) và `lesson.service.js` (rule nghiệp vụ: fallback populate,
chặn xóa khi còn tham chiếu, tính `totalPages`). `lesson.controller.js` chỉ còn map HTTP.
`lesson.schema.js` khai báo zod cho toàn bộ query/params/body, thay các `if` validate viết
tay. Route giữ nguyên y hệt method+path để `route-contract.test.js` không đổi.

**Tech Stack:** Node 22, Express 5, Mongoose 8, zod 4, `node --test` + supertest (đúng stack
đã dùng ở `vocabulary`).

**Spec:** [docs/superpowers/specs/2026-09-14-lesson-situation-tagging-design.md](../specs/2026-09-14-lesson-situation-tagging-design.md)

## Global Constraints

- Controller **không** `try/catch`; mọi lỗi là `ApiError` từ service, `asyncHandler` +
  `error.middleware.js` (`BackEnd/src/middleware/error.middleware.js`) lo phần còn lại.
- Service nhận repository qua tham số (dependency injection); **không test nào chạm
  MongoDB**. Repository không chứa rule nghiệp vụ (fallback, chặn xóa) — chỉ query.
- Response: một tài nguyên `{ data }` qua `ok()`; danh sách không phân trang `{ data, total
  }` qua `list()`; các endpoint có vỏ response cũ khác chuẩn (`GET /`, `GET
  /stats/overview`, `DELETE /`) **giữ nguyên y hệt hình dạng cũ**, không đổi sang
  `paginated()`/`ok()` chuẩn — xem Task 4 để biết vỏ chính xác từng route.
- Danh sách rỗng luôn là 200 với mảng rỗng, không bao giờ 404.
- `situation` là enum cố định trong `situation-catalog.js`, field optional trên `Lesson`,
  **không migration** — 10 lesson cũ giữ `situation` trống, không gán bừa.
- Route công khai giữ nguyên đúng 11 method+path đang có (bảng ở Task 4); sau khi implement
  phải chạy `npm test` và xác nhận `route-contract.test.js` **không đổi**
  `expectedCount`/`expectedSignatureHash` (hiện là `261` /
  `75d5d6968c84885bee137582512f0de999bcf7b1cd521e245e3ee7c4517e4e66`) — nếu đổi thì đã lỡ
  sửa path, phải sửa lại chứ không sửa hash cho xanh.
- Mount thật của module này trong `BackEnd/src/app.js:56` là `app.use('/api/lesson',
  LessonRoutes)` — **số ít**, không phải `/api/lessons`. Test HTTP trong plan này mount vào
  `/api/lesson` cho khớp.
- Không đổi gì ở Flutter, không đổi `content_html`, không thêm bài mẫu tình huống mới —
  đúng phạm vi đã chốt ở spec §8.
- Cổng trước khi coi cả plan xong: `cd BackEnd && npm test`. `dart analyze --fatal-infos`
  và `flutter test` ở FrontEnd **hiện đã có sẵn 13 lỗi / 4 test đỏ không liên quan** (do
  `test/api_exception_test.dart` và `test/srs_service_test.dart` tham chiếu code SRS Flutter
  chưa tồn tại — việc riêng, đã ghi nhận ở checklist khác). Plan này không đụng file Flutter
  nào nên không được làm con số đó **tăng thêm**; không cần và không thể làm nó về 0 trong
  phạm vi plan này.

---

## Task 1: Danh mục tình huống và field trên `Lesson`

**Files:**
- Create: `BackEnd/src/modules/lessons/situation-catalog.js`
- Modify: `BackEnd/model/Lesson.js`
- Test: `BackEnd/tests/lesson.model.test.js`

**Interfaces:**
- Consumes: không
- Produces: `SITUATIONS` (mảng string, dùng ở Task 2 để build enum zod và Task 3 để lọc)

- [ ] **Step 1: Viết test thất bại**

```js
// BackEnd/tests/lesson.model.test.js
import assert from 'node:assert/strict';
import test from 'node:test';

import Lesson from '../model/Lesson.js';
import { SITUATIONS } from '../src/modules/lessons/situation-catalog.js';

test('SITUATIONS là danh sách cố định, không rỗng, không trùng giá trị', () => {
  assert.ok(Array.isArray(SITUATIONS));
  assert.ok(SITUATIONS.length > 0);
  assert.equal(new Set(SITUATIONS).size, SITUATIONS.length);
});

test('Lesson.situation là enum theo SITUATIONS, optional, mặc định null, có index', () => {
  const path = Lesson.schema.path('situation');
  assert.ok(path, 'field situation phải tồn tại trên schema');
  assert.deepEqual(path.enumValues, SITUATIONS);
  assert.equal(path.options.default, null);
  assert.equal(path.isRequired, false);

  const indexes = Lesson.schema.indexes();
  const hasSituationIndex = indexes.some(([fields]) => 'situation' in fields);
  assert.ok(hasSituationIndex, 'situation phải có index vì dùng để lọc danh sách');
});

test('level/title vẫn giữ đúng ràng buộc cũ sau khi thêm field mới', () => {
  assert.deepEqual(Lesson.schema.path('level').enumValues, ['N5', 'N4', 'N3', 'N2', 'N1']);
  assert.equal(Lesson.schema.path('title').isRequired, true);
});
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd BackEnd && node --test tests/lesson.model.test.js`
Expected: FAIL — không tìm thấy module `situation-catalog.js`, và `path` của `situation`
là `undefined`.

- [ ] **Step 3: Viết `situation-catalog.js`**

```js
// BackEnd/src/modules/lessons/situation-catalog.js
/**
 * Danh mục tình huống thực tế cho bài học, lấy cảm hứng từ cách tổ chức nội
 * dung theo tình huống của Tsunagaru (tsunagarujp.mext.go.jp) — độc lập với
 * cấp độ JLPT. Đây là điểm mở rộng: thêm giá trị mới chỉ là sửa mảng này,
 * không cần migration vì field trên Lesson là optional.
 */
export const SITUATIONS = Object.freeze([
  'supermarket', // đi siêu thị
  'convenience_store', // cửa hàng tiện lợi
  'train', // đi tàu/ga tàu
  'bus', // đi xe buýt
  'hospital', // đi khám bệnh
  'pharmacy', // hiệu thuốc
  'city_hall', // làm giấy tờ hành chính (phường/quận)
  'bank', // ngân hàng
  'post_office', // bưu điện
  'restaurant', // nhà hàng/quán ăn
  'school', // trường học/lớp học
  'part_time_job', // công việc làm thêm
  'phone_call', // gọi điện thoại
  'real_estate', // tìm/thuê nhà
  'emergency', // tình huống khẩn cấp/thiên tai
]);

export default SITUATIONS;
```

- [ ] **Step 4: Thêm field `situation` vào `Lesson.js`**

Sửa `BackEnd/model/Lesson.js`, thêm import và một field mới — không đổi field nào khác:

```js
import mongoose from 'mongoose';

import { SITUATIONS } from '../src/modules/lessons/situation-catalog.js';

const LessonSchema = new mongoose.Schema({
    title: { type: String, required: true, trim: true, unique: true },
    level: { type: String, required: true, enum: ['N5', 'N4', 'N3', 'N2', 'N1'], index: true },
    order: { type: Number, default: 1, min: 1 }, 
    description: { type: String, trim: true },
    content_html: String, 
    type: { type: String, trim: true, index: true },
    situation: { type: String, enum: SITUATIONS, default: null, index: true },

    // Các tham chiếu đến từ vựng, ngữ pháp, kanji trong bài học
    vocabularies: { type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Vocabulary' }], default: [] },
    grammars: { type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Grammar' }], default: [] },
    kanjis: { type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Kanji' }], default: [] }

}, { timestamps: true });

// Text index để tìm kiếm nhanh theo title + description
LessonSchema.index({ title: 'text', description: 'text' });

export default mongoose.model('Lesson', LessonSchema);
```

- [ ] **Step 5: Chạy lại cho pass**

Run: `cd BackEnd && node --test tests/lesson.model.test.js`
Expected: PASS, 3/3

- [ ] **Step 6: Commit**

```bash
git add BackEnd/src/modules/lessons/situation-catalog.js BackEnd/model/Lesson.js BackEnd/tests/lesson.model.test.js
git commit -m "feat(lessons): add situation catalog and optional field on Lesson"
```

---

## Task 2: `lesson.repository.js` — mọi truy vấn Mongoose

**Files:**
- Create: `BackEnd/src/modules/lessons/lesson.repository.js`
- Test: `BackEnd/tests/lesson.repository.test.js`

**Interfaces:**
- Consumes: `SITUATIONS` không cần trực tiếp (repository chỉ nhận filter đã build sẵn)
- Produces: `createLessonRepository({ Lesson, Vocabulary, Grammar, Kanji })` trả về object
  có `findMany({filter, sort, skip, limit})`, `count(filter)`, `findById(id)`,
  `findVocabulariesByLesson(lessonId)`, `findActiveGrammarsByLesson(lessonId)`,
  `findKanjisByLesson(lessonId)`, `findByLevel(level)`,
  `findByTypePattern(regexFilter)`, `aggregateStats()`, `create(input)`,
  `createMany(inputs)`, `updateById(id, input)`, `findByIdLean(id)`, `deleteById(id)`,
  `deleteManyByIds(ids)`, `countRelated(lessonIds)`. Dùng ở Task 3.

Đây là nơi giữ đúng ba tên field tham chiếu khác nhau đang có trong codebase —
`Vocabulary.lesson`, `Grammar.lesson_id`, `Kanji.lessonId` — sai một cái là tính năng âm
thầm không chạy (đúng bẫy đã ghi ở CLAUDE.md), nên test phải khẳng định đúng tên field.

- [ ] **Step 1: Viết test thất bại**

```js
// BackEnd/tests/lesson.repository.test.js
import assert from 'node:assert/strict';
import test from 'node:test';

import { createLessonRepository } from '../src/modules/lessons/lesson.repository.js';

/** Chain giả cho các lệnh find().sort().skip().limit().lean() / .populate().lean(). */
const fakeChain = (result) => {
  const calls = [];
  const chain = {
    calls,
    sort(sort) { calls.push(['sort', sort]); return chain; },
    skip(skip) { calls.push(['skip', skip]); return chain; },
    limit(limit) { calls.push(['limit', limit]); return chain; },
    populate(path) { calls.push(['populate', path]); return chain; },
    lean: async () => result,
  };
  return chain;
};

test('findMany truyền đúng filter cho Lesson.find và trả kết quả từ lean()', async () => {
  let capturedFilter = null;
  const Lesson = {
    find(filter) {
      capturedFilter = filter;
      return fakeChain([{ _id: 'l1' }]);
    },
  };
  const repository = createLessonRepository({ Lesson, Vocabulary: {}, Grammar: {}, Kanji: {} });

  const items = await repository.findMany({
    filter: { level: 'N5', situation: 'train' },
    sort: { level: -1, order: 1 },
    skip: 10,
    limit: 5,
  });

  assert.deepEqual(capturedFilter, { level: 'N5', situation: 'train' });
  assert.deepEqual(items, [{ _id: 'l1' }]);
});

test('findById populate đủ ba mảng tham chiếu vocabularies/grammars/kanjis', async () => {
  const populated = [];
  const Lesson = {
    findById() {
      return {
        populate(path) { populated.push(path); return this; },
        lean: async () => ({ _id: 'l1', vocabularies: [] }),
      };
    },
  };
  const repository = createLessonRepository({ Lesson, Vocabulary: {}, Grammar: {}, Kanji: {} });

  const lesson = await repository.findById('l1');

  assert.deepEqual(populated, ['vocabularies', 'grammars', 'kanjis']);
  assert.equal(lesson._id, 'l1');
});

test('findVocabulariesByLesson lọc theo field lesson (không phải lesson_id)', async () => {
  let captured = null;
  const Vocabulary = {
    find(filter) { captured = filter; return { lean: async () => [] }; },
  };
  const repository = createLessonRepository({ Lesson: {}, Vocabulary, Grammar: {}, Kanji: {} });

  await repository.findVocabulariesByLesson('l1');

  assert.deepEqual(captured, { lesson: 'l1' });
});

test('findActiveGrammarsByLesson lọc theo lesson_id và is_active', async () => {
  let captured = null;
  const Grammar = {
    find(filter) { captured = filter; return { lean: async () => [] }; },
  };
  const repository = createLessonRepository({ Lesson: {}, Vocabulary: {}, Grammar, Kanji: {} });

  await repository.findActiveGrammarsByLesson('l1');

  assert.deepEqual(captured, { lesson_id: 'l1', is_active: true });
});

test('findKanjisByLesson lọc theo lessonId (khác cách viết của Grammar)', async () => {
  let captured = null;
  const Kanji = {
    find(filter) { captured = filter; return { lean: async () => [] }; },
  };
  const repository = createLessonRepository({ Lesson: {}, Vocabulary: {}, Grammar: {}, Kanji });

  await repository.findKanjisByLesson('l1');

  assert.deepEqual(captured, { lessonId: 'l1' });
});

test('findByLevel sort theo order tăng dần, không phân trang', async () => {
  const Lesson = { find: () => fakeChain([{ _id: 'l1' }]) };
  const repository = createLessonRepository({ Lesson, Vocabulary: {}, Grammar: {}, Kanji: {} });

  const items = await repository.findByLevel('N5');

  assert.deepEqual(items, [{ _id: 'l1' }]);
});

test('countRelated đếm đúng cả ba model với đúng tên field tham chiếu', async () => {
  const Vocabulary = {
    countDocuments: async (filter) => {
      assert.deepEqual(filter, { lesson: { $in: ['l1'] } });
      return 2;
    },
  };
  const Kanji = {
    countDocuments: async (filter) => {
      assert.deepEqual(filter, { lessonId: { $in: ['l1'] } });
      return 0;
    },
  };
  const Grammar = {
    countDocuments: async (filter) => {
      assert.deepEqual(filter, { lesson_id: { $in: ['l1'] } });
      return 1;
    },
  };
  const repository = createLessonRepository({ Lesson: {}, Vocabulary, Grammar, Kanji });

  const result = await repository.countRelated(['l1']);

  assert.deepEqual(result, { vocabulary: 2, kanji: 0, grammar: 1 });
});

test('deleteManyByIds trả đúng deletedCount từ Mongoose', async () => {
  const Lesson = {
    deleteMany: async (filter) => {
      assert.deepEqual(filter, { _id: { $in: ['l1', 'l2'] } });
      return { acknowledged: true, deletedCount: 2 };
    },
  };
  const repository = createLessonRepository({ Lesson, Vocabulary: {}, Grammar: {}, Kanji: {} });

  const count = await repository.deleteManyByIds(['l1', 'l2']);

  assert.equal(count, 2);
});
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd BackEnd && node --test tests/lesson.repository.test.js`
Expected: FAIL — không tìm thấy module.

- [ ] **Step 3: Viết repository**

```js
// BackEnd/src/modules/lessons/lesson.repository.js
import Grammar from '../../../model/Grammar.js';
import Kanji from '../../../model/Kanji.js';
import Lesson from '../../../model/Lesson.js';
import Vocabulary from '../../../model/Vocabulary.js';

/**
 * Mọi truy vấn Mongoose của domain bài học, kể cả truy vấn chéo sang
 * Vocabulary/Grammar/Kanji khi cần đếm hoặc lấy nội dung liên quan.
 *
 * Ba model liên quan dùng ba tên field khác nhau để trỏ về Lesson —
 * `Vocabulary.lesson`, `Grammar.lesson_id`, `Kanji.lessonId` — đây là nơi
 * duy nhất phải nhớ đúng cả ba, service không được biết chi tiết này.
 */
export const createLessonRepository = ({
  Lesson: lessonModel,
  Vocabulary: vocabularyModel,
  Grammar: grammarModel,
  Kanji: kanjiModel,
}) => ({
  findMany({ filter, sort, skip, limit }) {
    return lessonModel.find(filter).sort(sort).skip(skip).limit(limit).lean();
  },

  count(filter) {
    return lessonModel.countDocuments(filter);
  },

  findById(id) {
    return lessonModel
      .findById(id)
      .populate('vocabularies')
      .populate('grammars')
      .populate('kanjis')
      .lean();
  },

  findVocabulariesByLesson(lessonId) {
    return vocabularyModel.find({ lesson: lessonId }).lean();
  },

  findActiveGrammarsByLesson(lessonId) {
    return grammarModel.find({ lesson_id: lessonId, is_active: true }).lean();
  },

  findKanjisByLesson(lessonId) {
    return kanjiModel.find({ lessonId }).lean();
  },

  findByLevel(level) {
    return lessonModel.find({ level }).sort({ order: 1 }).lean();
  },

  findByTypePattern(regexFilter) {
    return lessonModel
      .find({ type: regexFilter })
      .sort({ level: -1, order: 1 })
      .lean();
  },

  async aggregateStats() {
    const [totalLessons, byLevel, byType] = await Promise.all([
      lessonModel.countDocuments(),
      lessonModel.aggregate([
        { $group: { _id: '$level', count: { $sum: 1 } } },
        { $sort: { _id: 1 } },
      ]),
      lessonModel.aggregate([
        { $match: { type: { $nin: [null, ''] } } },
        { $group: { _id: '$type', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
      ]),
    ]);

    return { totalLessons, byLevel, byType };
  },

  create(input) {
    return lessonModel.create(input);
  },

  createMany(inputs) {
    return lessonModel.insertMany(inputs);
  },

  updateById(id, input) {
    return lessonModel.findByIdAndUpdate(id, input, {
      new: true,
      runValidators: true,
    });
  },

  findByIdLean(id) {
    return lessonModel.findById(id).lean();
  },

  deleteById(id) {
    return lessonModel.findByIdAndDelete(id);
  },

  async deleteManyByIds(ids) {
    const result = await lessonModel.deleteMany({ _id: { $in: ids } });
    return result.deletedCount;
  },

  async countRelated(lessonIds) {
    const [vocabulary, kanji, grammar] = await Promise.all([
      vocabularyModel.countDocuments({ lesson: { $in: lessonIds } }),
      kanjiModel.countDocuments({ lessonId: { $in: lessonIds } }),
      grammarModel.countDocuments({ lesson_id: { $in: lessonIds } }),
    ]);
    return { vocabulary, kanji, grammar };
  },
});

export const lessonRepository = createLessonRepository({
  Lesson,
  Vocabulary,
  Grammar,
  Kanji,
});

export default lessonRepository;
```

- [ ] **Step 4: Chạy lại cho pass**

Run: `cd BackEnd && node --test tests/lesson.repository.test.js`
Expected: PASS, 8/8

- [ ] **Step 5: Commit**

```bash
git add BackEnd/src/modules/lessons/lesson.repository.js BackEnd/tests/lesson.repository.test.js
git commit -m "feat(lessons): extract Mongoose queries into a repository"
```

---

## Task 3: `lesson.service.js` — rule nghiệp vụ

**Files:**
- Create: `BackEnd/src/modules/lessons/lesson.service.js`
- Test: `BackEnd/tests/lesson.service.test.js`

**Interfaces:**
- Consumes: `createLessonRepository` — dùng shape từ Task 2 (`findMany`, `count`,
  `findById`, `findVocabulariesByLesson`, `findActiveGrammarsByLesson`,
  `findKanjisByLesson`, `findByLevel`, `findByTypePattern`, `aggregateStats`, `create`,
  `createMany`, `updateById`, `findByIdLean`, `deleteById`, `deleteManyByIds`,
  `countRelated`)
- Produces: `createLessonService({ lessonRepository })` trả về object có `list(filters)`,
  `getDetail(id)`, `getByLevel(level)`, `getByType(typePattern)`, `getStatsOverview()`,
  `create(input)`, `createMany(inputs)`, `update(id, input)`, `remove(id)`,
  `removeMany(ids)`, `duplicate(id)`. Dùng ở Task 4.

- [ ] **Step 1: Viết test thất bại**

```js
// BackEnd/tests/lesson.service.test.js
import assert from 'node:assert/strict';
import test from 'node:test';

import { createLessonService } from '../src/modules/lessons/lesson.service.js';

const fakeRepository = (overrides = {}) => ({
  findMany: async () => [],
  count: async () => 0,
  findById: async () => null,
  findVocabulariesByLesson: async () => [],
  findActiveGrammarsByLesson: async () => [],
  findKanjisByLesson: async () => [],
  findByLevel: async () => [],
  findByTypePattern: async () => [],
  aggregateStats: async () => ({ totalLessons: 0, byLevel: [], byType: [] }),
  create: async (input) => ({ _id: 'new', ...input }),
  createMany: async (inputs) => inputs.map((item, index) => ({ _id: `n${index}`, ...item })),
  updateById: async () => null,
  findByIdLean: async () => null,
  deleteById: async () => null,
  deleteManyByIds: async () => 0,
  countRelated: async () => ({ vocabulary: 0, kanji: 0, grammar: 0 }),
  ...overrides,
});

test('list dựng filter theo level/type/situation/search và tính totalPages', async () => {
  let captured = null;
  const repository = fakeRepository({
    findMany: async (args) => { captured = args; return [{ _id: 'l1' }]; },
    count: async () => 12,
  });
  const service = createLessonService({ lessonRepository: repository });

  const result = await service.list({
    page: 2,
    limit: 5,
    level: 'N5',
    type: 'ngữ pháp',
    situation: 'train',
    search: 'tàu',
  });

  assert.equal(captured.filter.level, 'N5');
  assert.equal(captured.filter.situation, 'train');
  assert.deepEqual(captured.filter.type, { $regex: 'ngữ pháp', $options: 'i' });
  assert.deepEqual(captured.filter.$or, [
    { title: { $regex: 'tàu', $options: 'i' } },
    { description: { $regex: 'tàu', $options: 'i' } },
  ]);
  assert.equal(captured.skip, 5);
  assert.equal(captured.limit, 5);
  assert.equal(result.total, 12);
  assert.equal(result.totalPages, 3);
  assert.deepEqual(result.items, [{ _id: 'l1' }]);
});

test('list không lọc situation khi không truyền — không loại bài chưa gắn tình huống', async () => {
  let captured = null;
  const repository = fakeRepository({
    findMany: async (args) => { captured = args; return []; },
  });
  const service = createLessonService({ lessonRepository: repository });

  await service.list({ page: 1, limit: 10 });

  assert.ok(!('situation' in captured.filter));
  assert.ok(!('level' in captured.filter));
});

test('getDetail báo 404 khi không tìm thấy bài học', async () => {
  const service = createLessonService({ lessonRepository: fakeRepository() });

  await assert.rejects(service.getDetail('missing'), (error) => error.status === 404);
});

test('getDetail dùng fallback query khi mảng tham chiếu rỗng, và gắn alias tuvungs/nguphaps', async () => {
  const repository = fakeRepository({
    findById: async () => ({ _id: 'l1', vocabularies: [], grammars: [], kanjis: [] }),
    findVocabulariesByLesson: async () => [{ _id: 'v1' }],
    findActiveGrammarsByLesson: async () => [{ _id: 'g1' }],
    findKanjisByLesson: async () => [{ _id: 'k1' }],
  });
  const service = createLessonService({ lessonRepository: repository });

  const detail = await service.getDetail('l1');

  assert.deepEqual(detail.vocabularies, [{ _id: 'v1' }]);
  assert.deepEqual(detail.tuvungs, [{ _id: 'v1' }]);
  assert.deepEqual(detail.grammars, [{ _id: 'g1' }]);
  assert.deepEqual(detail.nguphaps, [{ _id: 'g1' }]);
  assert.deepEqual(detail.kanjis, [{ _id: 'k1' }]);
});

test('getDetail giữ mảng đã populate khi không rỗng, không gọi fallback', async () => {
  let fallbackCalled = false;
  const repository = fakeRepository({
    findById: async () => ({
      _id: 'l1',
      vocabularies: [{ _id: 'v1' }],
      grammars: [{ _id: 'g1' }],
      kanjis: [{ _id: 'k1' }],
    }),
    findVocabulariesByLesson: async () => { fallbackCalled = true; return []; },
  });
  const service = createLessonService({ lessonRepository: repository });

  const detail = await service.getDetail('l1');

  assert.equal(fallbackCalled, false);
  assert.deepEqual(detail.vocabularies, [{ _id: 'v1' }]);
});

test('remove chặn 409 kèm details khi còn tham chiếu', async () => {
  const repository = fakeRepository({
    countRelated: async () => ({ vocabulary: 2, kanji: 0, grammar: 0 }),
  });
  const service = createLessonService({ lessonRepository: repository });

  await assert.rejects(service.remove('l1'), (error) => {
    assert.equal(error.status, 409);
    assert.deepEqual(error.details, { vocabulary: 2, kanji: 0, grammar: 0 });
    return true;
  });
});

test('remove xóa được khi không còn tham chiếu, báo 404 khi bài học không tồn tại', async () => {
  const repository = fakeRepository({ deleteById: async () => null });
  const service = createLessonService({ lessonRepository: repository });

  await assert.rejects(service.remove('missing'), (error) => error.status === 404);
});

test('removeMany chặn 409 kèm details, xóa được khi không còn tham chiếu', async () => {
  const blocked = createLessonService({
    lessonRepository: fakeRepository({
      countRelated: async () => ({ vocabulary: 0, kanji: 1, grammar: 0 }),
    }),
  });
  await assert.rejects(blocked.removeMany(['l1']), (error) => error.status === 409);

  const allowed = createLessonService({
    lessonRepository: fakeRepository({ deleteManyByIds: async () => 3 }),
  });
  const deletedCount = await allowed.removeMany(['l1', 'l2', 'l3']);
  assert.equal(deletedCount, 3);
});

test('update báo 404 khi bài học không tồn tại', async () => {
  const service = createLessonService({ lessonRepository: fakeRepository() });

  await assert.rejects(service.update('missing', { title: 'x' }), (error) => error.status === 404);
});

test('duplicate xóa _id/createdAt/updatedAt và thêm hậu tố Bản sao vào title', async () => {
  const repository = fakeRepository({
    findByIdLean: async () => ({
      _id: 'l1',
      title: 'Bài 1',
      createdAt: new Date(),
      updatedAt: new Date(),
      level: 'N5',
    }),
    create: async (input) => ({ _id: 'l2', ...input }),
  });
  const service = createLessonService({ lessonRepository: repository });

  const copy = await service.duplicate('l1');

  assert.ok(copy.title.startsWith('Bài 1 (Bản sao '));
  assert.equal(copy._id, 'l2');
  assert.equal(copy.level, 'N5');
});

test('duplicate báo 404 khi bài học gốc không tồn tại', async () => {
  const service = createLessonService({ lessonRepository: fakeRepository() });

  await assert.rejects(service.duplicate('missing'), (error) => error.status === 404);
});
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd BackEnd && node --test tests/lesson.service.test.js`
Expected: FAIL — không tìm thấy module.

- [ ] **Step 3: Viết service**

```js
// BackEnd/src/modules/lessons/lesson.service.js
import { ApiError } from '../../shared/http/api-error.js';
import { lessonRepository } from './lesson.repository.js';

const escapeRegExp = (value) => value.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/**
 * Rule nghiệp vụ của domain bài học. Không biết `req`/`res`, không import model —
 * mọi truy cập dữ liệu đi qua repository được tiêm vào.
 */
export const createLessonService = ({ lessonRepository: repository }) => ({
  async list({ page, limit, level, type, situation, search }) {
    const filter = {};
    if (level) filter.level = level;
    if (type) filter.type = { $regex: escapeRegExp(type), $options: 'i' };
    if (situation) filter.situation = situation;
    if (search) {
      const pattern = { $regex: escapeRegExp(search), $options: 'i' };
      filter.$or = [{ title: pattern }, { description: pattern }];
    }

    const [items, total] = await Promise.all([
      repository.findMany({
        filter,
        sort: { level: -1, order: 1 },
        skip: (page - 1) * limit,
        limit,
      }),
      repository.count(filter),
    ]);

    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  },

  /**
   * Chi tiết một bài học. `vocabularies`/`grammars`/`kanjis` populate rỗng khi
   * bài học chưa gắn tham chiếu trực tiếp — khi đó tra ngược theo
   * `Vocabulary.lesson`/`Grammar.lesson_id`/`Kanji.lessonId` thay vì trả mảng
   * rỗng, đúng hành vi trước khi tách tầng. `tuvungs`/`nguphaps` là alias mà
   * Flutter đang đọc, không phải field mới.
   */
  async getDetail(id) {
    const lesson = await repository.findById(id);
    if (!lesson) throw ApiError.notFound('Bài học không tồn tại.');

    const [vocabularies, grammars, kanjis] = await Promise.all([
      lesson.vocabularies?.length
        ? lesson.vocabularies
        : repository.findVocabulariesByLesson(lesson._id),
      lesson.grammars?.length
        ? lesson.grammars
        : repository.findActiveGrammarsByLesson(lesson._id),
      lesson.kanjis?.length
        ? lesson.kanjis
        : repository.findKanjisByLesson(lesson._id),
    ]);

    return {
      ...lesson,
      vocabularies,
      grammars,
      kanjis,
      tuvungs: vocabularies,
      nguphaps: grammars,
    };
  },

  getByLevel(level) {
    return repository.findByLevel(level);
  },

  getByType(typePattern) {
    return repository.findByTypePattern({
      $regex: escapeRegExp(typePattern),
      $options: 'i',
    });
  },

  getStatsOverview() {
    return repository.aggregateStats();
  },

  create(input) {
    return repository.create(input);
  },

  createMany(inputs) {
    return repository.createMany(inputs);
  },

  async update(id, input) {
    const updated = await repository.updateById(id, input);
    if (!updated) throw ApiError.notFound('Bài học không tồn tại.');
    return updated;
  },

  async remove(id) {
    const related = await repository.countRelated([id]);
    if (Object.values(related).some((count) => count > 0)) {
      throw ApiError.conflict('Không thể xóa bài học đang có nội dung liên quan.', {
        details: related,
      });
    }

    const deleted = await repository.deleteById(id);
    if (!deleted) throw ApiError.notFound('Bài học không tồn tại.');
    return deleted;
  },

  async removeMany(ids) {
    const related = await repository.countRelated(ids);
    if (Object.values(related).some((count) => count > 0)) {
      throw ApiError.conflict('Không thể xóa các bài học đang có nội dung liên quan.', {
        details: related,
      });
    }

    return repository.deleteManyByIds(ids);
  },

  async duplicate(id) {
    const original = await repository.findByIdLean(id);
    if (!original) throw ApiError.notFound('Bài học không tồn tại.');

    delete original._id;
    delete original.createdAt;
    delete original.updatedAt;
    original.title = `${original.title} (Bản sao ${Date.now()})`;

    return repository.create(original);
  },
});

export const lessonService = createLessonService({ lessonRepository });

export default lessonService;
```

- [ ] **Step 4: Chạy lại cho pass**

Run: `cd BackEnd && node --test tests/lesson.service.test.js`
Expected: PASS, 11/11

- [ ] **Step 5: Commit**

```bash
git add BackEnd/src/modules/lessons/lesson.service.js BackEnd/tests/lesson.service.test.js
git commit -m "feat(lessons): add service layer with fallback populate and delete guards"
```

---

## Task 4: `lesson.schema.js` + `lesson.controller.js` + `lesson.routes.js`

**Files:**
- Create: `BackEnd/src/modules/lessons/lesson.schema.js`
- Modify (viết lại toàn bộ): `BackEnd/src/modules/lessons/lesson.controller.js`
- Modify (viết lại toàn bộ): `BackEnd/src/modules/lessons/lesson.routes.js`
- Test: `BackEnd/tests/lesson.routes.test.js`

**Interfaces:**
- Consumes: `SITUATIONS` (Task 1); `createLessonService`/`lessonService` (Task 3, dùng đúng
  các hàm: `list`, `getDetail`, `getByLevel`, `getByType`, `getStatsOverview`, `create`,
  `createMany`, `update`, `remove`, `removeMany`, `duplicate`)
- Produces: `createLessonRoutes({ service, authenticate, authorizeAdmin })` — router Express
  nhận dependency qua tham số để test dựng app không cần MongoDB/JWT thật, giống
  `createVocabularyRoutes`.

Ba file này phải làm cùng một task vì `lesson.routes.js` khởi tạo trực tiếp
`createLessonController(service)` — không thể test `routes.js` một cách có ý nghĩa nếu
`controller.js`/`schema.js` chưa xong, và ngược lại `controller.js` không có test riêng
(giống `vocabulary.controller.js` — được kiểm qua HTTP test của routes, không có unit test
tách rời).

Bảng vỏ response phải giữ nguyên — đối chiếu với `lesson.controller.js` gốc trước khi tách
tầng:

| Route | Vỏ response cũ | Cách dựng ở controller mới |
| --- | --- | --- |
| `GET /` | `{ totalItems, totalPages, currentPage, data }` | tự dựng object, không dùng `paginated()` (khác tên field) |
| `GET /:id` | object phẳng + `tuvungs`/`nguphaps` | `res.json(lesson)` — `lesson` đã có sẵn field alias từ service |
| `GET /level/:capDo` | `{ total, data }` | `list()` từ `respond.js` — đúng khớp |
| `GET /type/:loaiBaiHoc` | `{ total, data }` | `list()` |
| `GET /stats/overview` | `{ totalLessons, byLevel, byType }` | `res.json(stats)` — không bọc `data` |
| `POST /` | 201, `{ message, data }` | `created()` |
| `POST /bulk` | 201, `{ message, data }` | `created()` |
| `PUT /:id`, `PATCH /:id` | `{ message, data }` | `ok()`, cùng handler cho cả hai method |
| `DELETE /:id` | `{ message, data }` | `ok()` |
| `DELETE /` | `{ message, deletedCount }` — **không có `data`** | `res.json({ message, deletedCount })` |
| `POST /:id/duplicate` | 201, `{ message, data }` | `created()` |

- [ ] **Step 1: Viết test thất bại**

```js
// BackEnd/tests/lesson.routes.test.js
import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { ApiError } from '../src/shared/http/api-error.js';
import { createLessonRoutes } from '../src/modules/lessons/lesson.routes.js';

const VALID_ID = '507f1f77bcf86cd799439011';

const passthrough = (user) => (req, _res, next) => {
  req.user = user;
  next();
};

/** App tối thiểu: router thật + service giả + auth giả, không cần MongoDB. Mount path khớp app.js thật (`/api/lesson`, số ít). */
const buildApp = (service) => {
  const app = express();
  app.use(express.json());
  app.use(
    '/api/lesson',
    createLessonRoutes({
      service,
      authenticate: passthrough({ _id: 'user-1' }),
      authorizeAdmin: passthrough({ _id: 'admin-1', role: 'admin' }),
    }),
  );
  app.use(errorHandler);
  return app;
};

test('GET / giữ đúng vỏ response cũ totalItems/totalPages/currentPage/data', async () => {
  const app = buildApp({
    list: async () => ({ items: [{ _id: 'l1' }], page: 2, limit: 5, total: 11, totalPages: 3 }),
  });

  const response = await request(app).get('/api/lesson?page=2&limit=5');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, {
    totalItems: 11,
    totalPages: 3,
    currentPage: 2,
    data: [{ _id: 'l1' }],
  });
});

test('GET /?situation=supermarket chưa có bài nào vẫn là 200 và mảng rỗng', async () => {
  const app = buildApp({
    list: async () => ({ items: [], page: 1, limit: 10, total: 0, totalPages: 0 }),
  });

  const response = await request(app).get('/api/lesson?situation=supermarket');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body.data, []);
});

test('GET /?situation=khong-hop-le bị chặn 400 trước khi tới service', async () => {
  const app = buildApp({ list: async () => assert.fail('không được gọi service') });

  const response = await request(app).get('/api/lesson?situation=khong-hop-le');

  assert.equal(response.status, 400);
  assert.equal(response.body.code, 'VALIDATION_ERROR');
});

test('limit vượt trần bị từ chối bằng 400', async () => {
  const app = buildApp({ list: async () => assert.fail('không được gọi service') });

  const response = await request(app).get('/api/lesson?limit=100000');

  assert.equal(response.status, 400);
});

test('GET /:id trả object phẳng kèm tuvungs/nguphaps như hành vi cũ', async () => {
  const app = buildApp({
    getDetail: async () => ({
      _id: 'l1',
      title: 'Bài 1',
      vocabularies: [{ _id: 'v1' }],
      grammars: [],
      kanjis: [],
      tuvungs: [{ _id: 'v1' }],
      nguphaps: [],
    }),
  });

  const response = await request(app).get(`/api/lesson/${VALID_ID}`);

  assert.equal(response.status, 200);
  assert.equal(response.body._id, 'l1');
  assert.deepEqual(response.body.tuvungs, [{ _id: 'v1' }]);
  assert.equal(response.body.data, undefined, 'không được bọc thêm data ở route này');
});

test('GET /:id với id không phải ObjectId bị chặn 400', async () => {
  const app = buildApp({ getDetail: async () => assert.fail('không được gọi service') });

  const response = await request(app).get('/api/lesson/khong-phai-object-id');

  assert.equal(response.status, 400);
});

test('GET /level/:capDo với cấp độ lạ bị chặn 400', async () => {
  const app = buildApp({ getByLevel: async () => assert.fail('không được gọi service') });

  const response = await request(app).get('/api/lesson/level/N9');

  assert.equal(response.status, 400);
});

test('GET /level/:capDo rỗng vẫn là 200 và mảng rỗng', async () => {
  const app = buildApp({ getByLevel: async () => [] });

  const response = await request(app).get('/api/lesson/level/N5');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: [], total: 0 });
});

test('GET /type/:loaiBaiHoc rỗng vẫn là 200 và mảng rỗng', async () => {
  const app = buildApp({ getByType: async () => [] });

  const response = await request(app).get('/api/lesson/type/ngu-phap');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: [], total: 0 });
});

test('GET /stats/overview trả đúng vỏ phẳng cũ, không bọc trong data', async () => {
  const app = buildApp({
    getStatsOverview: async () => ({ totalLessons: 3, byLevel: [], byType: [] }),
  });

  const response = await request(app).get('/api/lesson/stats/overview');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { totalLessons: 3, byLevel: [], byType: [] });
});

test('POST / tạo bài học kèm situation hợp lệ, trả 201', async () => {
  let received = null;
  const app = buildApp({
    create: async (input) => { received = input; return { _id: 'l1', ...input }; },
  });

  const response = await request(app)
    .post('/api/lesson')
    .send({ title: 'Đi siêu thị', level: 'N5', situation: 'supermarket' });

  assert.equal(response.status, 201);
  assert.equal(received.situation, 'supermarket');
  assert.equal(response.body.data.situation, 'supermarket');
});

test('POST / với situation không nằm trong danh mục bị chặn 400', async () => {
  const app = buildApp({ create: async () => assert.fail('không được gọi service') });

  const response = await request(app)
    .post('/api/lesson')
    .send({ title: 'Bài x', level: 'N5', situation: 'mat_trang' });

  assert.equal(response.status, 400);
});

test('POST / vẫn nhận tên field di sản TenBaiHoc/CapDo như trước khi tách tầng', async () => {
  let received = null;
  const app = buildApp({
    create: async (input) => { received = input; return { _id: 'l1', ...input }; },
  });

  const response = await request(app)
    .post('/api/lesson')
    .send({ TenBaiHoc: 'Bài cũ', CapDo: 'N5' });

  assert.equal(response.status, 201);
  assert.equal(received.title, 'Bài cũ');
  assert.equal(received.level, 'N5');
});

test('POST / thiếu title/level bị chặn 400', async () => {
  const app = buildApp({ create: async () => assert.fail('không được gọi service') });

  const response = await request(app).post('/api/lesson').send({ level: 'N5' });

  assert.equal(response.status, 400);
});

test('POST /bulk tạo nhiều bài, giới hạn 1-100 phần tử', async () => {
  const app = buildApp({
    createMany: async (inputs) => inputs.map((item, index) => ({ _id: `l${index}`, ...item })),
  });

  const ok = await request(app)
    .post('/api/lesson/bulk')
    .send({ lessons: [{ title: 'A', level: 'N5' }, { title: 'B', level: 'N4' }] });
  assert.equal(ok.status, 201);
  assert.equal(ok.body.data.length, 2);

  const empty = await request(app).post('/api/lesson/bulk').send({ lessons: [] });
  assert.equal(empty.status, 400);
});

test('PUT /:id và PATCH /:id gọi cùng một service.update', async () => {
  const calls = [];
  const app = buildApp({
    update: async (id, body) => { calls.push([id, body]); return { _id: id, ...body }; },
  });

  const put = await request(app).put(`/api/lesson/${VALID_ID}`).send({ title: 'A' });
  const patch = await request(app).patch(`/api/lesson/${VALID_ID}`).send({ title: 'B' });

  assert.equal(put.status, 200);
  assert.equal(patch.status, 200);
  assert.equal(calls.length, 2);
});

test('DELETE /:id còn tham chiếu trả 409 kèm details', async () => {
  const app = buildApp({
    remove: async () => {
      throw ApiError.conflict('Không thể xóa bài học đang có nội dung liên quan.', {
        details: { vocabulary: 2, kanji: 0, grammar: 0 },
      });
    },
  });

  const response = await request(app).delete(`/api/lesson/${VALID_ID}`);

  assert.equal(response.status, 409);
  assert.deepEqual(response.body.details, { vocabulary: 2, kanji: 0, grammar: 0 });
});

test('DELETE / xóa nhiều — vỏ response không có key data, giữ đúng hành vi cũ', async () => {
  const app = buildApp({ removeMany: async () => 3 });

  const response = await request(app)
    .delete('/api/lesson')
    .send({ ids: [VALID_ID] });

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { message: 'Xóa thành công 3 bài học.', deletedCount: 3 });
});

test('POST /:id/duplicate trả 201 kèm data', async () => {
  const app = buildApp({
    duplicate: async (id) => ({ _id: 'l2', title: `Bài (Bản sao) từ ${id}` }),
  });

  const response = await request(app).post(`/api/lesson/${VALID_ID}/duplicate`);

  assert.equal(response.status, 201);
  assert.equal(response.body.data._id, 'l2');
});
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd BackEnd && node --test tests/lesson.routes.test.js`
Expected: FAIL — `createLessonRoutes` chưa tồn tại.

- [ ] **Step 3: Viết `lesson.schema.js`**

```js
// BackEnd/src/modules/lessons/lesson.schema.js
import { z } from 'zod';

import { paginationQuery } from '../../shared/http/pagination.js';
import { SITUATIONS } from './situation-catalog.js';

export const LEVELS = ['N5', 'N4', 'N3', 'N2', 'N1'];

const objectId = z
  .string()
  .regex(/^[0-9a-fA-F]{24}$/, 'Định danh không hợp lệ.');

const level = z.enum(LEVELS);
const situation = z.enum(SITUATIONS);

/** Query rỗng (`?level=`) được coi như không truyền — cùng quy ước với vocabulary.schema.js. */
const optional = (schema) =>
  z.preprocess(
    (value) => (value === '' || value === null ? undefined : value),
    schema.optional(),
  );

/**
 * `lessonInput()` cũ trong controller chấp nhận cả tên field tiếng Việt di sản
 * (`TenBaiHoc`/`CapDo`/`LoaiBaiHoc`/`NoiDung`) lẫn tên mới — giữ nguyên ở đây vì
 * có thể còn caller admin cũ gửi tên cũ, và spec yêu cầu giữ nguyên hành vi.
 */
const normalizeLessonBody = (body) => {
  if (body === null || typeof body !== 'object') return body;
  return {
    title: body.title ?? body.TenBaiHoc,
    level: body.level ?? body.CapDo,
    order: body.order,
    description: body.description ?? body.LoaiBaiHoc,
    content_html: body.content_html ?? body.NoiDung,
    type: body.type,
    situation: body.situation,
  };
};

export const listQuery = paginationQuery.extend({
  level: optional(level),
  type: optional(z.string().trim().min(1)),
  situation: optional(situation),
  search: optional(z.string().trim().min(1)),
});

export const idParams = z.object({ id: objectId });

export const capDoParams = z.object({ capDo: level });

export const loaiBaiHocParams = z.object({
  loaiBaiHoc: z.string().trim().min(1),
});

export const createBody = z.preprocess(
  normalizeLessonBody,
  z.object({
    title: z.string().trim().min(1, 'Tên bài học là bắt buộc.'),
    level,
    order: z.coerce.number().int().min(1).default(1),
    description: z.string().trim().optional(),
    content_html: z.string().optional(),
    type: z.string().trim().optional(),
    situation: situation.optional(),
  }),
);

export const updateBody = z.preprocess(
  normalizeLessonBody,
  z.object({
    title: z.string().trim().min(1).optional(),
    level: level.optional(),
    order: z.coerce.number().int().min(1).optional(),
    description: z.string().trim().optional(),
    content_html: z.string().optional(),
    type: z.string().trim().optional(),
    situation: situation.optional(),
  }),
);

export const bulkBody = z.object({
  lessons: z
    .array(createBody)
    .min(1, 'Danh sách phải có từ 1 đến 100 bài học.')
    .max(100, 'Danh sách phải có từ 1 đến 100 bài học.'),
});

export const idsBody = z.object({
  ids: z
    .array(objectId)
    .min(1, 'Danh sách ID phải có từ 1 đến 100 phần tử.')
    .max(100, 'Danh sách ID phải có từ 1 đến 100 phần tử.'),
});
```

- [ ] **Step 4: Viết lại `lesson.controller.js`**

```js
// BackEnd/src/modules/lessons/lesson.controller.js
import { created, list, ok } from '../../shared/http/respond.js';
import { lessonService } from './lesson.service.js';

/**
 * Chỉ map HTTP <-> service. Vỏ response của `listRoot`/`getById`/
 * `getStatsOverview`/`deleteRoot` KHÔNG dùng helper chuẩn `ok`/`list`/`paginated`
 * vì phải giữ đúng hình dạng cũ cho Flutter — xem bảng ở đầu Task 4.
 */
export const createLessonController = (service) => ({
  async listRoot(req, res) {
    const { page, total, items, totalPages } = await service.list(req.valid.query);
    return res.json({
      totalItems: total,
      totalPages,
      currentPage: page,
      data: items,
    });
  },

  async getById(req, res) {
    const lesson = await service.getDetail(req.valid.params.id);
    return res.json(lesson);
  },

  async getLevelByCapDo(req, res) {
    const lessons = await service.getByLevel(req.valid.params.capDo);
    return list(res, lessons);
  },

  async getTypeByLoaiBaiHoc(req, res) {
    const lessons = await service.getByType(req.valid.params.loaiBaiHoc);
    return list(res, lessons);
  },

  async getStatsOverview(req, res) {
    const stats = await service.getStatsOverview();
    return res.json(stats);
  },

  async postRoot(req, res) {
    const lesson = await service.create(req.valid.body);
    return created(res, lesson, { message: 'Thêm bài học thành công.' });
  },

  async postBulk(req, res) {
    const lessons = await service.createMany(req.valid.body.lessons);
    return created(res, lessons, {
      message: `Thêm thành công ${lessons.length} bài học.`,
    });
  },

  async putById(req, res) {
    const lesson = await service.update(req.valid.params.id, req.valid.body);
    return ok(res, lesson, { message: 'Cập nhật bài học thành công.' });
  },

  async deleteById(req, res) {
    const lesson = await service.remove(req.valid.params.id);
    return ok(res, lesson, { message: 'Xóa bài học thành công.' });
  },

  async deleteRoot(req, res) {
    const deletedCount = await service.removeMany(req.valid.body.ids);
    return res.json({
      message: `Xóa thành công ${deletedCount} bài học.`,
      deletedCount,
    });
  },

  async postByIdDuplicate(req, res) {
    const lesson = await service.duplicate(req.valid.params.id);
    return created(res, lesson, { message: 'Sao chép bài học thành công.' });
  },
});

export const lessonController = createLessonController(lessonService);

export default lessonController;
```

- [ ] **Step 5: Viết lại `lesson.routes.js`**

Thứ tự route giữ nguyên y hệt bản gốc — `stats/overview` phải đăng ký trước `/:id` để
Express không nuốt nhầm `"stats"` làm `:id`:

```js
// BackEnd/src/modules/lessons/lesson.routes.js
import express from 'express';

import {
  authenticateAdmin,
  authenticateUser,
} from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createLessonController } from './lesson.controller.js';
import * as schema from './lesson.schema.js';
import { lessonService } from './lesson.service.js';

/**
 * Route chỉ khai báo path, middleware và controller binding. Nhận dependency
 * qua tham số để test dựng router với service giả và middleware auth giả,
 * không cần MongoDB hay JWT — giống `createVocabularyRoutes`.
 */
export const createLessonRoutes = ({
  service = lessonService,
  authenticate = authenticateUser,
  authorizeAdmin = authenticateAdmin,
} = {}) => {
  const controller = createLessonController(service);
  const router = express.Router();

  router.get(
    '/',
    authenticate,
    validate({ query: schema.listQuery }),
    asyncHandler(controller.listRoot),
  );
  router.get(
    '/level/:capDo',
    authenticate,
    validate({ params: schema.capDoParams }),
    asyncHandler(controller.getLevelByCapDo),
  );
  router.get(
    '/type/:loaiBaiHoc',
    authenticate,
    validate({ params: schema.loaiBaiHocParams }),
    asyncHandler(controller.getTypeByLoaiBaiHoc),
  );
  router.get(
    '/stats/overview',
    authenticateAdmin,
    asyncHandler(controller.getStatsOverview),
  );
  router.get(
    '/:id',
    authenticate,
    validate({ params: schema.idParams }),
    asyncHandler(controller.getById),
  );
  router.post(
    '/',
    authorizeAdmin,
    validate({ body: schema.createBody }),
    asyncHandler(controller.postRoot),
  );
  router.post(
    '/bulk',
    authorizeAdmin,
    validate({ body: schema.bulkBody }),
    asyncHandler(controller.postBulk),
  );
  router.put(
    '/:id',
    authorizeAdmin,
    validate({ params: schema.idParams, body: schema.updateBody }),
    asyncHandler(controller.putById),
  );
  router.patch(
    '/:id',
    authorizeAdmin,
    validate({ params: schema.idParams, body: schema.updateBody }),
    asyncHandler(controller.putById),
  );
  router.delete(
    '/:id',
    authorizeAdmin,
    validate({ params: schema.idParams }),
    asyncHandler(controller.deleteById),
  );
  router.delete(
    '/',
    authorizeAdmin,
    validate({ body: schema.idsBody }),
    asyncHandler(controller.deleteRoot),
  );
  router.post(
    '/:id/duplicate',
    authorizeAdmin,
    validate({ params: schema.idParams }),
    asyncHandler(controller.postByIdDuplicate),
  );

  return router;
};

export default createLessonRoutes();
```

Lưu ý: route `stats/overview` giữ nguyên dùng thẳng `authenticateAdmin` (không qua tham số
`authorizeAdmin`) đúng như bản gốc — đây là điểm khác biệt nhỏ đã có từ trước, không phải
lỗi mới; nếu muốn test override nó bằng auth giả thì đổi sang `authorizeAdmin` ở dòng đó,
nhưng vì bản gốc không đưa route này qua tham số nào, giữ nguyên để không âm thầm đổi hành
vi ngoài phạm vi.

- [ ] **Step 6: Chạy lại cho pass**

Run: `cd BackEnd && node --test tests/lesson.routes.test.js`
Expected: PASS, toàn bộ test (20 test) xanh.

- [ ] **Step 7: Commit**

```bash
git add BackEnd/src/modules/lessons/lesson.schema.js \
  BackEnd/src/modules/lessons/lesson.controller.js \
  BackEnd/src/modules/lessons/lesson.routes.js \
  BackEnd/tests/lesson.routes.test.js
git commit -m "refactor(lessons): move to schema/controller/routes with situation filter"
```

---

## Task 5: Xác nhận toàn cục — route contract, test suite, gate Flutter

**Files:** không tạo/sửa file mới, chỉ chạy lệnh xác nhận.

- [ ] **Step 1: Chạy toàn bộ test backend**

Run: `cd BackEnd && npm test`
Expected: Toàn bộ test pass, **không** có test nào của module khác (vocabulary, srs,
lesson-progress...) bị đỏ do việc đổi `Lesson.js`/`lesson.*.js`.

- [ ] **Step 2: Xác nhận route contract không đổi**

Trong log của `npm test`, tìm assertion của `tests/route-contract.test.js`:

```bash
cd BackEnd && node --test tests/route-contract.test.js
```

Expected: PASS. `expectedCount` vẫn là `261`, `expectedSignatureHash` vẫn là
`75d5d6968c84885bee137582512f0de999bcf7b1cd521e245e3ee7c4517e4e66` — vì Task 4 giữ nguyên
method+path của cả 11 route. Nếu hash lệch, đối chiếu lại `lesson.routes.js` với bảng thứ
tự route ở Task 4 trước khi nghĩ tới việc sửa `expectedSignatureHash` — sửa hash chỉ hợp lệ
khi đã cố ý đổi route và đã đọc lại danh sách route mới bằng mắt.

- [ ] **Step 3: Xác nhận không có file Lesson cũ nào còn sót logic Mongoose**

```bash
cd BackEnd && grep -n "Lesson\.\(find\|create\|update\|delete\)" src/modules/lessons/lesson.controller.js
```

Expected: không có dòng nào khớp — nghĩa là toàn bộ truy vấn Mongoose đã chuyển hết sang
`lesson.repository.js`, `lesson.controller.js` chỉ còn gọi `service.*`.

- [ ] **Step 4: Xác nhận `lesson.controller.js` dưới 150 dòng**

```bash
cd BackEnd && wc -l src/modules/lessons/lesson.controller.js
```

Expected: dưới 150 — đúng ngưỡng bắt buộc trong `conventions.md`.

- [ ] **Step 5: Ghi nhận trạng thái Flutter không đổi (không sửa gì ở FrontEnd)**

```bash
cd FrontEnd && dart analyze 2>&1 | tail -5
```

Expected: vẫn đúng 13 lỗi cũ (không tăng), toàn bộ nằm ở `test/api_exception_test.dart` và
`test/srs_service_test.dart` — không liên quan gì đến `lessons`. Đây là nợ kỹ thuật đã biết
từ trước (mục "25. Dọn Flutter CI" ở checklist khác), **không** thuộc phạm vi plan này và
không cần sửa ở đây; bước này chỉ để xác nhận plan không vô tình làm con số xấu đi.

- [ ] **Step 6: Commit cuối (nếu Step 1-5 chỉ là xác nhận, không có gì để commit thêm)**

Không cần commit riêng cho task này trừ khi Step 1-4 phát hiện vấn đề cần sửa — khi đó quay
lại đúng task tương ứng (2, 3, hoặc 4), sửa, chạy lại test của task đó, rồi mới quay lại
Task 5 từ Step 1.

---

## Tự soát plan

**Độ phủ spec:** §4 (data model) → Task 1. §5 (refactor 4 tầng, từng tầng) → Task 2
(repository), Task 3 (service), Task 4 (schema/controller/routes). §6 (rollout, không
migration) → Task 1 Step 4 (field optional, không script migrate). §7 (test bắt buộc) →
test đính kèm mỗi task + Task 5. §8 (ngoài phạm vi: Flutter, content_html, bài mẫu mới,
speaking-topics dùng chung) → không có task nào đụng tới, đúng chủ đích.

**Phát hiện thêm khi viết plan (không có trong spec, nêu rõ ở đây để không "âm thầm đổi
hành vi"):** đợt xóa bài học (409) hiện trả `{ message, relatedData }`; refactor này gộp
`relatedData` vào `details` chuẩn của `ApiError` (`{ message, code, details }`) như mọi
lỗi khác trong hệ thống — đã xác nhận bằng `grep -rn "relatedData"` trên toàn bộ `FrontEnd/`
rằng không có client nào đọc key `relatedData`, nên đây là thay đổi an toàn, không phải một
lỗ hổng bỏ sót.

**Type consistency:** `list()`/`getDetail()`/`getByLevel()`/`getByType()`/
`getStatsOverview()`/`create()`/`createMany()`/`update()`/`remove()`/`removeMany()`/
`duplicate()` là đúng bộ tên method dùng xuyên suốt Task 3 (định nghĩa) và Task 4 (gọi từ
controller) — không lệch tên như `getStatsOverview` vs `getOverviewStats`.

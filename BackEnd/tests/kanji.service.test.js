import assert from 'node:assert/strict';
import test from 'node:test';

import { createKanjiService } from '../src/modules/kanji/kanji.service.js';
import { ApiError } from '../src/shared/http/api-error.js';

const NOW = new Date('2026-11-04T03:00:00.000Z');
const USER = 'u1';
const KANJI = { _id: 'k1', character: '学', meaning: 'học' };

const fakeRepository = ({ rows = [KANJI], lessons = [] } = {}) => {
  const store = rows.map((row) => ({ ...row }));
  return {
    store,
    async findById(id) {
      return store.find((row) => row._id === id) ?? null;
    },
    async findLessonsUsing(id) {
      return lessons.filter((lesson) => lesson.kanjis.includes(id)).map(({ _id, title }) => ({ _id, title }));
    },
    async deleteById(id) {
      const index = store.findIndex((row) => row._id === id);
      return index === -1 ? null : store.splice(index, 1)[0];
    },
  };
};

/** Kho thẻ ôn trong bộ nhớ: khoá theo (user, loại, nội dung) như unique index thật. */
const fakeSrs = ({ cards = [] } = {}) => {
  const store = cards.map((card) => ({ ...card }));
  const matches = ({ userId, itemId, itemType }) => (card) =>
    card.user === userId && card.item_id === itemId && card.item_type === itemType;
  return {
    store,
    async findProgress(args) {
      return store.find(matches(args)) ?? null;
    },
    async ensureProgress({ userId, itemId, itemType, initial }) {
      const existing = store.find(matches({ userId, itemId, itemType }));
      if (existing) return { progress: existing, created: false };
      const card = { _id: `p${store.length + 1}`, user: userId, item_id: itemId, item_type: itemType, ...initial };
      store.push(card);
      return { progress: card, created: true };
    },
    async deleteProgress(args) {
      const index = store.findIndex(matches(args));
      if (index === -1) return 0;
      store.splice(index, 1);
      return 1;
    },
    async hasCardsForItem({ itemType, itemId }) {
      return store.some((card) => card.item_type === itemType && card.item_id === itemId);
    },
  };
};

const build = ({ repository = fakeRepository(), srs = fakeSrs() } = {}) => ({
  service: createKanjiService({ repository, srs, clock: () => NOW }),
  repository,
  srs,
});

const rejectsWith = (status, code) => (error) => {
  assert.ok(error instanceof ApiError);
  assert.equal(error.status, status);
  if (code) assert.equal(error.code, code);
  return true;
};

test('thêm vào ôn tập tạo thẻ Kanji hộp 1, hẹn sau 24 giờ', async () => {
  const { service, srs } = build();

  const { progress, created } = await service.markLearned({ id: 'k1', userId: USER });

  assert.equal(created, true);
  assert.deepEqual(progress, {
    _id: 'p1',
    item_id: 'k1',
    item_type: 'Kanji',
    box: 1,
    next_review: '2026-11-05T03:00:00.000Z',
    streak: 0,
  });
  assert.equal(srs.store.length, 1);
});

test('thêm lần nữa trả thẻ đã có và không đổi lịch', async () => {
  const existing = {
    _id: 'p9',
    user: USER,
    item_id: 'k1',
    item_type: 'Kanji',
    box: 3,
    next_review: new Date('2026-11-10T00:00:00.000Z'),
    streak: 2,
  };
  const { service, srs } = build({ srs: fakeSrs({ cards: [existing] }) });

  const { progress, created } = await service.markLearned({ id: 'k1', userId: USER });

  assert.equal(created, false);
  assert.equal(progress.box, 3);
  assert.equal(progress.next_review, '2026-11-10T00:00:00.000Z');
  assert.equal(srs.store.length, 1);
});

test('một từ vựng cùng ID không chiếm chỗ thẻ Kanji', async () => {
  const vocabulary = { _id: 'p9', user: USER, item_id: 'k1', item_type: 'Vocabulary', box: 4 };
  const { service, srs } = build({ srs: fakeSrs({ cards: [vocabulary] }) });

  const { created } = await service.markLearned({ id: 'k1', userId: USER });

  assert.equal(created, true);
  assert.equal(srs.store.length, 2);
});

test('Kanji không tồn tại thì không tạo thẻ', async () => {
  const { service, srs } = build();

  await assert.rejects(service.markLearned({ id: 'k-none', userId: USER }), rejectsWith(404));
  assert.equal(srs.store.length, 0);
});

test('gỡ khỏi ôn tập chỉ xoá thẻ Kanji của chính user, gỡ lần nữa là 404', async () => {
  const cards = [
    { _id: 'p1', user: USER, item_id: 'k1', item_type: 'Kanji' },
    { _id: 'p2', user: 'u2', item_id: 'k1', item_type: 'Kanji' },
  ];
  const { service, srs } = build({ srs: fakeSrs({ cards }) });

  await service.unmarkLearned({ id: 'k1', userId: USER });

  assert.deepEqual(srs.store.map((card) => card.user), ['u2']);
  await assert.rejects(service.unmarkLearned({ id: 'k1', userId: USER }), rejectsWith(404));
});

test('chi tiết Kanji kèm tiến độ ôn của user đang xem, chưa thêm thì null', async () => {
  const cards = [
    {
      _id: 'p1',
      user: USER,
      item_id: 'k1',
      item_type: 'Kanji',
      box: 2,
      next_review: new Date('2026-11-07T03:00:00.000Z'),
      streak: 1,
    },
  ];
  const { service } = build({ srs: fakeSrs({ cards }) });

  const mine = await service.getDetail({ id: 'k1', userId: USER });
  const theirs = await service.getDetail({ id: 'k1', userId: 'u2' });

  assert.equal(mine.character, '学');
  assert.deepEqual(mine.srs_progress, {
    _id: 'p1',
    item_id: 'k1',
    item_type: 'Kanji',
    box: 2,
    next_review: '2026-11-07T03:00:00.000Z',
    streak: 1,
  });
  assert.equal(theirs.srs_progress, null);
  await assert.rejects(service.getDetail({ id: 'k-none', userId: USER }), rejectsWith(404));
});

test('xoá Kanji còn trong lịch ôn của bất kỳ ai bị chặn bằng 409', async () => {
  const cards = [{ _id: 'p1', user: 'u2', item_id: 'k1', item_type: 'Kanji' }];
  const { service, repository } = build({ srs: fakeSrs({ cards }) });

  await assert.rejects(service.remove('k1'), rejectsWith(409, 'KANJI_IN_REVIEW'));
  assert.equal(repository.store.length, 1);
});

test('xoá Kanji đang thuộc một bài học bị chặn bằng 409 và nêu tên bài', async () => {
  const lessons = [{ _id: 'l1', title: 'Tình huống: Tự giới thiệu', kanjis: ['k1'] }];
  const { service, repository } = build({ repository: fakeRepository({ lessons }) });

  await assert.rejects(service.remove('k1'), (error) => {
    rejectsWith(409, 'KANJI_IN_LESSON')(error);
    assert.deepEqual(error.details, { lessons: ['Tình huống: Tự giới thiệu'] });
    return true;
  });
  assert.equal(repository.store.length, 1);
});

test('thẻ từ vựng trùng ID không chặn xoá Kanji; Kanji không còn thì 404', async () => {
  const cards = [{ _id: 'p1', user: USER, item_id: 'k1', item_type: 'Vocabulary' }];
  const { service, repository } = build({ srs: fakeSrs({ cards }) });

  await service.remove('k1');

  assert.equal(repository.store.length, 0);
  await assert.rejects(service.remove('k1'), rejectsWith(404));
});

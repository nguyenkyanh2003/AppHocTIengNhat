import assert from 'node:assert/strict';
import test from 'node:test';

import LessonProgress from '../model/LessonProgress.js';
import { createLessonProgressRepository } from '../src/modules/lesson-progress/lesson-progress.repository.js';
import { createLessonProgressService } from '../src/modules/lesson-progress/lesson-progress.service.js';

const USER_ID = '507f1f77bcf86cd799439011';
const LESSON_ID = '507f1f77bcf86cd799439012';
const VOCAB_A = '507f1f77bcf86cd799439021';
const VOCAB_B = '507f1f77bcf86cd799439022';
const KANJI_A = '507f1f77bcf86cd799439031';
const OUTSIDER = '507f1f77bcf86cd799439099';

const CONTENT = {
  vocabularyIds: [VOCAB_A, VOCAB_B],
  grammarIds: [],
  kanjiIds: [KANJI_A],
};

const applyTotals = (doc, totals) => {
  doc.total_vocabularies = totals.vocabularies;
  doc.total_grammars = totals.grammars;
  doc.total_kanjis = totals.kanjis;
};

/**
 * Repository giả dùng **model thật trong bộ nhớ**: `markItemLearned` và
 * `unmarkItemLearned` là code thật, chỉ `save()` được bỏ đi. Nhờ vậy test khẳng
 * định được ràng buộc "counter luôn bằng độ dài mảng ID" mà không cần MongoDB.
 */
const fakeRepository = ({ content = CONTENT, seed = null } = {}) => {
  const state = {
    doc: seed,
    rewardKeys: new Set(),
    xp: [],
    activity: 0,
  };

  const ensureDoc = () => {
    state.doc ??= new LessonProgress({ user: USER_ID, lesson: LESSON_ID });
    return state.doc;
  };

  return {
    state,

    findLessonContent: async () => content,
    findProgress: async () => (state.doc ? state.doc.toObject() : null),
    findAllProgress: async () => (state.doc ? [state.doc.toObject()] : []),
    findProgressForLessons: async () => (state.doc ? [state.doc.toObject()] : []),
    findLessonsByLevel: async () => [{ _id: LESSON_ID }],

    startProgress: async ({ totals, at }) => {
      const created = state.doc === null;
      const doc = ensureDoc();
      applyTotals(doc, totals);
      doc.last_studied_at = at;
      return { progress: doc.toObject(), created };
    },

    applyItemLearned: async ({ totals, itemType, itemId, learned, at }) => {
      const doc = ensureDoc();
      applyTotals(doc, totals);
      const wasCompleted = doc.is_completed === true;

      if (learned) doc.markItemLearned(itemType, itemId);
      else doc.unmarkItemLearned(itemType, itemId);

      if (!wasCompleted && doc.is_completed && !doc.completion_reward_state) {
        doc.completion_reward_state = 'pending';
      }

      doc.last_studied_at = at;
      return doc.toObject();
    },

    saveCompletion: async ({ content: source, completedAt, lastStudiedAt, rewardState }) => {
      if (!state.doc) return null;
      const doc = state.doc;

      doc.learned_vocabulary_ids = source.vocabularyIds;
      doc.learned_grammar_ids = source.grammarIds;
      doc.learned_kanji_ids = source.kanjiIds;
      doc.completed_vocabularies = source.vocabularyIds.length;
      doc.completed_grammars = source.grammarIds.length;
      doc.completed_kanjis = source.kanjiIds.length;
      applyTotals(doc, {
        vocabularies: source.vocabularyIds.length,
        grammars: source.grammarIds.length,
        kanjis: source.kanjiIds.length,
      });
      doc.is_completed = true;
      doc.completed_at = completedAt;
      doc.last_studied_at = lastStudiedAt;
      doc.completion_reward_state = rewardState;

      return doc.toObject();
    },

    markCompletionRewardGranted: async () => {
      if (state.doc) state.doc.completion_reward_state = 'granted';
    },

    deleteProgress: async () => {
      state.doc = null;
    },

    recordStudyActivity: async () => {
      state.activity += 1;
      return { is_new_day: true };
    },

    grantXpOnce: async ({ rewardKey, amount, reason }) => {
      if (state.rewardKeys.has(rewardKey)) return false;
      state.rewardKeys.add(rewardKey);
      state.xp.push({ rewardKey, amount, reason });
      return true;
    },

    claimRewardKeyWithoutXp: async ({ rewardKey }) => {
      state.rewardKeys.add(rewardKey);
    },
  };
};

const buildService = (repository) =>
  createLessonProgressService({
    repository,
    now: () => new Date('2026-01-01T00:00:00.000Z'),
  });

const totalXp = (repository) =>
  repository.state.xp.reduce((sum, entry) => sum + entry.amount, 0);

const idsOf = (values) => values.map((value) => String(value));

test('hoàn thành bài ghi đủ ID, counter bằng độ dài mảng và total theo nội dung thật', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);

  await service.startLesson({ userId: USER_ID, lessonId: LESSON_ID });
  const progress = await service.completeLesson({ userId: USER_ID, lessonId: LESSON_ID });

  assert.deepEqual(idsOf(progress.learned_vocabulary_ids), [VOCAB_A, VOCAB_B]);
  assert.deepEqual(idsOf(progress.learned_kanji_ids), [KANJI_A]);
  assert.equal(progress.completed_vocabularies, 2);
  assert.equal(progress.total_vocabularies, 2);
  assert.equal(progress.completed_kanjis, 1);
  assert.equal(progress.total_kanjis, 1);
  assert.equal(progress.completed_grammars, 0);
  assert.equal(progress.is_completed, true);
  assert.ok(progress.completed_at);

  // Counter phải bằng độ dài mảng ID, nếu không lần đánh dấu tiếp theo sẽ kéo
  // counter tụt xuống vì model tính lại từ mảng.
  assert.equal(progress.completed_vocabularies, progress.learned_vocabulary_ids.length);
  assert.equal(progress.completed_kanjis, progress.learned_kanji_ids.length);
});

test('đánh dấu thêm một mục sau khi hoàn thành không làm counter tụt', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);

  await service.startLesson({ userId: USER_ID, lessonId: LESSON_ID });
  await service.completeLesson({ userId: USER_ID, lessonId: LESSON_ID });

  const after = await service.updateItem({
    userId: USER_ID,
    lessonId: LESSON_ID,
    itemType: 'vocabulary',
    itemId: VOCAB_A,
    completed: true,
  });

  assert.equal(after.completed_vocabularies, 2);
  assert.equal(after.is_completed, true);
});

test('gọi hoàn thành nhiều lần chỉ cộng 20 XP một lần', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);

  await service.startLesson({ userId: USER_ID, lessonId: LESSON_ID });
  const startXp = totalXp(repository);

  await service.completeLesson({ userId: USER_ID, lessonId: LESSON_ID });
  await service.completeLesson({ userId: USER_ID, lessonId: LESSON_ID });
  await service.completeLesson({ userId: USER_ID, lessonId: LESSON_ID });

  assert.equal(totalXp(repository) - startXp, 20);
});

test('thử lại sau lỗi giữa chừng vẫn nhận đủ thưởng và không nhân đôi', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);
  await service.startLesson({ userId: USER_ID, lessonId: LESSON_ID });
  const startXp = totalXp(repository);

  // Lần đầu: ghi tiến độ xong thì lỗi đúng lúc cộng XP.
  const grantXpOnce = repository.grantXpOnce;
  repository.grantXpOnce = async () => {
    throw new Error('mất kết nối');
  };
  await assert.rejects(
    service.completeLesson({ userId: USER_ID, lessonId: LESSON_ID }),
    /mất kết nối/,
  );
  assert.equal(repository.state.doc.completion_reward_state, 'pending');

  // Lần thử lại: khoản thưởng được hoàn tất đúng một lần.
  repository.grantXpOnce = grantXpOnce;
  await service.completeLesson({ userId: USER_ID, lessonId: LESSON_ID });
  await service.completeLesson({ userId: USER_ID, lessonId: LESSON_ID });

  assert.equal(totalXp(repository) - startXp, 20);
  assert.equal(repository.state.doc.completion_reward_state, 'granted');
});

test('bản ghi cũ đã hoàn thành được chuẩn hóa nhưng không nhận thưởng hồi tố', async () => {
  const legacy = new LessonProgress({
    user: USER_ID,
    lesson: LESSON_ID,
    is_completed: true,
    completed_at: new Date('2025-12-01T00:00:00.000Z'),
  });
  const repository = fakeRepository({ seed: legacy });
  const service = buildService(repository);

  const progress = await service.completeLesson({ userId: USER_ID, lessonId: LESSON_ID });

  assert.equal(totalXp(repository), 0);
  assert.equal(progress.completed_vocabularies, 2);
  assert.equal(progress.total_vocabularies, 2);
  // Mốc hoàn thành cũ được giữ nguyên.
  assert.equal(progress.completed_at.toISOString(), '2025-12-01T00:00:00.000Z');

  await service.completeLesson({ userId: USER_ID, lessonId: LESSON_ID });
  assert.equal(totalXp(repository), 0);
});

test('học nốt mục cuối cùng cũng nhận thưởng hoàn thành, và complete sau đó không cộng thêm', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);
  await service.startLesson({ userId: USER_ID, lessonId: LESSON_ID });
  const startXp = totalXp(repository);

  for (const [itemType, itemId] of [
    ['vocabulary', VOCAB_A],
    ['vocabulary', VOCAB_B],
    ['kanji', KANJI_A],
  ]) {
    await service.updateItem({
      userId: USER_ID,
      lessonId: LESSON_ID,
      itemType,
      itemId,
      completed: true,
    });
  }

  // 3 mục x 2 XP + 20 XP hoàn thành
  assert.equal(totalXp(repository) - startXp, 26);

  await service.completeLesson({ userId: USER_ID, lessonId: LESSON_ID });
  assert.equal(totalXp(repository) - startXp, 26);
});

test('đánh dấu lại cùng một mục không cộng thêm 2 XP', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);
  await service.startLesson({ userId: USER_ID, lessonId: LESSON_ID });
  const startXp = totalXp(repository);

  const mark = () =>
    service.updateItem({
      userId: USER_ID,
      lessonId: LESSON_ID,
      itemType: 'vocabulary',
      itemId: VOCAB_A,
      completed: true,
    });

  await mark();
  await mark();
  await mark();

  assert.equal(totalXp(repository) - startXp, 2);
});

test('gỡ đánh dấu rồi đánh dấu lại không nhận lại khoản thưởng đã ghi nhận', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);
  await service.startLesson({ userId: USER_ID, lessonId: LESSON_ID });
  const startXp = totalXp(repository);

  const setLearned = (completed) =>
    service.updateItem({
      userId: USER_ID,
      lessonId: LESSON_ID,
      itemType: 'vocabulary',
      itemId: VOCAB_A,
      completed,
    });

  await setLearned(true);
  const unmarked = await setLearned(false);
  assert.equal(unmarked.completed_vocabularies, 0);
  assert.equal(unmarked.is_completed, false);

  await setLearned(true);

  assert.equal(totalXp(repository) - startXp, 2);
});

test('mục không thuộc bài học bị từ chối 400', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);

  await assert.rejects(
    service.updateItem({
      userId: USER_ID,
      lessonId: LESSON_ID,
      itemType: 'vocabulary',
      itemId: OUTSIDER,
      completed: true,
    }),
    (error) => {
      assert.equal(error.status, 400);
      return true;
    },
  );
});

test('hoàn thành khi chưa có tiến độ trả 404, bài không tồn tại trả 404', async () => {
  const empty = fakeRepository();
  await assert.rejects(
    buildService(empty).completeLesson({ userId: USER_ID, lessonId: LESSON_ID }),
    (error) => {
      assert.equal(error.status, 404);
      return true;
    },
  );

  const noLesson = fakeRepository({ content: null });
  await assert.rejects(
    buildService(noLesson).startLesson({ userId: USER_ID, lessonId: LESSON_ID }),
    (error) => {
      assert.equal(error.status, 404);
      return true;
    },
  );
});

test('bắt đầu lại bài đã học không cộng thêm XP mở bài', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);

  await service.startLesson({ userId: USER_ID, lessonId: LESSON_ID });
  await service.startLesson({ userId: USER_ID, lessonId: LESSON_ID });

  assert.equal(totalXp(repository), 3);
});

test('reset xóa tiến độ và thống kê phản ánh dữ liệu còn lại', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);

  await service.startLesson({ userId: USER_ID, lessonId: LESSON_ID });
  await service.completeLesson({ userId: USER_ID, lessonId: LESSON_ID });

  const stats = await service.getStats(USER_ID);
  assert.equal(stats.total_lessons, 1);
  assert.equal(stats.completed_lessons, 1);
  assert.equal(stats.total_vocabularies_learned, 2);

  const levelStats = await service.getLevelStats({ userId: USER_ID, level: 'N5' });
  assert.equal(levelStats.progress_percentage, 100);

  await service.resetLesson({ userId: USER_ID, lessonId: LESSON_ID });
  assert.equal((await service.getStats(USER_ID)).total_lessons, 0);
});

test('nội dung bài lấy từ khóa ngoại khi mảng tham chiếu rỗng', async () => {
  const repository = createLessonProgressRepository({
    Lesson: {
      findById: () => ({
        lean: async () => ({
          _id: LESSON_ID,
          vocabularies: [],
          grammars: [],
          kanjis: [],
        }),
      }),
    },
    Vocabulary: { distinct: async () => [VOCAB_A, VOCAB_B] },
    Grammar: { distinct: async () => [] },
    Kanji: { distinct: async () => [KANJI_A] },
  });

  const content = await repository.findLessonContent(LESSON_ID);

  assert.deepEqual(content.vocabularyIds, [VOCAB_A, VOCAB_B]);
  assert.deepEqual(content.grammarIds, []);
  assert.deepEqual(content.kanjiIds, [KANJI_A]);
});

test('bài học không tồn tại trả về null nội dung', async () => {
  const repository = createLessonProgressRepository({
    Lesson: { findById: () => ({ lean: async () => null }) },
  });

  assert.equal(await repository.findLessonContent(LESSON_ID), null);
});

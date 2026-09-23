import assert from 'node:assert/strict';
import test from 'node:test';

import mongoose from 'mongoose';

import ExerciseResult from '../model/ExerciseResult.js';
import StreakDay from '../model/StreakDay.js';
import ActivityEvent from '../model/ActivityEvent.js';
import { DEMO_LEARNER_HISTORY, DEMO_PEERS } from '../scripts/demo-dataset.js';
import { buildDemoJournal, studyDays, summarizeJournal } from '../scripts/demo-history.js';
import { SAMPLE_EXERCISES } from '../scripts/sample-exercises.js';
import { scoreExerciseAnswers } from '../src/modules/exercise/exercise-scoring.service.js';

const TODAY = '2026-09-23';
const USER = new mongoose.Types.ObjectId();
const oid = () => new mongoose.Types.ObjectId();

/** Bài tập mẫu thật, gắn `_id` như khi đã nạp vào DB. */
const exercises = SAMPLE_EXERCISES.filter((row) => row.exercise.level === 'N5')
  .slice(0, 6)
  .map(({ exercise }) => ({
    ...exercise,
    _id: oid(),
    questions: exercise.questions.map((question) => ({
      ...question,
      _id: oid(),
      answers: question.answers.map((answer) => ({ ...answer, _id: oid() })),
    })),
  }));

const cards = Array.from({ length: 23 }, oid);

const journalFor = (overrides = {}) =>
  buildDemoJournal({
    userId: USER,
    username: 'demo_hocvien',
    profile: DEMO_LEARNER_HISTORY,
    todayKey: TODAY,
    cardIds: cards,
    exercises,
    ...overrides,
  });

test('the learner studied every day but one, never today, so the live streak is 13', () => {
  const { days, events } = journalFor();

  assert.equal(days.length, 19);
  assert.ok(!days.some((day) => day.day_key === TODAY), 'hôm nay để trống cho buổi demo');
  assert.ok(!days.some((day) => day.day_key === '2026-09-09'), 'ngày nghỉ cách đây 14 ngày');

  const summary = summarizeJournal({
    studiedDays: days.map((day) => day.day_key),
    totalXp: events.reduce((sum, event) => sum + event.xp_delta, 0),
  });
  assert.equal(summary.current_streak, 13);
  assert.equal(summary.last_activity_day, '2026-09-22');
  assert.equal(summary.total_active_days, 19);
});

test('the same account always gets the same history', () => {
  assert.deepEqual(journalFor(), journalFor());
  assert.notDeepEqual(
    journalFor().events.map((event) => event.occurred_at),
    journalFor({ username: 'demo_thulan' }).events.map((event) => event.occurred_at),
  );
});

test('every calendar day adds up exactly to its own events', () => {
  const { days, events } = journalFor();
  for (const day of days) {
    const own = events.filter((event) => event.day_key === day.day_key);
    const reviews = own.filter((event) => event.type === 'srs.review');
    assert.equal(day.direct_xp, own.reduce((sum, event) => sum + event.xp_delta, 0), day.day_key);
    assert.equal(day.review_count, reviews.length);
    assert.equal(day.correct_self_reports + day.wrong_self_reports, reviews.length);
  }
});

test('reviews point at the user real cards and XP follows the policy table', () => {
  const { events } = journalFor();
  const cardIds = new Set(cards.map(String));

  for (const event of events.filter((e) => e.type === 'srs.review')) {
    assert.ok(cardIds.has(event.source_id));
    assert.equal(event.xp_delta, 2);
  }
  assert.equal(new Set(events.map((event) => event.event_key)).size, events.length, 'khoá event không trùng');
});

test('each exercise event has a stored result that re-scores to the same grade', () => {
  const { events, results } = journalFor();
  const submissions = events.filter((event) => event.type === 'exercise.submit');

  assert.equal(submissions.length, results.length);
  assert.ok(results.length >= 6);
  for (const [index, result] of results.entries()) {
    const exercise = exercises.find((candidate) => candidate._id === result.exercise_id);
    const rescored = scoreExerciseAnswers({
      questions: exercise.questions,
      answers: result.user_answers,
      passScore: exercise.pass_score,
    });
    assert.equal(rescored.correctCount, result.correct_count);
    assert.equal(rescored.isPassed, result.is_passed);
    assert.equal(submissions[index].xp_delta, result.is_passed ? 10 : 5);
  }
});

test('documents pass their Mongoose model validation', () => {
  const { events, days, results } = journalFor();
  for (const [Model, docs] of [
    [ActivityEvent, events],
    [StreakDay, days],
    [ExerciseResult, results],
  ]) {
    for (const doc of docs) assert.equal(new Model(doc).validateSync(), undefined);
  }
});

test('days that already have real activity are left untouched', () => {
  const { days, events } = journalFor({ skipDays: new Set(['2026-09-22']) });
  const full = journalFor();

  assert.ok(!days.some((day) => day.day_key === '2026-09-22'));
  assert.ok(!events.some((event) => event.day_key === '2026-09-22'));
  // Bỏ một ngày không làm lệch lịch sử dựng sẵn của các ngày còn lại.
  assert.deepEqual(days, full.days.filter((day) => day.day_key !== '2026-09-22'));
});

test('without cards or exercises the journal simply has nothing for them', () => {
  const { events, results } = journalFor({ cardIds: [], exercises: [] });
  assert.deepEqual(events, []);
  assert.deepEqual(results, []);
});

test('peers have distinct paces for a meaningful leaderboard', () => {
  const xpOf = (peer) =>
    buildDemoJournal({
      userId: oid(),
      username: peer.username,
      profile: peer.history,
      todayKey: TODAY,
      cardIds: cards,
      exercises,
    }).events.reduce((sum, event) => sum + event.xp_delta, 0);

  const totals = DEMO_PEERS.map(xpOf);
  assert.equal(new Set(totals).size, DEMO_PEERS.length);
  assert.deepEqual(studyDays({ todayKey: TODAY, days: 3, missedOffsets: [2] }), ['2026-09-22', '2026-09-20']);
});

test('the journal summary finds the longest run and the current one', () => {
  const summary = summarizeJournal({
    studiedDays: ['2026-09-01', '2026-09-02', '2026-09-03', '2026-09-10', '2026-09-11', '2026-09-11'],
    totalXp: 42,
  });
  assert.deepEqual(summary, {
    current_streak: 2,
    longest_streak: 3,
    last_activity_day: '2026-09-11',
    tracking_started_day: '2026-09-01',
    total_active_days: 5,
    total_xp: 42,
  });
});

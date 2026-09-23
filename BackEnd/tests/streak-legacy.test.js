import assert from 'node:assert/strict';
import test from 'node:test';

import mongoose from 'mongoose';

import { backupProblems, checksumOf, parseDocuments, serializeDocuments } from '../scripts/backup-format.js';
import {
  auditUserStreaks,
  LEGACY_REWARD_TYPE,
  MIGRATION_VERSION,
  planUserMigration,
  suggestLegacyTimeZone,
  timeOfDayHistogram,
  verifyUserMigration,
} from '../scripts/streak-legacy.js';
import { projectStreak } from '../src/modules/streaks/streak-rules.js';

const oid = (hex) => new mongoose.Types.ObjectId(hex.padStart(24, '0'));
const USER = oid('a1');
const STREAK_ID = oid('51');
const VN = 'Asia/Ho_Chi_Minh';

/** Nửa đêm giờ Việt Nam lưu dưới dạng UTC — đúng cách code cũ ghi `activity_dates`. */
const vnMidnight = (day) => new Date(`${day}T00:00:00+07:00`);

const legacyStreak = (over = {}) => ({
  _id: STREAK_ID,
  user: USER,
  current_streak: 4,
  longest_streak: 9,
  total_xp: 45,
  last_activity_date: vnMidnight('2026-09-19'),
  activity_dates: [vnMidnight('2026-09-18'), vnMidnight('2026-09-19'), vnMidnight('2026-09-19')],
  xp_history: [
    { amount: 10, reason: 'Daily login', earned_at: new Date('2026-09-18T01:00:00Z') },
    { amount: 10, reason: 'Daily login', earned_at: new Date('2026-09-18T01:00:00Z') },
    { amount: 25, reason: 'Hoàn thành bài học', earned_at: new Date('2026-09-19T16:30:00Z') },
  ],
  reward_keys: ['lesson-complete:l1', 'lesson-item:l1:vocabulary:v1', 'lesson-complete:l1'],
  ...over,
});

// --- audit ------------------------------------------------------------------

test('audit counts problems by group without exposing document content', () => {
  const report = auditUserStreaks({
    streaks: [
      legacyStreak(),
      legacyStreak({ _id: oid('52'), current_streak: 12, total_xp: -5 }),
      legacyStreak({ _id: oid('53'), user: 'not-an-id', last_activity_date: null, xp_history: [{ reason: 'x' }] }),
    ],
    userIds: new Set([USER.toHexString()]),
  });

  assert.equal(report.total, 3);
  assert.equal(report.duplicateUsers, 1);
  assert.equal(report.userMissingOrWrongType, 1);
  assert.equal(report.totalXpInvalid, 1);
  assert.equal(report.currentAboveLongest, 1);
  assert.equal(report.lastActivityDateMissing, 1);
  assert.equal(report.xpHistoryEntriesInvalid, 1);
  assert.deepEqual(report.arrays.reward_keys, { min: 3, max: 3, total: 9 });
});

test('legacy dates that cluster on Vietnamese midnight suggest that time zone; mixed ones suggest nothing', () => {
  const vn = timeOfDayHistogram([vnMidnight('2026-09-01'), vnMidnight('2026-09-02')]);
  assert.deepEqual(vn, [{ time: '17:00', count: 2 }]);
  assert.equal(suggestLegacyTimeZone(vn).timeZone, VN);

  const mixed = timeOfDayHistogram([vnMidnight('2026-09-01'), new Date('2026-09-02T00:00:00Z')]);
  assert.equal(suggestLegacyTimeZone(mixed), null);
});

// --- plan -------------------------------------------------------------------

test('xp history becomes one legacy event per row, keyed by position so equal rows stay separate', () => {
  const plan = planUserMigration({ streak: legacyStreak() });
  const xp = plan.events.filter((event) => event.type === 'legacy.xp');

  assert.deepEqual(
    xp.map((event) => [event.event_key, event.xp_delta, event.day_key]),
    [
      [`legacy-xp:${STREAK_ID}:0`, 10, '2026-09-18'],
      [`legacy-xp:${STREAK_ID}:1`, 10, '2026-09-18'],
      // 16:30 UTC là 23:30 giờ Việt Nam — vẫn là ngày 19.
      [`legacy-xp:${STREAK_ID}:2`, 25, '2026-09-19'],
    ],
  );
  assert.ok(xp.every((event) => event.counts_as_study === false && event.policy_version === MIGRATION_VERSION));
  assert.equal(plan.legacyXpTotal, 45);
});

test('reward keys keep their exact key so the new writer will not pay them again', () => {
  const plan = planUserMigration({ streak: legacyStreak(), completedAchievementIds: [oid('ac')] });
  const markers = plan.events.filter((event) => event.type === LEGACY_REWARD_TYPE);

  assert.deepEqual(
    markers.map((event) => [event.event_key, event.xp_delta]),
    [
      ['lesson-complete:l1', 0],
      ['lesson-item:l1:vocabulary:v1', 0],
      [`achievement:${USER}:${oid('ac')}`, 0],
    ],
  );
});

test('without a known legacy time zone, days and the last activity day are left alone', () => {
  const plan = planUserMigration({ streak: legacyStreak() });

  assert.deepEqual(plan.days, []);
  assert.deepEqual(plan.summaryPatch, { tracking_started_day: '2026-09-20' });
});

test('with the time zone, legacy dates become unique calendar days', () => {
  const plan = planUserMigration({ streak: legacyStreak(), legacyTimeZone: VN });

  assert.deepEqual(plan.days, ['2026-09-18', '2026-09-19']);
  assert.equal(plan.summaryPatch.last_activity_day, '2026-09-19');
});

test('a streak alive at cutover is kept; one already broken is not revived', () => {
  const lastDayFor = (day) =>
    planUserMigration({ streak: legacyStreak({ last_activity_date: vnMidnight(day) }), legacyTimeZone: VN })
      .summaryPatch.last_activity_day;
  const view = (day, today) => projectStreak({ currentStreak: 4, lastActivityDay: lastDayFor(day) }, today).currentStreak;

  assert.equal(view('2026-09-20', '2026-09-20'), 4, 'học hôm cutover');
  assert.equal(view('2026-09-19', '2026-09-20'), 4, 'học hôm trước cutover');
  assert.equal(view('2026-09-15', '2026-09-20'), 0, 'đã đứt trước cutover');
});

test('fields the new write path already set are never overwritten', () => {
  const plan = planUserMigration({
    streak: legacyStreak({ last_activity_day: '2026-09-22', tracking_started_day: '2026-09-21' }),
    legacyTimeZone: VN,
  });
  assert.deepEqual(plan.summaryPatch, {});
});

test('broken xp rows are still copied, with zero XP, and reported', () => {
  const plan = planUserMigration({
    streak: legacyStreak({ xp_history: [{ reason: 'hỏng' }], createdAt: new Date('2026-01-01T00:00:00Z') }),
  });
  const [event] = plan.events;

  assert.equal(event.xp_delta, 0);
  assert.deepEqual(event.occurred_at, new Date('2026-01-01T00:00:00Z'));
  assert.equal(plan.problems.length, 1);
});

test('verification reports what is missing and the balance gap without fixing it', () => {
  const plan = planUserMigration({ streak: legacyStreak(), legacyTimeZone: VN });
  const allKeys = new Set(plan.events.map((event) => event.event_key));

  const ok = verifyUserMigration({
    plan,
    streak: { total_xp: 65 },
    storedEventKeys: allKeys,
    storedDayKeys: new Set(plan.days),
    activityXpTotal: 20,
  });
  assert.deepEqual(ok, { ok: true, missingEvents: 0, missingDays: 0, xpDifference: 0 });

  const partial = verifyUserMigration({
    plan,
    streak: { total_xp: 100 },
    storedEventKeys: new Set(),
    storedDayKeys: new Set(['2026-09-18']),
  });
  assert.equal(partial.ok, false);
  assert.equal(partial.missingEvents, plan.events.length);
  assert.equal(partial.missingDays, 1);
  assert.equal(partial.xpDifference, 55);
});

// --- backup format ----------------------------------------------------------

test('backups keep BSON types and checksum the same data identically in any order', () => {
  const docs = [
    { _id: oid('2'), user: USER, at: new Date('2026-09-19T00:00:00Z'), xp: 5 },
    { _id: oid('1'), user: USER, at: new Date('2026-09-18T00:00:00Z'), xp: 10 },
  ];
  const restored = parseDocuments(serializeDocuments(docs));

  assert.ok(restored[0].user instanceof mongoose.Types.ObjectId);
  assert.ok(restored[0].at instanceof Date);
  assert.equal(checksumOf(restored), checksumOf([...docs].reverse()));
  assert.notEqual(checksumOf(docs), checksumOf([{ ...docs[0], xp: 6 }, docs[1]]));
});

test('a backup is only usable for migration once a restore rehearsal passed', () => {
  const required = ['userstreaks', 'activityevents'];
  const manifest = { collections: { userstreaks: {}, activityevents: {} } };

  assert.equal(backupProblems(manifest, required).length, 1);
  assert.deepEqual(backupProblems({ ...manifest, restore_checked_at: '2026-09-23' }, required), []);
  assert.match(backupProblems({ collections: {}, restore_checked_at: 'x' }, required)[0], /userstreaks/);
});

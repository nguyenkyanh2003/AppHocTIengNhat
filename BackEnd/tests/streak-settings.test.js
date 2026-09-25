import assert from 'node:assert/strict';
import test from 'node:test';

import StreakSettings, {
  SETTINGS_GOAL_OPTIONS,
  SETTINGS_REMINDER_WINDOW,
} from '../model/StreakSettings.js';
import {
  DAILY_GOAL_OPTIONS,
  DEFAULT_DAILY_GOAL,
  DEFAULT_REMINDER_TIME,
  REMINDER_WINDOW,
} from '../src/modules/streaks/streak-policy.js';
import {
  effectiveGoal,
  isDailyGoal,
  isReminderTime,
  planGoalChange,
  settingsView,
} from '../src/modules/streaks/streak-settings.js';

const TODAY = '2026-09-25';
const TOMORROW = '2026-09-26';

// --- mục tiêu ngày -------------------------------------------------------------

test('người chưa chọn gì có mục tiêu mặc định 20 XP', () => {
  assert.equal(effectiveGoal(null, TODAY), DEFAULT_DAILY_GOAL);
  assert.equal(effectiveGoal({}, TODAY), DEFAULT_DAILY_GOAL);
});

test('mục tiêu mới chỉ có hiệu lực từ ngày Việt Nam kế tiếp', () => {
  // Spec §5.1: không thay điều kiện giữa ngày.
  const patch = planGoalChange(null, 30, TODAY);
  assert.deepEqual(patch, { daily_goal_xp: 30, previous_goal_xp: 20, goal_effective_from: TOMORROW });
  assert.equal(effectiveGoal(patch, TODAY), 20);
  assert.equal(effectiveGoal(patch, TOMORROW), 30);
});

test('đổi hai lần trong một ngày vẫn giữ mục tiêu của hôm nay làm mốc', () => {
  const first = planGoalChange(null, 30, TODAY);
  const second = planGoalChange(first, 50, TODAY);
  assert.deepEqual(second, { daily_goal_xp: 50, previous_goal_xp: 20, goal_effective_from: TOMORROW });
  assert.equal(effectiveGoal(second, TODAY), 20);
});

test('chọn lại đúng mục tiêu hôm nay thì huỷ thay đổi đang chờ', () => {
  const pending = planGoalChange(null, 30, TODAY);
  assert.deepEqual(planGoalChange(pending, 20, TODAY), {
    daily_goal_xp: 20,
    previous_goal_xp: null,
    goal_effective_from: null,
  });
});

test('đổi mục tiêu ngay ngày nó bắt đầu hiệu lực lấy mục tiêu mới làm mốc', () => {
  const pending = planGoalChange(null, 30, TODAY);
  assert.deepEqual(planGoalChange(pending, 10, TOMORROW), {
    daily_goal_xp: 10,
    previous_goal_xp: 30,
    goal_effective_from: '2026-09-27',
  });
});

test('isDailyGoal chỉ nhận đúng bốn mức', () => {
  for (const goal of [10, 20, 30, 50]) assert.equal(isDailyGoal(goal), true);
  for (const goal of [0, 25, 100, '20', null, undefined]) assert.equal(isDailyGoal(goal), false);
});

// --- giờ nhắc ------------------------------------------------------------------

test('giờ nhắc phải là HH:MM trong khung 08:00–21:59', () => {
  for (const time of ['08:00', '12:30', '20:00', '21:59']) assert.equal(isReminderTime(time), true, time);
  for (const time of ['07:59', '22:00', '23:30', '00:00', '8:00', '20:60', '24:00', '20:00:00', '', 2000, null]) {
    assert.equal(isReminderTime(time), false, String(time));
  }
});

// --- dạng trả về cho client ------------------------------------------------------

test('settingsView trả mặc định khi chưa có cài đặt', () => {
  assert.deepEqual(settingsView(null, TODAY), {
    daily_goal_xp: 20,
    next_daily_goal_xp: null,
    next_goal_from: null,
    goal_options: [10, 20, 30, 50],
    reminder_enabled: false,
    reminder_time: '20:00',
    reminder_window: { start: '08:00', end: '21:59' },
    revision: 0,
  });
});

test('settingsView báo mục tiêu đang chờ và ngày bắt đầu', () => {
  const settings = { ...planGoalChange(null, 30, TODAY), reminder_enabled: true, reminder_time: '19:30', revision: 3 };
  const view = settingsView(settings, TODAY);
  assert.equal(view.daily_goal_xp, 20);
  assert.equal(view.next_daily_goal_xp, 30);
  assert.equal(view.next_goal_from, TOMORROW);
  assert.equal(view.reminder_enabled, true);
  assert.equal(view.reminder_time, '19:30');
  assert.equal(view.revision, 3);
});

test('qua ngày hiệu lực thì không còn gì "đang chờ"', () => {
  const settings = planGoalChange(null, 30, TODAY);
  const view = settingsView(settings, '2026-09-27');
  assert.equal(view.daily_goal_xp, 30);
  assert.equal(view.next_daily_goal_xp, null);
  assert.equal(view.next_goal_from, null);
});

// --- model --------------------------------------------------------------------

test('model dùng đúng hằng số của chính sách', () => {
  // Model không import tầng nghiệp vụ; test này là thứ giữ hai bên khớp nhau.
  assert.deepEqual([...SETTINGS_GOAL_OPTIONS], [...DAILY_GOAL_OPTIONS]);
  assert.deepEqual({ ...SETTINGS_REMINDER_WINDOW }, { ...REMINDER_WINDOW });
  const doc = new StreakSettings({ user: '507f1f77bcf86cd799439011' });
  assert.equal(doc.daily_goal_xp, DEFAULT_DAILY_GOAL);
  assert.equal(doc.reminder_time, DEFAULT_REMINDER_TIME);
  assert.equal(doc.reminder_enabled, false);
  assert.equal(doc.revision, 0);
  assert.equal(doc.validateSync(), undefined);
});

test('model mỗi user chỉ một bản cài đặt', () => {
  const user = StreakSettings.schema.path('user');
  assert.equal(user.options.unique, true);
  assert.equal(user.options.required, true);
});

test('model chặn mục tiêu lạ, giờ ngoài khung và ngày hiệu lực sai định dạng', () => {
  const doc = new StreakSettings({
    user: '507f1f77bcf86cd799439011',
    daily_goal_xp: 25,
    previous_goal_xp: 15,
    reminder_time: '22:30',
    goal_effective_from: '2026-02-30',
  });
  const error = doc.validateSync();
  assert.ok(error);
  assert.deepEqual(
    Object.keys(error.errors).sort(),
    ['daily_goal_xp', 'goal_effective_from', 'previous_goal_xp', 'reminder_time'],
  );
});

test('model chấp nhận previous_goal_xp và ngày hiệu lực để trống', () => {
  const doc = new StreakSettings({
    user: '507f1f77bcf86cd799439011',
    previous_goal_xp: null,
    goal_effective_from: null,
  });
  assert.equal(doc.validateSync(), undefined);
});

import assert from 'node:assert/strict';
import test from 'node:test';

import mongoose from 'mongoose';

import LearningGoal from '../model/LearningGoal.js';

const USER_ID = new mongoose.Types.ObjectId();

test('mục tiêu thuộc một tài khoản; hạn và thời điểm hoàn thành mặc định trống', () => {
  const goal = new LearningGoal({ user: USER_ID, type: 'vocabulary', title: 'Đạt 150 từ vựng', target: 150 });

  assert.equal(goal.validateSync(), undefined);
  assert.equal(goal.deadline, null);
  assert.equal(goal.completed_at, null);
  assert.equal(LearningGoal.schema.path('user').options.ref, 'User');
});

test('chỉ ba loại tích luỹ, số cần đạt ít nhất 1, hạn dạng YYYY-MM-DD', () => {
  assert.deepEqual(LearningGoal.schema.path('type').enumValues, ['lessons', 'vocabulary', 'kanji']);

  const error = new LearningGoal({ user: USER_ID, type: 'days', title: 'X', target: 0, deadline: '04/11/2026' }).validateSync();
  assert.deepEqual(Object.keys(error.errors).sort(), ['deadline', 'target', 'type']);
});

test('có index cho danh sách mục tiêu của một người', () => {
  const indexes = LearningGoal.schema.indexes().map(([fields]) => fields);
  assert.ok(indexes.some((fields) => fields.user === 1 && fields.createdAt === -1));
});

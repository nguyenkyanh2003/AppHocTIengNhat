import assert from 'node:assert/strict';
import test from 'node:test';

import mongoose from 'mongoose';

import Notification from '../model/Notification.js';

const USER_ID = new mongoose.Types.ObjectId();

test('mỗi thông báo thuộc đúng một người nhận, mặc định chưa đọc', () => {
  const notification = new Notification({ recipient: USER_ID, title: 'Chào', message: 'Học tiếp nhé' });

  assert.equal(notification.validateSync(), undefined);
  assert.equal(notification.is_read, false);
  assert.equal(notification.read_at, null);
  assert.equal(notification.type, 'SYSTEM');
  assert.equal(notification.sender, null);
});

test('thiếu người nhận, tiêu đề hoặc nội dung thì không lưu được', () => {
  const error = new Notification({}).validateSync();

  assert.deepEqual(Object.keys(error.errors).sort(), ['message', 'recipient', 'title']);
});

test('loại thông báo dùng chung với Flutter; bỏ target_level kiểu phát theo cấp độ', () => {
  assert.deepEqual(Notification.schema.path('type').enumValues, ['SYSTEM', 'LESSON', 'EXAM', 'ACHIEVEMENT']);
  assert.equal(Notification.schema.path('target_level'), undefined);
  assert.equal(Notification.schema.path('recipient').options.ref, 'User');
});

test('có index cho danh sách theo người nhận và cho bộ đếm chưa đọc', () => {
  const indexes = Notification.schema.indexes().map(([fields]) => fields);

  assert.ok(indexes.some((fields) => fields.recipient === 1 && fields.createdAt === -1));
  assert.ok(indexes.some((fields) => fields.recipient === 1 && fields.is_read === 1));
  assert.ok(!indexes.some((fields) => Object.values(fields).includes('text')), 'text index không ai dùng');
});

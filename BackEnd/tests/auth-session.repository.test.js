import assert from 'node:assert/strict';
import test from 'node:test';

import mongoose from 'mongoose';

import AuthSession from '../model/AuthSession.js';
import { createAuthSessionRepository } from '../src/modules/users/auth-session.repository.js';

const ID = '507f1f77bcf86cd799439011';
const AT = new Date('2026-11-05T00:00:00.000Z');

/** Model giả: ghi lại lời gọi; truy vấn kết thúc bằng `lean()`. */
const fakeModel = (calls) => {
  const chain = (name, args) => {
    calls.push([name, ...args]);
    const query = {
      select: (fields) => { calls.push(['select', fields]); return query; },
      lean: async () => null,
    };
    return query;
  };
  return {
    findById: (...args) => chain('findById', args),
    findOne: (...args) => chain('findOne', args),
    findOneAndUpdate: (...args) => chain('findOneAndUpdate', args),
    updateMany: async (...args) => { calls.push(['updateMany', ...args]); },
  };
};

const REVOKED = { $set: { revoked_at: AT, revoked_reason: 'logout' } };

test('thay refresh token chỉ khớp khi token hiện tại vẫn là token vừa đọc và phiên chưa thu hồi', async () => {
  const calls = [];
  const repository = createAuthSessionRepository({ AuthSession: fakeModel(calls) });

  await repository.rotate({
    id: ID, fromHash: 'hien-tai', toHash: 'moi', previousHash: 'cu', previousRetiredAt: AT, supersededHash: 'bi-thay', expiresAt: AT, at: AT,
  });

  assert.deepEqual(calls, [[
    'findOneAndUpdate',
    { _id: ID, refresh_token_hash: 'hien-tai', revoked_at: null },
    {
      $set: {
        refresh_token_hash: 'moi',
        previous_token_hash: 'cu',
        previous_retired_at: AT,
        superseded_token_hash: 'bi-thay',
        expires_at: AT,
        last_used_at: AT,
      },
      $inc: { rotation: 1 },
    },
    { new: true },
  ]]);
});

test('token đã nghỉ gồm token vừa bị thay và token bị thay trong lúc ân hạn', async () => {
  const calls = [];
  const repository = createAuthSessionRepository({ AuthSession: fakeModel(calls) });

  await repository.findByRetiredHash('h');

  assert.deepEqual(calls, [['findOne', { $or: [{ previous_token_hash: 'h' }, { superseded_token_hash: 'h' }] }]]);
});

test('đăng xuất đóng phiên bằng bất kỳ refresh token nào của phiên đó, chỉ phiên chưa thu hồi', async () => {
  const calls = [];
  const repository = createAuthSessionRepository({ AuthSession: fakeModel(calls) });

  await repository.revokeByTokenHash({ hash: 'h', reason: 'logout', at: AT });

  assert.deepEqual(calls, [[
    'updateMany',
    {
      $or: [{ refresh_token_hash: 'h' }, { previous_token_hash: 'h' }, { superseded_token_hash: 'h' }],
      revoked_at: null,
    },
    REVOKED,
  ]]);
});

test('thu hồi theo phiên và theo tài khoản; mã phiên sai định dạng không chạm database', async () => {
  const calls = [];
  const repository = createAuthSessionRepository({ AuthSession: fakeModel(calls) });

  await repository.revoke({ id: ID, reason: 'logout', at: AT });
  await repository.revokeAllForUser({ userId: 'u1', reason: 'logout', at: AT });
  assert.equal(await repository.findById('khong-phai-object-id'), null);
  assert.equal(await repository.revoke({ id: 'khong-phai-object-id', reason: 'logout', at: AT }), null);

  assert.deepEqual(calls, [
    ['updateMany', { _id: ID, revoked_at: null }, REVOKED],
    ['updateMany', { user: 'u1', revoked_at: null }, REVOKED],
  ]);
});

test('model: có đủ trường và index cho token đã nghỉ, MongoDB tự xoá phiên hết hạn', () => {
  for (const field of ['previous_token_hash', 'previous_retired_at', 'superseded_token_hash']) {
    assert.ok(AuthSession.schema.path(field), field);
  }
  assert.equal(AuthSession.schema.path('rotation').options.default, 0);
  const indexes = AuthSession.schema.indexes();
  assert.ok(indexes.some(([fields, options]) => fields.expires_at === 1 && options.expireAfterSeconds === 0));
  assert.ok(mongoose.isValidObjectId(ID));
  for (const field of ['previous_token_hash', 'superseded_token_hash']) {
    assert.equal(AuthSession.schema.path(field).options.index, true, field);
  }
});

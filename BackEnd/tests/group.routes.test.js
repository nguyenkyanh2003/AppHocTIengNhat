import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler, notFoundHandler } from '../src/middleware/error.middleware.js';
import { createGroupRoutes } from '../src/modules/study-groups/group.routes.js';
import { ApiError } from '../src/shared/http/api-error.js';

const GROUP_ID = '507f1f77bcf86cd799439011';
const USER_ID = '507f1f77bcf86cd799439012';
const GROUP = { _id: GROUP_ID, name: 'Ôn N5' };

const fakeUpload = (file) => (req, _res, next) => {
  if (file) req.file = file;
  next();
};

const buildApp = (service, { file } = {}) => {
  const app = express();
  app.use(express.json());
  app.use('/api/group', createGroupRoutes({
    service,
    authenticate: (req, _res, next) => { req.user = { _id: 'me' }; next(); },
    uploadAvatar: fakeUpload(file),
  }));
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
};

const recording = (methods) => {
  const calls = [];
  const service = Object.fromEntries(Object.entries(methods).map(([name, result]) => [name, async (args) => {
    calls.push([name, args]);
    if (result instanceof Error) throw result;
    return result;
  }]));
  return { calls, service };
};

test('danh sách theo contract phân trang; nhóm của tôi là `{ data, total }`', async () => {
  const { calls, service } = recording({ list: { items: [GROUP], total: 1, page: 1, limit: 10 }, listMine: [GROUP] });
  const app = buildApp(service);

  assert.deepEqual((await request(app).get('/api/group?limit=10&is_private=false&search=')).body, {
    data: [GROUP], page: 1, limit: 10, total: 1, totalPages: 1,
  });
  assert.deepEqual((await request(app).get('/api/group/me')).body, { data: [GROUP], total: 1 });
  assert.deepEqual(calls, [
    ['list', { page: 1, limit: 10, is_private: false, search: undefined }],
    ['listMine', 'me'],
  ]);
});

test('tạo nhóm 201 với mặc định; thiếu tên hay cấp độ lạ là 400', async () => {
  const { calls, service } = recording({ create: GROUP });
  const app = buildApp(service);

  const response = await request(app).post('/api/group').send({ name: ' Ôn N5 ', creator_id: 'someone-else' });

  assert.equal(response.status, 201);
  assert.deepEqual(calls, [['create', { userId: 'me', input: { name: 'Ôn N5', level: 'ALL', is_private: false, max_members: 50 } }]]);
  assert.equal((await request(app).post('/api/group').send({ name: '' })).status, 400);
  assert.equal((await request(app).post('/api/group').send({ name: 'a', level: 'N6' })).status, 400);
});

test('chi tiết, sửa, xoá, thống kê theo id nhóm', async () => {
  const { calls, service } = recording({ detail: GROUP, update: GROUP, remove: undefined, stats: { member_count: 3 } });
  const app = buildApp(service);

  assert.deepEqual((await request(app).get(`/api/group/${GROUP_ID}`)).body, { data: GROUP });
  await request(app).put(`/api/group/${GROUP_ID}`).send({ description: 'Mỗi tối 20h' });
  assert.deepEqual((await request(app).delete(`/api/group/${GROUP_ID}`)).body.data, { deleted: true });
  assert.deepEqual((await request(app).get(`/api/group/${GROUP_ID}/stats`)).body, { data: { member_count: 3 } });
  assert.equal((await request(app).put(`/api/group/${GROUP_ID}`).send({})).status, 400);
  assert.equal((await request(app).get('/api/group/abc')).status, 400);

  assert.deepEqual(calls, [
    ['detail', { userId: 'me', groupId: GROUP_ID }],
    ['update', { userId: 'me', groupId: GROUP_ID, changes: { description: 'Mỗi tối 20h' } }],
    ['remove', { userId: 'me', groupId: GROUP_ID }],
    ['stats', { userId: 'me', groupId: GROUP_ID }],
  ]);
});

test('tham gia, rời, mời ra, thăng, hạ chức giữ đường dẫn cũ', async () => {
  const { calls, service } = recording({ join: GROUP, leave: undefined, kick: GROUP, promote: GROUP, demote: GROUP });
  const app = buildApp(service);

  assert.deepEqual((await request(app).post(`/api/group/join/${GROUP_ID}`)).body.data, GROUP);
  assert.deepEqual((await request(app).post(`/api/group/leave/${GROUP_ID}`)).body.data, { left: true });
  await request(app).delete(`/api/group/kick/${GROUP_ID}/${USER_ID}`);
  await request(app).put(`/api/group/promote/${GROUP_ID}/${USER_ID}`);
  await request(app).put(`/api/group/demote/${GROUP_ID}/${USER_ID}`);
  assert.equal((await request(app).put(`/api/group/promote/${GROUP_ID}/abc`)).status, 400);

  const member = { userId: 'me', groupId: GROUP_ID, memberId: USER_ID };
  assert.deepEqual(calls, [
    ['join', { userId: 'me', groupId: GROUP_ID }],
    ['leave', { userId: 'me', groupId: GROUP_ID }],
    ['kick', member],
    ['promote', member],
    ['demote', member],
  ]);
});

test('đổi ảnh nhóm: thiếu file 400; có file thì lưu đường dẫn ảnh đã tải', async () => {
  assert.equal((await request(buildApp(recording({ setAvatar: GROUP }).service)).put(`/api/group/${GROUP_ID}/avatar`)).status, 400);

  const { calls, service } = recording({ setAvatar: GROUP });
  const image = Buffer.from([0xff, 0xd8, 0xff]);
  await request(buildApp(service, { file: { buffer: image } })).put(`/api/group/${GROUP_ID}/avatar`);
  assert.deepEqual(calls, [['setAvatar', { userId: 'me', groupId: GROUP_ID, image }]]);
});

test('không có quyền là 403, không phải 500', async () => {
  const { service } = recording({ kick: ApiError.forbidden('Chỉ quản trị viên nhóm.') });
  assert.equal((await request(buildApp(service)).delete(`/api/group/kick/${GROUP_ID}/${USER_ID}`)).status, 403);
});

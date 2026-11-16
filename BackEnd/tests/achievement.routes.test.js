import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler, notFoundHandler } from '../src/middleware/error.middleware.js';
import { createAchievementRoutes } from '../src/modules/achievements/achievement.routes.js';

const ID = '64b7f0c2a1b2c3d4e5f60718';

const asUser = (req, _res, next) => {
  req.user = { _id: 'user-1' };
  next();
};

const buildApp = (service = {}) => {
  const app = express();
  app.use(express.json());
  app.use(
    '/api/achievement',
    createAchievementRoutes({ service, authenticate: asUser, authenticateAsAdmin: asUser }),
  );
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
};

const validDefinition = {
  name: 'Word Beginner',
  name_vi: 'Người Mới Học Từ',
  description: 'Learn 50 words',
  description_vi: 'Học 50 từ vựng',
  icon: '📚',
  category: 'vocabulary',
  requirement_type: 'count',
  requirement_value: 50,
};

test('learner routes answer in the shared envelopes', async () => {
  const app = buildApp({
    listActive: async () => [{ name: 'a' }],
    myAchievements: async (userId) => ({ earned: [], locked: [], total: 0, completed: 0, userId }),
    byCategory: async (userId, category) => ({ achievements: [], user_progress: [], category }),
    stats: async () => ({ total_achievements: 2, earned_achievements: 1 }),
  });

  assert.deepEqual((await request(app).get('/api/achievement/all')).body, { data: [{ name: 'a' }], total: 1 });
  assert.equal((await request(app).get('/api/achievement/my-achievements')).body.data.userId, 'user-1');
  assert.equal((await request(app).get('/api/achievement/category/kanji')).body.data.category, 'kanji');
  assert.deepEqual((await request(app).get('/api/achievement/stats')).body, {
    data: { total_achievements: 2, earned_achievements: 1 },
  });
  assert.equal((await request(app).get('/api/achievement/category/social')).status, 400);
});

test('admin list is a `{ data, total }` list, empty included', async () => {
  const app = buildApp({ listAll: async () => [] });

  const response = await request(app).get('/api/achievement/admin/all');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: [], total: 0 });
});

test('progress can no longer be self-reported', async () => {
  const response = await request(buildApp()).post('/api/achievement/update-progress').send({ progress: 999 });
  assert.equal(response.status, 404);
});

test('admin create validates the definition and applies defaults', async () => {
  let received = null;
  const app = buildApp({
    create: async (payload) => {
      received = payload;
      return { _id: ID, ...payload };
    },
  });

  const response = await request(app).post('/api/achievement/admin').send(validDefinition);

  assert.equal(response.status, 201);
  assert.equal(response.body.message, 'Tạo thành tích thành công');
  assert.equal(received.xp_reward, 100);
  assert.equal(received.rarity, 'common');
  assert.equal(received.is_active, true);

  for (const bad of [
    { ...validDefinition, name: '' },
    { ...validDefinition, category: 'social' },
    { ...validDefinition, requirement_value: 0 },
    { ...validDefinition, xp_reward: 10 ** 9 },
  ]) {
    assert.equal((await request(app).post('/api/achievement/admin').send(bad)).status, 400);
  }
});

test('a badge cannot mix a category with a criterion from another one', async () => {
  const app = buildApp({
    create: async (payload) => ({ _id: ID, ...payload }),
    update: async (id, updates) => ({ _id: id, ...updates }),
  });

  for (const bad of [
    { category: 'kanji', requirement_type: 'xp' },
    { category: 'vocabulary', requirement_type: 'streak' },
    { category: 'streak', requirement_type: 'count' },
    { category: 'xp', requirement_type: 'count' },
  ]) {
    const created = await request(app).post('/api/achievement/admin').send({ ...validDefinition, ...bad });
    assert.equal(created.status, 400, JSON.stringify(bad));
    assert.equal((await request(app).put(`/api/achievement/admin/${ID}`).send(bad)).status, 400, JSON.stringify(bad));
  }

  for (const good of [
    { category: 'streak', requirement_type: 'streak' },
    { category: 'xp', requirement_type: 'xp' },
    { category: 'lesson', requirement_type: 'completion' },
    { category: 'kanji', requirement_type: 'count' },
  ]) {
    const created = await request(app).post('/api/achievement/admin').send({ ...validDefinition, ...good });
    assert.equal(created.status, 201, JSON.stringify(good));
  }

  // Sửa riêng lẻ một trường thì không có gì để đối chiếu.
  assert.equal((await request(app).put(`/api/achievement/admin/${ID}`).send({ xp_reward: 5 })).status, 200);
});

test('admin update and delete take a valid id', async () => {
  const app = buildApp({
    update: async (id, updates) => ({ _id: id, ...updates }),
    remove: async () => undefined,
  });

  const updated = await request(app).put(`/api/achievement/admin/${ID}`).send({ xp_reward: '150' });
  assert.deepEqual(updated.body, { data: { _id: ID, xp_reward: 150 }, message: 'Cập nhật thành công' });

  const deleted = await request(app).delete(`/api/achievement/admin/${ID}`);
  assert.deepEqual(deleted.body, { data: { deleted: true }, message: 'Xóa thành tích thành công' });

  assert.equal((await request(app).delete('/api/achievement/admin/abc')).status, 400);
});

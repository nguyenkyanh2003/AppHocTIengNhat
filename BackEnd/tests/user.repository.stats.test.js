import assert from 'node:assert/strict';
import test from 'node:test';

import { createUserRepository } from '../src/modules/users/user.repository.js';

/** Model giả ghi lại pipeline `aggregate` để kiểm trường được nhóm. */
const statsModel = () => {
  const pipelines = [];
  const query = { select: () => query, sort: () => query, limit: () => query, lean: async () => [] };
  return {
    pipelines,
    countDocuments: async () => 3,
    aggregate: async (pipeline) => {
      pipelines.push(pipeline);
      return [];
    },
    find: () => query,
  };
};

test('thống kê người dùng nhóm theo giá trị của trường, không theo một hằng chuỗi', async () => {
  const User = statsModel();

  const stats = await createUserRepository({ User }).stats();

  assert.deepEqual(
    User.pipelines.map((pipeline) => pipeline[0].$group._id),
    ['$VaiTro', '$TrangThai', '$TrinhDo'],
  );
  assert.deepEqual(Object.keys(stats), ['totalUsers', 'byRole', 'byStatus', 'byLevel', 'recentUsers', 'activeUsers']);
});

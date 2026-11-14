import assert from 'node:assert/strict';
import test from 'node:test';

import { createReportService } from '../src/modules/reports/report.service.js';

const ID = '507f1f77bcf86cd799439011';
const NOW = new Date('2026-11-14T03:00:00.000Z');

const fakeRepository = (results = {}) => {
  const calls = [];
  const repository = new Proxy({}, {
    get: (_target, name) => async (args) => {
      calls.push([name, args]);
      const result = results[name];
      return typeof result === 'function' ? result(args) : result;
    },
  });
  return { calls, repository };
};

const service = (results) => {
  const fake = fakeRepository(results);
  return { ...fake, service: createReportService({ repository: fake.repository, now: () => NOW }) };
};

test('gửi báo cáo gắn với người đang đăng nhập, luôn bắt đầu ở trạng thái chờ', async () => {
  const { calls, service: reports } = service({ create: (doc) => ({ _id: ID, ...doc }) });

  const report = await reports.create({
    userId: 'u1',
    input: { type: 'bug', title: 'Lỗi', description: 'Không mở được bài', priority: 'high', related_id: null },
  });

  assert.equal(report._id, ID);
  assert.deepEqual(calls, [['create', {
    user_id: 'u1', type: 'bug', title: 'Lỗi', description: 'Không mở được bài', priority: 'high', related_id: null,
  }]]);
});

test('báo cáo của tôi chỉ lấy của chính mình, lọc trạng thái, phân trang', async () => {
  const { calls, service: reports } = service({ findPage: [{ _id: ID }], count: 3 });

  const page = await reports.listMine({ userId: 'u1', page: 2, limit: 2, status: 'pending' });

  assert.deepEqual(page, { items: [{ _id: ID }], total: 3, page: 2, limit: 2 });
  assert.deepEqual(calls[0], ['findPage', { filter: { user_id: 'u1', status: 'pending' }, skip: 2, limit: 2, withUser: false }]);
});

test('quản trị xem mọi báo cáo, lọc theo trạng thái, loại, mức ưu tiên và người gửi', async () => {
  const { calls, service: reports } = service({ findPage: [], count: 0 });

  await reports.listAll({ page: 1, limit: 20, status: 'resolved', type: 'bug', priority: 'high', userId: 'u2' });

  assert.deepEqual(calls[0][1], {
    filter: { status: 'resolved', type: 'bug', priority: 'high', user_id: 'u2' },
    skip: 0,
    limit: 20,
    withUser: true,
  });
});

test('xử lý xong thì ghi thời điểm; mở lại thì xoá thời điểm cũ; phản hồi trống không ghi đè phản hồi cũ', async () => {
  const { calls, service: reports } = service({ updateStatus: { _id: ID } });

  await reports.updateStatus({ id: ID, status: 'resolved', adminResponse: 'Đã sửa' });
  await reports.updateStatus({ id: ID, status: 'in_progress' });

  assert.deepEqual(calls, [
    ['updateStatus', { id: ID, set: { status: 'resolved', resolved_at: NOW, admin_response: 'Đã sửa' } }],
    ['updateStatus', { id: ID, set: { status: 'in_progress', resolved_at: null } }],
  ]);
});

test('báo cáo không có là 404 khi đổi trạng thái hay xoá', async () => {
  await assert.rejects(service({ updateStatus: null }).service.updateStatus({ id: ID, status: 'resolved' }), { status: 404 });
  await assert.rejects(service({ deleteById: null }).service.remove(ID), { status: 404 });
});

test('thống kê đổi thời gian xử lý trung bình sang giờ, làm tròn hai chữ số', async () => {
  const raw = { total: 4, byStatus: [{ _id: 'pending', count: 1 }], byType: [], byPriority: [], recentReports: [] };
  const { service: reports } = service({ stats: { ...raw, avgResolutionMs: 5_400_000 + 18_000 } });

  assert.deepEqual(await reports.stats(), { ...raw, avgResolutionTimeHours: 1.51 });
  assert.equal((await service({ stats: { ...raw, avgResolutionMs: null } }).service.stats()).avgResolutionTimeHours, 0);
});

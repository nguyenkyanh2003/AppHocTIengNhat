import assert from 'node:assert/strict';
import test from 'node:test';

import { createNotificationService } from '../src/modules/notifications/notification.service.js';

const A = 'aaaaaaaaaaaaaaaaaaaaaaaa';
const B = 'bbbbbbbbbbbbbbbbbbbbbbbb';
const ADMIN = 'cccccccccccccccccccccccc';

const same = (left, right) => String(left) === String(right);

/**
 * Repository giả lưu trong bộ nhớ, theo đúng hợp đồng của repository thật:
 * mọi thao tác của người dùng đều lọc theo `recipient`.
 */
const memoryRepository = ({ users = [A, B, ADMIN], learners = [A, B] } = {}) => {
  const rows = [];
  let sequence = 0;
  const owned = (row, { id, recipient }) => same(row._id, id) && same(row.recipient, recipient);
  const matches = (row, filter) =>
    same(row.recipient, filter.recipient) && (filter.is_read === undefined || row.is_read === filter.is_read);
  const insert = (doc) => {
    sequence += 1;
    const row = { _id: `n${sequence}`, data: {}, is_read: false, read_at: null, sender: null, createdAt: new Date(Date.UTC(2026, 10, 1, 0, sequence)), ...doc };
    rows.push(row);
    return { ...row };
  };

  return {
    rows,
    findPage: async ({ filter, skip, limit }) =>
      rows.filter((row) => matches(row, filter)).sort((a, b) => b.createdAt - a.createdAt).slice(skip, skip + limit).map((row) => ({ ...row })),
    count: async (filter) => rows.filter((row) => matches(row, filter)).length,
    markRead: async ({ id, recipient, readAt }) => {
      const row = rows.find((candidate) => owned(candidate, { id, recipient }) && !candidate.is_read);
      if (!row) return null;
      Object.assign(row, { is_read: true, read_at: readAt });
      return { ...row };
    },
    findOwned: async (query) => {
      const row = rows.find((candidate) => owned(candidate, query));
      return row ? { ...row } : null;
    },
    markAllRead: async ({ recipient, readAt }) => {
      const unread = rows.filter((row) => same(row.recipient, recipient) && !row.is_read);
      unread.forEach((row) => Object.assign(row, { is_read: true, read_at: readAt }));
      return unread.length;
    },
    deleteOwned: async (query) => {
      const index = rows.findIndex((row) => owned(row, query));
      if (index === -1) return 0;
      rows.splice(index, 1);
      return 1;
    },
    create: async (doc) => insert(doc),
    insertMany: async (docs) => docs.map(insert).length,
    userExists: async (id) => users.some((user) => same(user, id)),
    findBroadcastRecipientIds: async () => learners,
  };
};

const setup = (options) => {
  let now = new Date('2026-11-04T08:00:00.000Z');
  const repository = memoryRepository(options);
  const service = createNotificationService({ notificationRepository: repository, clock: () => now });
  return { repository, service, advance: (ms) => { now = new Date(now.getTime() + ms); } };
};

const send = (service, recipientId, title = 'Chào') =>
  service.sendToUser({ recipientId, senderId: ADMIN, title, message: `Nội dung ${title}`, type: 'SYSTEM' });

const titlesOf = async (service, userId, status = 'all') =>
  (await service.list({ userId, page: 1, limit: 20, status })).items.map((item) => item.title);

test('mỗi người chỉ thấy thông báo của mình, mới nhất trước, lọc được đã đọc/chưa đọc', async () => {
  const { service } = setup();
  const first = await send(service, A, 'A1');
  await send(service, B, 'B1');
  await send(service, A, 'A2');
  await service.markRead({ id: first.id, userId: A });

  assert.deepEqual(await titlesOf(service, A), ['A2', 'A1']);
  assert.deepEqual(await titlesOf(service, A, 'unread'), ['A2']);
  assert.deepEqual(await titlesOf(service, A, 'read'), ['A1']);
  assert.deepEqual(await titlesOf(service, B), ['B1']);
});

test('danh sách có phân trang theo hợp đồng chung', async () => {
  const { service } = setup();
  for (const title of ['1', '2', '3']) await send(service, A, title);

  const page = await service.list({ userId: A, page: 2, limit: 2, status: 'all' });

  assert.deepEqual({ ...page, items: page.items.map((item) => item.title) }, { items: ['1'], page: 2, limit: 2, total: 3 });
});

test('A không đọc, không xoá được thông báo của B — trả 404 như không tồn tại', async () => {
  const { service, repository } = setup();
  const ofB = await send(service, B, 'B1');

  await assert.rejects(() => service.markRead({ id: ofB.id, userId: A }), { status: 404 });
  await assert.rejects(() => service.remove({ id: ofB.id, userId: A }), { status: 404 });
  await assert.rejects(() => service.remove({ id: 'ffffffffffffffffffffffff', userId: A }), { status: 404 });

  assert.equal(repository.rows.length, 1);
  assert.equal(repository.rows[0].is_read, false);
});

test('thông báo gửi tất cả: A đọc rồi xoá bản của mình, bản của B vẫn nguyên', async () => {
  const { service } = setup();
  assert.equal(await service.broadcast({ senderId: ADMIN, title: 'Bảo trì', message: 'Tối nay', type: 'SYSTEM' }), 2);
  const [ofA] = (await service.list({ userId: A, page: 1, limit: 20, status: 'all' })).items;

  await service.markRead({ id: ofA.id, userId: A });
  await service.remove({ id: ofA.id, userId: A });

  assert.deepEqual(await titlesOf(service, A), []);
  assert.deepEqual(await titlesOf(service, B, 'unread'), ['Bảo trì']);
  assert.equal(await service.countUnread(B), 1);
});

test('bộ đếm chưa đọc đúng sau đọc một, xoá và đọc tất cả', async () => {
  const { service } = setup();
  const first = await send(service, A, '1');
  const second = await send(service, A, '2');
  await send(service, A, '3');
  await send(service, B, 'B');
  assert.equal(await service.countUnread(A), 3);

  await service.markRead({ id: first.id, userId: A });
  assert.equal(await service.countUnread(A), 2);

  await service.remove({ id: second.id, userId: A });
  assert.equal(await service.countUnread(A), 1);

  assert.equal(await service.markAllRead(A), 1);
  assert.equal(await service.countUnread(A), 0);
  assert.equal(await service.countUnread(B), 1, 'đọc tất cả của A không chạm thông báo của B');
});

test('đọc lại không đổi thời điểm đọc đầu tiên', async () => {
  const { service, advance } = setup();
  const created = await send(service, A);

  const firstRead = await service.markRead({ id: created.id, userId: A });
  advance(60_000);
  const secondRead = await service.markRead({ id: created.id, userId: A });

  assert.equal(firstRead.read_at, '2026-11-04T08:00:00.000Z');
  assert.deepEqual(secondRead, firstRead);
});

test('đọc tất cả khi không còn gì chưa đọc vẫn thành công', async () => {
  const { service } = setup();
  assert.equal(await service.markAllRead(A), 0);
});

test('gửi cho người không tồn tại là 404 và không tạo gì', async () => {
  const { service, repository } = setup();

  await assert.rejects(() => send(service, 'dddddddddddddddddddddddd'), { status: 404 });
  assert.equal(repository.rows.length, 0);
});

test('gửi tất cả tới từng người học, ghi người gửi; không có ai thì gửi 0', async () => {
  const { service, repository } = setup();
  await service.broadcast({ senderId: ADMIN, title: 'Kỳ thi', message: 'Tháng 12', type: 'EXAM' });

  assert.deepEqual(repository.rows.map((row) => [row.recipient, row.sender, row.type]), [[A, ADMIN, 'EXAM'], [B, ADMIN, 'EXAM']]);

  const empty = setup({ learners: [] });
  assert.equal(await empty.service.broadcast({ senderId: ADMIN, title: 'X', message: 'Y', type: 'SYSTEM' }), 0);
});

test('thông báo trả về đúng hình dạng hợp đồng', async () => {
  const { service } = setup();
  const created = await send(service, A, 'Chào');

  assert.deepEqual(created, {
    id: 'n1',
    title: 'Chào',
    message: 'Nội dung Chào',
    type: 'SYSTEM',
    data: {},
    is_read: false,
    read_at: null,
    created_at: '2026-11-01T00:01:00.000Z',
  });
});

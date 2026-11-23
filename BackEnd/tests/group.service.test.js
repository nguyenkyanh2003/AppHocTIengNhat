import assert from 'node:assert/strict';
import test from 'node:test';

import { createGroupService } from '../src/modules/study-groups/group.service.js';
import { ApiError } from '../src/shared/http/api-error.js';

const NOW = new Date('2026-11-14T03:00:00.000Z');
const CREATOR = 'u-creator';
const ADMIN = 'u-admin';
const MEMBER = 'u-member';
const STRANGER = 'u-stranger';

/** Nhóm như bản lưu: thành viên chỉ có id và vai trò. */
const GROUP = (overrides = {}) => ({
  _id: 'g1',
  name: 'Ôn N5',
  creator_id: CREATOR,
  is_private: false,
  member_count: 3,
  max_members: 50,
  level: 'N5',
  createdAt: NOW,
  members: [
    { user_id: CREATOR, role: 'admin' },
    { user_id: ADMIN, role: 'admin' },
    { user_id: MEMBER, role: 'member' },
  ],
  ...overrides,
});

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

/** Kho ảnh giả: `replace` gọi `apply` với một đường dẫn mới như kho thật. */
const fakeImages = () => {
  const calls = [];
  return {
    calls,
    async replace({ folder, prefix, previous, apply }) {
      calls.push(['replace', { folder, prefix, previous }]);
      return apply(`/uploads/${folder}/${prefix}-moi.jpg`);
    },
  };
};

const build = (results) => {
  const fake = fakeRepository({ findActive: GROUP(), findActiveDetail: GROUP(), ...results });
  const images = fakeImages();
  return { ...fake, images, service: createGroupService({ repository: fake.repository, now: () => NOW, images }) };
};

const rejectsWith = (status) => (error) => {
  assert.ok(error instanceof ApiError, error);
  assert.equal(error.status, status);
  return true;
};

const writes = (calls) => calls.filter(([name]) => !name.startsWith('find') && name !== 'nameTaken');

test('danh sách nhóm: lọc cấp độ, riêng tư và tìm nguyên văn trong tên hoặc mô tả', async () => {
  const { calls, service } = build({ findPage: [], count: 0 });

  await service.list({ page: 2, limit: 10, level: 'N5', is_private: false, search: 'N5 (sáng)' });

  const pattern = { $regex: 'N5 \\(sáng\\)', $options: 'i' };
  assert.deepEqual(calls[0], ['findPage', {
    filter: { level: 'N5', is_private: false, $or: [{ name: pattern }, { description: pattern }] },
    skip: 10,
    limit: 10,
  }]);
});

test('tạo nhóm: người tạo là quản trị viên đầu tiên; tên đang dùng là 409', async () => {
  const { calls, service } = build({ nameTaken: false, create: { _id: 'g1' } });

  await service.create({ userId: CREATOR, input: { name: 'Ôn N5', level: 'N5' } });

  assert.deepEqual(calls[1], ['create', {
    name: 'Ôn N5',
    level: 'N5',
    creator_id: CREATOR,
    members: [{ user_id: CREATOR, role: 'admin', joined_at: NOW }],
    member_count: 1,
  }]);
  await assert.rejects(build({ nameTaken: true }).service.create({ userId: CREATOR, input: { name: 'Ôn N5' } }), rejectsWith(409));
});

test('chi tiết kèm vai trò của người xem; nhóm riêng tư chỉ thành viên mới xem được', async () => {
  const detail = await build().service.detail({ userId: ADMIN, groupId: 'g1' });
  assert.deepEqual([detail.current_user_role, detail.is_member], ['admin', true]);

  const outsider = await build().service.detail({ userId: STRANGER, groupId: 'g1' });
  assert.deepEqual([outsider.current_user_role, outsider.is_member], [null, false]);

  const secret = build({ findActiveDetail: GROUP({ is_private: true }) });
  await assert.rejects(secret.service.detail({ userId: STRANGER, groupId: 'g1' }), rejectsWith(403));
  await assert.rejects(build({ findActiveDetail: null }).service.detail({ userId: ADMIN, groupId: 'g9' }), rejectsWith(404));
});

test('sửa nhóm chỉ dành cho quản trị viên; giới hạn thành viên không thấp hơn số đang có', async () => {
  const { calls, service } = build({ nameTaken: false, update: true });

  await service.update({ userId: ADMIN, groupId: 'g1', changes: { name: 'Ôn N4', max_members: 10 } });
  assert.deepEqual(writes(calls), [['update', { id: 'g1', set: { name: 'Ôn N4', max_members: 10 } }]]);

  await assert.rejects(build().service.update({ userId: MEMBER, groupId: 'g1', changes: { name: 'x' } }), rejectsWith(403));
  await assert.rejects(build().service.update({ userId: ADMIN, groupId: 'g1', changes: { max_members: 2 } }), rejectsWith(400));
  await assert.rejects(
    build({ nameTaken: true }).service.update({ userId: ADMIN, groupId: 'g1', changes: { name: 'Trùng' } }),
    rejectsWith(409),
  );
});

test('xoá nhóm chỉ người tạo; xoá là ẩn đi', async () => {
  const { calls, service } = build({ deactivate: true });

  await service.remove({ userId: CREATOR, groupId: 'g1' });
  assert.deepEqual(writes(calls), [['deactivate', 'g1']]);
  await assert.rejects(build().service.remove({ userId: ADMIN, groupId: 'g1' }), rejectsWith(403));
});

test('tham gia: nhóm công khai còn chỗ; đã ở trong nhóm, nhóm riêng tư hay đã đủ đều bị chặn', async () => {
  const { calls, service } = build({ addMember: true });

  await service.join({ userId: STRANGER, groupId: 'g1' });
  assert.deepEqual(writes(calls), [['addMember', { id: 'g1', userId: STRANGER, joinedAt: NOW }]]);

  await assert.rejects(build().service.join({ userId: MEMBER, groupId: 'g1' }), rejectsWith(409));
  await assert.rejects(build({ findActive: GROUP({ is_private: true }) }).service.join({ userId: STRANGER, groupId: 'g1' }), rejectsWith(403));
  await assert.rejects(build({ findActive: GROUP({ max_members: 3 }) }).service.join({ userId: STRANGER, groupId: 'g1' }), rejectsWith(409));
  await assert.rejects(build({ addMember: null }).service.join({ userId: STRANGER, groupId: 'g1' }), rejectsWith(409));
});

test('rời nhóm: người tạo không rời được; người ngoài nhóm là 404', async () => {
  const { calls, service } = build({ removeMember: true });

  await service.leave({ userId: MEMBER, groupId: 'g1' });
  assert.deepEqual(writes(calls), [['removeMember', { id: 'g1', userId: MEMBER }]]);

  await assert.rejects(build().service.leave({ userId: CREATOR, groupId: 'g1' }), rejectsWith(400));
  await assert.rejects(build().service.leave({ userId: STRANGER, groupId: 'g1' }), rejectsWith(404));
});

test('mời ra, thăng, hạ chức đúng quyền và đúng đối tượng', async () => {
  const { calls, service } = build({ removeMember: true, setRole: true });

  await service.kick({ userId: ADMIN, groupId: 'g1', memberId: MEMBER });
  await service.promote({ userId: ADMIN, groupId: 'g1', memberId: MEMBER });
  await service.demote({ userId: CREATOR, groupId: 'g1', memberId: ADMIN });
  assert.deepEqual(writes(calls), [
    ['removeMember', { id: 'g1', userId: MEMBER }],
    ['setRole', { id: 'g1', userId: MEMBER, role: 'admin' }],
    ['setRole', { id: 'g1', userId: ADMIN, role: 'member' }],
  ]);

  const { service: groups } = build();
  await assert.rejects(groups.kick({ userId: MEMBER, groupId: 'g1', memberId: ADMIN }), rejectsWith(403));
  await assert.rejects(groups.kick({ userId: ADMIN, groupId: 'g1', memberId: ADMIN }), rejectsWith(400));
  await assert.rejects(groups.kick({ userId: ADMIN, groupId: 'g1', memberId: CREATOR }), rejectsWith(400));
  await assert.rejects(groups.kick({ userId: ADMIN, groupId: 'g1', memberId: STRANGER }), rejectsWith(404));
  await assert.rejects(groups.promote({ userId: ADMIN, groupId: 'g1', memberId: ADMIN }), rejectsWith(409));
  await assert.rejects(groups.demote({ userId: ADMIN, groupId: 'g1', memberId: MEMBER }), rejectsWith(403));
  await assert.rejects(groups.demote({ userId: CREATOR, groupId: 'g1', memberId: CREATOR }), rejectsWith(400));
  await assert.rejects(groups.demote({ userId: CREATOR, groupId: 'g1', memberId: MEMBER }), rejectsWith(409));
});

test('thống kê đếm thành viên, quản trị viên và người hoạt động trong 24 giờ qua', async () => {
  const { calls, service } = build({ countActiveSince: 2 });

  const stats = await service.stats({ userId: MEMBER, groupId: 'g1' });

  assert.deepEqual(calls.at(-1), ['countActiveSince', {
    userIds: [CREATOR, ADMIN, MEMBER],
    since: new Date('2026-11-13T03:00:00.000Z'),
  }]);
  assert.deepEqual(stats, { member_count: 3, admin_count: 2, active_members: 2, level: 'N5', is_private: false, created_at: NOW });
});

const IMAGE = Buffer.from([0xff, 0xd8, 0xff]);

test('đổi ảnh nhóm: quản trị viên lưu ảnh mới, ảnh cũ được thay', async () => {
  const { calls, images, service } = build({ findActive: GROUP({ avatar: '/uploads/group-avatars/cu.png' }), update: { matchedCount: 1 } });

  await service.setAvatar({ userId: ADMIN, groupId: 'g1', image: IMAGE });

  assert.deepEqual(writes(calls), [['update', { id: 'g1', set: { avatar: '/uploads/group-avatars/group-moi.jpg' } }]]);
  assert.deepEqual(images.calls, [['replace', { folder: 'group-avatars', prefix: 'group', previous: '/uploads/group-avatars/cu.png' }]]);
});

test('đổi ảnh nhóm: thành viên thường bị từ chối trước khi đụng tới tệp', async () => {
  const { images, service } = build();

  await assert.rejects(service.setAvatar({ userId: MEMBER, groupId: 'g1', image: IMAGE }), rejectsWith(403));
  assert.deepEqual(images.calls, []);
});

test('đổi ảnh nhóm: nhóm vừa bị xoá thì 404 để kho ảnh dọn tệp vừa lưu', async () => {
  const { service } = build({ update: { matchedCount: 0 } });

  await assert.rejects(service.setAvatar({ userId: ADMIN, groupId: 'g1', image: IMAGE }), rejectsWith(404));
});

import { ApiError } from '../../shared/http/api-error.js';
import { toSkip } from '../../shared/http/pagination.js';
import { withoutUndefined } from '../../shared/utils/object.js';
import { escapeRegExp } from '../../shared/utils/regexp.js';
import { groupRepository } from './group.repository.js';

const DAY_MS = 24 * 60 * 60 * 1000;

/** Tham chiếu có thể đã populate (`{ _id, HoTen... }`) hoặc chỉ là id. */
const idOf = (ref) => String(ref?._id ?? ref);
const memberOf = (group, userId) => group.members.find((member) => idOf(member.user_id) === String(userId));
const isCreator = (group, userId) => idOf(group.creator_id) === String(userId);
const canManage = (group, userId) => isCreator(group, userId) || memberOf(group, userId)?.role === 'admin';

const groupNotFound = () => ApiError.notFound('Nhóm không tồn tại.');
const notAMember = () => ApiError.notFound('Người dùng này không phải là thành viên của nhóm.');
const nameTaken = () => ApiError.conflict('Tên nhóm đã tồn tại.', { code: 'DUPLICATE_GROUP_NAME' });

/** Nhóm kèm vai trò của người đang xem. */
const withViewer = (group, userId) => {
  const member = memberOf(group, userId);
  return { ...group, current_user_role: member?.role ?? null, is_member: Boolean(member) };
};

/**
 * Nhóm học. Người tạo luôn là quản trị viên; quản trị viên sửa nhóm, mời ra và
 * thăng chức; chỉ người tạo mới xoá nhóm và hạ chức quản trị viên.
 */
export const createGroupService = ({ repository = groupRepository, now = () => new Date() } = {}) => {
  const load = async (groupId) => (await repository.findActive(groupId)) ?? Promise.reject(groupNotFound());

  const requireManager = (group, userId) => {
    if (!canManage(group, userId)) throw ApiError.forbidden('Chỉ quản trị viên nhóm mới làm được việc này.');
  };

  const requireCreator = (group, userId, action) => {
    if (!isCreator(group, userId)) throw ApiError.forbidden(`Chỉ người tạo nhóm mới có thể ${action}.`);
  };

  /** Bản đầy đủ sau một lần ghi, để màn chi tiết vẽ lại một lần. */
  const detailed = async (groupId, userId) => withViewer(await repository.findActiveDetail(groupId), userId);

  return {
    /** Từ khoá khớp nguyên văn trong tên hoặc mô tả, không phân biệt hoa thường. */
    async list({ page, limit, level, is_private: isPrivate, search }) {
      const pattern = search && { $regex: escapeRegExp(search), $options: 'i' };
      const filter = withoutUndefined({
        level,
        is_private: isPrivate,
        $or: pattern ? [{ name: pattern }, { description: pattern }] : undefined,
      });
      const [items, total] = await Promise.all([
        repository.findPage({ filter, skip: toSkip({ page, limit }), limit }),
        repository.count(filter),
      ]);
      return { items, total, page, limit };
    },

    listMine(userId) {
      return repository.findMine(userId);
    },

    async create({ userId, input }) {
      if (await repository.nameTaken({ name: input.name })) throw nameTaken();
      const group = await repository.create({
        ...input,
        creator_id: userId,
        members: [{ user_id: userId, role: 'admin', joined_at: now() }],
        member_count: 1,
      });
      return detailed(group._id, userId);
    },

    /** Nhóm riêng tư chỉ thành viên mới xem được. */
    async detail({ userId, groupId }) {
      const group = await repository.findActiveDetail(groupId);
      if (!group) throw groupNotFound();
      if (group.is_private && !memberOf(group, userId)) throw ApiError.forbidden('Nhóm này ở chế độ riêng tư.');
      return withViewer(group, userId);
    },

    async update({ userId, groupId, changes }) {
      const group = await load(groupId);
      requireManager(group, userId);
      if (changes.max_members !== undefined && changes.max_members < group.member_count) {
        throw ApiError.badRequest(`Nhóm đang có ${group.member_count} thành viên, giới hạn không thể thấp hơn.`);
      }
      if (changes.name && (await repository.nameTaken({ name: changes.name, excludeId: groupId }))) throw nameTaken();
      await repository.update({ id: groupId, set: changes });
      return detailed(groupId, userId);
    },

    async remove({ userId, groupId }) {
      requireCreator(await load(groupId), userId, 'xóa nhóm');
      await repository.deactivate(groupId);
    },

    async join({ userId, groupId }) {
      const group = await load(groupId);
      if (memberOf(group, userId)) throw ApiError.conflict('Bạn đã là thành viên của nhóm.');
      if (group.is_private) throw ApiError.forbidden('Nhóm này ở chế độ riêng tư. Vui lòng liên hệ quản trị viên để được mời.');
      if (group.member_count >= group.max_members) throw ApiError.conflict('Nhóm đã đạt số lượng thành viên tối đa.');
      // Điều kiện được xét lại trong chính lệnh ghi: hai người cùng vào chỗ cuối thì một người bị từ chối.
      if (!(await repository.addMember({ id: groupId, userId, joinedAt: now() }))) {
        throw ApiError.conflict('Nhóm vừa đủ thành viên. Vui lòng thử nhóm khác.');
      }
      return detailed(groupId, userId);
    },

    async leave({ userId, groupId }) {
      const group = await load(groupId);
      if (isCreator(group, userId)) {
        throw ApiError.badRequest('Người tạo nhóm không thể rời nhóm. Bạn chỉ có thể xóa nhóm.');
      }
      if (!memberOf(group, userId)) throw notAMember();
      await repository.removeMember({ id: groupId, userId });
    },

    async kick({ userId, groupId, memberId }) {
      const group = await load(groupId);
      requireManager(group, userId);
      if (String(memberId) === String(userId)) throw ApiError.badRequest('Bạn không thể tự mời chính mình ra khỏi nhóm.');
      if (isCreator(group, memberId)) throw ApiError.badRequest('Không thể mời người tạo nhóm ra khỏi nhóm.');
      if (!memberOf(group, memberId)) throw notAMember();
      await repository.removeMember({ id: groupId, userId: memberId });
      return detailed(groupId, userId);
    },

    async promote({ userId, groupId, memberId }) {
      const group = await load(groupId);
      requireManager(group, userId);
      const member = memberOf(group, memberId);
      if (!member) throw notAMember();
      if (member.role === 'admin') throw ApiError.conflict('Người dùng đã là quản trị viên.');
      await repository.setRole({ id: groupId, userId: memberId, role: 'admin' });
      return detailed(groupId, userId);
    },

    async demote({ userId, groupId, memberId }) {
      const group = await load(groupId);
      requireCreator(group, userId, 'hạ chức quản trị viên');
      if (isCreator(group, memberId)) throw ApiError.badRequest('Không thể hạ chức người tạo nhóm.');
      const member = memberOf(group, memberId);
      if (!member) throw notAMember();
      if (member.role === 'member') throw ApiError.conflict('Người dùng đã là thành viên thường.');
      await repository.setRole({ id: groupId, userId: memberId, role: 'member' });
      return detailed(groupId, userId);
    },

    /** "Hoạt động" là đăng nhập trong 24 giờ qua — không phụ thuộc múi giờ máy chủ. */
    async stats({ userId, groupId }) {
      const group = await load(groupId);
      if (group.is_private && !memberOf(group, userId)) throw ApiError.forbidden('Nhóm này ở chế độ riêng tư.');
      const activeMembers = await repository.countActiveSince({
        userIds: group.members.map((member) => member.user_id),
        since: new Date(now().getTime() - DAY_MS),
      });
      return {
        member_count: group.member_count,
        admin_count: group.members.filter((member) => member.role === 'admin').length,
        active_members: activeMembers,
        level: group.level,
        is_private: group.is_private,
        created_at: group.createdAt,
      };
    },

    async setAvatar({ userId, groupId, avatar }) {
      requireManager(await load(groupId), userId);
      await repository.update({ id: groupId, set: { avatar } });
      return detailed(groupId, userId);
    },
  };
};

export const groupService = createGroupService();

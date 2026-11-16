import StudyGroup from '../../../model/StudyGroup.js';
import User from '../../../model/User.js';

/** Thông tin người dùng hiện trên nhóm (tên field tiếng Việt của model `User`). */
const USER_FIELDS = 'HoTen TenDangNhap Email AnhDaiDien';
const NEWEST_FIRST = { createdAt: -1, _id: -1 };
const ACTIVE = { is_active: true };

/**
 * Mọi truy vấn Mongoose của nhóm học. Thành viên là mảng con: thêm, bớt, đổi
 * vai trò bằng lệnh nguyên tử, `member_count` đổi cùng lệnh nên không lệch.
 */
export const createGroupRepository = ({ StudyGroup: groupModel = StudyGroup, User: userModel = User } = {}) => ({
  findPage({ filter, skip, limit }) {
    return groupModel
      .find({ ...filter, ...ACTIVE })
      .select('-members')
      .populate('creator_id', USER_FIELDS)
      .sort(NEWEST_FIRST)
      .skip(skip)
      .limit(limit)
      .lean();
  },

  count(filter) {
    return groupModel.countDocuments({ ...filter, ...ACTIVE });
  },

  findMine(userId) {
    return groupModel
      .find({ 'members.user_id': userId, ...ACTIVE })
      .select('-members')
      .populate('creator_id', USER_FIELDS)
      .sort(NEWEST_FIRST)
      .lean();
  },

  /** Thành viên chỉ có id và vai trò: đủ để xét quyền. */
  findActive(id) {
    return groupModel.findOne({ _id: id, ...ACTIVE }).lean();
  },

  findActiveDetail(id) {
    return groupModel
      .findOne({ _id: id, ...ACTIVE })
      .populate('creator_id', USER_FIELDS)
      .populate('members.user_id', USER_FIELDS)
      .lean();
  },

  async nameTaken({ name, excludeId }) {
    return Boolean(await groupModel.exists({ name, ...ACTIVE, ...(excludeId && { _id: { $ne: excludeId } }) }));
  },

  async create(doc) {
    return (await groupModel.create(doc)).toObject();
  },

  update({ id, set }) {
    return groupModel.updateOne({ _id: id, ...ACTIVE }, { $set: set }, { runValidators: true });
  },

  /** Ẩn nhóm thay vì xoá hẳn. */
  deactivate(id) {
    return groupModel.updateOne({ _id: id }, { $set: { is_active: false } });
  },

  /** Thêm khi người đó chưa ở trong nhóm và nhóm còn chỗ; `null` khi không thoả. */
  addMember({ id, userId, joinedAt }) {
    return groupModel
      .findOneAndUpdate(
        { _id: id, ...ACTIVE, 'members.user_id': { $ne: userId }, $expr: { $lt: ['$member_count', '$max_members'] } },
        { $push: { members: { user_id: userId, role: 'member', joined_at: joinedAt } }, $inc: { member_count: 1 } },
      )
      .lean();
  },

  removeMember({ id, userId }) {
    return groupModel
      .findOneAndUpdate(
        { _id: id, 'members.user_id': userId },
        { $pull: { members: { user_id: userId } }, $inc: { member_count: -1 } },
      )
      .lean();
  },

  setRole({ id, userId, role }) {
    return groupModel.updateOne({ _id: id, 'members.user_id': userId }, { $set: { 'members.$.role': role } });
  },

  countActiveSince({ userIds, since }) {
    return userModel.countDocuments({ _id: { $in: userIds }, LanDangNhapCuoi: { $gte: since } });
  },
});

export const groupRepository = createGroupRepository();

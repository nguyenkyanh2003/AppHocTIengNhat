import { ApiError } from '../../shared/http/api-error.js';
import { created, list, ok, paginated } from '../../shared/http/respond.js';

/** Người thao tác luôn lấy từ phiên đăng nhập (`req.user`), không bao giờ từ body. */
export const createGroupController = (service) => {
  const groupKey = (req) => ({ userId: req.user._id, groupId: req.valid.params.groupID });
  const memberKey = (req) => ({ ...groupKey(req), memberId: req.valid.params.userID });

  return {
    async list(req, res) {
      return paginated(res, await service.list(req.valid.query));
    },

    async listMine(req, res) {
      return list(res, await service.listMine(req.user._id));
    },

    async create(req, res) {
      const group = await service.create({ userId: req.user._id, input: req.valid.body });
      return created(res, group, { message: 'Tạo nhóm thành công.' });
    },

    async detail(req, res) {
      return ok(res, await service.detail(groupKey(req)));
    },

    async update(req, res) {
      const group = await service.update({ ...groupKey(req), changes: req.valid.body });
      return ok(res, group, { message: 'Cập nhật thông tin nhóm thành công.' });
    },

    async remove(req, res) {
      await service.remove(groupKey(req));
      return ok(res, { deleted: true }, { message: 'Xóa nhóm thành công.' });
    },

    async join(req, res) {
      return ok(res, await service.join(groupKey(req)), { message: 'Tham gia nhóm thành công.' });
    },

    async leave(req, res) {
      await service.leave(groupKey(req));
      return ok(res, { left: true }, { message: 'Rời nhóm thành công.' });
    },

    async kick(req, res) {
      return ok(res, await service.kick(memberKey(req)), { message: 'Đã mời thành viên ra khỏi nhóm.' });
    },

    async promote(req, res) {
      return ok(res, await service.promote(memberKey(req)), { message: 'Thăng chức thành viên thành công.' });
    },

    async demote(req, res) {
      return ok(res, await service.demote(memberKey(req)), { message: 'Hạ chức thành viên thành công.' });
    },

    async stats(req, res) {
      return ok(res, await service.stats(groupKey(req)));
    },

    async setAvatar(req, res) {
      if (!req.file) throw ApiError.badRequest('Vui lòng chọn file ảnh.');
      const group = await service.setAvatar({ ...groupKey(req), avatar: `/uploads/group-avatars/${req.file.filename}` });
      return ok(res, group, { message: 'Cập nhật ảnh nhóm thành công.' });
    },
  };
};

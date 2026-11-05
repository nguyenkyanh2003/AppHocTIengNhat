import mongoose from 'mongoose';

import AuthSession from '../../../model/AuthSession.js';

/**
 * Mọi truy vấn Mongoose của phiên đăng nhập. Điều kiện đúng/sai nằm **trong**
 * bộ lọc của lệnh ghi: hai request làm mới cùng một token thì chỉ một request
 * khớp, request kia nhận `null`.
 */
export const createAuthSessionRepository = ({ AuthSession: model = AuthSession } = {}) => {
  /** Token đã nghỉ của một phiên: vừa bị thay, hoặc bị thay trong lúc ân hạn. */
  const retired = (hash) => [{ previous_token_hash: hash }, { superseded_token_hash: hash }];

  const revokeWhere = (filter, { reason, at }) =>
    model.updateMany({ ...filter, revoked_at: null }, { $set: { revoked_at: at, revoked_reason: reason } });

  return {
    async create({ userId, tokenHash, expiresAt }) {
      const session = await model.create({ user: userId, refresh_token_hash: tokenHash, expires_at: expiresAt });
      return session.toObject();
    },

    /** Middleware gọi ở mọi request: chỉ lấy trường cần để quyết định còn dùng được không. */
    findById(id) {
      if (!mongoose.isValidObjectId(id)) return null;
      return model.findById(id).select('user expires_at revoked_at').lean();
    },

    findByTokenHash(hash) {
      return model.findOne({ refresh_token_hash: hash }).lean();
    },

    findByRetiredHash(hash) {
      return model.findOne({ $or: retired(hash) }).lean();
    },

    /** Thay refresh token, chỉ khi token hiện tại vẫn là [fromHash] và phiên chưa thu hồi. */
    rotate({ id, fromHash, toHash, previousHash, previousRetiredAt, supersededHash, expiresAt, at }) {
      return model
        .findOneAndUpdate(
          { _id: id, refresh_token_hash: fromHash, revoked_at: null },
          {
            $set: {
              refresh_token_hash: toHash,
              previous_token_hash: previousHash,
              previous_retired_at: previousRetiredAt,
              superseded_token_hash: supersededHash,
              expires_at: expiresAt,
              last_used_at: at,
            },
            $inc: { rotation: 1 },
          },
          { new: true },
        )
        .lean();
    },

    revoke({ id, ...change }) {
      if (!mongoose.isValidObjectId(id)) return null;
      return revokeWhere({ _id: id }, change);
    },

    /** Đóng phiên bằng bất kỳ refresh token nào của nó: client có thể đã mất phản hồi làm mới. */
    revokeByTokenHash({ hash, ...change }) {
      return revokeWhere({ $or: [{ refresh_token_hash: hash }, ...retired(hash)] }, change);
    },

    revokeAllForUser({ userId, ...change }) {
      return revokeWhere({ user: userId }, change);
    },
  };
};

export const authSessionRepository = createAuthSessionRepository();

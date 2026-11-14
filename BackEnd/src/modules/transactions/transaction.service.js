import { isDuplicateKeyError } from '../../shared/db/duplicate-key.js';
import { ApiError } from '../../shared/http/api-error.js';
import { toSkip } from '../../shared/http/pagination.js';
import { withoutUndefined } from '../../shared/utils/object.js';
import { transactionRepository } from './transaction.repository.js';

/** Khoảng ngày theo `createdAt`; không truyền đầu nào thì không lọc theo ngày. */
const createdBetween = (startDate, endDate) =>
  startDate || endDate ? withoutUndefined({ $gte: startDate, $lte: endDate }) : undefined;

/**
 * Bản đồ án chưa nối cổng thanh toán: người dùng chỉ gửi yêu cầu, quản trị viên
 * đối soát rồi đổi trạng thái bằng tay.
 */
export const createTransactionService = ({ repository }) => ({
  async create({ userId, input }) {
    try {
      return await repository.create({ ...input, user: userId, status: 'pending' });
    } catch (error) {
      if (isDuplicateKeyError(error)) {
        throw ApiError.conflict('Mã thanh toán này đã gắn với một giao dịch khác.', { code: 'DUPLICATE_PAYMENT_REF' });
      }
      throw error;
    }
  },

  async listAll({ page, limit, status, type, userId, startDate, endDate }) {
    const filter = withoutUndefined({ status, type, user: userId, createdAt: createdBetween(startDate, endDate) });
    const [items, total] = await Promise.all([
      repository.findPage({ filter, skip: toSkip({ page, limit }), limit }),
      repository.count(filter),
    ]);
    return { items, total, page, limit };
  },

  async updateStatus({ id, status, notes }) {
    const transaction = await repository.updateStatus({ id, set: withoutUndefined({ status, notes }) });
    if (!transaction) throw ApiError.notFound('Không tìm thấy giao dịch.');
    return transaction;
  },
});

export const transactionService = createTransactionService({ repository: transactionRepository });

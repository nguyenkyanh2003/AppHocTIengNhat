import { ApiError } from '../../shared/http/api-error.js';
import { toSkip } from '../../shared/http/pagination.js';
import { withoutUndefined } from '../../shared/utils/object.js';
import { reportRepository } from './report.repository.js';

const HOUR_MS = 60 * 60 * 1000;
const notFound = () => ApiError.notFound('Không tìm thấy báo cáo.');

export const createReportService = ({ repository, now = () => new Date() }) => {
  const page = async ({ filter, page: number, limit, withUser }) => {
    const [items, total] = await Promise.all([
      repository.findPage({ filter, skip: toSkip({ page: number, limit }), limit, withUser }),
      repository.count(filter),
    ]);
    return { items, total, page: number, limit };
  };

  return {
    /** Báo cáo luôn của người đang đăng nhập và bắt đầu ở trạng thái chờ (mặc định của model). */
    create({ userId, input }) {
      return repository.create({ user_id: userId, ...input });
    },

    listMine({ userId, page: number, limit, status }) {
      return page({ filter: withoutUndefined({ user_id: userId, status }), page: number, limit, withUser: false });
    },

    listAll({ page: number, limit, status, type, priority, userId }) {
      return page({ filter: withoutUndefined({ status, type, priority, user_id: userId }), page: number, limit, withUser: true });
    },

    /**
     * Xử lý xong thì ghi thời điểm; đổi sang trạng thái khác (mở lại) thì xoá
     * thời điểm cũ, để thời gian xử lý trung bình không tính một lần xong đã bị huỷ.
     */
    async updateStatus({ id, status, adminResponse }) {
      const set = {
        status,
        resolved_at: status === 'resolved' ? now() : null,
        ...(adminResponse !== undefined && { admin_response: adminResponse }),
      };
      const report = await repository.updateStatus({ id, set });
      if (!report) throw notFound();
      return report;
    },

    async remove(id) {
      const report = await repository.deleteById(id);
      if (!report) throw notFound();
    },

    async stats() {
      const { avgResolutionMs, ...counts } = await repository.stats();
      const hours = avgResolutionMs ? Math.round((avgResolutionMs / HOUR_MS) * 100) / 100 : 0;
      return { ...counts, avgResolutionTimeHours: hours };
    },
  };
};

export const reportService = createReportService({ repository: reportRepository });

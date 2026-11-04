import { list } from '../../shared/http/respond.js';

/**
 * Controller chỉ map HTTP <-> service. `total` là số kết quả trả về (mỗi nhóm
 * đã bị giới hạn), không phải tổng số bản ghi khớp trong cơ sở dữ liệu.
 */
export const createSearchController = (service) => ({
  async search(req, res) {
    const { q, limit_per_type: limitPerType } = req.valid.query;
    const results = await service.search({ q, limitPerType });
    return list(res, results);
  },
});

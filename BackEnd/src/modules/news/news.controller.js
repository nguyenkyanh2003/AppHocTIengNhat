import { list, ok, paginated } from '../../shared/http/respond.js';

export const createNewsController = (service) => ({
  async list(req, res) {
    return paginated(res, await service.list(req.valid.query));
  },

  async detail(req, res) {
    return ok(res, await service.getDetail(req.valid.params.id));
  },

  async related(req, res) {
    return list(res, await service.related({ id: req.valid.params.id, limit: req.valid.query.limit }));
  },
});

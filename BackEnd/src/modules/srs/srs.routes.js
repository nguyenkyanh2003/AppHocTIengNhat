import express from 'express';

import { authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createSrsController } from './srs.controller.js';
import { srsService } from './srs.service.js';
import * as schema from './srs.schema.js';

/**
 * Sáu route SRS (spec SRS §3.3). Định danh trong path là `Vocabulary._id`,
 * không phải `SRSProgress._id`.
 *
 * Bốn route admin và `/my-cards` của module cũ đã bị bỏ: chưa có consumer và
 * ngoài phạm vi demo. Mở lại cần nghiệp vụ và test quyền riêng.
 */
export const createSrsRoutes = ({ service = srsService, authenticate = authenticateUser } = {}) => {
  const controller = createSrsController(service);
  const router = express.Router();

  router.get('/due', authenticate, validate({ query: schema.dueQuery }), asyncHandler(controller.getDue));
  router.get(
    '/due/count',
    authenticate,
    validate({ query: schema.itemTypeQuery }),
    asyncHandler(controller.getDueCount),
  );
  router.get('/stats', authenticate, validate({ query: schema.itemTypeQuery }), asyncHandler(controller.getStats));
  router.post('/review', authenticate, validate({ body: schema.reviewBody }), asyncHandler(controller.postReview));
  router.post(
    '/items/:itemId/reset',
    authenticate,
    validate({ params: schema.itemParams, body: schema.resetBody }),
    asyncHandler(controller.postReset),
  );
  router.delete(
    '/items/:itemId',
    authenticate,
    validate({ params: schema.itemParams, query: schema.itemTypeQuery }),
    asyncHandler(controller.deleteItem),
  );

  return router;
};

export default createSrsRoutes();

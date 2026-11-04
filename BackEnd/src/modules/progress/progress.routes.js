import express from 'express';

import { authenticateAdmin, authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createProgressController } from './progress.controller.js';
import * as schema from './progress.schema.js';
import { progressService } from './progress.service.js';

/** Nhận dependency qua tham số để test dựng router với service và auth giả. */
export const createProgressRoutes = ({
  service = progressService,
  authenticate = authenticateUser,
  authenticateAsAdmin = authenticateAdmin,
} = {}) => {
  const controller = createProgressController(service);
  const router = express.Router();

  router.get('/', authenticate, asyncHandler(controller.list));
  router.get(
    '/admin/analytics',
    authenticateAsAdmin,
    validate({ query: schema.analyticsQuery }),
    asyncHandler(controller.adminAnalytics),
  );
  router.get('/dashboard/stats', authenticate, asyncHandler(controller.stats));
  router.get(
    '/dashboard/timeline',
    authenticate,
    validate({ query: schema.timelineQuery }),
    asyncHandler(controller.timeline),
  );
  router.get(
    '/dashboard/heatmap',
    authenticate,
    validate({ query: schema.heatmapQuery }),
    asyncHandler(controller.heatmap),
  );
  router.get('/dashboard/breakdown', authenticate, asyncHandler(controller.breakdown));

  return router;
};

export default createProgressRoutes();

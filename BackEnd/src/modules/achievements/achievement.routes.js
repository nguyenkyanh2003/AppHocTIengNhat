import express from 'express';

import { authenticateAdmin, authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createAchievementController } from './achievement.controller.js';
import { achievementService } from './achievement.service.js';
import * as schema from './achievement.schema.js';

/** Nhận dependency qua tham số để test dựng router với service và auth giả. */
export const createAchievementRoutes = ({
  service = achievementService,
  authenticate = authenticateUser,
  authenticateAsAdmin = authenticateAdmin,
} = {}) => {
  const controller = createAchievementController(service);
  const router = express.Router();

  router.get('/all', authenticate, asyncHandler(controller.getAll));
  router.get('/my-achievements', authenticate, asyncHandler(controller.getMyAchievements));
  router.get(
    '/category/:category',
    authenticate,
    validate({ params: schema.categoryParams }),
    asyncHandler(controller.getByCategory),
  );
  router.get('/admin/all', authenticateAsAdmin, asyncHandler(controller.getAdminAll));
  router.post('/admin', authenticateAsAdmin, validate({ body: schema.createBody }), asyncHandler(controller.postCreate));
  router.put(
    '/admin/:id',
    authenticateAsAdmin,
    validate({ params: schema.idParams, body: schema.updateBody }),
    asyncHandler(controller.putAdminById),
  );
  router.delete(
    '/admin/:id',
    authenticateAsAdmin,
    validate({ params: schema.idParams }),
    asyncHandler(controller.deleteAdminById),
  );
  router.get('/stats', authenticate, asyncHandler(controller.getStats));

  return router;
};

export default createAchievementRoutes();

import express from 'express';

import { authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createGoalController } from './goal.controller.js';
import * as schema from './goal.schema.js';
import { goalService } from './goal.service.js';

/** Nhận dependency qua tham số để test dựng router với service và auth giả. */
export const createGoalRoutes = ({ service = goalService, authenticate = authenticateUser } = {}) => {
  const controller = createGoalController(service);
  const byId = validate({ params: schema.idParams });
  const router = express.Router();

  router.get('/', authenticate, asyncHandler(controller.list));
  router.post('/', authenticate, validate({ body: schema.createBody }), asyncHandler(controller.create));
  router.patch('/:id', authenticate, byId, validate({ body: schema.updateBody }), asyncHandler(controller.update));
  router.delete('/:id', authenticate, byId, asyncHandler(controller.remove));

  return router;
};

export default createGoalRoutes();

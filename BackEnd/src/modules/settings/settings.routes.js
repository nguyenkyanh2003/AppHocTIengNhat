import express from 'express';

import { authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createSettingsController } from './settings.controller.js';
import * as schema from './settings.schema.js';
import { settingsService } from './settings.service.js';

/** Nhận dependency qua tham số để test dựng router với service và auth giả. */
export const createSettingsRoutes = ({ service = settingsService, authenticate = authenticateUser } = {}) => {
  const controller = createSettingsController(service);
  const router = express.Router();

  router.get('/', authenticate, asyncHandler(controller.get));
  router.post('/', authenticate, validate({ body: schema.settingsBody }), asyncHandler(controller.save));

  return router;
};

export default createSettingsRoutes();

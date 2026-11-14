import express from 'express';

import { authenticateAdmin, authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createReportController } from './report.controller.js';
import * as schema from './report.schema.js';
import { reportService } from './report.service.js';

/** Nhận dependency qua tham số để test dựng router với service và auth giả. */
export const createReportRoutes = ({
  service = reportService,
  authenticate = authenticateUser,
  authorizeAdmin = authenticateAdmin,
} = {}) => {
  const controller = createReportController(service);
  const byId = validate({ params: schema.idParams });
  const router = express.Router();

  router.post('/create', authenticate, validate({ body: schema.createBody }), asyncHandler(controller.create));
  router.get('/my-reports', authenticate, validate({ query: schema.mineQuery }), asyncHandler(controller.listMine));
  router.get('/admin/all', authorizeAdmin, validate({ query: schema.adminQuery }), asyncHandler(controller.listAll));
  router.put('/admin/:id/status', authorizeAdmin, byId, validate({ body: schema.statusBody }), asyncHandler(controller.updateStatus));
  router.delete('/admin/:id', authorizeAdmin, byId, asyncHandler(controller.remove));
  router.get('/admin/stats', authorizeAdmin, asyncHandler(controller.stats));

  return router;
};

export default createReportRoutes();

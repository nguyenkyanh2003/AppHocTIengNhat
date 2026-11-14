import express from 'express';

import { authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createNotebookController } from './notebook.controller.js';
import * as schema from './notebook.schema.js';
import { notebookService } from './notebook.service.js';

/**
 * Nhận dependency qua tham số để test dựng router với service và auth giả.
 * Xác thực gắn theo từng route (không `router.use`) để path không tồn tại vẫn là 404.
 */
export const createNotebookRoutes = ({ service = notebookService, authenticate = authenticateUser } = {}) => {
  const controller = createNotebookController(service);
  const byId = validate({ params: schema.idParams });
  const router = express.Router();

  router.get('/', authenticate, validate({ query: schema.listQuery }), asyncHandler(controller.list));
  router.post('/', authenticate, validate({ body: schema.createBody }), asyncHandler(controller.create));
  router.get('/:id', authenticate, byId, asyncHandler(controller.detail));
  router.put('/:id', authenticate, byId, validate({ body: schema.updateBody }), asyncHandler(controller.update));
  router.delete('/:id', authenticate, byId, asyncHandler(controller.remove));

  return router;
};

export default createNotebookRoutes();

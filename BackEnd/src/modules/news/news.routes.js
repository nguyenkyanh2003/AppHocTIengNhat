import express from 'express';

import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createNewsController } from './news.controller.js';
import * as schema from './news.schema.js';
import { newsService } from './news.service.js';

/**
 * Tin tức đọc công khai, không cần đăng nhập. Nhận service qua tham số để test
 * dựng router với service giả.
 */
export const createNewsRoutes = ({ service = newsService } = {}) => {
  const controller = createNewsController(service);
  const byId = validate({ params: schema.idParams });
  const router = express.Router();

  router.get('/', validate({ query: schema.listQuery }), asyncHandler(controller.list));
  router.get('/:id', byId, asyncHandler(controller.detail));
  router.get('/:id/related', byId, validate({ query: schema.relatedQuery }), asyncHandler(controller.related));

  return router;
};

export default createNewsRoutes();

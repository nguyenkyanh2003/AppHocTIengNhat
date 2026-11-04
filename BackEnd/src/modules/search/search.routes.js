import express from 'express';

import { authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createSearchController } from './search.controller.js';
import * as schema from './search.schema.js';
import { searchService } from './search.service.js';

/**
 * Nhận dependency qua tham số để test dựng router với service và auth giả.
 * Cần đăng nhập như danh sách từ vựng và Kanji mà kết quả trỏ tới.
 */
export const createSearchRoutes = ({
  service = searchService,
  authenticate = authenticateUser,
} = {}) => {
  const controller = createSearchController(service);
  const router = express.Router();

  router.get('/', authenticate, validate({ query: schema.searchQuery }), asyncHandler(controller.search));

  return router;
};

export default createSearchRoutes();

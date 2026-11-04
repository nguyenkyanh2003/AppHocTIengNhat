import express from 'express';

import { authenticateAdmin, authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createNotificationController } from './notification.controller.js';
import * as schema from './notification.schema.js';
import { notificationService } from './notification.service.js';

/**
 * Nhận dependency qua tham số để test dựng router với service và auth giả.
 * Bảy route giữ nguyên đường dẫn cũ; hai route gửi chỉ dành cho admin.
 */
export const createNotificationRoutes = ({
  service = notificationService,
  authenticate = authenticateUser,
  authorizeAdmin = authenticateAdmin,
} = {}) => {
  const controller = createNotificationController(service);
  const byId = validate({ params: schema.idParams });
  const router = express.Router();

  router.get('/', authenticate, validate({ query: schema.listQuery }), asyncHandler(controller.list));
  router.get('/count/unread', authenticate, asyncHandler(controller.countUnread));
  router.put('/read/:id', authenticate, byId, asyncHandler(controller.markRead));
  router.put('/read-all', authenticate, asyncHandler(controller.markAllRead));
  router.delete('/:id', authenticate, byId, asyncHandler(controller.remove));
  router.post('/', authorizeAdmin, validate({ body: schema.sendBody }), asyncHandler(controller.send));
  router.post('/broadcast/all', authorizeAdmin, validate({ body: schema.broadcastBody }), asyncHandler(controller.broadcast));

  return router;
};

export default createNotificationRoutes();

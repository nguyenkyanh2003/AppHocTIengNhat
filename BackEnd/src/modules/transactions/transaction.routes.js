import express from 'express';

import { authenticateAdmin, authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createTransactionController } from './transaction.controller.js';
import * as schema from './transaction.schema.js';
import { transactionService } from './transaction.service.js';

/** Nhận dependency qua tham số để test dựng router với service và auth giả. */
export const createTransactionRoutes = ({
  service = transactionService,
  authenticate = authenticateUser,
  authorizeAdmin = authenticateAdmin,
} = {}) => {
  const controller = createTransactionController(service);
  const router = express.Router();

  router.post('/create', authenticate, validate({ body: schema.createBody }), asyncHandler(controller.create));
  router.get('/admin/all', authorizeAdmin, validate({ query: schema.adminQuery }), asyncHandler(controller.listAll));
  router.put(
    '/admin/:id/status',
    authorizeAdmin,
    validate({ params: schema.idParams, body: schema.statusBody }),
    asyncHandler(controller.updateStatus),
  );

  return router;
};

export default createTransactionRoutes();

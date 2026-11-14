import express from 'express';

import { authenticateAdmin, authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createGrammarController } from './grammar.controller.js';
import * as schema from './grammar.schema.js';
import { grammarService } from './grammar.service.js';

/** Nhận dependency qua tham số để test dựng router với service và auth giả. */
export const createGrammarRoutes = ({
  service = grammarService,
  authenticate = authenticateUser,
  authorizeAdmin = authenticateAdmin,
} = {}) => {
  const controller = createGrammarController(service);
  const byId = validate({ params: schema.idParams });
  const router = express.Router();

  router.get('/', authenticate, validate({ query: schema.listQuery }), asyncHandler(controller.list));
  router.get('/:id', authenticate, byId, asyncHandler(controller.detail));
  router.post('/', authorizeAdmin, validate({ body: schema.createBody }), asyncHandler(controller.create));
  router.put('/:id', authorizeAdmin, byId, validate({ body: schema.updateBody }), asyncHandler(controller.update));
  router.delete('/:id', authorizeAdmin, byId, asyncHandler(controller.remove));

  return router;
};

export default createGrammarRoutes();

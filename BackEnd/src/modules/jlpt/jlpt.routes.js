import express from 'express';

import { authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { jlptSubmissionService } from './jlpt-submission.service.js';
import { createJlptController } from './jlpt.controller.js';
import * as schema from './jlpt.schema.js';
import { jlptService } from './jlpt.service.js';

/** Nhận dependency qua tham số để test dựng router với service và auth giả. */
export const createJlptRoutes = ({
  service = jlptService,
  submission = jlptSubmissionService,
  authenticate = authenticateUser,
} = {}) => {
  const controller = createJlptController({ service, submission });
  const byId = validate({ params: schema.idParams });
  const router = express.Router();

  router.get('/', authenticate, validate({ query: schema.listQuery }), asyncHandler(controller.list));
  router.get('/practice', authenticate, validate({ query: schema.practiceQuery }), asyncHandler(controller.practice));
  router.get('/:id/solutions', authenticate, byId, asyncHandler(controller.solutions));
  router.get('/:id', authenticate, byId, asyncHandler(controller.detail));
  router.post('/:id/submit', authenticate, byId, validate({ body: schema.submitBody }), asyncHandler(controller.submit));

  return router;
};

export default createJlptRoutes();

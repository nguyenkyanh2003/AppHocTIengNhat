import express from 'express';

import { authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { exerciseSubmissionService } from './exercise-submission.service.js';
import { createExerciseController } from './exercise.controller.js';
import * as schema from './exercise.schema.js';
import { exerciseService } from './exercise.service.js';

/** Nhận dependency qua tham số để test dựng router với service và auth giả. */
export const createExerciseRoutes = ({
  service = exerciseService,
  submission = exerciseSubmissionService,
  authenticate = authenticateUser,
} = {}) => {
  const controller = createExerciseController({ service, submission });
  const router = express.Router();

  router.get('/level/:level', authenticate, validate({ params: schema.levelParams }), asyncHandler(controller.listByLevel));
  router.get('/lesson/:lessonID', authenticate, validate({ params: schema.lessonParams }), asyncHandler(controller.listByLesson));
  router.post(
    '/submit/:id',
    authenticate,
    validate({ params: schema.idParams, body: schema.submitBody }),
    asyncHandler(controller.submit),
  );
  router.get('/history', authenticate, validate({ query: schema.historyQuery }), asyncHandler(controller.history));
  router.get('/result/:resultId', authenticate, validate({ params: schema.resultParams }), asyncHandler(controller.result));
  router.get('/:id', authenticate, validate({ params: schema.idParams }), asyncHandler(controller.detail));

  return router;
};

export default createExerciseRoutes();

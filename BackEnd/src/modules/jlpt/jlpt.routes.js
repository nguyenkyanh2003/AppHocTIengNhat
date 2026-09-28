import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import * as schema from './jlpt.schema.js';
import express from 'express';
import { authenticateUser } from '../../middleware/auth.middleware.js';
import * as controller from './jlpt.controller.js';

const router = express.Router();

router.get('/', authenticateUser, controller.listExams);
router.get('/practice', authenticateUser, controller.getPracticeQuestions);
router.get('/:id/solutions', authenticateUser, controller.getSolutions);
router.get('/:id', authenticateUser, controller.getExam);
router.post(
    '/:id/submit',
    authenticateUser,
    validate({ params: schema.submitParams, body: schema.submitBody }),
    asyncHandler(controller.submitExamHandler),
);

export default router;

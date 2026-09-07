import express from 'express';
import { authenticateUser } from '../../middleware/auth.middleware.js';
import * as controller from './lesson-progress.controller.js';

const router = express.Router();

router.use(authenticateUser);

router.get('/lesson/:lessonId', controller.getLessonByLessonId);
router.get('/lessons', controller.getLessons);
router.post('/lesson/:lessonId/start', controller.postLessonByLessonIdStart);
router.post('/lesson/:lessonId/update', controller.postLessonByLessonIdUpdate);
router.post('/lesson/:lessonId/complete', controller.postLessonByLessonIdComplete);
router.post('/lesson/:lessonId/reset', controller.postLessonByLessonIdReset);
router.get('/stats', controller.getStats);
router.get('/level/:level', controller.getLevelByLevel);

export default router;

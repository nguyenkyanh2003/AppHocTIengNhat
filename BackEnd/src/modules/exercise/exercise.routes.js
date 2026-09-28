import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import * as schema from './exercise.schema.js';
import express from 'express';
import { authenticateUser } from '../../middleware/auth.middleware.js';
import * as controller from './exercise.controller.js';

const router = express.Router();

router.get("/level/:level", authenticateUser, controller.listByLevel);
router.get("/type/:type", authenticateUser, controller.listByType);
router.get("/lesson/:lessonID", authenticateUser, controller.listByLesson);
router.post(
    "/submit/:id",
    authenticateUser,
    validate({ params: schema.submitParams, body: schema.submitBody }),
    asyncHandler(controller.submitExercise),
);
router.get("/history", authenticateUser, controller.getMyHistory);
router.get("/result/:resultId", authenticateUser, controller.getMyResult);
router.get("/:id", authenticateUser, controller.getExercise);

export default router;

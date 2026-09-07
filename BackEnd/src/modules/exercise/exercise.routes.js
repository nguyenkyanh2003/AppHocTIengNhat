import express from 'express';
import { authenticateAdmin, authenticateUser } from '../../middleware/auth.middleware.js';
import * as controller from './exercise.controller.js';

const router = express.Router();

router.get("/level/:level", authenticateUser, controller.listByLevel);
router.get("/type/:type", authenticateUser, controller.listByType);
router.get("/lesson/:lessonID", authenticateUser, controller.listByLesson);
router.post("/submit/:id", authenticateUser, controller.submitExercise);
router.get("/check-answers/:id", authenticateUser, controller.checkAnswers);
router.get("/history", authenticateUser, controller.getMyHistory);
router.get("/result/:resultId", authenticateUser, controller.getMyResult);
router.get("/my-results/:id", authenticateUser, controller.getMyResultsForExercise);
router.get("/:id", authenticateUser, controller.getExercise);
router.post("/lesson/:lessonID", authenticateAdmin, controller.createExercise);
router.put("/:id", authenticateAdmin, controller.updateExercise);
router.delete("/:id", authenticateAdmin, controller.deleteExercise);
router.post("/questions/:id", authenticateAdmin, controller.addQuestion);
router.put("/questions/:id", authenticateAdmin, controller.updateQuestion);
router.delete("/questions/:id", authenticateAdmin, controller.deleteQuestion);
router.get("/admin/result/:id", authenticateAdmin, controller.getAdminResult);
router.post("/upload/:id", authenticateAdmin, controller.upload.single('file'), controller.uploadQuestions);

export default router;

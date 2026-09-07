import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './vocabulary.controller.js';

const router = express.Router();

router.get("/", authenticateUser, controller.getRoot);
router.get("/search", authenticateUser, controller.getSearch);
router.get("/situations", authenticateUser, controller.getSituations);
router.get("/lesson/:lessonId", authenticateUser, controller.getLessonByLessonId);
router.get("/level/:levelEnum", authenticateUser, controller.getLevelByLevelEnum);
router.get("/situation/search", authenticateUser, controller.getSituationSearch);
router.get("/random/practice", authenticateUser, controller.getRandomPractice);
router.get("/admin/stats", authenticateAdmin, controller.getAdminStats);
router.get("/admin/export", authenticateAdmin, controller.getAdminExport);
router.get("/:id", authenticateUser, controller.getById);
router.post("/learn/:id", authenticateUser, controller.postLearnById);
router.post("/", authenticateAdmin, controller.postRoot);
router.put("/:id", authenticateAdmin, controller.putById);
router.delete("/:id", authenticateAdmin, controller.deleteById);
router.delete("/", authenticateAdmin, controller.deleteRoot);
router.post("/upload", authenticateAdmin, controller.upload.single("fileExcel"), controller.postUpload);
router.post("/:id/mark-learned", authenticateUser, controller.postByIdMarkLearned);
router.delete("/:id/mark-learned", authenticateUser, controller.deleteByIdMarkLearned);

export default router;

import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './kanji.controller.js';

const router = express.Router();

router.get("/", authenticateUser, controller.getRoot);
router.get("/search", authenticateUser, controller.getSearch);
router.get("/level/:level", authenticateUser, controller.getLevelByLevel);
router.get("/lesson/:lessonId", authenticateUser, controller.getLessonByLessonId);
router.get("/:id", authenticateUser, controller.getById);
router.post("/learn/:id", authenticateUser, controller.postLearnById);
router.post("/", authenticateAdmin, controller.postRoot);
router.post("/upload", authenticateAdmin, controller.upload.single('fileExcel'), controller.postUpload);
router.put("/:id", authenticateAdmin, controller.putById);
router.delete("/:id", authenticateAdmin, controller.deleteById);

export default router;

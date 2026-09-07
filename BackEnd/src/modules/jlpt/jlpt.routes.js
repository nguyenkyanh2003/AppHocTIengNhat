import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './jlpt.controller.js';

const router = express.Router();

router.get('/', authenticateUser, controller.listExams);
router.get('/practice', authenticateUser, controller.getPracticeQuestions);
router.get('/:id/solutions', authenticateUser, controller.getSolutions);
router.get('/:id', authenticateUser, controller.getExam);
router.post('/submit/:id', authenticateUser, controller.submitExamHandler);
router.post('/:id/submit', authenticateUser, controller.submitExamHandler);
router.post('/', authenticateAdmin, controller.createExam);
router.put("/publish/:id", authenticateAdmin, controller.setPublishStatus);
router.put("/:id", authenticateAdmin, controller.updateExam);
router.put("/reading/:groupId", authenticateAdmin, controller.updateReadingGroup);
router.put("/listening/:groupId", authenticateAdmin, controller.updateListeningGroup);
router.put("/question/:questionId", authenticateAdmin, controller.updateQuestion);
router.delete("/:id", authenticateAdmin, controller.deleteExam);
router.delete("/question/:questionId/:type", authenticateAdmin, controller.deleteQuestion);
router.post('/importExcel/:id', authenticateAdmin, controller.upload.single('file'), controller.importQuestions);
router.get("/answers/:id", authenticateUser, controller.getAnswers);
router.get("/history/me", authenticateUser, controller.getMyHistory);
router.get("/history/:historyId", authenticateUser, controller.getHistoryDetail);
router.post("/:id/moji-goi", authenticateAdmin, controller.addMojiGoiQuestion);
router.post("/:id/bunpou", authenticateAdmin, controller.addBunpouQuestion);
router.post("/:id/dokkai", authenticateAdmin, controller.addDokkaiGroup);
router.post("/:id/choukai", authenticateAdmin, controller.addChoukaiGroup);
router.delete("/group/:groupId/:type", authenticateAdmin, controller.deleteQuestionGroup);
router.get("/stats/:id", authenticateAdmin, controller.getExamStats);
router.get("/results/:id", authenticateAdmin, controller.getExamResults);
router.get("/admin/all", authenticateAdmin, controller.listAdminExams);

export default router;

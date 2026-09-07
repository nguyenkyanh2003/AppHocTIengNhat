import express from 'express';
import { authenticateAdmin, authenticateUser } from '../../middleware/auth.middleware.js';
import * as controller from './progress.controller.js';
import { getAdminAnalytics } from './analytics.controller.js';

const router = express.Router();

router.get("/", authenticateUser, controller.getMyProgress);
router.post("/lesson/:lessonID", authenticateUser, controller.getLessonProgress);
router.post("/lesson/:lessonID/update", authenticateUser, controller.updateLessonProgress);
router.get("/study-time", authenticateUser, controller.getStudyTime);
router.get("/achievements", authenticateUser, controller.getRecentAchievements);
router.delete("/lesson/:lessonID", authenticateUser, controller.deleteLessonProgress);
router.get("/admin", authenticateAdmin, controller.listAdminProgress);
router.get("/admin/user/:userID", authenticateAdmin, controller.getAdminUserProgress);
router.get("/admin/stats", authenticateAdmin, controller.getAdminStats);
router.get("/admin/analytics", authenticateAdmin, getAdminAnalytics);
router.put("/admin/:id", authenticateAdmin, controller.updateAdminProgress);
router.delete("/admin/:id", authenticateAdmin, controller.deleteAdminProgress);
router.delete("/admin/bulk/delete", authenticateAdmin, controller.deleteManyProgress);
router.delete("/admin/user/:userID/clear", authenticateAdmin, controller.clearUserProgress);
router.get('/dashboard/stats', authenticateUser, controller.getDashboardStats);
router.get('/dashboard/timeline', authenticateUser, controller.getDashboardTimeline);
router.get('/dashboard/heatmap', authenticateUser, controller.getDashboardHeatmap);
router.get('/dashboard/breakdown', authenticateUser, controller.getDashboardBreakdown);

export default router;

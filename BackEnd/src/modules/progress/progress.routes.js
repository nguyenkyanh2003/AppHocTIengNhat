import express from 'express';
import { authenticateAdmin, authenticateUser } from '../../middleware/auth.middleware.js';
import * as controller from './progress.controller.js';
import { getAdminAnalytics } from './analytics.controller.js';

const router = express.Router();

router.get("/", authenticateUser, controller.getMyProgress);
router.get("/admin/analytics", authenticateAdmin, getAdminAnalytics);
router.get('/dashboard/stats', authenticateUser, controller.getDashboardStats);
router.get('/dashboard/timeline', authenticateUser, controller.getDashboardTimeline);
router.get('/dashboard/heatmap', authenticateUser, controller.getDashboardHeatmap);
router.get('/dashboard/breakdown', authenticateUser, controller.getDashboardBreakdown);

export default router;

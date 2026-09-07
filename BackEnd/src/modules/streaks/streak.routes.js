import express from 'express';
import { authenticateUser } from '../../middleware/auth.middleware.js';
import * as controller from './streak.controller.js';

const router = express.Router();

router.get('/my-streak', authenticateUser, controller.getMyStreak);
router.post('/add-xp', authenticateUser, controller.postAddXp);
router.get('/xp-history', authenticateUser, controller.getXpHistory);
router.get('/leaderboard', authenticateUser, controller.getLeaderboard);
router.post('/test/reset-yesterday', authenticateUser, controller.postTestResetYesterday);
router.get('/test/debug', authenticateUser, controller.getTestDebug);

export default router;

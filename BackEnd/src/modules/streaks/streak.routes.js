import express from 'express';

import { authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createStreakController } from './streak.controller.js';
import { streakReadService } from './streak-read.service.js';
import * as schema from './streak.schema.js';

/**
 * Route streak: chỉ đọc. Nhận dependency qua tham số để test dựng router với
 * service giả và auth giả, không cần MongoDB hay JWT.
 */
export const createStreakRoutes = ({
  readService = streakReadService,
  authenticate = authenticateUser,
} = {}) => {
  const controller = createStreakController(readService);
  const router = express.Router();

  router.get('/my-streak', authenticate, asyncHandler(controller.getMyStreak));
  router.get(
    '/xp-history',
    authenticate,
    validate({ query: schema.xpHistoryQuery }),
    asyncHandler(controller.getXpHistory),
  );
  router.get('/days', authenticate, validate({ query: schema.daysQuery }), asyncHandler(controller.getDays));
  router.get(
    '/leaderboard',
    authenticate,
    validate({ query: schema.leaderboardQuery }),
    asyncHandler(controller.getLeaderboard),
  );

  return router;
};

export default createStreakRoutes();

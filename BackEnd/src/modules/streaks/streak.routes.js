import express from 'express';

import { authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createStreakController } from './streak.controller.js';
import { streakReadService } from './streak-read.service.js';
import { streakSettingsService } from './streak-settings.service.js';
import * as schema from './streak.schema.js';

/**
 * Route streak: đọc tóm tắt/lịch sử/lịch/bảng xếp hạng, và cài đặt mục tiêu —
 * không route nào ghi XP hay ngày học. Nhận dependency qua tham số để test dựng
 * router với service giả và auth giả, không cần MongoDB hay JWT.
 */
export const createStreakRoutes = ({
  readService = streakReadService,
  settingsService = streakSettingsService,
  authenticate = authenticateUser,
} = {}) => {
  const controller = createStreakController(readService, settingsService);
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
  router.get('/settings', authenticate, asyncHandler(controller.getSettings));
  router.put(
    '/settings',
    authenticate,
    validate({ body: schema.settingsBody }),
    asyncHandler(controller.putSettings),
  );

  return router;
};

export default createStreakRoutes();

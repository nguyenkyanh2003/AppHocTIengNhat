import express from 'express';
import { authenticateAdmin, authenticateUser } from '../../middleware/auth.middleware.js';
import * as controller from './achievement.controller.js';

const router = express.Router();

router.get('/all', authenticateUser, controller.getAll);
router.get('/my-achievements', authenticateUser, controller.getMyAchievements);
router.get('/category/:category', authenticateUser, controller.getCategoryByCategory);
router.post('/update-progress', authenticateUser, controller.postUpdateProgress);
router.get('/admin/all', authenticateAdmin, controller.getAdminAll);
router.post('/admin', authenticateAdmin, controller.postCreate);
router.put('/admin/:id', authenticateAdmin, controller.putAdminById);
router.delete('/admin/:id', authenticateAdmin, controller.deleteAdminById);
router.get('/stats', authenticateUser, controller.getStats);

export default router;

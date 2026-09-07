import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './notification.controller.js';

const router = express.Router();

router.get('/', authenticateUser, controller.getRoot);
router.get('/:id', authenticateUser, controller.getById);
router.get('/count/unread', authenticateUser, controller.getCountUnread);
router.put('/read/:id', authenticateUser, controller.putReadById);
router.put('/read-all', authenticateUser, controller.putReadAll);
router.delete('/:id', authenticateUser, controller.deleteById);
router.delete('/clear/read', authenticateUser, controller.deleteClearRead);
router.post('/', authenticateAdmin, controller.postRoot);
router.post('/broadcast', authenticateAdmin, controller.postBroadcast);
router.post('/broadcast/all', authenticateAdmin, controller.postBroadcastAll);
router.get('/admin/all', authenticateAdmin, controller.getAdminAll);
router.get('/admin/stats', authenticateAdmin, controller.getAdminStats);
router.put('/admin/:id', authenticateAdmin, controller.putAdminById);
router.delete('/admin/:id', authenticateAdmin, controller.deleteAdminById);
router.delete('/admin/bulk/delete', authenticateAdmin, controller.deleteAdminBulkDelete);

export default router;

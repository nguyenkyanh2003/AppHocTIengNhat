import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './notification.controller.js';

const router = express.Router();

router.get('/', authenticateUser, controller.getRoot);
router.get('/count/unread', authenticateUser, controller.getCountUnread);
router.put('/read/:id', authenticateUser, controller.putReadById);
router.put('/read-all', authenticateUser, controller.putReadAll);
router.delete('/:id', authenticateUser, controller.deleteById);
router.post('/', authenticateAdmin, controller.postRoot);
router.post('/broadcast/all', authenticateAdmin, controller.postBroadcastAll);

export default router;

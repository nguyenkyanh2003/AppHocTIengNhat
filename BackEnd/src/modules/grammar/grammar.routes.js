import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './grammar.controller.js';

const router = express.Router();

router.get('/', authenticateUser, controller.getRoot);
router.get('/popular/:level', authenticateUser, controller.getPopularByLevel);
router.get('/:id', authenticateUser, controller.getById);
router.post('/learn/:id', authenticateUser, controller.postLearnById);
router.post('/', authenticateAdmin, controller.postRoot);
router.put('/:id', authenticateAdmin, controller.putById);
router.delete('/:id', authenticateAdmin, controller.deleteById);

export default router;

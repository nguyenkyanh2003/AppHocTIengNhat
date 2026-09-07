import express from 'express';
import { authenticateUser } from '../../middleware/auth.middleware.js';
import * as controller from './settings.controller.js';

const router = express.Router();

router.get('/', authenticateUser, controller.getRoot);
router.post('/', authenticateUser, controller.postRoot);
router.patch('/:setting', authenticateUser, controller.patchBySetting);

export default router;

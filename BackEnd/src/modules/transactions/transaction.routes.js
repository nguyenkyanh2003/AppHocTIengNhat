import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './transaction.controller.js';

const router = express.Router();

router.post("/create", authenticateUser, controller.postCreate);
router.get("/admin/all", authenticateAdmin, controller.getAdminAll);
router.put("/admin/:id/status", authenticateAdmin, controller.putAdminByIdStatus);

export default router;

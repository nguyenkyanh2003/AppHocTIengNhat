import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './report.controller.js';

const router = express.Router();

router.post("/create", authenticateUser, controller.postCreate);
router.get("/my-reports", authenticateUser, controller.getMyReports);
router.delete("/:id", authenticateUser, controller.deleteById);
router.get("/admin/all", authenticateAdmin, controller.getAdminAll);
router.put("/admin/:id/status", authenticateAdmin, controller.putAdminByIdStatus);
router.delete("/admin/:id", authenticateAdmin, controller.deleteAdminById);
router.get("/admin/stats", authenticateAdmin, controller.getAdminStats);

export default router;

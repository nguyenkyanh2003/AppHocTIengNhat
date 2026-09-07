import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './report.controller.js';

const router = express.Router();

router.post("/create", authenticateUser, controller.postCreate);
router.get("/my-reports", authenticateUser, controller.getMyReports);
router.get("/:id", authenticateUser, controller.getById);
router.delete("/:id", authenticateUser, controller.deleteById);
router.get("/admin/all", authenticateAdmin, controller.getAdminAll);
router.put("/admin/:id/status", authenticateAdmin, controller.putAdminByIdStatus);
router.put("/admin/:id/priority", authenticateAdmin, controller.putAdminByIdPriority);
router.delete("/admin/:id", authenticateAdmin, controller.deleteAdminById);
router.delete("/admin/bulk/delete", authenticateAdmin, controller.deleteAdminBulkDelete);
router.get("/admin/stats", authenticateAdmin, controller.getAdminStats);

export default router;

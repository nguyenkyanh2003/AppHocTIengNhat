import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './transaction.controller.js';

const router = express.Router();

router.get("/my-transactions", authenticateUser, controller.getMyTransactions);
router.get("/:id", authenticateUser, controller.getById);
router.post("/create", authenticateUser, controller.postCreate);
router.put("/:id/cancel", authenticateUser, controller.putByIdCancel);
router.get("/stats/me", authenticateUser, controller.getStatsMe);
router.get("/admin/all", authenticateAdmin, controller.getAdminAll);
router.get("/admin/:id", authenticateAdmin, controller.getAdminById);
router.put("/admin/:id/status", authenticateAdmin, controller.putAdminByIdStatus);
router.put("/admin/:id", authenticateAdmin, controller.putAdminById);
router.delete("/admin/:id", authenticateAdmin, controller.deleteAdminById);
router.delete("/admin/bulk/delete", authenticateAdmin, controller.deleteAdminBulkDelete);
router.get("/admin/stats/overview", authenticateAdmin, controller.getAdminStatsOverview);
router.get("/admin/user/:userId", authenticateAdmin, controller.getAdminUserByUserId);
router.post("/admin/:id/refund", authenticateAdmin, controller.postAdminByIdRefund);

export default router;

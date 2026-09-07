import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './srs-progress.controller.js';

const router = express.Router();

router.get('/due', authenticateUser, controller.getDue);
router.get("/due/count", authenticateUser, controller.getDueCount);
router.post("/answer/:id", authenticateUser, controller.postAnswerById);
router.post('/review', authenticateUser, controller.postReview);
router.get("/my-cards", authenticateUser, controller.getMyCards);
router.get('/stats', authenticateUser, controller.getStats);
router.delete("/:id", authenticateUser, controller.deleteById);
router.put("/reset/:id", authenticateUser, controller.putResetById);
router.get("/admin/all", authenticateAdmin, controller.getAdminAll);
router.get("/admin/stats", authenticateAdmin, controller.getAdminStats);
router.delete("/admin/:id", authenticateAdmin, controller.deleteAdminById);
router.delete("/admin/user/:userId/clear", authenticateAdmin, controller.deleteAdminUserByUserIdClear);

export default router;

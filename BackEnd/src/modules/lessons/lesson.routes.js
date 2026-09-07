import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './lesson.controller.js';

const router = express.Router();

router.get("/", authenticateUser, controller.getRoot);
router.get("/level/:capDo", authenticateUser, controller.getLevelByCapDo);
router.get("/type/:loaiBaiHoc", authenticateUser, controller.getTypeByLoaiBaiHoc);
router.get("/stats/overview", authenticateAdmin, controller.getStatsOverview);
router.get("/:id", authenticateUser, controller.getById);
router.post("/", authenticateAdmin, controller.postRoot);
router.post("/bulk", authenticateAdmin, controller.postBulk);
router.put("/:id", authenticateAdmin, controller.putById);
router.patch("/:id", authenticateAdmin, controller.patchById);
router.delete("/:id", authenticateAdmin, controller.deleteById);
router.delete("/", authenticateAdmin, controller.deleteRoot);
router.post("/:id/duplicate", authenticateAdmin, controller.postByIdDuplicate);

export default router;

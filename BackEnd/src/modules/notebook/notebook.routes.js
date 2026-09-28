import express from 'express';
import { authenticateUser } from '../../middleware/auth.middleware.js';
import * as controller from './notebook.controller.js';

const router = express.Router();

router.get("/", authenticateUser, controller.getRoot);
router.get("/:id", authenticateUser, controller.getById);
router.post("/", authenticateUser, controller.postRoot);
router.put("/:id", authenticateUser, controller.putById);
router.delete("/:id", authenticateUser, controller.deleteById);
router.delete("/", authenticateUser, controller.deleteRoot);
router.get("/related/:item_type/:item_id", authenticateUser, controller.getRelatedByItemTypeByItemId);
router.get("/tags/all", authenticateUser, controller.getTagsAll);
router.get("/stats/me", authenticateUser, controller.getStatsMe);

export default router;

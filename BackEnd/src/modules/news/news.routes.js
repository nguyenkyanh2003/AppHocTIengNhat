import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './news.controller.js';

const router = express.Router();

router.get("/", controller.getRoot);
router.get("/:id", controller.getById);
router.get("/:id/related", controller.getByIdRelated);
router.get("/categories/all", controller.getCategoriesAll);
router.get("/admin/all", authenticateAdmin, controller.getAdminAll);
router.post("/", authenticateAdmin, controller.postRoot);
router.put("/:id", authenticateAdmin, controller.putById);
router.delete("/:id", authenticateAdmin, controller.deleteById);
router.delete("/", authenticateAdmin, controller.deleteRoot);
router.get("/admin/stats", authenticateAdmin, controller.getAdminStats);

export default router;

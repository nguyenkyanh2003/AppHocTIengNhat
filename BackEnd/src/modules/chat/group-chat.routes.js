import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './group-chat.controller.js';

const router = express.Router();

router.post("/:groupID", authenticateUser, controller.isMember, controller.postByGroupID);
router.post("/:groupID/upload", authenticateUser, controller.isMember, controller.upload.single('file'), controller.postByGroupIDUpload);
router.get("/:groupID", authenticateUser, controller.isMember, controller.getByGroupID);
router.get("/:groupID/latest", authenticateUser, controller.isMember, controller.getByGroupIDLatest);
router.put("/:groupID/:messageID", authenticateUser, controller.isMember, controller.putByGroupIDByMessageID);
router.delete("/:groupID/:messageID", authenticateUser, controller.isMember, controller.deleteByGroupIDByMessageID);
router.get("/:groupID/search", authenticateUser, controller.isMember, controller.getByGroupIDSearch);
router.get("/:groupID/statistics", authenticateUser, controller.isMember, controller.getByGroupIDStatistics);
router.delete("/admin/:groupID/clear", authenticateAdmin, controller.deleteAdminByGroupIDClear);

export default router;

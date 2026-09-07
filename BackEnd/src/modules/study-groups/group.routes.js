import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import { uploadGroupAvatar } from '../../middleware/upload.middleware.js';
import * as controller from './group.controller.js';

const router = express.Router();

router.post("/", authenticateUser, controller.createGroup);
router.get("/", authenticateUser, controller.listGroups);
router.get("/me", authenticateUser, controller.listMyGroups);
router.get("/:groupID", authenticateUser, controller.getGroup);
router.put("/:groupID", authenticateUser, controller.isGroupAdmin, controller.updateGroup);
router.delete("/:groupID", authenticateUser, controller.deleteGroup);
router.post("/join/:groupID", authenticateUser, controller.joinGroup);
router.post("/leave/:groupID", authenticateUser, controller.leaveGroup);
router.delete("/kick/:groupID/:userID", authenticateUser, controller.isGroupAdmin, controller.kickMember);
router.put("/promote/:groupID/:userID", authenticateUser, controller.isGroupAdmin, controller.promoteMember);
router.put("/demote/:groupID/:userID", authenticateUser, controller.demoteMember);
router.post("/invite/:groupID/:userID", authenticateUser, controller.isGroupAdmin, controller.inviteMember);
router.get('/:groupID/stats', authenticateUser, controller.getGroupStats);
router.get("/admin/all", authenticateAdmin, controller.listAdminGroups);
router.delete("/admin/:groupID", authenticateAdmin, controller.deleteAdminGroup);
router.get("/admin/statistics", authenticateAdmin, controller.getAdminGroupStatistics);
router.put("/:groupID/avatar", authenticateUser, controller.isGroupAdmin, uploadGroupAvatar, controller.updateGroupAvatar);

export default router;

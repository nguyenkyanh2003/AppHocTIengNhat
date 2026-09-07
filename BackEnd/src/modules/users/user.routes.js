import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import { uploadUserAvatar } from '../../middleware/upload.middleware.js';
import { createRateLimiter } from '../../middleware/security.middleware.js';
import * as controller from './user.controller.js';

const router = express.Router();
const authRateLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: 'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.',
});

router.post("/login", authRateLimiter, controller.postLogin);
router.post("/logout", authenticateUser, controller.postLogout);
router.post("/register", controller.postRegister);
router.post("/forgot-password", authRateLimiter, controller.postForgotPassword);
router.post("/reset-password", authRateLimiter, controller.postResetPassword);
router.get("/profile/:id", authenticateUser, controller.getProfileById);
router.get("/me", authenticateUser, controller.getMe);
router.put("/profile/:id", authenticateUser, controller.putProfileById);
router.put("/change-password/:id", authenticateUser, controller.putChangePasswordById);
router.get("/admin/users", authenticateAdmin, controller.getAdminUsers);
router.get("/admin/users/:id", authenticateAdmin, controller.getAdminUsersById);
router.post("/admin/users", authenticateAdmin, controller.postAdminUsers);
router.put("/admin/users/:id", authenticateAdmin, controller.putAdminUsersById);
router.delete("/admin/users/:id", authenticateAdmin, controller.deleteAdminUsersById);
router.delete("/admin/users", authenticateAdmin, controller.deleteAdminUsers);
router.get("/admin/stats", authenticateAdmin, controller.getAdminStats);
router.put("/admin/users/:id/toggle-status", authenticateAdmin, controller.putAdminUsersByIdToggleStatus);
router.put("/profile/:userID/avatar", authenticateUser, uploadUserAvatar, controller.putProfileByUserIDAvatar);

export default router;

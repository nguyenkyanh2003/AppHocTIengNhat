import express from 'express';

import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import { uploadUserAvatar } from '../../middleware/upload.middleware.js';
import { createRateLimiter } from '../../middleware/security.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import * as controller from './user.controller.js';
import { createUserAuthController } from './user-auth.controller.js';
import * as schema from './user.schema.js';
import { userAuthService } from './user-auth.service.js';

const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000;
const RATE_LIMIT_MAX = 20;
const RATE_LIMIT_MESSAGE = 'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.';

/**
 * Mỗi nghiệp vụ auth có định danh giới hạn riêng.
 *
 * Tên cố định thay cho `req.path` để biến thể hoa/thường và dấu `/` cuối không
 * mở thêm ngân sách thử. Ba tên tách rời để thử sai đăng nhập không khóa luôn
 * đường khôi phục mật khẩu của chính người dùng đó.
 */
const authRateLimiter = (name) =>
  createRateLimiter({
    name,
    windowMs: RATE_LIMIT_WINDOW_MS,
    max: RATE_LIMIT_MAX,
    message: RATE_LIMIT_MESSAGE,
  });

/**
 * Nhận dependency qua tham số để test dựng router với service giả và auth giả,
 * không cần MongoDB, SMTP hay secret thật.
 */
export const createUserRoutes = ({
  authService = userAuthService,
  authenticate = authenticateUser,
  authorizeAdmin = authenticateAdmin,
  uploadAvatar = uploadUserAvatar,
} = {}) => {
  const auth = createUserAuthController(authService);
  const router = express.Router();

  router.post(
    "/login",
    authRateLimiter('login'),
    validate({ body: schema.loginBody }),
    asyncHandler(auth.login),
  );
  router.post("/logout", authenticate, controller.postLogout);
  router.post("/register", controller.postRegister);
  router.post(
    "/forgot-password",
    authRateLimiter('forgot-password'),
    validate({ body: schema.forgotPasswordBody }),
    asyncHandler(auth.forgotPassword),
  );
  router.post(
    "/reset-password",
    authRateLimiter('reset-password'),
    validate({ body: schema.resetPasswordBody }),
    asyncHandler(auth.resetPassword),
  );
  router.get("/profile/:id", authenticate, controller.getProfileById);
  router.get("/me", authenticate, controller.getMe);
  router.put("/profile/:id", authenticate, controller.putProfileById);
  router.put(
    "/change-password/:id",
    authenticate,
    validate({
      params: schema.changePasswordParams,
      body: schema.changePasswordBody,
    }),
    asyncHandler(auth.changePassword),
  );
  router.get("/admin/users", authorizeAdmin, controller.getAdminUsers);
  router.get("/admin/users/:id", authorizeAdmin, controller.getAdminUsersById);
  router.post("/admin/users", authorizeAdmin, controller.postAdminUsers);
  router.put("/admin/users/:id", authorizeAdmin, controller.putAdminUsersById);
  router.delete("/admin/users/:id", authorizeAdmin, controller.deleteAdminUsersById);
  router.delete("/admin/users", authorizeAdmin, controller.deleteAdminUsers);
  router.get("/admin/stats", authorizeAdmin, controller.getAdminStats);
  router.put("/admin/users/:id/toggle-status", authorizeAdmin, controller.putAdminUsersByIdToggleStatus);
  router.put("/profile/:userID/avatar", authenticate, uploadAvatar, controller.putProfileByUserIDAvatar);

  return router;
};

export default createUserRoutes();

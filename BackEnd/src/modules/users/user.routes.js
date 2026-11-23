import express from 'express';

import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import { uploadImage } from '../../middleware/upload.middleware.js';
import { createRateLimiter } from '../../middleware/security.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createUserAuthController } from './user-auth.controller.js';
import { userAuthService } from './user-auth.service.js';
import { createUserController } from './user.controller.js';
import * as schema from './user.schema.js';
import { userService as defaultUserService } from './user.service.js';

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
const authRateLimiter = (name, options = {}) =>
  createRateLimiter({
    name,
    windowMs: RATE_LIMIT_WINDOW_MS,
    max: RATE_LIMIT_MAX,
    message: RATE_LIMIT_MESSAGE,
    ...options,
  });

/**
 * Nhận dependency qua tham số để test dựng router với service giả và auth giả,
 * không cần MongoDB, SMTP hay secret thật.
 */
export const createUserRoutes = ({
  authService = userAuthService,
  userService = defaultUserService,
  authenticate = authenticateUser,
  authorizeAdmin = authenticateAdmin,
  uploadAvatar = uploadImage,
} = {}) => {
  const auth = createUserAuthController(authService);
  const users = createUserController(userService);
  const byId = validate({ params: schema.idParams });
  const router = express.Router();

  // Chỉ lần sai mới tốn lượt: cả lớp đăng nhập qua một wifi (chung IP) không
  // chặn nhau, còn đoán mật khẩu thì vẫn bị chặn sau 20 lần sai.
  router.post(
    "/login",
    authRateLimiter('login', { skipSuccessfulRequests: true }),
    validate({ body: schema.loginBody }),
    asyncHandler(auth.login),
  );
  // Access token chỉ sống 15 phút: client đổi refresh token lấy cặp mới. Không
  // qua `authenticate` — chính access token hết hạn là lý do gọi route này.
  router.post("/refresh-token", validate({ body: schema.refreshBody }), asyncHandler(auth.refresh));
  router.post("/logout", validate({ body: schema.logoutBody }), asyncHandler(auth.logout));
  router.post("/register", validate({ body: schema.registerBody }), asyncHandler(users.register));
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
  router.get("/profile/:id", authenticate, byId, asyncHandler(users.profile));
  router.put(
    "/profile/:id",
    authenticate,
    byId,
    validate({ body: schema.updateProfileBody }),
    asyncHandler(users.updateProfile),
  );
  router.put(
    "/change-password/:id",
    authenticate,
    validate({
      params: schema.changePasswordParams,
      body: schema.changePasswordBody,
    }),
    asyncHandler(auth.changePassword),
  );
  router.get("/admin/users", authorizeAdmin, validate({ query: schema.adminListQuery }), asyncHandler(users.adminList));
  router.put(
    "/admin/users/:id",
    authorizeAdmin,
    byId,
    validate({ body: schema.adminUpdateBody }),
    asyncHandler(users.adminUpdate),
  );
  router.delete("/admin/users/:id", authorizeAdmin, byId, asyncHandler(users.adminRemove));
  router.get("/admin/stats", authorizeAdmin, asyncHandler(users.adminStats));
  router.put(
    "/profile/:userID/avatar",
    authenticate,
    validate({ params: schema.avatarParams }),
    uploadAvatar,
    asyncHandler(users.setAvatar),
  );

  return router;
};

export default createUserRoutes();

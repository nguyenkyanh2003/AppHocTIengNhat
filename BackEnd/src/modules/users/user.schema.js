import { z } from 'zod';
import { jlptLevel, objectId } from '../../shared/http/schemas.js';

/**
 * Độ dài tối thiểu của mật khẩu — **một** ngưỡng cho đăng ký, đặt lại và đổi
 * mật khẩu; Flutter giữ cùng số trong `PasswordPolicy.minLength`. Đăng nhập
 * không kiểm độ dài: tài khoản cũ đặt mật khẩu ngắn hơn vẫn phải vào được.
 */
export const PASSWORD_MIN_LENGTH = 8;

const newPassword = z
  .string()
  .min(PASSWORD_MIN_LENGTH, `Mật khẩu phải có ít nhất ${PASSWORD_MIN_LENGTH} ký tự.`);

const required = (message) => z.string().trim().min(1, message);

/**
 * Đăng nhập chỉ nhận chuỗi.
 *
 * Mongoose ép một mảng trên path String thành `$in`, nên `username` dạng mảng
 * hoặc object toán tử (`{ "$ne": null }`) vẫn tạo ra truy vấn hợp lệ và trả về
 * một tài khoản mà người gửi không chỉ định. Chốt kiểu ở đây chặn cả họ payload
 * đó trước khi chạm tới database.
 */
export const loginBody = z.object({
  username: z.string().trim().min(1, 'Vui lòng nhập tên đăng nhập.'),
  password: z.string().min(1, 'Vui lòng nhập mật khẩu.'),
});

/**
 * Email khôi phục mật khẩu phải là **một** địa chỉ hợp lệ.
 *
 * `z.email()` từ chối mảng, object và chuỗi sai định dạng. Đây là lớp chặn thứ
 * nhất của lỗ hổng gửi token cho địa chỉ do người gửi tự chọn; lớp thứ hai là
 * service luôn gửi tới `user.Email` đọc từ database.
 */
export const forgotPasswordBody = z.object({
  // Cắt khoảng trắng **trước** khi kiểm tra định dạng: thứ tự ngược lại sẽ từ
  // chối địa chỉ hợp lệ mà người dùng dán kèm dấu cách.
  email: z.string().trim().pipe(z.email('Email không hợp lệ.')),
});

/**
 * Đăng ký: mọi trường là chuỗi — cùng lý do với [loginBody], `username` hay
 * `email` dạng object toán tử không được chạm tới truy vấn kiểm tra trùng.
 * Email về chữ thường như model lưu, để kiểm tra trùng không lọt chữ hoa.
 */
export const registerBody = z.object({
  username: required('Vui lòng nhập tên đăng nhập.'),
  hoTen: required('Vui lòng nhập họ tên.'),
  email: z.string().trim().toLowerCase().pipe(z.email('Email không hợp lệ.')),
  password: newPassword,
  trinhDo: jlptLevel.optional(),
});

/** Refresh token là chuỗi ngẫu nhiên base64url; mảng hay object toán tử bị chặn ở đây. */
const refreshToken = z.string().min(1, 'Thiếu refresh token.').max(200);

export const refreshBody = z.object({ refreshToken });

/** Đăng xuất không bắt buộc refresh token: client chỉ còn access token vẫn đăng xuất được. */
export const logoutBody = z.object({ refreshToken: refreshToken.optional() });

export const resetPasswordBody = z.object({
  token: z.string().min(1, 'Thiếu token đặt lại mật khẩu.'),
  newPassword,
});

export const changePasswordParams = z.object({ id: objectId });

/**
 * `oldPassword` không bắt buộc ở tầng schema vì admin đổi mật khẩu tài khoản
 * khác không cần nó. Rule "người dùng tự đổi thì phải có mật khẩu cũ" là rule
 * nghiệp vụ và nằm ở service.
 */
export const changePasswordBody = z.object({
  oldPassword: z.string().min(1).optional(),
  newPassword,
});

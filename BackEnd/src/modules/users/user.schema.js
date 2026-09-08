import { z } from 'zod';

const objectId = z
  .string()
  .regex(/^[0-9a-fA-F]{24}$/, 'Định danh không hợp lệ.');

/** Ngưỡng 8 ký tự giữ đúng rule mà controller cũ đang kiểm tra thủ công. */
const newPassword = z.string().min(8, 'Mật khẩu phải có ít nhất 8 ký tự.');

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

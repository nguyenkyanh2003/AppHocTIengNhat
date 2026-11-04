/**
 * Escape ký tự đặc biệt để chuỗi người dùng nhập được khớp nguyên văn trong
 * `RegExp` hay `$regex`: `C++` không thành lượng từ, `[` không làm vỡ biểu thức.
 */
export const escapeRegExp = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

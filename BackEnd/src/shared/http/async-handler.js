/**
 * Bọc một handler async để lỗi đi thẳng về error middleware.
 *
 * Nhờ vậy controller không cần try/catch: mọi lỗi (kể cả ApiError do service
 * ném ra) đều được `errorHandler` xử lý ở một chỗ duy nhất.
 */
export const asyncHandler = (handler) => (req, res, next) => {
  Promise.resolve(handler(req, res, next)).catch(next);
};

export default asyncHandler;

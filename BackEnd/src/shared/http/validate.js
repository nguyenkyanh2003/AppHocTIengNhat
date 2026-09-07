import { ApiError } from './api-error.js';

const SOURCES = ['params', 'query', 'body'];

const formatIssues = (error) =>
  error.issues.map((issue) => ({
    path: issue.path.join('.'),
    message: issue.message,
  }));

/**
 * Validate request bằng zod schema và gắn kết quả đã parse vào `req.valid`.
 *
 * Controller chỉ đọc `req.valid.query` / `req.valid.params` / `req.valid.body`,
 * không đọc dữ liệu thô. Express 5 không cho ghi đè `req.query` nên giá trị đã
 * ép kiểu bắt buộc phải nằm ở `req.valid`.
 */
export const validate = (schemas = {}) => (req, _res, next) => {
  req.valid = req.valid ?? {};

  for (const source of SOURCES) {
    const schema = schemas[source];
    if (!schema) continue;

    const result = schema.safeParse(req[source]);
    if (!result.success) {
      return next(
        ApiError.badRequest('Dữ liệu gửi lên không hợp lệ.', {
          code: 'VALIDATION_ERROR',
          details: formatIssues(result.error),
        }),
      );
    }

    req.valid[source] = result.data;
  }

  return next();
};

export default validate;

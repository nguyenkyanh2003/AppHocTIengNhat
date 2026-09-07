/**
 * Lỗi nghiệp vụ có ý nghĩa HTTP.
 *
 * Service ném ApiError; controller không bắt lỗi. `error.middleware.js` dịch
 * ApiError sang response, nên message ở đây là message người dùng sẽ đọc.
 */
export class ApiError extends Error {
  constructor(status, message, { code, details } = {}) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
    this.details = details;
  }

  static badRequest(message, options) {
    return new ApiError(400, message, { code: 'BAD_REQUEST', ...options });
  }

  static unauthorized(message, options) {
    return new ApiError(401, message, { code: 'UNAUTHORIZED', ...options });
  }

  static forbidden(message, options) {
    return new ApiError(403, message, { code: 'FORBIDDEN', ...options });
  }

  static notFound(message, options) {
    return new ApiError(404, message, { code: 'NOT_FOUND', ...options });
  }

  static conflict(message, options) {
    return new ApiError(409, message, { code: 'CONFLICT', ...options });
  }

  static isApiError(error) {
    return error instanceof ApiError;
  }
}

export default ApiError;

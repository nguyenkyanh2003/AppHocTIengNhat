const rateLimitBuckets = new Map();

export const securityHeaders = (req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('Referrer-Policy', 'no-referrer');
  res.setHeader('Permissions-Policy', 'camera=(), geolocation=(), microphone=(self)');
  res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
  next();
};

export const productionResponseSanitizer = (nodeEnv) => (req, res, next) => {
  if (nodeEnv !== 'production') return next();
  const originalJson = res.json.bind(res);
  res.json = (body) => {
    if (body && typeof body === 'object' && !Array.isArray(body)) {
      delete body.error;
      delete body.stack;
    }
    return originalJson(body);
  };
  return next();
};

/**
 * Giới hạn số lần thử theo IP cho **một nghiệp vụ**, không theo URL.
 *
 * Khóa bucket phải là định danh cố định do server đặt: Express mặc định không
 * phân biệt hoa/thường và không bắt buộc dấu `/` cuối, nên `/login`, `/Login`
 * và `/login/` cùng vào một handler. Nếu khóa lấy từ `req.path` thì mỗi biến
 * thể URL lại mở một ngân sách thử mới và giới hạn coi như không tồn tại.
 *
 * Mỗi nghiệp vụ khai báo `name` riêng để quota của chúng độc lập với nhau:
 * thử sai đăng nhập không được khóa luôn đường khôi phục mật khẩu.
 *
 * [skipSuccessfulRequests]: request trả mã < 400 được trả lại lượt. Lượt vẫn
 * bị trừ **trước** khi xử lý, nên gửi song song nhiều lần đoán mật khẩu không
 * lọt qua hạn mức; chỉ sau khi biết là đúng mới hoàn lại.
 */
export const createRateLimiter = ({ windowMs, max, message, name, skipSuccessfulRequests = false }) => {
  if (typeof name !== 'string' || name.trim() === '') {
    throw new Error('createRateLimiter yêu cầu `name` cố định cho từng nghiệp vụ.');
  }

  /** Hoàn lượt khi request thành công, nếu bucket vẫn còn là bucket đã trừ (chưa sang cửa sổ mới). */
  const refundOnSuccess = (res, bucket) => {
    res.on('finish', () => {
      if (res.statusCode < 400 && bucket.count > 0) bucket.count -= 1;
    });
  };

  return (req, res, next) => {
    const now = Date.now();
    const key = `${req.ip}:${name}`;
    let bucket = rateLimitBuckets.get(key);

    if (!bucket || bucket.resetAt <= now) {
      bucket = { count: 0, resetAt: now + windowMs };
      rateLimitBuckets.set(key, bucket);
    }

    bucket.count += 1;
    if (bucket.count > max) {
      res.setHeader('Retry-After', Math.ceil((bucket.resetAt - now) / 1000));
      return res.status(429).json({ message });
    }
    if (skipSuccessfulRequests) refundOnSuccess(res, bucket);

    if (rateLimitBuckets.size > 10_000) {
      for (const [bucketKey, stale] of rateLimitBuckets) {
        if (stale.resetAt <= now) rateLimitBuckets.delete(bucketKey);
      }
    }

    return next();
  };
};

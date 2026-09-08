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
 */
export const createRateLimiter = ({ windowMs, max, message, name }) => {
  if (typeof name !== 'string' || name.trim() === '') {
    throw new Error('createRateLimiter yêu cầu `name` cố định cho từng nghiệp vụ.');
  }

  return (req, res, next) => {
    const now = Date.now();
    const key = `${req.ip}:${name}`;
    const current = rateLimitBuckets.get(key);

    if (!current || current.resetAt <= now) {
      rateLimitBuckets.set(key, { count: 1, resetAt: now + windowMs });
      return next();
    }

    current.count += 1;
    if (current.count > max) {
      res.setHeader('Retry-After', Math.ceil((current.resetAt - now) / 1000));
      return res.status(429).json({ message });
    }

    if (rateLimitBuckets.size > 10_000) {
      for (const [bucketKey, bucket] of rateLimitBuckets) {
        if (bucket.resetAt <= now) rateLimitBuckets.delete(bucketKey);
      }
    }

    return next();
  };
};

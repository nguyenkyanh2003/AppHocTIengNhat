import env from '../config/env.js';

export const notFoundHandler = (req, res) => {
  res.status(404).json({ message: 'API không tồn tại' });
};

export const errorHandler = (err, req, res, next) => {
  console.error(err.stack);
  const response = { message: 'Đã có lỗi xảy ra ở máy chủ' };
  if (env.nodeEnv !== 'production') response.error = err.message;
  res.status(err.status || 500).json(response);
};

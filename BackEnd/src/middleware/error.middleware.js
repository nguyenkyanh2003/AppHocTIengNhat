import mongoose from 'mongoose';
import multer from 'multer';

import env from '../config/env.js';
import { ApiError } from '../shared/http/api-error.js';

export const notFoundHandler = (req, res) => {
  res.status(404).json({ message: 'API không tồn tại' });
};

const GENERIC_MESSAGE = 'Đã có lỗi xảy ra ở máy chủ';

/** Dịch lỗi kỹ thuật sang lỗi HTTP có message đọc được. */
const translate = (err) => {
  if (ApiError.isApiError(err)) {
    return {
      status: err.status,
      message: err.message,
      code: err.code,
      details: err.details,
    };
  }

  if (err instanceof mongoose.Error.ValidationError) {
    return {
      status: 400,
      message: 'Dữ liệu không hợp lệ.',
      code: 'VALIDATION_ERROR',
      details: Object.values(err.errors).map((issue) => ({
        path: issue.path,
        message: issue.message,
      })),
    };
  }

  if (err instanceof mongoose.Error.CastError) {
    return {
      status: 400,
      message: 'Định danh không hợp lệ.',
      code: 'INVALID_ID',
      details: [{ path: err.path, message: `Giá trị không hợp lệ: ${err.value}` }],
    };
  }

  if (err?.code === 11000) {
    return {
      status: 409,
      message: 'Dữ liệu đã tồn tại.',
      code: 'DUPLICATE_KEY',
      details: Object.keys(err.keyPattern ?? {}).map((path) => ({
        path,
        message: 'Giá trị đã được sử dụng.',
      })),
    };
  }

  if (err instanceof multer.MulterError) {
    return {
      status: 400,
      message:
        err.code === 'LIMIT_FILE_SIZE'
          ? 'Tệp vượt quá dung lượng cho phép.'
          : 'Tệp tải lên không hợp lệ.',
      code: err.code,
    };
  }

  return {
    status: err?.status ?? 500,
    message: GENERIC_MESSAGE,
    code: undefined,
    details: undefined,
  };
};

export const errorHandler = (err, req, res, next) => {
  const { status, message, code, details } = translate(err);

  if (status >= 500) {
    console.error(err.stack ?? err);
  }

  const response = { message };
  if (code) response.code = code;
  if (details) response.details = details;
  if (env.nodeEnv !== 'production') response.error = err.message;

  res.status(status).json(response);
};

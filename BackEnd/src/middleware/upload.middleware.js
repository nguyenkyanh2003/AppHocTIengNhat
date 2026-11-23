import multer from 'multer';

import { ApiError } from '../shared/http/api-error.js';

const MAX_FILE_BYTES = 5 * 1024 * 1024;

// `image/jpg` không chuẩn nhưng vài client vẫn gửi.
const IMAGE_MIME_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];

/**
 * Lọc sơ theo loại client khai, để từ chối sớm tệp rõ ràng không phải ảnh.
 * Định dạng thật do `image-store` đọc từ nội dung tệp lúc lưu.
 */
const imageFilter = (req, file, cb) => {
  if (IMAGE_MIME_TYPES.includes(file.mimetype)) return cb(null, true);
  cb(ApiError.badRequest('Chỉ chấp nhận file ảnh (jpeg, jpg, png, gif, webp).'));
};

/**
 * Ảnh đại diện và ảnh nhóm (trường `avatar`), giữ trong bộ nhớ.
 *
 * Không ghi xuống đĩa ở đây: middleware chạy trước khi service kiểm quyền, nên
 * ghi ngay thì request bị từ chối vẫn để lại tệp. Service lưu qua `imageStore`
 * sau khi kiểm quyền.
 */
export const uploadImage = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_FILE_BYTES },
  fileFilter: imageFilter,
}).single('avatar');

// Chỉ nhận .xlsx: ExcelJS không đọc được .xls (Excel 97–2003). MIME vẫn nhận
// `vnd.ms-excel` vì có máy Windows gửi kiểu đó cho cả tệp .xlsx.
const excelFilter = (req, file, cb) => {
  const validExtension = /\.xlsx$/i.test(file.originalname);
  const validMime = [
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/octet-stream',
  ].includes(file.mimetype);

  if (validExtension && validMime) return cb(null, true);
  cb(ApiError.badRequest('Chỉ nhận tệp Excel .xlsx. Tệp .xls (Excel 97–2003) hãy mở bằng Excel rồi lưu lại dạng .xlsx.'));
};

/** Tệp Excel nhập nội dung (trường `fileExcel`), giữ trong bộ nhớ. */
export const uploadContentExcel = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_FILE_BYTES },
  fileFilter: excelFilter,
}).single('fileExcel');

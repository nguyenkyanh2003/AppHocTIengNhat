import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Đảm bảo folder uploads tồn tại
const uploadDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const userAvatarDir = path.join(uploadDir, 'avatars');
if (!fs.existsSync(userAvatarDir)) {
  fs.mkdirSync(userAvatarDir, { recursive: true });
}

const groupAvatarDir = path.join(uploadDir, 'group-avatars');
if (!fs.existsSync(groupAvatarDir)) {
  fs.mkdirSync(groupAvatarDir, { recursive: true });
}

// Storage cho user avatar
const userAvatarStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, userAvatarDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'user-' + uniqueSuffix + path.extname(file.originalname));
  }
});

// Storage cho group avatar
const groupAvatarStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, groupAvatarDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'group-' + uniqueSuffix + path.extname(file.originalname));
  }
});

// File filter - chỉ cho phép ảnh
const imageFilter = (req, file, cb) => {
  const allowedExtensions = /jpeg|jpg|png|gif|webp/;
  const allowedMimeTypes = /image\/(jpeg|jpg|png|gif|webp)/;
  
  const extname = allowedExtensions.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedMimeTypes.test(file.mimetype);

  // Chấp nhận nếu extension đúng HOẶC mimetype đúng (để tương thích với web)
  if (mimetype || extname) {
    return cb(null, true);
  } else {
    cb(new Error('Chỉ chấp nhận file ảnh (jpeg, jpg, png, gif, webp)'));
  }
};

// Upload user avatar
export const uploadUserAvatar = multer({
  storage: userAvatarStorage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: imageFilter
}).single('avatar');

// Upload group avatar
export const uploadGroupAvatar = multer({
  storage: groupAvatarStorage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: imageFilter
}).single('avatar');

// Dọn ảnh đại diện và ảnh nhóm không còn bản ghi nào trỏ tới.
//
// Trước khi app biết xoá ảnh cũ lúc thay ảnh (và xoá ảnh của tài khoản bị xoá),
// mỗi lần đổi ảnh để lại một tệp trong uploads/. Từ nay không phát sinh thêm;
// script này dọn phần tồn lại. Nhóm đã ẩn (xoá mềm) vẫn tính là còn dùng ảnh.
//
//   node scripts/clean-uploads.js           # chỉ liệt kê
//   node scripts/clean-uploads.js --apply   # xoá
import { readdirSync, rmSync, statSync } from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

import mongoose from 'mongoose';

import env from '../src/config/env.js';
import { UPLOADS_ROOT } from '../src/shared/files/image-store.js';
import StudyGroup from '../model/StudyGroup.js';
import User from '../model/User.js';

/** Thư mục chứa ảnh người dùng tải lên; các thư mục khác trong uploads/ là nội dung của app. */
export const IMAGE_FOLDERS = ['avatars', 'group-avatars'];

/** Các tệp (đường dẫn công khai `/uploads/...`) không nằm trong [referenced]. */
export const orphanUploads = ({ files, referenced }) => {
  const used = new Set(referenced);
  return files.filter((publicPath) => !used.has(publicPath));
};

const uploadedImages = () =>
  IMAGE_FOLDERS.flatMap((folder) => {
    const dir = path.join(UPLOADS_ROOT, folder);
    try {
      return readdirSync(dir)
        .filter((name) => statSync(path.join(dir, name)).isFile())
        .map((name) => `/uploads/${folder}/${name}`);
    } catch (error) {
      if (error.code === 'ENOENT') return [];
      throw error;
    }
  });

const referencedImages = async () => {
  const [users, groups] = await Promise.all([
    User.find({ AnhDaiDien: { $regex: '^/uploads/' } }).select('AnhDaiDien').lean(),
    StudyGroup.find({ avatar: { $regex: '^/uploads/' } }).select('avatar').lean(),
  ]);
  return [...users.map((user) => user.AnhDaiDien), ...groups.map((group) => group.avatar)];
};

const main = async () => {
  const apply = process.argv.includes('--apply');
  await mongoose.connect(env.mongoUri, { dbName: env.databaseName });
  try {
    const orphans = orphanUploads({ files: uploadedImages(), referenced: await referencedImages() });
    if (orphans.length === 0) {
      console.log('✅ Không có ảnh nào bị bỏ rơi.');
      return;
    }
    for (const publicPath of orphans) {
      if (apply) rmSync(path.join(UPLOADS_ROOT, publicPath.slice('/uploads/'.length)));
      console.log(`${apply ? '🗑️  đã xoá' : '•'} ${publicPath}`);
    }
    console.log(apply
      ? `\n✅ Đã xoá ${orphans.length} ảnh không còn dùng.`
      : `\n🔍 ${orphans.length} ảnh không còn bản ghi nào dùng. Chạy lại với --apply để xoá.`);
  } finally {
    await mongoose.disconnect();
  }
};

if (import.meta.url === pathToFileURL(process.argv[1]).href) await main();

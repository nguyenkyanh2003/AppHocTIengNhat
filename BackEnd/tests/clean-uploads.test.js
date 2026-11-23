import assert from 'node:assert/strict';
import test from 'node:test';

import { IMAGE_FOLDERS, orphanUploads } from '../scripts/clean-uploads.js';

test('chỉ ảnh không còn bản ghi nào trỏ tới bị coi là bỏ rơi', () => {
  const orphans = orphanUploads({
    files: ['/uploads/avatars/dang-dung.png', '/uploads/avatars/anh-cu.png', '/uploads/group-avatars/nhom.jpg'],
    referenced: ['/uploads/avatars/dang-dung.png', '/uploads/group-avatars/nhom.jpg', 'https://via.placeholder.com/150'],
  });

  assert.deepEqual(orphans, ['/uploads/avatars/anh-cu.png']);
});

test('chỉ dọn thư mục ảnh người dùng tải lên, không đụng nội dung của app', () => {
  assert.deepEqual(IMAGE_FOLDERS, ['avatars', 'group-avatars']);
});

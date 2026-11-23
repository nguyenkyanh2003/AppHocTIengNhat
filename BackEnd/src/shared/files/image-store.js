import { randomUUID } from 'node:crypto';
import { mkdir, unlink, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { ApiError } from '../http/api-error.js';

/** Thư mục `BackEnd/uploads`, phục vụ tĩnh ở `/uploads` (xem `app.js`). */
export const UPLOADS_ROOT = fileURLToPath(new URL('../../../uploads/', import.meta.url));
const PUBLIC_PREFIX = '/uploads/';

const startsWith = (buffer, bytes, offset = 0) =>
  buffer.length >= offset + bytes.length && buffer.subarray(offset, offset + bytes.length).equals(bytes);

/** Chữ ký đầu tệp của các định dạng ảnh nhận lưu. SVG không có: nó là tài liệu chạy được script. */
const SIGNATURES = [
  ['jpg', (buffer) => startsWith(buffer, Buffer.from([0xff, 0xd8, 0xff]))],
  ['png', (buffer) => startsWith(buffer, Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))],
  ['gif', (buffer) => startsWith(buffer, Buffer.from('GIF87a')) || startsWith(buffer, Buffer.from('GIF89a'))],
  ['webp', (buffer) => startsWith(buffer, Buffer.from('RIFF')) && startsWith(buffer, Buffer.from('WEBP'), 8)],
];

/**
 * Đuôi tệp đúng với nội dung, hoặc `null` khi không phải ảnh.
 *
 * Không tin tên tệp hay MIME client khai: `image_picker` trên Android nén lại
 * thành JPEG nhưng giữ tên `.png`, còn một tệp HTML đổi tên thành `.png` vẫn
 * qua được bộ lọc theo tên.
 */
export const imageExtensionOf = (buffer) => SIGNATURES.find(([, matches]) => matches(buffer))?.[0] ?? null;

const notAnImage = () => ApiError.badRequest('Tệp tải lên không phải ảnh (jpeg, png, gif, webp).');

/**
 * Ảnh người dùng tải lên (ảnh đại diện, ảnh nhóm), lưu dưới [root].
 *
 * Service gọi store **sau** khi kiểm quyền — tệp không bao giờ được ghi cho
 * một request rồi bị từ chối — và dùng [replace] để ảnh cũ được xoá khi đã
 * có ảnh mới. Xoá là việc dọn dẹp: hỏng thì ghi log, không làm hỏng request
 * đã ghi xong.
 */
export const createImageStore = ({ root = UPLOADS_ROOT, log = console.error } = {}) => {
  /** Đường dẫn trên đĩa của một ảnh store này tạo, hoặc `null` (URL ngoài, ảnh mẫu, đường dẫn trèo ra ngoài). */
  const fileOf = (publicPath) => {
    if (typeof publicPath !== 'string' || !publicPath.startsWith(PUBLIC_PREFIX)) return null;
    const file = path.resolve(root, publicPath.slice(PUBLIC_PREFIX.length));
    return file.startsWith(path.resolve(root) + path.sep) ? file : null;
  };

  const store = {
    /** Ghi [buffer] vào `<root>/<folder>/`, trả đường dẫn công khai `/uploads/<folder>/<tên>`. */
    async save({ folder, prefix, buffer }) {
      const extension = imageExtensionOf(buffer);
      if (!extension) throw notAnImage();
      const name = `${prefix}-${Date.now()}-${randomUUID()}.${extension}`;
      await mkdir(path.join(root, folder), { recursive: true });
      await writeFile(path.join(root, folder, name), buffer);
      return `${PUBLIC_PREFIX}${folder}/${name}`;
    },

    async remove(publicPath) {
      const file = fileOf(publicPath);
      if (!file) return;
      try {
        await unlink(file);
      } catch (error) {
        if (error.code !== 'ENOENT') log(`Không xoá được ảnh cũ ${publicPath}: ${error.message}`);
      }
    },

    /**
     * Ghi ảnh mới, để [apply] lưu đường dẫn vào bản ghi, rồi mới xoá ảnh
     * [previous]. [apply] ném lỗi thì xoá ảnh mới và giữ nguyên ảnh cũ.
     */
    async replace({ folder, prefix, buffer, previous, apply }) {
      const next = await store.save({ folder, prefix, buffer });
      let result;
      try {
        result = await apply(next);
      } catch (error) {
        await store.remove(next);
        throw error;
      }
      await store.remove(previous);
      return result;
    },
  };
  return store;
};

export const imageStore = createImageStore();

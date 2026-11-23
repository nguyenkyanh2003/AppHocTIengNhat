import assert from 'node:assert/strict';
import { existsSync, mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import test from 'node:test';

import { createImageStore, imageExtensionOf } from '../src/shared/files/image-store.js';

const PNG = Buffer.from('89504e470d0a1a0a0000000d49484452', 'hex');
const JPEG = Buffer.from('ffd8ffe000104a4649460001', 'hex');
const GIF = Buffer.from('GIF89a\x01\x00\x01\x00\x00\x00', 'latin1');
const WEBP = Buffer.concat([Buffer.from('RIFF'), Buffer.alloc(4), Buffer.from('WEBPVP8 ')]);

const withStore = (run) => async () => {
  const root = mkdtempSync(path.join(tmpdir(), 'uploads-'));
  try {
    await run({ root, store: createImageStore({ root, log: () => {} }) });
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
};

test('nhận định dạng ảnh theo nội dung tệp, không theo tên hay MIME client khai', () => {
  assert.equal(imageExtensionOf(PNG), 'png');
  assert.equal(imageExtensionOf(JPEG), 'jpg');
  assert.equal(imageExtensionOf(GIF), 'gif');
  assert.equal(imageExtensionOf(WEBP), 'webp');
  assert.equal(imageExtensionOf(Buffer.from('<html><script>alert(1)</script></html>')), null);
  assert.equal(imageExtensionOf(Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"></svg>')), null);
  assert.equal(imageExtensionOf(Buffer.alloc(0)), null);
});

test('lưu ảnh với đuôi đúng nội dung: JPEG gửi kèm tên .png vẫn lưu .jpg', withStore(async ({ root, store }) => {
  const saved = await store.save({ folder: 'avatars', prefix: 'user', buffer: JPEG });

  assert.match(saved, /^\/uploads\/avatars\/user-[\w-]+\.jpg$/);
  assert.deepEqual(readFileSync(path.join(root, 'avatars', path.basename(saved))), JPEG);
}));

test('tệp không phải ảnh bị từ chối, không ghi gì xuống đĩa', withStore(async ({ root, store }) => {
  await assert.rejects(
    store.save({ folder: 'avatars', prefix: 'user', buffer: Buffer.from('<html></html>') }),
    (error) => error.status === 400 && /ảnh/.test(error.message),
  );
  assert.equal(existsSync(path.join(root, 'avatars')) ? readdirSync(path.join(root, 'avatars')).length : 0, 0);
}));

test('xoá chỉ tệp do store tạo; bỏ qua ảnh mẫu, đường dẫn trèo ra ngoài và tệp đã mất', withStore(async ({ root, store }) => {
  const saved = await store.save({ folder: 'avatars', prefix: 'user', buffer: PNG });
  const outside = path.join(root, '..', `ngoai-${path.basename(root)}.txt`);
  writeFileSync(outside, 'không được xoá');

  await store.remove(saved);
  await store.remove('https://via.placeholder.com/150');
  await store.remove(`/uploads/../${path.basename(outside)}`);
  await store.remove('/uploads/avatars/khong-co.png');
  await store.remove(null);

  assert.equal(existsSync(path.join(root, 'avatars', path.basename(saved))), false);
  assert.equal(readFileSync(outside, 'utf8'), 'không được xoá');
  rmSync(outside);
}));

test('thay ảnh: ghi bản ghi xong mới xoá ảnh cũ; ghi hỏng thì xoá ảnh mới, giữ ảnh cũ', withStore(async ({ root, store }) => {
  const old = await store.save({ folder: 'avatars', prefix: 'user', buffer: PNG });

  await assert.rejects(
    store.replace({ folder: 'avatars', prefix: 'user', buffer: JPEG, previous: old, apply: async () => { throw new Error('db hỏng'); } }),
    /db hỏng/,
  );
  assert.deepEqual(readdirSync(path.join(root, 'avatars')), [path.basename(old)]);

  let written;
  const result = await store.replace({
    folder: 'avatars', prefix: 'user', buffer: JPEG, previous: old,
    apply: async (next) => {
      written = next;
      return { avatar: next };
    },
  });
  assert.deepEqual(result, { avatar: written });
  assert.deepEqual(readdirSync(path.join(root, 'avatars')), [path.basename(written)]);
}));

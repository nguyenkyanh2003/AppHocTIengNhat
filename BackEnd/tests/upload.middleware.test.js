import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { uploadContentExcel, uploadImage } from '../src/middleware/upload.middleware.js';

const buildApp = () => {
  const app = express();
  app.post('/upload', uploadContentExcel, (req, res) => res.json({ name: req.file?.originalname ?? null }));
  app.use(errorHandler);
  return app;
};

test('tệp sai loại là lỗi của người tải lên (400 kèm lời giải thích), không phải lỗi máy chủ', async () => {
  const response = await request(buildApp())
    .post('/upload')
    .attach('fileExcel', Buffer.from('xin chào'), { filename: 'kanji.txt', contentType: 'text/plain' });

  assert.equal(response.status, 400);
  assert.match(response.body.message, /Excel/);
});

test('tệp Excel đúng loại đi tiếp tới handler', async () => {
  const response = await request(buildApp())
    .post('/upload')
    .attach('fileExcel', Buffer.from('PK'), {
      filename: 'kanji.xlsx',
      contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });

  assert.deepEqual(response.body, { name: 'kanji.xlsx' });
});

test('tệp .xls (Excel 97–2003) bị chặn ngay, kèm cách lưu lại thành .xlsx', async () => {
  // ExcelJS chỉ đọc .xlsx: nhận .xls rồi mới báo "không đọc được" là hứa suông.
  const response = await request(buildApp())
    .post('/upload')
    .attach('fileExcel', Buffer.from([0xd0, 0xcf, 0x11, 0xe0]), {
      filename: 'kanji.xls',
      contentType: 'application/vnd.ms-excel',
    });

  assert.equal(response.status, 400);
  assert.match(response.body.message, /\.xlsx/);
  assert.doesNotMatch(response.body.message, /\.xls hoặc/);
});

test('ảnh tải lên chỉ giữ trong bộ nhớ: chưa kiểm quyền thì chưa có gì ghi xuống đĩa', async () => {
  const app = express();
  app.put('/avatar', uploadImage, (req, res) => res.json({ bytes: req.file.buffer.length, path: req.file.path ?? null }));
  app.use(errorHandler);

  const response = await request(app)
    .put('/avatar')
    .attach('avatar', Buffer.from([0xff, 0xd8, 0xff, 0xe0]), { filename: 'a.png', contentType: 'image/png' });

  assert.deepEqual(response.body, { bytes: 4, path: null });
});

test('ảnh: tệp khai không phải ảnh bị chặn với 400', async () => {
  const app = express();
  app.put('/avatar', uploadImage, (req, res) => res.json({ ok: true }));
  app.use(errorHandler);

  const response = await request(app)
    .put('/avatar')
    .attach('avatar', Buffer.from('xin chào'), { filename: 'a.txt', contentType: 'text/plain' });

  assert.equal(response.status, 400);
  assert.match(response.body.message, /ảnh/);
});

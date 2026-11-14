import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { uploadContentExcel } from '../src/middleware/upload.middleware.js';

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

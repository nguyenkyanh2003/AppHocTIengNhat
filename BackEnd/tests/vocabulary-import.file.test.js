import assert from 'node:assert/strict';
import test from 'node:test';

import { parseCsv, splitCsvLine } from '../src/modules/vocabulary/vocabulary-import.file.js';

test('a comma inside a quoted cell does not split the row', () => {
  // Nghĩa tiếng Việt rất hay có dấu phẩy: "học sinh, sinh viên". Tách bằng
  // split(',') là hỏng ngay dòng dữ liệu đầu tiên.
  assert.deepEqual(splitCsvLine('学生,がくせい,"học sinh, sinh viên"'), [
    '学生',
    'がくせい',
    'học sinh, sinh viên',
  ]);
});

test('an escaped quote survives as one quote', () => {
  assert.deepEqual(splitCsvLine('a,"nói ""xin chào""",c'), ['a', 'nói "xin chào"', 'c']);
});

test('empty cells are preserved so column positions never shift', () => {
  assert.deepEqual(splitCsvLine('学生,,học sinh'), ['学生', '', 'học sinh']);
  assert.deepEqual(splitCsvLine('a,b,'), ['a', 'b', '']);
});

test('a semicolon file from a Vietnamese Excel is read as columns, not one cell', () => {
  const { headers, rows } = parseCsv('Từ vựng;Hiragana;Nghĩa\n学生;がくせい;học sinh');
  assert.deepEqual(headers, ['Từ vựng', 'Hiragana', 'Nghĩa']);
  assert.deepEqual(rows, [['学生', 'がくせい', 'học sinh']]);
});

test('a tab separated file is read too', () => {
  const { headers } = parseCsv('Từ vựng\tHiragana\tNghĩa\n学生\tがくせい\thọc sinh');
  assert.equal(headers.length, 3);
});

test('a UTF-8 BOM does not corrupt the first header', () => {
  // Excel trên Windows gần như luôn ghi BOM. Dính vào ô đầu thì header đầu
  // tiên không khớp alias nào, và người dùng nhận "thiếu cột từ vựng" trên
  // một file rõ ràng có cột đó.
  const { headers } = parseCsv('﻿Từ vựng,Hiragana,Nghĩa\n学生,がくせい,học sinh');
  assert.equal(headers[0], 'Từ vựng');
});

test('Windows line endings and trailing blank lines are handled', () => {
  const { rows } = parseCsv('a,b,c\r\n学生,がくせい,học sinh\r\n\r\n');
  assert.equal(rows.length, 1);
});

test('an empty file yields an empty report instead of throwing', () => {
  assert.deepEqual(parseCsv(''), { headers: [], rows: [] });
});

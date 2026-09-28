import assert from 'node:assert/strict';
import test from 'node:test';

import Excel from 'exceljs';

import {
  EXCEL_HEADERS,
  readWorkbookRows,
  toVocabularyRows,
} from '../src/modules/vocabulary/vocabulary-import.service.js';

const CONTEXT = { lesson: 'lesson-1', level: 'N5' };

test('map header tiếng Việt sang field trong DB', () => {
  const rows = toVocabularyRows(
    [
      {
        [EXCEL_HEADERS.word]: '学生',
        [EXCEL_HEADERS.hiragana]: 'がくせい',
        [EXCEL_HEADERS.meaning]: 'học sinh',
        [EXCEL_HEADERS.usage_context]: 'Trường học',
      },
    ],
    CONTEXT,
  );

  assert.deepEqual(rows, [
    {
      word: '学生',
      hiragana: 'がくせい',
      meaning: 'học sinh',
      usage_context: 'Trường học',
      lesson: 'lesson-1',
      level: 'N5',
      examples: [],
    },
  ]);
});

test('bỏ qua dòng thiếu cột bắt buộc', () => {
  const rows = toVocabularyRows(
    [
      { [EXCEL_HEADERS.word]: '本' },
      {
        [EXCEL_HEADERS.word]: '水',
        [EXCEL_HEADERS.hiragana]: 'みず',
        [EXCEL_HEADERS.meaning]: 'nước',
      },
    ],
    CONTEXT,
  );

  assert.equal(rows.length, 1);
  assert.equal(rows[0].word, '水');
});

test('tình huống trống được lưu là null', () => {
  const [row] = toVocabularyRows(
    [
      {
        [EXCEL_HEADERS.word]: '水',
        [EXCEL_HEADERS.hiragana]: 'みず',
        [EXCEL_HEADERS.meaning]: 'nước',
        [EXCEL_HEADERS.usage_context]: '   ',
      },
    ],
    CONTEXT,
  );

  assert.equal(row.usage_context, null);
});

test('ô rich text được lấy phần chữ, không phải object', () => {
  const [row] = toVocabularyRows(
    [
      {
        [EXCEL_HEADERS.word]: { richText: [{ text: '学' }, { text: '生' }] },
        [EXCEL_HEADERS.hiragana]: { text: 'がくせい' },
        [EXCEL_HEADERS.meaning]: 'học sinh',
      },
    ],
    CONTEXT,
  );

  assert.equal(row.word, '学生');
  assert.equal(row.hiragana, 'がくせい');
});

const workbookBuffer = async (rows) => {
  const workbook = new Excel.Workbook();
  const worksheet = workbook.addWorksheet('Tu Vung');
  rows.forEach((row) => worksheet.addRow(row));
  return Buffer.from(await workbook.xlsx.writeBuffer());
};

test('đọc file Excel thật thành mảng object theo header', async () => {
  const buffer = await workbookBuffer([
    [EXCEL_HEADERS.word, EXCEL_HEADERS.hiragana, EXCEL_HEADERS.meaning],
    ['学生', 'がくせい', 'học sinh'],
  ]);

  const rows = await readWorkbookRows(buffer);

  assert.equal(rows.length, 1);
  assert.equal(rows[0][EXCEL_HEADERS.word], '学生');
});

test('file thiếu cột bắt buộc báo lỗi 400 nêu rõ cột thiếu', async () => {
  const buffer = await workbookBuffer([
    [EXCEL_HEADERS.word, EXCEL_HEADERS.hiragana],
    ['学生', 'がくせい'],
  ]);

  await assert.rejects(
    () => readWorkbookRows(buffer),
    (error) =>
      error.status === 400 && error.message.includes(EXCEL_HEADERS.meaning),
  );
});

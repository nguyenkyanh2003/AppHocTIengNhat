import assert from 'node:assert/strict';
import test from 'node:test';

import Excel from 'exceljs';

import { cellText, readSheetRows } from '../src/shared/excel/sheet.js';

const workbookBuffer = async (rows) => {
  const workbook = new Excel.Workbook();
  const worksheet = workbook.addWorksheet('Kanji');
  rows.forEach((row) => worksheet.addRow(row));
  return Buffer.from(await workbook.xlsx.writeBuffer());
};

test('đọc sheet đầu thành object theo header', async () => {
  const rows = await readSheetRows(await workbookBuffer([['KyTuKanji', 'Nghia'], ['学', 'học']]), {
    requiredHeaders: ['KyTuKanji'],
  });

  assert.deepEqual(rows, [{ KyTuKanji: '学', Nghia: 'học' }]);
});

test('thiếu cột bắt buộc hay file không phải .xlsx là 400 đọc được', async () => {
  await assert.rejects(
    readSheetRows(await workbookBuffer([['KyTuKanji'], ['学']]), { requiredHeaders: ['KyTuKanji', 'Nghia'] }),
    (error) => error.status === 400 && error.message.includes('Nghia'),
  );
  await assert.rejects(
    readSheetRows(Buffer.from('không phải excel')),
    (error) => error.status === 400 && /xlsx/.test(error.message),
  );
});

test('ô rich text, công thức hay số đều đọc ra chữ', () => {
  assert.equal(cellText({ richText: [{ text: '学' }, { text: '生' }] }), '学生');
  assert.equal(cellText({ formula: 'A1', result: 5 }), '5');
  assert.equal(cellText(42), '42');
  assert.equal(cellText(null), '');
});

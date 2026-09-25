import assert from 'node:assert/strict';
import test from 'node:test';

import {
  contentHash,
  faststart,
  isFaststart,
  mp4Duration,
  readBoxes,
} from '../scripts/mp4-file.js';

/** Một hộp MP4: 4 byte kích thước, 4 byte tên, rồi nội dung. */
const box = (type, ...parts) => {
  const body = Buffer.concat(parts);
  const header = Buffer.alloc(8);
  header.writeUInt32BE(body.length + 8, 0);
  header.write(type, 4, 'latin1');
  return Buffer.concat([header, body]);
};

const u32 = (...values) => {
  const buffer = Buffer.alloc(values.length * 4);
  values.forEach((value, index) => buffer.writeUInt32BE(value, index * 4));
  return buffer;
};

/** `mvhd` bản 0: version/flags, creation, modification, timescale, duration. */
const mvhd = (timescale, duration) => box('mvhd', u32(0, 0, 0, timescale, duration));

const moovWith = (chunkOffsets, { timescale = 1000, duration = 36_800 } = {}) =>
  box(
    'moov',
    mvhd(timescale, duration),
    box('trak', box('mdia', box('minf', box('stbl', box('stco', u32(0, chunkOffsets.length, ...chunkOffsets)))))),
  );

/**
 * File "xuất thường": ftyp, mdat chứa hai khối dữ liệu, moov ở cuối trỏ về hai
 * khối đó bằng vị trí tuyệt đối trong file.
 */
const movieWithMoovAtEnd = () => {
  const ftyp = box('ftyp', Buffer.from('isom'), u32(0x200));
  const mdat = box('mdat', Buffer.from('FRAME-A!'), Buffer.from('FRAME-B!'));
  const firstChunk = ftyp.length + 8;
  return Buffer.concat([ftyp, mdat, moovWith([firstChunk, firstChunk + 8])]);
};

const chunkOffsetsOf = (file) => {
  const moov = readBoxes(file).find((b) => b.type === 'moov');
  const stco = file.indexOf('stco', moov.start);
  const count = file.readUInt32BE(stco + 8);
  return Array.from({ length: count }, (_, index) => file.readUInt32BE(stco + 12 + index * 4));
};

test('đọc được thời lượng từ mvhd', () => {
  assert.equal(mp4Duration(movieWithMoovAtEnd()), 36.8);
});

test('file moov ở cuối chưa faststart; sau khi dời thì moov đứng trước mdat', () => {
  const original = movieWithMoovAtEnd();
  assert.equal(isFaststart(original), false);

  const optimized = faststart(original);

  assert.deepEqual(readBoxes(optimized).map((b) => b.type), ['ftyp', 'moov', 'mdat']);
  assert.equal(isFaststart(optimized), true);
  assert.equal(optimized.length, original.length);
  assert.equal(mp4Duration(optimized), mp4Duration(original));
});

test('vị trí khối trong mục lục vẫn trỏ đúng dữ liệu hình sau khi dời', () => {
  const original = movieWithMoovAtEnd();
  const optimized = faststart(original);

  const read = (file) => chunkOffsetsOf(file).map((at) => file.toString('latin1', at, at + 8));
  assert.deepEqual(read(original), ['FRAME-A!', 'FRAME-B!']);
  assert.deepEqual(read(optimized), ['FRAME-A!', 'FRAME-B!']);
});

test('file đã faststart thì không làm gì', () => {
  const optimized = faststart(movieWithMoovAtEnd());
  assert.equal(faststart(optimized), null);
});

test('không phải MP4 thì báo lỗi rõ ràng chứ không trả file hỏng', () => {
  assert.throws(() => faststart(Buffer.from('đây không phải video')), /MP4|kích thước sai/);
  assert.throws(() => mp4Duration(box('ftyp', Buffer.from('isom'))), /moov/);
});

test('hai file cùng nội dung có cùng dấu vân tay, khác một byte là khác', () => {
  const a = movieWithMoovAtEnd();
  const b = Buffer.from(a);
  assert.equal(contentHash(a), contentHash(b));
  b[b.length - 1] ^= 1;
  assert.notEqual(contentHash(a), contentHash(b));
});

import { createHash } from 'node:crypto';

/**
 * Đọc và tối ưu file MP4 cho việc phát trên web, không cần ffmpeg.
 *
 * Trình phát chỉ bắt đầu được khi đã có hộp `moov` (mục lục của video: thời
 * lượng, vị trí từng khung hình). File quay/xuất thông thường đặt `moov` ở
 * **cuối**, nên trình duyệt phải tải phần đầu, phát hiện thiếu mục lục, rồi xin
 * thêm phần cuối file mới phát được — người học thấy vòng xoay lâu hơn hẳn.
 * [faststart] chuyển `moov` lên trước dữ liệu hình (`mdat`), giống
 * `ffmpeg -movflags +faststart`, để khung hình đầu hiện ngay.
 *
 * Toàn bộ là hàm thuần trên `Buffer`: test dựng file MP4 giả trong bộ nhớ.
 */

/** Hộp chứa hộp con trên đường từ `moov` tới bảng vị trí khối dữ liệu. */
const CONTAINERS = new Set(['moov', 'trak', 'mdia', 'minf', 'stbl']);

/**
 * Các hộp nằm liền nhau trong đoạn `[start, end)` của [buffer].
 *
 * @returns {{ type: string, start: number, size: number, header: number }[]}
 */
export const readBoxes = (buffer, start = 0, end = buffer.length) => {
  const boxes = [];
  let offset = start;
  while (offset + 8 <= end) {
    let size = buffer.readUInt32BE(offset);
    const type = buffer.toString('latin1', offset + 4, offset + 8);
    let header = 8;
    if (size === 1) {
      size = Number(buffer.readBigUInt64BE(offset + 8));
      header = 16;
    } else if (size === 0) {
      size = end - offset;
    }
    if (size < header || offset + size > end) {
      throw new Error(`Hộp "${type}" tại byte ${offset} có kích thước sai — file hỏng hoặc không phải MP4.`);
    }
    boxes.push({ type, start: offset, size, header });
    offset += size;
  }
  return boxes;
};

const requireBox = (boxes, type) => {
  const box = boxes.find((candidate) => candidate.type === type);
  if (!box) throw new Error(`File không có hộp "${type}" — không phải MP4 phát được.`);
  return box;
};

/** Thời lượng video tính bằng giây, đọc từ `moov/mvhd`. */
export const mp4Duration = (buffer) => {
  const moov = requireBox(readBoxes(buffer), 'moov');
  const mvhd = requireBox(readBoxes(buffer, moov.start + moov.header, moov.start + moov.size), 'mvhd');
  const body = mvhd.start + mvhd.header;
  const version = buffer.readUInt8(body);

  const timescale = version === 1 ? buffer.readUInt32BE(body + 20) : buffer.readUInt32BE(body + 12);
  const duration = version === 1
    ? Number(buffer.readBigUInt64BE(body + 24))
    : buffer.readUInt32BE(body + 16);
  if (timescale === 0) throw new Error('`mvhd` có timescale bằng 0.');
  return duration / timescale;
};

/** `true` khi mục lục `moov` đã nằm trước dữ liệu hình `mdat`. */
export const isFaststart = (buffer) => {
  const boxes = readBoxes(buffer);
  const moov = requireBox(boxes, 'moov');
  const mdat = requireBox(boxes, 'mdat');
  return moov.start < mdat.start;
};

/** Cộng [shift] vào mọi vị trí khối dữ liệu (`stco`/`co64`) trong [moov]. */
const shiftChunkOffsets = (moov, shift) => {
  const visit = (start, end) => {
    for (const box of readBoxes(moov, start, end)) {
      const body = box.start + box.header;
      if (CONTAINERS.has(box.type)) {
        visit(body, box.start + box.size);
      } else if (box.type === 'stco' || box.type === 'co64') {
        const wide = box.type === 'co64';
        const count = moov.readUInt32BE(body + 4);
        for (let index = 0; index < count; index += 1) {
          const at = body + 8 + index * (wide ? 8 : 4);
          if (wide) {
            moov.writeBigUInt64BE(moov.readBigUInt64BE(at) + BigInt(shift), at);
          } else {
            const value = moov.readUInt32BE(at) + shift;
            if (value > 0xffffffff) {
              throw new Error('Vị trí khối vượt 4 GB sau khi dời — file quá lớn, cần dùng ffmpeg.');
            }
            moov.writeUInt32BE(value, at);
          }
        }
      }
    }
  };
  visit(8, moov.length);
};

/**
 * Bản sao của [buffer] với `moov` dời lên ngay trước `mdat` đầu tiên, hoặc
 * `null` nếu file đã tối ưu sẵn.
 *
 * Dữ liệu hình không đổi một byte; chỉ mục lục bị dời và mọi vị trí khối trong
 * nó được cộng thêm đúng kích thước của chính nó.
 */
export const faststart = (buffer) => {
  const boxes = readBoxes(buffer);
  const moovBox = requireBox(boxes, 'moov');
  const firstMdat = requireBox(boxes, 'mdat');
  if (moovBox.start < firstMdat.start) return null;
  if (boxes.some((box) => box.type === 'mdat' && box.start > moovBox.start)) {
    throw new Error('`moov` nằm giữa hai hộp `mdat` — chưa hỗ trợ, cần dùng ffmpeg.');
  }
  if (moovBox.header !== 8) throw new Error('`moov` dùng kích thước 64-bit — chưa hỗ trợ.');

  const moov = Buffer.from(buffer.subarray(moovBox.start, moovBox.start + moovBox.size));
  shiftChunkOffsets(moov, moov.length);

  const before = boxes.filter((box) => box.start < firstMdat.start);
  const after = boxes.filter((box) => box.start >= firstMdat.start && box.type !== 'moov');
  const slice = (box) => buffer.subarray(box.start, box.start + box.size);

  return Buffer.concat([...before.map(slice), moov, ...after.map(slice)]);
};

/** Dấu vân tay nội dung, để phát hiện hai "video khác nhau" thực ra là một file. */
export const contentHash = (buffer) => createHash('sha256').update(buffer).digest('hex');

import { parseTimecode } from '../src/modules/lessons/lesson-video.review.js';

/**
 * Đọc lời thoại của video từ một file văn bản gõ tay.
 *
 * Lời thoại chạy theo video cần **mốc thời gian của từng câu**, mà mốc đó chỉ
 * có được khi ngồi xem video — không trích tự động từ file MP4 (video của bài
 * không kèm track phụ đề) và cũng không có trên trang nguồn. Vì phải gõ tay,
 * định dạng ở đây là văn bản thuần thay vì JSON: không dấu ngoặc, không dấu
 * phẩy cuối dòng, sai ở đâu báo đúng số dòng đó.
 *
 *   # dòng ghi chú
 *   ## scene-1.mp4
 *   00:04-00:07 | オウ / Ou | 佐藤さん、おはようございます。 | Satoo-san, ohayoo gozaimasu. | Chào buổi sáng anh Sato.
 *   00:08       |           | いい天気ですね。              |                             | Thời tiết đẹp nhỉ.
 *
 * Một dòng là một câu thoại, năm ô ngăn bằng `|`:
 *   1. `mốc bắt đầu` hoặc `bắt đầu-kết thúc` (`mm:ss`, `mm:ss:ff`, `hh:mm:ss:ff`);
 *   2. người nói `tiếng Nhật / tiếng Việt` — để trống nếu không cần;
 *   3. câu tiếng Nhật (bắt buộc);
 *   4. roma-ji — để trống thì app không hiện lớp roma-ji của câu đó;
 *   5. nghĩa tiếng Việt (bắt buộc).
 *
 * `## <tên file>` mở đầu phần lời thoại của một cảnh, khớp với tên file video
 * trong `uploads/lesson-videos/<bài>/`.
 *
 * Hàm thuần, không đọc đĩa — `apply-transcript.js` lo phần file.
 */

const FIELDS = 5;
const TIME_RANGE = /^([^-\s]+)(?:\s*-\s*([^-\s]+))?$/;

const splitSpeaker = (cell) => {
  const [ja, vi] = cell.split('/').map((part) => part.trim());
  return { speaker_ja: ja || null, speaker_vi: vi || null };
};

/** Một câu thoại, hoặc lỗi kèm số dòng để sửa đúng chỗ. */
const parseLine = (raw, lineNumber) => {
  const cells = raw.split('|').map((cell) => cell.trim());
  if (cells.length !== FIELDS) {
    return { error: `Dòng ${lineNumber}: cần đúng ${FIELDS} ô ngăn bằng "|", đang có ${cells.length}.` };
  }

  const [time, speaker, textJa, romaji, textVi] = cells;
  const range = TIME_RANGE.exec(time);
  if (!range) return { error: `Dòng ${lineNumber}: mốc thời gian "${time}" không đọc được.` };

  const [, start, end] = range;
  for (const value of [start, end]) {
    if (value !== undefined && parseTimecode(value) === null) {
      return { error: `Dòng ${lineNumber}: mốc thời gian "${value}" không đọc được (cần dạng mm:ss).` };
    }
  }
  if (end !== undefined && parseTimecode(end) < parseTimecode(start)) {
    return { error: `Dòng ${lineNumber}: mốc kết thúc "${end}" trước mốc bắt đầu "${start}".` };
  }
  if (!textJa) return { error: `Dòng ${lineNumber}: thiếu câu tiếng Nhật (ô thứ 3).` };
  if (!textVi) return { error: `Dòng ${lineNumber}: thiếu nghĩa tiếng Việt (ô thứ 5).` };

  return {
    line: {
      start,
      ...(end === undefined ? {} : { end }),
      ...splitSpeaker(speaker),
      text_ja: textJa,
      romaji: romaji || null,
      text_vi: textVi,
    },
  };
};

/**
 * @param text Nội dung file lời thoại.
 * @returns {{ scenes: Map<string, object[]>, errors: string[] }}
 *   `scenes` theo tên file video, giữ nguyên thứ tự xuất hiện trong file.
 */
export const parseTranscriptText = (text) => {
  const scenes = new Map();
  const errors = [];
  let current = null;

  text.split(/\r?\n/).forEach((raw, index) => {
    const lineNumber = index + 1;
    const content = raw.trim();
    if (content === '' || /^#(?!#)/.test(content)) return;

    const heading = /^##\s*(.+?)\s*$/.exec(content);
    if (heading) {
      current = heading[1];
      if (scenes.has(current)) errors.push(`Dòng ${lineNumber}: "${current}" đã có phần lời thoại ở trên.`);
      else scenes.set(current, []);
      return;
    }

    if (current === null) {
      errors.push(`Dòng ${lineNumber}: câu thoại nằm trước dòng "## <tên file video>".`);
      return;
    }

    const { line, error } = parseLine(content, lineNumber);
    if (error) errors.push(error);
    else scenes.get(current).push(line);
  });

  return { scenes, errors };
};

/**
 * Ghi lời thoại đã đọc vào file mô tả video của bài.
 *
 * Chỉ chạm những cảnh có trong file văn bản; cảnh khác giữ nguyên. Tên cảnh
 * không khớp video nào trong bài là lỗi — gõ nhầm tên file thì lời thoại rơi
 * vào hư không mà không ai biết.
 *
 * Tiêu đề cảnh chưa có dòng nào bên dưới được **bỏ qua**, không ghi đè bằng
 * mảng rỗng: đó là chỗ đang gõ dở, không phải lệnh xoá lời thoại đã có.
 */
export const applyTranscripts = ({ manifest, scenes }) => {
  const videos = manifest.videos ?? [];
  const errors = [];
  const applied = [];
  const empty = [];

  const updated = videos.map((video) => {
    const name = video.url.split('/').pop();
    const lines = scenes.get(name);
    if (!lines) return video;
    if (lines.length === 0) {
      empty.push(name);
      return video;
    }
    applied.push({ name, count: lines.length });
    return { ...video, transcript: lines };
  });

  const known = new Set(videos.map((video) => video.url.split('/').pop()));
  for (const name of scenes.keys()) {
    if (!known.has(name)) {
      errors.push(`Bài này không có cảnh "${name}". Các cảnh đang có: ${[...known].join(', ') || '(chưa có cảnh nào)'}.`);
    }
  }

  return { manifest: { ...manifest, videos: updated }, applied, empty, errors };
};

import { parseTimecode } from '../src/modules/lessons/lesson-video.review.js';

/**
 * Đọc nội dung học theo video từ một file văn bản gõ tay: lời thoại chạy theo
 * video (phần "Kịch bản"), câu then chốt (phần "Mẫu câu") và bảng từ vựng.
 *
 * Lời thoại chạy theo video cần **mốc thời gian của từng câu**, mà mốc đó chỉ
 * có được khi ngồi xem video. Vì phải gõ tay, định dạng ở đây là văn bản thuần
 * thay vì JSON: không dấu ngoặc, không dấu phẩy cuối dòng, sai ở đâu báo đúng
 * số dòng đó.
 *
 *   # dòng ghi chú
 *   ## scene-1.mp4
 *   00:05  | アンジェラ / Anjera / Angela | すみません。       | Sumimasen.             | Xin lỗi, cho tôi hỏi.
 *   *00:07 | アンジェラ / Anjera / Angela | 牛乳はどこですか。 | Gyuunyuu wa doko desu ka. | Sữa ở đâu ạ?
 *   ### từ vựng
 *   牛乳 | ぎゅうにゅう | gyuunyuu | sữa
 *
 * Một dòng là một câu thoại, năm ô ngăn bằng `|`:
 *   1. `mốc bắt đầu` hoặc `bắt đầu-kết thúc` (`mm:ss`, `mm:ss:ff`); thêm `*`
 *      ở đầu để đánh dấu câu then chốt của cảnh;
 *   2. người nói — `tiếng Nhật`, `tiếng Nhật / tiếng Việt`, hoặc đủ ba dạng
 *      `tiếng Nhật / roma-ji / tiếng Việt`; để trống nếu không cần;
 *   3. câu tiếng Nhật (bắt buộc);
 *   4. roma-ji — để trống thì app không hiện lớp roma-ji của câu đó;
 *   5. nghĩa tiếng Việt (bắt buộc).
 *
 * `## <tên file>` mở đầu một cảnh, khớp tên file video trong
 * `uploads/lesson-videos/<bài>/`. Sau `### từ vựng`, mỗi dòng là một từ:
 * `mặt chữ | cách đọc | roma-ji | nghĩa` cho tới cảnh kế tiếp.
 *
 * Hàm thuần, không đọc đĩa — `apply-transcript.js` lo phần file.
 */

const FIELDS = 5;
const WORD_FIELDS = 4;
const TIME_RANGE = /^([^-\s]+)(?:\s*-\s*([^-\s]+))?$/;
const VOCABULARY_HEADING = /^###\s*từ vựng\s*$/i;

/** `ja`, `ja / vi` hoặc `ja / romaji / vi`. */
const splitSpeaker = (cell) => {
  const parts = cell.split('/').map((part) => part.trim());
  const [ja, romaji, vi] = parts.length === 3 ? parts : [parts[0], undefined, parts[1]];
  return { speaker_ja: ja || null, speaker_romaji: romaji || null, speaker_vi: vi || null };
};

/** Một câu thoại, hoặc lỗi kèm số dòng để sửa đúng chỗ. */
const parseLine = (raw, lineNumber) => {
  const cells = raw.split('|').map((cell) => cell.trim());
  if (cells.length !== FIELDS) {
    return { error: `Dòng ${lineNumber}: cần đúng ${FIELDS} ô ngăn bằng "|", đang có ${cells.length}.` };
  }

  const [timeCell, speaker, textJa, romaji, textVi] = cells;
  const keyPhrase = timeCell.startsWith('*');
  const time = keyPhrase ? timeCell.slice(1).trim() : timeCell;
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
      key_phrase: keyPhrase,
    },
  };
};

/** Một từ trong bảng từ vựng: bắt buộc mặt chữ và nghĩa. */
const parseWord = (raw, lineNumber) => {
  const cells = raw.split('|').map((cell) => cell.trim());
  if (cells.length !== WORD_FIELDS) {
    return { error: `Dòng ${lineNumber}: từ vựng cần ${WORD_FIELDS} ô "mặt chữ | cách đọc | roma-ji | nghĩa", đang có ${cells.length}.` };
  }
  const [word, reading, romaji, meaning] = cells;
  if (!word) return { error: `Dòng ${lineNumber}: từ vựng thiếu mặt chữ.` };
  if (!meaning) return { error: `Dòng ${lineNumber}: từ vựng thiếu nghĩa.` };
  return { word: { word, reading: reading || null, romaji: romaji || null, meaning } };
};

/**
 * @param text Nội dung file lời thoại.
 * @returns {{ scenes: Map<string, { lines: object[], vocabulary: object[] }>, errors: string[] }}
 *   `scenes` theo tên file video, giữ nguyên thứ tự xuất hiện trong file.
 */
export const parseTranscriptText = (text) => {
  const scenes = new Map();
  const errors = [];
  let current = null;
  let inVocabulary = false;

  text.split(/\r?\n/).forEach((raw, index) => {
    const lineNumber = index + 1;
    const content = raw.trim();
    if (content === '') return;

    if (VOCABULARY_HEADING.test(content)) {
      if (current === null) errors.push(`Dòng ${lineNumber}: "### từ vựng" nằm trước dòng "## <tên file video>".`);
      else inVocabulary = true;
      return;
    }
    if (/^#(?!#)/.test(content)) return;

    const heading = /^##\s*(.+?)\s*$/.exec(content);
    if (heading) {
      current = heading[1];
      inVocabulary = false;
      if (scenes.has(current)) errors.push(`Dòng ${lineNumber}: "${current}" đã có phần lời thoại ở trên.`);
      else scenes.set(current, { lines: [], vocabulary: [] });
      return;
    }

    if (current === null) {
      errors.push(`Dòng ${lineNumber}: câu thoại nằm trước dòng "## <tên file video>".`);
      return;
    }

    const scene = scenes.get(current);
    if (inVocabulary) {
      const { word, error } = parseWord(content, lineNumber);
      if (error) errors.push(error);
      else scene.vocabulary.push(word);
    } else {
      const { line, error } = parseLine(content, lineNumber);
      if (error) errors.push(error);
      else scene.lines.push(line);
    }
  });

  return { scenes, errors };
};

/**
 * Ghi lời thoại và từ vựng đã đọc vào file mô tả video của bài.
 *
 * Chỉ chạm những cảnh có trong file văn bản; cảnh khác giữ nguyên. Tên cảnh
 * không khớp video nào trong bài là lỗi — gõ nhầm tên file thì nội dung rơi
 * vào hư không mà không ai biết.
 *
 * Phần còn trống của một cảnh (chưa gõ câu nào, hay chưa có bảng từ) được
 * **bỏ qua**, không ghi đè bằng mảng rỗng: đó là chỗ đang gõ dở, không phải
 * lệnh xoá nội dung đã có.
 */
export const applyTranscripts = ({ manifest, scenes }) => {
  const videos = manifest.videos ?? [];
  const errors = [];
  const applied = [];
  const empty = [];

  const updated = videos.map((video) => {
    const name = video.url.split('/').pop();
    const scene = scenes.get(name);
    if (!scene) return video;
    if (scene.lines.length === 0 && scene.vocabulary.length === 0) {
      empty.push(name);
      return video;
    }
    applied.push({ name, count: scene.lines.length, words: scene.vocabulary.length });
    return {
      ...video,
      ...(scene.lines.length > 0 ? { transcript: scene.lines } : {}),
      ...(scene.vocabulary.length > 0 ? { vocabulary: scene.vocabulary } : {}),
    };
  });

  const known = new Set(videos.map((video) => video.url.split('/').pop()));
  for (const name of scenes.keys()) {
    if (!known.has(name)) {
      errors.push(`Bài này không có cảnh "${name}". Các cảnh đang có: ${[...known].join(', ') || '(chưa có cảnh nào)'}.`);
    }
  }

  return { manifest: { ...manifest, videos: updated }, applied, empty, errors };
};

/**
 * Đọc tài liệu lời thoại dạng Markdown (mỗi video một bảng) thành các câu
 * thoại theo bài và theo file video.
 *
 * Khuôn tài liệu:
 *
 *   ## Bài 8 – Đi tàu điện
 *   ### 8. Ôn tập · …          → summary.mp4
 *   ### 8-1 · …                → scene-1.mp4
 *   | Thời gian | Người nói | Lời thoại |
 *   |:---:|:---:|---|
 *   | **00:05** | 男性客       | 静岡に行きたいです。 |     ← tiếng Nhật
 *   | | Dansee-kyaku | Shizuoka ni ikitai desu. |           ← roma-ji
 *   | | Khách nam    | Tôi muốn đi Shizuoka.   |             ← tiếng Việt
 *
 * Mỗi câu là ba hàng liền nhau: hàng có mốc thời gian (tiếng Nhật), rồi hai
 * hàng không mốc (roma-ji, tiếng Việt), cột người nói cũng theo ba dạng đó.
 * Người nói viết nghiêng (`*Chủ đề*`) là nhãn chứ không phải người — thẻ tiêu
 * đề trên màn hình — nên chỉ đứng ở lớp tiếng Việt.
 *
 * Hàm thuần, không đọc đĩa — `import-transcript-markdown.js` lo phần file.
 */

const LESSON_HEADING = /^##\s+Bài\s+(\d+)\b/;
const VIDEO_HEADING = /^###\s+(\d+)(?:-(\d+))?\.?\s/;
const TIME = /^\*\*(\d{1,2}:\d{2})\*\*$/;

const stripEmphasis = (text) => text.replace(/^\*+|\*+$/g, '').trim();

/** Ba ô của một hàng bảng `| a | b | c |`, hoặc `null` nếu không phải hàng dữ liệu. */
const cellsOf = (row) => {
  const cells = row.split('|').slice(1, -1).map((cell) => cell.trim());
  if (cells.length !== 3) return null;
  if (cells[0] === 'Thời gian' || /^:?-{3,}:?$/.test(cells[0])) return null;
  return cells;
};

/**
 * @returns {{
 *   lessons: Map<number, Map<string, { start, speaker, textJa, romaji, textVi }[]>>,
 *   errors: string[],
 * }}
 *   `lessons` theo số bài, rồi theo tên file video (`scene-1.mp4`, `summary.mp4`).
 *   `speaker` là `{ ja, romaji, vi }`, mỗi dạng có thể `null`.
 */
export const parseTranscriptMarkdown = (markdown) => {
  const lessons = new Map();
  const errors = [];
  let lesson = null;
  let video = null;
  let pending = null;

  const flush = () => {
    if (pending === null) return;
    if (pending.rows.length !== 3) {
      errors.push(`Dòng ${pending.lineNumber}: câu lúc ${pending.start} có ${pending.rows.length} hàng, cần đúng 3 (Nhật / roma-ji / Việt).`);
    } else {
      const [[jaSpeaker, textJa], [roSpeaker, romaji], [viSpeaker, textVi]] = pending.rows;
      const label = /^\*[^*].*\*$/.test(jaSpeaker);
      video.push({
        start: pending.start,
        speaker: label
          ? { ja: null, romaji: null, vi: stripEmphasis(jaSpeaker) || null }
          : { ja: jaSpeaker || null, romaji: roSpeaker || null, vi: viSpeaker || null },
        textJa: stripEmphasis(textJa),
        romaji: romaji || null,
        textVi: textVi,
      });
    }
    pending = null;
  };

  markdown.split(/\r?\n/).forEach((raw, index) => {
    const lineNumber = index + 1;
    const line = raw.trim();

    const lessonHeading = LESSON_HEADING.exec(line);
    if (lessonHeading) {
      flush();
      lesson = Number(lessonHeading[1]);
      if (!lessons.has(lesson)) lessons.set(lesson, new Map());
      video = null;
      return;
    }

    const videoHeading = VIDEO_HEADING.exec(line);
    if (videoHeading) {
      flush();
      const [, number, scene] = videoHeading;
      if (lesson === null || Number(number) !== lesson) {
        errors.push(`Dòng ${lineNumber}: video "${line}" không nằm dưới "## Bài ${number}".`);
        video = null;
        return;
      }
      const fileName = scene === undefined ? 'summary.mp4' : `scene-${scene}.mp4`;
      video = [];
      lessons.get(lesson).set(fileName, video);
      return;
    }

    if (!line.startsWith('|') || video === null) return;
    const cells = cellsOf(line);
    if (cells === null) return;

    const [time, speaker, text] = cells;
    if (time !== '') {
      flush();
      const match = TIME.exec(time);
      if (!match) {
        errors.push(`Dòng ${lineNumber}: mốc thời gian "${time}" không đọc được.`);
        return;
      }
      pending = { start: match[1].padStart(5, '0'), lineNumber, rows: [[speaker, text]] };
    } else if (pending !== null) {
      pending.rows.push([speaker, text]);
    }
  });
  flush();

  return { lessons, errors };
};

/**
 * Mốc thời gian cho file `.txt`. Tài liệu làm tròn xuống theo giây, nên hai
 * câu nói liền nhau có thể cùng một mốc; câu sau được lùi thêm nửa giây
 * (`:15` = 15/30 khung) để câu trước vẫn kịp được tô sáng.
 */
export const spreadTimecodes = (lines) =>
  lines.map((line, index) => {
    const same = index > 0 && lines[index - 1].start === line.start;
    return same ? `${line.start}:15` : line.start;
  });

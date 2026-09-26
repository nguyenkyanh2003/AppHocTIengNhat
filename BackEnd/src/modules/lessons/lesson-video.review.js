/** Cùng danh sách với `Lesson.videos.kind` — không import model để test khỏi cần Mongoose. */
const VIDEO_KINDS = ['scene', 'review'];

/**
 * Kiểm và chuẩn hoá dữ liệu video + lời thoại của bài học.
 *
 * Tách khỏi script nhập để test không cần MongoDB, giống
 * `vocabulary-tags.review.js`. Dữ liệu video là file soạn tay nên mọi lỗi phải
 * chỉ đúng video và đúng dòng, không lọc bỏ trong im lặng.
 */

/**
 * Đổi mốc thời gian của lời thoại sang **giây**.
 *
 * Nhận `mm:ss`, `mm:ss:ff` (ff = số khung hình, 30 khung/giây — định dạng của
 * bản ghi gốc) và `hh:mm:ss:ff`. Trả về `null` nếu không đọc được, để người
 * soạn sửa lại chứ không để lọt một dòng nhảy sai chỗ.
 */
export const parseTimecode = (value) => {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value !== 'string') return null;

  const parts = value.trim().split(':');
  if (parts.length < 2 || parts.length > 4) return null;
  if (parts.some((part) => !/^\d+$/.test(part))) return null;

  const numbers = parts.map(Number);
  const frames = parts.length >= 3 ? numbers.pop() : 0;
  const seconds = numbers.pop();
  const minutes = numbers.pop() ?? 0;
  const hours = numbers.pop() ?? 0;

  return hours * 3600 + minutes * 60 + seconds + frames / 30;
};

const REQUIRED_LINE_FIELDS = ['text_ja', 'text_vi'];

const reviewLine = (line, index) => {
  const errors = [];
  if (line === null || typeof line !== 'object') {
    return { errors: [`Lời thoại ${index + 1}: không phải object.`] };
  }

  const start = parseTimecode(line.start);
  const end = line.end === undefined || line.end === null ? null : parseTimecode(line.end);

  if (start === null) errors.push(`Lời thoại ${index + 1}: \`start\` không đọc được (${line.start}).`);
  if (line.end !== undefined && line.end !== null && end === null) {
    errors.push(`Lời thoại ${index + 1}: \`end\` không đọc được (${line.end}).`);
  }
  if (start !== null && end !== null && end < start) {
    errors.push(`Lời thoại ${index + 1}: \`end\` nhỏ hơn \`start\`.`);
  }
  for (const field of REQUIRED_LINE_FIELDS) {
    if (!line[field] || typeof line[field] !== 'string') {
      errors.push(`Lời thoại ${index + 1}: thiếu \`${field}\`.`);
    }
  }
  if (errors.length > 0) return { errors };

  return {
    errors: [],
    line: {
      start_seconds: start,
      end_seconds: end,
      speaker_ja: line.speaker_ja?.trim() || null,
      speaker_romaji: line.speaker_romaji?.trim() || null,
      speaker_vi: line.speaker_vi?.trim() || null,
      text_ja: line.text_ja.trim(),
      romaji: line.romaji?.trim() || null,
      text_vi: line.text_vi.trim(),
      key_phrase: line.key_phrase === true,
    },
  };
};

/** Một từ trong bảng từ vựng của video: bắt buộc mặt chữ và nghĩa. */
const reviewWord = (word, index) => {
  if (word === null || typeof word !== 'object') return { errors: [`Từ ${index + 1}: không phải object.`] };
  const errors = [];
  if (!word.word || typeof word.word !== 'string') errors.push(`Từ ${index + 1}: thiếu \`word\`.`);
  if (!word.meaning || typeof word.meaning !== 'string') errors.push(`Từ ${index + 1}: thiếu \`meaning\`.`);
  if (errors.length > 0) return { errors };
  return {
    errors: [],
    word: {
      word: word.word.trim(),
      reading: word.reading?.trim() || null,
      romaji: word.romaji?.trim() || null,
      meaning: word.meaning.trim(),
    },
  };
};

const reviewVideo = (video, index) => {
  const label = `Video ${index + 1}`;
  if (video === null || typeof video !== 'object') {
    return { errors: [`${label}: không phải object.`] };
  }

  const errors = [];
  if (!video.title || typeof video.title !== 'string') errors.push(`${label}: thiếu \`title\`.`);
  if (!video.url || typeof video.url !== 'string') errors.push(`${label}: thiếu \`url\`.`);
  const kind = video.kind ?? 'scene';
  if (!VIDEO_KINDS.includes(kind)) {
    errors.push(`${label}: \`kind\` phải là ${VIDEO_KINDS.join(' hoặc ')} (đang là "${video.kind}").`);
  }

  const transcript = [];
  const rawLines = Array.isArray(video.transcript) ? video.transcript : [];
  rawLines.forEach((rawLine, lineIndex) => {
    const result = reviewLine(rawLine, lineIndex);
    if (result.errors.length > 0) errors.push(...result.errors.map((e) => `${label} · ${e}`));
    else transcript.push(result.line);
  });

  const vocabulary = [];
  (Array.isArray(video.vocabulary) ? video.vocabulary : []).forEach((rawWord, wordIndex) => {
    const result = reviewWord(rawWord, wordIndex);
    if (result.errors.length > 0) errors.push(...result.errors.map((e) => `${label} · ${e}`));
    else vocabulary.push(result.word);
  });

  // Lời thoại phải tăng dần theo thời gian: giao diện tô sáng dòng đang nói
  // bằng cách quét từ trên xuống, thứ tự sai thì tô nhầm dòng.
  for (let i = 1; i < transcript.length; i += 1) {
    if (transcript[i].start_seconds < transcript[i - 1].start_seconds) {
      errors.push(`${label}: lời thoại ${i + 1} có mốc thời gian lùi về trước.`);
      break;
    }
  }

  if (errors.length > 0) return { errors };

  return {
    errors: [],
    video: {
      title: video.title.trim(),
      url: video.url.trim(),
      description: video.description?.trim() || null,
      source: video.source?.trim() || null,
      kind,
      transcript,
      vocabulary,
    },
  };
};

/**
 * @param {{ lesson: { title }, videos }} data Nội dung file dữ liệu.
 * @returns {{ videos: Array, errors: string[] }}
 */
export const reviewLessonVideos = (data) => {
  if (data === null || typeof data !== 'object') {
    return { videos: [], errors: ['File phải là một object JSON.'] };
  }
  if (!Array.isArray(data.videos) || data.videos.length === 0) {
    return { videos: [], errors: ['Thiếu danh sách `videos`.'] };
  }

  const videos = [];
  const errors = [];
  data.videos.forEach((video, index) => {
    const result = reviewVideo(video, index);
    if (result.errors.length > 0) errors.push(...result.errors);
    else videos.push(result.video);
  });

  // Hai cảnh trỏ cùng một file thì người học bấm "Cảnh 2" mà xem lại cảnh 1.
  const seen = new Map();
  videos.forEach((video, index) => {
    const first = seen.get(video.url);
    if (first === undefined) seen.set(video.url, index);
    else errors.push(`Video ${index + 1}: trùng \`url\` với video ${first + 1}.`);
  });

  return { videos, errors };
};

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const DATA_DIR = fileURLToPath(new URL('../data/lesson-videos/', import.meta.url));

/**
 * Câu then chốt ("Mẫu câu") trong kịch bản video của từng bài, theo tiêu đề
 * bài — nguồn câu hỏi cho bài tập hội thoại của bài có video, thay cho hội
 * thoại soạn sẵn.
 *
 * Đọc thẳng `data/lesson-videos/*.json` (đã commit cùng repo). Câu lặp lại
 * giữa cảnh và video ôn tập chỉ lấy một lần. Người nói là nhãn (thẻ chủ đề,
 * không có tên tiếng Nhật) thì bỏ, để câu hỏi không mở đầu bằng "Chủ đề:".
 *
 * @returns {Map<string, { speaker: string | null, text_ja: string, reading: string | null, text_vi: string }[]>}
 */
export const loadVideoKeyPhrases = (dir = DATA_DIR) => {
  const byLesson = new Map();
  const names = fs.readdirSync(dir).filter((name) => /^n5-\d{2}-.+\.json$/.test(name)).sort();

  for (const name of names) {
    const manifest = JSON.parse(fs.readFileSync(path.join(dir, name), 'utf8'));
    const seen = new Set();
    const phrases = [];
    for (const video of manifest.videos ?? []) {
      for (const line of video.transcript ?? []) {
        if (!line.key_phrase || seen.has(line.text_ja)) continue;
        seen.add(line.text_ja);
        phrases.push({
          speaker: line.speaker_ja ? (line.speaker_vi ?? line.speaker_ja) : null,
          text_ja: line.text_ja,
          reading: line.romaji ?? null,
          text_vi: line.text_vi,
        });
      }
    }
    if (phrases.length > 0) byLesson.set(manifest.lesson.title, phrases);
  }
  return byLesson;
};

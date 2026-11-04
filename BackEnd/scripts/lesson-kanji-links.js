import { kanjiCharacters } from '../src/modules/vocabulary/vocabulary-kanji.js';

/**
 * Gắn Kanji vào bài học (spec Kanji SRS, Đợt 2).
 *
 * Mỗi chữ chỉ được giới thiệu **một lần**: ở bài đầu tiên của chương trình
 * (N5 → N1, trong cùng cấp theo `order`) có chữ đó trong từ vựng. Gặp lại chữ ở
 * bài sau thì người học đã có nó trong lịch ôn, không cần học lại từ đầu.
 *
 * Chỉ thêm, không gỡ: chữ đã thuộc một bài thì giữ nguyên chỗ, nên chạy lại sau
 * khi bổ sung Kanji mới vào seed chỉ gắn thêm các chữ mới.
 */
const LEVELS = ['N5', 'N4', 'N3', 'N2', 'N1'];

const curriculumOrder = (a, b) =>
  LEVELS.indexOf(a.level) - LEVELS.indexOf(b.level) ||
  (a.order ?? 0) - (b.order ?? 0) ||
  String(a._id).localeCompare(String(b._id));

/**
 * Chữ bài đang có, đọc đúng như `lesson-progress.repository`: mảng `kanjis` của
 * bài, hoặc — khi mảng rỗng — các chữ trỏ ngược về bài qua `Kanji.lessonId`.
 */
const currentKanjiIds = (lesson, kanjis) =>
  lesson.kanjis?.length > 0
    ? lesson.kanjis.map(String)
    : kanjis.filter((kanji) => String(kanji.lessonId) === String(lesson._id)).map((kanji) => String(kanji._id));

/**
 * @param lessons  `{ _id, title, level, order, kanjis, words }` — `words` là mặt chữ
 *                 các từ vựng của bài, theo thứ tự trong bài.
 * @param kanjis   `{ _id, character, lessonId }`
 * @returns `updates`: bài cần ghi lại mảng `kanjis` (đầy đủ, chữ cũ trước chữ mới);
 *          `unmatched`: chữ không có trong từ vựng của bài nào.
 */
export const planLessonKanjiLinks = ({ lessons, kanjis }) => {
  const current = new Map(lessons.map((lesson) => [String(lesson._id), currentKanjiIds(lesson, kanjis)]));
  const linked = new Set([...current.values()].flat());
  const free = new Map(
    kanjis.filter((kanji) => !linked.has(String(kanji._id))).map((kanji) => [kanji.character, kanji]),
  );

  const updates = [];
  for (const lesson of [...lessons].sort(curriculumOrder)) {
    const picked = [];
    for (const character of lesson.words.flatMap(kanjiCharacters)) {
      const kanji = free.get(character);
      if (!kanji) continue;
      free.delete(character);
      picked.push(kanji);
    }
    if (picked.length === 0) continue;

    updates.push({
      lessonId: lesson._id,
      title: lesson.title,
      kanjiIds: [...current.get(String(lesson._id)), ...picked.map((kanji) => String(kanji._id))],
      added: picked.map((kanji) => kanji.character),
    });
  }

  return { updates, unmatched: [...free.keys()] };
};

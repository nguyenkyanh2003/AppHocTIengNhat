import {
  DIFFICULTIES,
  TOPIC_LEVELS,
  TOPICS,
  WORD_TYPES,
} from './vocabulary-taxonomy.js';

/**
 * Chia từ vựng của một cấp thành các **bộ học** khoảng 20 từ.
 *
 * Bộ không lưu trong DB mà được tính lại từ `topic` / `word_type` /
 * `difficulty` mỗi lần hỏi. Lưu bộ thành collection riêng thì mỗi lần nhập
 * thêm từ hay sửa nhãn lại phải đồng bộ hai nơi; tính lại thì một cấp chỉ
 * khoảng 1.000 từ, rẻ, và luôn khớp dữ liệu.
 *
 * Cách chia (xem `vocabulary-taxonomy.js`):
 * - N5, N4: theo chủ đề — mỗi chủ đề là một nhóm.
 * - N3–N1: theo độ khó rồi đến từ loại — "Cơ bản · Động từ" là một nhóm.
 *   Nhóm theo độ khó trước để người học đi hết phần cơ bản của mọi từ loại
 *   rồi mới lên phần khó hơn, như thứ tự unit của Mimikara Oboeru.
 *
 * Mỗi nhóm cắt thành các phần đều nhau, không phần nào quá `SET_SIZE` từ.
 * Cắt đều (23 từ → 12 + 11) thay vì cắt cứng 20 (→ 20 + 3) để không có bộ
 * lẻ vài từ trông như bị bỏ sót.
 */

export const SET_SIZE = 20;

// Id có dạng `N5.food.1` (cấp.chủ đề.phần), `N3.1.v.2` (cấp.độ khó.từ
// loại.phần) hoặc `N3.x.other.1`: đọc được bằng mắt và không phụ thuộc `_id`
// của MongoDB.
export const SET_ID_PATTERN = /^(N[1-5])\.([a-z0-9]+(?:\.[a-z]+)?)\.(\d+)$/;

const TOPIC_ORDER = Object.keys(TOPICS);

/** Tên riêng trong giáo trình không phải từ để học, không đưa vào bộ nào. */
const HIDDEN_TOPICS = new Set(['proper']);

export const levelOfSetId = (setId) => SET_ID_PATTERN.exec(setId)?.[1] ?? null;

const topicGroups = (words) => {
  const groups = new Map();
  for (const word of words) {
    if (!word.topic || HIDDEN_TOPICS.has(word.topic)) continue;
    if (!groups.has(word.topic)) groups.set(word.topic, []);
    groups.get(word.topic).push(word);
  }

  return [...groups.entries()]
    .sort(([a], [b]) => TOPIC_ORDER.indexOf(a) - TOPIC_ORDER.indexOf(b))
    .map(([topic, items]) => ({
      key: topic,
      title: TOPICS[topic],
      section: null,
      items,
    }));
};

/**
 * Từ loại dùng để chia bộ ở N3–N1. Gộp tính từ い/な làm một, và gộp các từ
 * loại hiếm (liên từ, cụm từ, ...) thành "Từ khác" không chia độ khó: tách
 * riêng thì N3 có bộ chỉ 1–2 từ, vô nghĩa để học.
 */
const SET_WORD_TYPES = Object.freeze({
  n: { key: 'n', title: WORD_TYPES.n },
  v: { key: 'v', title: WORD_TYPES.v },
  ai: { key: 'adj', title: 'Tính từ' },
  ana: { key: 'adj', title: 'Tính từ' },
  adv: { key: 'adv', title: WORD_TYPES.adv },
});
const OTHER_GROUP = Object.freeze({ key: 'other', title: 'Từ nối & cụm từ' });
const GROUP_ORDER = ['n', 'v', 'adj', 'adv'];
// Nhóm "khác" đứng sau mọi mức độ khó.
const OTHER_RANK = 99;

const wordTypeGroups = (words) => {
  const groups = new Map();
  for (const word of words) {
    if (!word.word_type || !word.difficulty) continue;

    const type = SET_WORD_TYPES[word.word_type];
    const group = type
      ? { ...type, difficulty: word.difficulty, rank: word.difficulty * 10 + GROUP_ORDER.indexOf(type.key) }
      : { ...OTHER_GROUP, difficulty: 'x', rank: OTHER_RANK };
    const key = `${group.difficulty}.${group.key}`;

    if (!groups.has(key)) groups.set(key, { group, items: [] });
    groups.get(key).items.push(word);
  }

  return [...groups.entries()]
    .sort(([, a], [, b]) => a.group.rank - b.group.rank)
    .map(([key, { group, items }]) => ({
      key,
      title: group.title,
      section: DIFFICULTIES[group.difficulty] ?? 'Từ khác',
      items,
    }));
};

const split = (items) => {
  const parts = Math.ceil(items.length / SET_SIZE);
  const size = Math.ceil(items.length / parts);
  return Array.from({ length: parts }, (_, index) =>
    items.slice(index * size, (index + 1) * size),
  );
};

/**
 * @param {string} level Cấp của mọi từ trong `words`.
 * @param {Array<{_id, topic?, word_type?, difficulty?}>} words Đã sắp theo
 *   thứ tự muốn học (repository sắp theo `_id`, tức thứ tự nhập từ giáo trình).
 * @returns {Array<{id, level, title, section, part, partCount, wordIds}>}
 */
export const buildSets = (level, words) => {
  const groups = TOPIC_LEVELS.includes(level)
    ? topicGroups(words)
    : wordTypeGroups(words);

  return groups.flatMap(({ key, title, section, items }) => {
    const parts = split(items);
    return parts.map((part, index) => ({
      id: `${level}.${key}.${index + 1}`,
      level,
      title,
      section,
      part: index + 1,
      partCount: parts.length,
      wordIds: part.map((word) => String(word._id)),
    }));
  });
};

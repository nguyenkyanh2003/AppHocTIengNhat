/**
 * Tiêu chí huy hiệu mà **server tự xác minh được**, dưới dạng hàm thuần.
 *
 * Mỗi huy hiệu được quy về một số đo trên dữ liệu server đã ghi — không có
 * đường nào nhận tiến độ do client khai (đó là lý do `update-progress` bị gỡ,
 * spec streak §3.6). Huy hiệu có tổ hợp `category`/`requirement_type` không
 * quy được về số đo nào thì **không bao giờ tự cấp**.
 */

/** Số đo cho huy hiệu đếm (`count`/`completion`), theo nhóm. */
const COUNT_METRICS = Object.freeze({
  vocabulary: 'learnedVocabulary',
  kanji: 'learnedKanji',
  grammar: 'learnedGrammar',
  lesson: 'completedLessons',
  practice: 'exerciseSubmissions',
  streak: 'currentStreak',
  xp: 'totalXp',
});

/** Số đo lấy từ tóm tắt streak; các số đo còn lại phải đếm trong DB. */
export const SNAPSHOT_METRICS = Object.freeze(['currentStreak', 'totalXp']);

/** Tên số đo mà một huy hiệu dùng, hoặc `null` nếu server không xác minh được. */
export const metricOf = ({ category, requirement_type: type }) => {
  if (type === 'streak') return 'currentStreak';
  if (type === 'xp') return 'totalXp';
  if (type === 'count' || type === 'completion') return COUNT_METRICS[category] ?? null;
  return null;
};

const target = (achievement) =>
  Number.isSafeInteger(achievement.requirement_value) && achievement.requirement_value > 0
    ? achievement.requirement_value
    : null;

/** Đã đạt tiêu chí chưa. Ngưỡng hỏng (0, âm, không nguyên) thì không bao giờ đạt. */
export const isUnlocked = (achievement, metrics) => {
  const metric = metricOf(achievement);
  const goal = target(achievement);
  return metric !== null && goal !== null && (metrics[metric] ?? 0) >= goal;
};

/** Tiến độ hiển thị, chặn ở ngưỡng để thanh tiến độ không vượt 100%. */
export const progressOf = (achievement, metrics) => {
  const metric = metricOf(achievement);
  const goal = target(achievement);
  if (metric === null || goal === null) return 0;
  return Math.min(metrics[metric] ?? 0, goal);
};

/** Những số đo cần đếm trong DB để xét một tập huy hiệu — không đếm thừa. */
export const countedMetricsFor = (achievements) => [
  ...new Set(
    achievements
      .map(metricOf)
      .filter((metric) => metric !== null && !SNAPSHOT_METRICS.includes(metric)),
  ),
];

import { POLICY_VERSION, xpFor } from '../src/modules/streaks/streak-policy.js';
import { addDays, daysBetween } from '../src/modules/streaks/streak-rules.js';

/**
 * Lịch sử học dựng sẵn cho tài khoản demo — dữ liệu thuần, `seed-demo.js` lo
 * phần ghi.
 *
 * Mục đích là để màn streak, heatmap, lịch sử XP, bảng xếp hạng và huy hiệu có
 * nội dung như khi mở một app học thật sau vài tuần sử dụng. Ba nguyên tắc:
 *
 * 1. **Mọi event đều có dữ liệu thật đứng sau.** Lượt ôn trỏ vào thẻ SRS có
 *    thật của user; lượt nộp bài đi kèm một `ExerciseResult` với bài làm từng
 *    câu trên bài tập có thật. XP lấy từ `streak-policy`, không tự đặt số.
 * 2. **Tất định.** Mỗi tài khoản có hạt giống riêng (theo username), nên chạy
 *    lại cho đúng cùng một lịch sử; khoá event gắn với ngày nên không nhân bản.
 * 3. **Không đè hoạt động thật.** Hôm nay để trống cho người demo tự học; ngày
 *    đã có hoạt động thật thì runner bỏ qua.
 */

/** Hạt giống 32-bit từ một chuỗi (FNV-1a). */
const hashOf = (text) => {
  let hash = 0x811c9dc5;
  for (const char of text) {
    hash ^= char.codePointAt(0);
    hash = Math.imul(hash, 0x01000193);
  }
  return hash >>> 0;
};

/** Bộ sinh số giả ngẫu nhiên có hạt giống (mulberry32) — cùng hạt giống, cùng dãy số. */
export const seededRandom = (seed) => {
  let state = hashOf(seed);
  return () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
};

const between = (random, [min, max]) => min + Math.floor(random() * (max - min + 1));

/** Mốc thời gian giờ Việt Nam của một ngày, cộng thêm số giây. */
const atVietnamTime = (day, minuteOfDay, extraSeconds = 0) => {
  const hours = String(Math.floor(minuteOfDay / 60)).padStart(2, '0');
  const minutes = String(minuteOfDay % 60).padStart(2, '0');
  return new Date(new Date(`${day}T${hours}:${minutes}:00+07:00`).getTime() + extraSeconds * 1000);
};

/**
 * Những ngày có học: `days` ngày gần nhất **trước** hôm nay, trừ các ngày nghỉ
 * (`missedOffsets`, tính từ hôm qua là 1). Mới nhất trước.
 */
export const studyDays = ({ todayKey, days, missedOffsets = [] }) =>
  Array.from({ length: days }, (_, index) => index + 1)
    .filter((offset) => !missedOffsets.includes(offset))
    .map((offset) => addDays(todayKey, -offset));

/**
 * Bài làm cho một bài tập: `correctCount` câu đầu chọn đúng, các câu còn lại
 * chọn đáp án sai đầu tiên — chấm lại bằng chính đề ra đúng điểm đã ghi.
 */
const answerSheet = (exercise, correctCount) =>
  exercise.questions.map((question, index) => {
    const correct = question.answers.find((answer) => answer.is_correct);
    const chosen = index < correctCount ? correct : question.answers.find((answer) => !answer.is_correct);
    return {
      question_id: question._id,
      answer_id: chosen._id,
      is_correct: chosen === correct,
      correct_answer_id: correct._id,
    };
  });

/**
 * Nhật ký học của một user trong khoảng ngày cho trước.
 *
 * @param cardIds    `_id` các thẻ SRS có thật của user — nguồn của lượt ôn.
 * @param exercises  Bài tập có thật kèm câu hỏi và đáp án (có `_id`).
 * @param skipDays   Ngày đã có hoạt động thật — không dựng gì cho ngày đó.
 */
export const buildDemoJournal = ({ userId, username, profile, todayKey, cardIds, exercises, skipDays = new Set() }) => {
  const random = seededRandom(username);
  const events = [];
  const days = [];
  const results = [];

  const daysToBuild = studyDays({ todayKey, days: profile.days, missedOffsets: profile.missedOffsets }).reverse();
  daysToBuild.forEach((day, dayIndex) => {
    // Rút số ngẫu nhiên cho **mọi** ngày, kể cả ngày bỏ qua, để thêm một ngày
    // hoạt động thật không làm lệch lịch sử dựng sẵn của các ngày khác.
    const reviewCount = cardIds.length === 0 ? 0 : between(random, profile.reviewsPerDay);
    const sessionStart = between(random, [6 * 60 + 30, 8 * 60 + 30]);
    const flips = Array.from({ length: reviewCount }, () => random() < profile.accuracy);
    const practises = exercises.length > 0 && dayIndex % profile.exerciseEvery === 0;
    const exerciseAccuracy = Math.min(1, profile.accuracy + (random() - 0.5) * 0.3);
    const eveningStart = between(random, [19 * 60, 21 * 60 + 30]);
    const secondsPerQuestion = between(random, [8, 20]);
    if (skipDays.has(day)) return;

    const dayEvents = flips.map((remembered, index) => ({
      user: userId,
      event_key: `demo:${day}:srs:${index}`,
      type: 'srs.review',
      source_id: String(cardIds[(dayIndex * 7 + index) % cardIds.length]),
      occurred_at: atVietnamTime(day, sessionStart, index * 25),
      day_key: day,
      xp_delta: xpFor('srs.review'),
      reason: 'srs.review',
      counts_as_study: true,
      policy_version: POLICY_VERSION,
    }));

    if (practises) {
      const exercise = exercises[Math.floor(dayIndex / profile.exerciseEvery) % exercises.length];
      const total = exercise.questions.length;
      const correctCount = Math.round(total * exerciseAccuracy);
      const score = Math.round((correctCount / total) * 100);
      const passed = score >= (exercise.pass_score ?? 60);
      const completedAt = atVietnamTime(day, eveningStart);
      results.push({
        user_id: userId,
        exercise_id: exercise._id,
        score,
        correct_count: correctCount,
        total_questions: total,
        time_spent: total * secondsPerQuestion,
        user_answers: answerSheet(exercise, correctCount),
        is_passed: passed,
        completed_at: completedAt,
      });
      dayEvents.push({
        user: userId,
        event_key: `demo:${day}:exercise`,
        type: 'exercise.submit',
        source_id: String(exercise._id),
        occurred_at: completedAt,
        day_key: day,
        xp_delta: xpFor('exercise.submit', { passed }),
        reason: 'exercise.submit',
        counts_as_study: true,
        policy_version: POLICY_VERSION,
      });
    }

    if (dayEvents.length === 0) return;
    events.push(...dayEvents);
    days.push({
      user: userId,
      day_key: day,
      status: 'studied',
      origin: 'activity',
      direct_xp: dayEvents.reduce((sum, event) => sum + event.xp_delta, 0),
      review_count: flips.length,
      correct_self_reports: flips.filter(Boolean).length,
      wrong_self_reports: flips.filter((remembered) => !remembered).length,
    });
  });

  return { events, days, results };
};

/**
 * Tóm tắt streak **suy ra từ nhật ký** — cùng định nghĩa với đường ghi: chuỗi
 * hiện tại là số ngày học liền nhau kết thúc ở ngày học gần nhất, chuỗi dài
 * nhất là đoạn liền nhau dài nhất.
 *
 * @param studiedDays  Mọi ngày `studied` của user (không tính ngày legacy chưa xác minh).
 * @param totalXp      Tổng `xp_delta` của mọi event của user.
 */
export const summarizeJournal = ({ studiedDays, totalXp }) => {
  const sorted = [...new Set(studiedDays)].sort();
  let longest = 0;
  let run = 0;
  sorted.forEach((day, index) => {
    run = index > 0 && daysBetween(sorted[index - 1], day) === 1 ? run + 1 : 1;
    longest = Math.max(longest, run);
  });
  return {
    current_streak: run,
    longest_streak: longest,
    last_activity_day: sorted.at(-1) ?? null,
    tracking_started_day: sorted[0] ?? null,
    total_active_days: sorted.length,
    total_xp: totalXp,
  };
};

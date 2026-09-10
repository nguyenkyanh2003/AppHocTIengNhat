import { ApiError } from '../../shared/http/api-error.js';
import { streakRepository } from './streak.repository.js';
import { applyActivity, dayKey, projectStreak } from './streak-rules.js';

/**
 * XP của từng loại hoạt động, quyết định ở server.
 *
 * Trước đây mỗi module tự chọn số XP và endpoint `/streak/add-xp` còn nhận
 * `amount` thẳng từ client mà không có trần. Bảng này là nguồn duy nhất —
 * `recordActivity` không bao giờ đọc `amount` từ tham số gọi vào.
 */
export const XP_BY_ACTIVITY = Object.freeze({
  'srs.review': 2,
  'lesson.progress': 5,
  'exercise.submit': 10,
  'lesson.complete': 15,
  'jlpt.submit': 20,
});

/**
 * Hoạt động chỉ được thưởng một lần cho mỗi `sourceId` — chống trùng dựa vào
 * `reward_keys` sẵn có trên `UserStreak`.
 *
 * `srs.review` cố ý **không** nằm trong tập này: một thẻ được ôn lại nhiều
 * lần trong đời nó (đến hạn lại, ôn sai rồi ôn đúng...), nên khoá theo
 * `sourceId` sẽ chỉ cho thưởng đúng một lần đầu tiên rồi khoá cứng luôn thẻ
 * đó — sai với nghiệp vụ SRS. Tính duy nhất trong-một-ngày của SRS do tầng
 * SRS tự lo bằng cập nhật có điều kiện (`casApplyAnswer`), không phải ở đây;
 * nếu thêm khoá cho `srs.review` thì `reward_keys` phình vô hạn theo số lượt
 * ôn — đúng cái bệnh mà đường ghi nhận này được tạo ra để sửa.
 */
const ONE_SHOT = new Set(['lesson.complete', 'lesson.progress', 'exercise.submit', 'jlpt.submit']);

/**
 * Một thang mốc duy nhất, dùng cho cả thưởng XP lẫn huy hiệu — tránh lặp lại
 * lỗi cũ ở `streak.controller.js` (dùng `% 7` / `% 30`, không khớp danh sách
 * mốc thật của bảng `Achievement`, và không dừng lại khi vượt mốc cuối).
 */
export const STREAK_MILESTONES = Object.freeze([7, 14, 30, 50, 100, 365]);

export const createStreakService = ({
  repository = streakRepository,
  rules = { applyActivity, dayKey, projectStreak },
} = {}) => ({
  /**
   * Ghi nhận một hoạt động học đã hoàn thành — đường duy nhất được phép
   * cộng XP và tăng streak, thay cho ba cách ghi cũ (`UserStreak.addXP`,
   * `updateStreakOnActivity`, và `findOneAndUpdate` tay của JLPT không bao
   * giờ tăng chuỗi).
   *
   * Chỉ gọi **sau khi** nghiệp vụ của hoạt động đã ghi thành công (đã lưu
   * bài nộp, đã lưu lượt ôn...). Hàm nhận `session` và truyền xuống mọi lệnh
   * repository để chạy trong cùng transaction với lệnh ghi đó — lỗi ở đây
   * rollback luôn cả phần nghiệp vụ, không để XP "mồ côi" khi phần kia lỗi.
   *
   * `correct`/`score`... (nếu người gọi truyền vào) không ảnh hưởng gì: trả
   * lời sai vẫn là một hoạt động học, chuỗi và XP không phân biệt đúng/sai —
   * quyết định gọi hay không gọi hàm này thuộc về tầng nghiệp vụ đang xử lý
   * đáp án, không phải ở đây.
   */
  async recordActivity({ userId, type, sourceId, now = new Date(), session }) {
    const xp = XP_BY_ACTIVITY[type];
    if (xp === undefined) {
      throw ApiError.badRequest('Loại hoạt động không hợp lệ.', {
        code: 'UNKNOWN_ACTIVITY_TYPE',
      });
    }

    const current = await repository.ensureFor({ userId, session });
    // Chỉ hoạt động một-lần mới có rewardKey — xem giải thích ở khai báo
    // ONE_SHOT. `srs.review` để `undefined`: không lọc, không ghi mảng.
    //
    // Vòng sửa 1: không còn đọc `current.reward_keys` để tự quyết "đã thưởng
    // chưa" ở đây — đọc rồi set tuyệt đối ở repository chính là nguyên nhân
    // mất cập nhật khi hai hoạt động one-shot khác nhau về cùng lúc trong
    // ngày (xem comment ở `casUpdate`). Điều kiện chống trùng chuyển hẳn vào
    // filter CAS; service chỉ còn việc tính patch rồi để repository quyết
    // nguyên tử trong một lệnh ghi duy nhất.
    const isOneShot = ONE_SHOT.has(type);
    const rewardKey = isOneShot ? `${type}:${sourceId}` : undefined;

    const todayKey = rules.dayKey(now);
    const next = rules.applyActivity(
      {
        currentStreak: current.current_streak,
        longestStreak: current.longest_streak,
        lastActivityDay: current.last_activity_day,
        freezesAvailable: current.freezes_available,
      },
      todayKey,
    );

    // Chỉ còn các trường streak tính lại mỗi lần — total_xp cộng qua $inc,
    // reward_keys ghi qua $addToSet, cả hai làm ở casUpdate, không phải patch
    // tuyệt đối ở đây (patch tuyệt đối là đúng thứ gây ra lỗi Vòng sửa 1).
    const patch = {
      current_streak: next.currentStreak,
      longest_streak: next.longestStreak,
      last_activity_day: next.lastActivityDay,
      freezes_available: current.freezes_available - next.freezesUsed,
    };

    const saved = await repository.casUpdate({
      userId,
      expectedDay: current.last_activity_day,
      patch,
      xpDelta: xp,
      rewardKey,
      session,
    });

    // Thua CAS giờ có hai nguyên nhân khác nhau, cả hai đều nằm trong cùng
    // một filter nguyên tử ở casUpdate nên không phân biệt được ở đây bằng
    // gì khác ngoài đọc lại — nhưng đáng phân biệt vì ý nghĩa nghiệp vụ khác
    // nhau (dù kết quả trả về hiện tại giống nhau: không cộng XP, không ghi
    // ngày, không tiêu băng lần nữa):
    // - đã thưởng rồi (gửi lại cùng sourceId của hoạt động one-shot — double
    //   submit, retry sau timeout): không phải do đua với ai.
    // - một request khác (thiết bị khác, retry trùng lúc) đã đẩy
    //   last_activity_day trước — hoạt động này thật sự bị "thua" vào tay
    //   một request khác đang cùng học.
    if (!saved) {
      const latest = await repository.findByUser({ userId, session });
      const alreadyRewarded = isOneShot && (latest?.reward_keys ?? []).includes(rewardKey);
      const currentStreak = latest?.current_streak ?? current.current_streak;

      if (alreadyRewarded) {
        return { currentStreak, isNewDay: false, xpAwarded: 0, milestonesReached: [] };
      }
      return { currentStreak, isNewDay: false, xpAwarded: 0, milestonesReached: [] };
    }

    // Chỉ ghi appendXpEvent/markDay SAU KHI CAS thắng — hai lệnh này không có
    // điều kiện, nếu gọi trước khi biết CAS thắng hay thua thì bên thua vẫn
    // để lại một bản ghi XP mồ côi không tương ứng streak nào được cập nhật.
    await repository.appendXpEvent({
      userId,
      amount: xp,
      reason: type,
      type,
      sourceId,
      earnedAt: now,
      session,
    });
    await repository.markDay({ userId, dayKey: todayKey, status: 'studied', session });
    // Những ngày băng đã bảo vệ (nghỉ nhưng có băng che) chỉ được đánh dấu
    // lịch, không cộng XP — không ai "học" vào ngày đó cả, băng chỉ giữ chuỗi.
    for (const frozenDay of next.frozenDays) {
      await repository.markDay({ userId, dayKey: frozenDay, status: 'frozen', session });
    }

    // Mốc chỉ được coi là "chạm" ở đúng ngày chuỗi tăng lên đúng giá trị đó —
    // dùng so sánh bằng (không phải >=) để một mốc chỉ trả về đúng một lần,
    // không lặp lại ở mọi ngày sau đó chuỗi vẫn còn lớn hơn mốc.
    const milestonesReached = next.isNewDay
      ? STREAK_MILESTONES.filter((milestone) => milestone === next.currentStreak)
      : [];

    return {
      currentStreak: next.currentStreak,
      isNewDay: next.isNewDay,
      xpAwarded: xp,
      milestonesReached,
    };
  },

  /**
   * Tóm tắt streak để hiển thị (màn hồ sơ, trang chủ...).
   *
   * Dùng `projectStreak`, không phải `applyActivity`: đường đọc không được
   * phép tiêu băng hay ghi ngày — chỉ mở app xem streak không phải là một
   * hoạt động học.
   */
  async readSummary({ userId, now = new Date() }) {
    const streak = await repository.findByUser({ userId });
    if (!streak) {
      return { current_streak: 0, longest_streak: 0, total_xp: 0, freezes_available: 0 };
    }

    const view = rules.projectStreak(
      {
        currentStreak: streak.current_streak,
        lastActivityDay: streak.last_activity_day,
        freezesAvailable: streak.freezes_available,
      },
      rules.dayKey(now),
    );

    return { ...streak, current_streak: view.currentStreak };
  },
});

/** Bản dựng sẵn dùng repository thật, cho controller không cần tự lắp tham số. */
export const streakService = createStreakService();

export default streakService;

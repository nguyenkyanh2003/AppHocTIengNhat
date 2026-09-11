import { ApiError } from '../../shared/http/api-error.js';
import { streakRepository } from './streak.repository.js';
import { applyActivity, dayKey, projectStreak } from './streak-rules.js';
import * as defaultPolicy from './streak-policy.js';

/**
 * Cổng ghi hoạt động học — **đường duy nhất** được phép cộng XP, nối chuỗi và
 * đánh dấu ngày học.
 *
 * Thay cho bốn cách ghi cũ chạy song song: `UserStreak.addXP`,
 * `updateStreakOnActivity`, `findOneAndUpdate` viết tay trong JLPT, và
 * `POST /streak/add-xp` nhận thẳng `amount` từ client. Bốn đường đó không
 * cùng luật ngày, không cùng bảng XP, và không đường nào chống được trùng.
 *
 * Caller là service nghiệp vụ **đã xác thực xong** user, nội dung và kết quả.
 * Không có endpoint nào cho client gửi trực tiếp một hoạt động, một số XP,
 * một ngày học hay một trạng thái huy hiệu (spec §3.1).
 */

/**
 * Số lần thử lại CAS trước khi chịu thua.
 *
 * Phải có chặn trên: `revision` đổi ở mọi lần ghi, nên một user đang học trên
 * nhiều thiết bị về lý thuyết có thể làm request này thua mãi. Thà trả 409 để
 * client thử lại còn hơn giữ một transaction mở vô hạn.
 */
const MAX_CAS_ATTEMPTS = 5;

export const createStreakService = ({
  repository = streakRepository,
  rules = { applyActivity, dayKey, projectStreak },
  policy = defaultPolicy,
} = {}) => {
  /**
   * Chạy CAS tới khi thắng, đọc lại trạng thái sau mỗi lần thua.
   *
   * Đọc lại là bắt buộc chứ không phải tối ưu: thua CAS nghĩa là có người vừa
   * ghi, nên `revision` **và** các trường streak trong tay đều đã cũ. Thử lại
   * với đúng bản đọc cũ thì hoặc thua tiếp mãi, hoặc thắng rồi ghi đè mất thứ
   * người kia vừa viết.
   *
   * `buildWrite` được gọi lại mỗi vòng với bản đọc mới nhất, nên luật ngày
   * cũng được tính lại trên trạng thái mới.
   */
  const casWithRetry = async ({ userId, session, buildWrite }) => {
    let summary = await repository.ensureSummary({ userId, session });

    for (let attempt = 1; attempt <= MAX_CAS_ATTEMPTS; attempt += 1) {
      const write = buildWrite(summary);
      const saved = await repository.casSummary({
        userId,
        expectedRevision: summary.revision ?? 0,
        patch: write.patch,
        inc: write.inc,
        session,
      });
      if (saved) return { summary: saved, write };

      summary = (await repository.findByUser({ userId, session })) ?? summary;
    }

    // Event đã nằm trong nhật ký rồi. Ném ở đây để cả transaction rollback —
    // nuốt lỗi sẽ để lại một event có XP mà tóm tắt không bao giờ cộng, và
    // lần gửi lại sau sẽ bị chính khoá đó chặn.
    throw ApiError.conflict('Không ghi được streak do có quá nhiều ghi đồng thời.', {
      code: 'STREAK_WRITE_CONFLICT',
    });
  };

  /**
   * Phát thưởng cho những mốc vừa vượt qua, trong cùng transaction.
   *
   * Khoá theo `user + loại thưởng + mốc` nên mỗi mốc chỉ được cấp đúng một
   * lần trong đời tài khoản — kể cả khi chuỗi đứt rồi leo lại qua đúng mốc đó
   * (spec §3.3).
   *
   * **Không** gọi lại `recordActivity`: event thưởng không phải hoạt động
   * học, không đánh dấu ngày, và nếu nó tự quay lại cổng ghi thì XP vừa cộng
   * có thể đẩy chuỗi qua một mốc khác và sinh vòng lặp phát thưởng (§3.4).
   */
  const awardMilestones = async ({ userId, milestones, occurredAt, todayKey, session, rewards }) => {
    const awarded = [];

    for (const milestone of milestones) {
      const xp = policy.xpFor(policy.MILESTONE_REWARD_TYPE, rewards?.[milestone]);
      const event = await repository.insertEvent({
        userId,
        eventKey: `streak-milestone:${userId}:${milestone}`,
        type: policy.MILESTONE_REWARD_TYPE,
        sourceId: String(milestone),
        occurredAt,
        dayKey: todayKey,
        xpDelta: xp,
        reason: policy.MILESTONE_REWARD_TYPE,
        countsAsStudy: false,
        policyVersion: policy.POLICY_VERSION,
        session,
      });
      // `null` nghĩa là mốc này đã được cấp trước đó — không phải lỗi.
      if (!event) continue;

      awarded.push(milestone);
      if (xp > 0) {
        await casWithRetry({ userId, session, buildWrite: () => ({ inc: { total_xp: xp } }) });
      }
    }

    return awarded;
  };

  return {
    /**
     * Ghi nhận một hoạt động đã hoàn thành.
     *
     * Gọi **sau khi** nghiệp vụ đã ghi thành công trong cùng transaction (đã
     * lưu bài nộp, đã thắng CAS của SRS), và truyền `session` xuống để lỗi ở
     * đây rollback luôn cả phần nghiệp vụ — không để XP "mồ côi".
     *
     * `occurrenceKey` là **bắt buộc với mọi loại**. Service này không tự bịa
     * khoá từ `type:sourceId` nữa: một thẻ SRS được ôn lại nhiều lần trong đời
     * nó, nên ID thẻ một mình không định danh được lượt ôn — đó chính là lý do
     * thiết kế cũ phải chia hoạt động thành "một lần" (có chống trùng) và
     * "lặp lại" (không chống trùng gì cả). Caller đã xác thực nghiệp vụ, nó
     * biết định danh thật của lần xảy ra.
     *
     * Trình tự đúng spec §3.1: **ghi event trước**, rồi mới cập nhật tóm tắt
     * và ngày. Chính lần insert event là câu trả lời cho "đã ghi chưa".
     */
    async recordActivity(
      { userId, type, sourceId, occurrenceKey, context },
      { session, now = new Date() } = {},
    ) {
      if (!occurrenceKey) {
        throw ApiError.badRequest('Hoạt động phải có định danh lần xảy ra.', {
          code: 'MISSING_OCCURRENCE_KEY',
          details: { type },
        });
      }

      // Ném trước khi ghi bất cứ thứ gì: loại lạ là lỗi lập trình ở caller,
      // và một event mang loại không có trong bảng chính sách sẽ không bao giờ
      // đọc lại được cho đúng.
      const xp = policy.xpFor(type, context?.outcome);
      const countsAsStudy = policy.countsAsStudy(type);
      const todayKey = rules.dayKey(now);

      const event = await repository.insertEvent({
        userId,
        eventKey: occurrenceKey,
        type,
        sourceId,
        occurredAt: now,
        dayKey: todayKey,
        xpDelta: xp,
        reason: type,
        countsAsStudy,
        policyVersion: policy.POLICY_VERSION,
        receipt: context?.receipt,
        session,
      });

      if (!event) {
        // Đã ghi rồi: gửi lại sau timeout, double submit, hai thiết bị. Trả
        // đúng trạng thái hiện tại và không đụng vào gì cả.
        const latest = await repository.findByUser({ userId, session });
        return {
          currentStreak: latest?.current_streak ?? 0,
          isNewDay: false,
          xpAwarded: 0,
          duplicate: true,
          milestonesReached: [],
        };
      }

      // Hoạt động không phải học và không có XP (đăng nhập, mở bài, bỏ qua):
      // đã vào nhật ký để không phát lại, và dừng ở đó. Đây là chỗ sửa lỗi
      // "đăng nhập cũng nối chuỗi" — nó không còn đi qua nhánh nào chạm tới
      // `current_streak` nữa.
      if (!countsAsStudy && xp === 0) {
        const summary = await repository.ensureSummary({ userId, session });
        return {
          currentStreak: summary?.current_streak ?? 0,
          isNewDay: false,
          xpAwarded: 0,
          duplicate: false,
          milestonesReached: [],
        };
      }

      // Event có XP nhưng không phải hoạt động học: chỉ cộng XP, không đụng
      // tới chuỗi ngày.
      if (!countsAsStudy) {
        const { summary } = await casWithRetry({
          userId,
          session,
          buildWrite: () => ({ inc: { total_xp: xp } }),
        });
        return {
          currentStreak: summary.current_streak ?? 0,
          isNewDay: false,
          xpAwarded: xp,
          duplicate: false,
          milestonesReached: [],
        };
      }

      let previousStreak = 0;
      const { summary, write } = await casWithRetry({
        userId,
        session,
        buildWrite: (current) => {
          previousStreak = current.current_streak ?? 0;
          const next = rules.applyActivity(
            {
              currentStreak: previousStreak,
              longestStreak: current.longest_streak ?? 0,
              lastActivityDay: current.last_activity_day ?? null,
              freezesAvailable: current.freezes_available ?? 0,
            },
            todayKey,
          );

          const patch = {
            current_streak: next.currentStreak,
            longest_streak: next.longestStreak,
            last_activity_day: next.lastActivityDay,
            policy_version: policy.POLICY_VERSION,
          };
          // Chỉ đặt mốc bắt đầu theo dõi đúng một lần. Đẩy nó lên ngày hôm nay
          // ở mỗi lần học sẽ xoá mất ranh giới giữa "chưa từng theo dõi" và
          // "đã nghỉ", và khoảng trống trước mốc không được coi là nghỉ học
          // (spec §3.2).
          if (!current.tracking_started_day) patch.tracking_started_day = todayKey;
          // Băng chỉ bị tiêu ở đây — tức chỉ khi người học thật sự học, không
          // phải lúc mở app. Phần B mới phát băng nên nhánh này hiện không bao
          // giờ chạy; viết sẵn vì bỏ trống nó nghĩa là `frozenDays` được ghi
          // vào lịch mà kho băng không bao giờ vơi — băng vô hạn.
          if (next.freezesUsed > 0) {
            patch.freezes_available = (current.freezes_available ?? 0) - next.freezesUsed;
          }

          const inc = { total_xp: xp };
          // Ngày học chỉ được đếm ở đúng lần ghi làm ngày đó thành ngày mới.
          // Hoạt động thứ hai trong ngày có `isNewDay === false`.
          if (next.isNewDay) inc.total_active_days = 1;

          return { patch, inc, next };
        },
      });

      const next = write.next;

      await repository.upsertDay({
        userId,
        dayKey: todayKey,
        status: 'studied',
        incDirectXp: xp,
        incReviewCount: type === 'srs.review' ? 1 : 0,
        incCorrect: type === 'srs.review' && context?.outcome?.remembered === true ? 1 : 0,
        incWrong: type === 'srs.review' && context?.outcome?.remembered === false ? 1 : 0,
        session,
      });

      // Ngày được băng che: chỉ đánh dấu lịch, không XP, không phải ngày học.
      // Băng thuộc Phần B nên hiện `frozenDays` luôn rỗng.
      for (const frozenDay of next.frozenDays) {
        await repository.upsertDay({ userId, dayKey: frozenDay, status: 'frozen', session });
      }

      const milestonesReached = await awardMilestones({
        userId,
        milestones: policy.milestonesCrossed(previousStreak, next.currentStreak),
        occurredAt: now,
        todayKey,
        session,
        rewards: context?.rewards,
      });

      return {
        currentStreak: summary.current_streak ?? next.currentStreak,
        isNewDay: next.isNewDay,
        xpAwarded: xp,
        duplicate: false,
        milestonesReached,
      };
    },

    /**
     * Tóm tắt streak để **hiển thị** (trang chủ, hồ sơ, sau khi đăng nhập).
     *
     * Dùng `projectStreak` chứ không `applyActivity`: đường đọc không được ghi
     * gì, không tiêu băng và không phát thưởng. Mở app xem streak không phải
     * là một hoạt động học — đó chính là lỗi cũ mà spec §3.5 đóng lại.
     */
    async readSummary({ userId, now = new Date() }) {
      const streak = await repository.findByUser({ userId });
      if (!streak) {
        return { current_streak: 0, longest_streak: 0, total_xp: 0, total_active_days: 0 };
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
  };
};

/** Bản dựng sẵn dùng repository thật, cho controller không cần tự lắp tham số. */
export const streakService = createStreakService();

export default streakService;

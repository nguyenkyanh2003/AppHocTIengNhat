import { ApiError } from '../../shared/http/api-error.js';
import { achievementService } from '../achievements/achievement.service.js';
import { streakRepository } from './streak.repository.js';
import { applyActivity, dayKey, MAX_FREEZES, projectStreak } from './streak-rules.js';
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
  achievements = achievementService,
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
   * Đánh dấu những mốc chuỗi ngày vừa vượt qua, trong cùng transaction.
   *
   * Event mốc là 0 XP: nó chỉ để mỗi mốc được báo đúng một lần trong đời tài
   * khoản — kể cả khi chuỗi đứt rồi leo lại qua đúng mốc đó (spec §3.3). XP
   * của mốc nằm ở huy hiệu streak tương ứng, xét ở `awardAchievements`.
   *
   * **Không** gọi lại `recordActivity`: event thưởng không phải hoạt động
   * học, không đánh dấu ngày, và nếu nó tự quay lại cổng ghi thì có thể sinh
   * vòng lặp phát thưởng (§3.4).
   */
  const markMilestones = async ({ userId, milestones, occurredAt, todayKey, session }) => {
    const reached = [];

    for (const milestone of milestones) {
      const eventKey = `streak-milestone:${userId}:${milestone}`;

      // Tra trước khi ghi: mốc đã có rồi mà vẫn thử ghi thì unique index huỷ
      // luôn transaction đang dở của hoạt động học.
      if (await repository.findEventByKey({ userId, eventKey, session })) continue;

      await repository.insertEvent({
        userId,
        eventKey,
        type: policy.MILESTONE_REWARD_TYPE,
        sourceId: String(milestone),
        occurredAt,
        dayKey: todayKey,
        xpDelta: policy.xpFor(policy.MILESTONE_REWARD_TYPE),
        reason: policy.MILESTONE_REWARD_TYPE,
        countsAsStudy: false,
        policyVersion: policy.POLICY_VERSION,
        session,
      });
      reached.push(milestone);
    }

    return reached;
  };

  /**
   * Tặng băng cho những mốc chuỗi **vừa vượt qua bằng hoạt động này** (spec §5.2).
   *
   * Gọi sau khi CAS chính đã xử lý ngày và khoảng nghỉ: băng tặng hôm nay không
   * được dùng cứu khoảng nghỉ đã qua. Mỗi mốc tặng đúng một lần trong đời tài
   * khoản nhờ khoá `streak-freeze:<user>:<mốc>` — tách khỏi khoá mốc chuỗi và
   * khoá huy hiệu, nên huy hiệu nhận trước Phần B không kéo theo băng.
   *
   * Kho đầy thì phần thưởng bị bỏ, không để dành lĩnh sau; event vẫn được ghi
   * (`receipt.granted = false`) để mốc đó không bao giờ được xét lại. CAS chạy
   * trước khi ghi event vì receipt cần biết kho **lúc thắng CAS** — cả hai nằm
   * trong cùng transaction nên thứ tự không làm hở gì.
   */
  const giftFreezes = async ({ userId, milestones, occurredAt, todayKey, session }) => {
    const gifted = [];

    for (const milestone of milestones) {
      const eventKey = `streak-freeze:${userId}:${milestone}`;
      if (await repository.findEventByKey({ userId, eventKey, session })) continue;

      let granted = false;
      await casWithRetry({
        userId,
        session,
        buildWrite: (current) => {
          const inventory = current.freezes_available ?? 0;
          granted = inventory < MAX_FREEZES;
          return { patch: { freezes_available: granted ? inventory + 1 : inventory } };
        },
      });

      await repository.insertEvent({
        userId,
        eventKey,
        type: policy.FREEZE_GIFT_TYPE,
        sourceId: String(milestone),
        occurredAt,
        dayKey: todayKey,
        xpDelta: policy.xpFor(policy.FREEZE_GIFT_TYPE),
        reason: policy.FREEZE_GIFT_TYPE,
        countsAsStudy: false,
        policyVersion: policy.POLICY_VERSION,
        receipt: { granted },
        session,
      });
      if (granted) gifted.push(milestone);
    }

    return gifted;
  };

  /**
   * Cấp những huy hiệu mà hoạt động vừa ghi làm đạt tiêu chí.
   *
   * Tiêu chí do server tự đếm (`achievement-rules.js`), xét trên `snapshot`
   * **trước** thưởng: XP của huy hiệu vừa cấp không kéo theo huy hiệu XP khác
   * trong cùng lần ghi. Khoá `achievement:<user>:<huy hiệu>` giữ mỗi huy hiệu
   * một lần trong đời tài khoản; XP lấy từ cấu hình Achievement qua policy.
   */
  const awardAchievements = async ({ userId, snapshot, occurredAt, todayKey, session }) => {
    const unlocked = await achievements.findUnlocked({ userId, snapshot, session });
    const awarded = [];

    for (const { id, xpReward, progress } of unlocked) {
      const eventKey = `achievement:${userId}:${id}`;
      if (await repository.findEventByKey({ userId, eventKey, session })) continue;

      const xp = policy.xpFor(policy.ACHIEVEMENT_REWARD_TYPE, { configuredXp: xpReward });
      await repository.insertEvent({
        userId,
        eventKey,
        type: policy.ACHIEVEMENT_REWARD_TYPE,
        sourceId: id,
        occurredAt,
        dayKey: todayKey,
        xpDelta: xp,
        reason: policy.ACHIEVEMENT_REWARD_TYPE,
        countsAsStudy: false,
        policyVersion: policy.POLICY_VERSION,
        session,
      });
      if (xp > 0) {
        await casWithRetry({ userId, session, buildWrite: () => ({ inc: { total_xp: xp } }) });
      }
      await achievements.markCompleted({ userId, achievementId: id, progress, earnedAt: occurredAt, session });
      awarded.push({ id, xp });
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

      // Tra khoá **trước** khi ghi. Không phải để tối ưu: lệnh ghi đụng unique
      // index sẽ huỷ cả transaction, kéo theo phần nghiệp vụ mà caller vừa ghi
      // trong cùng session. Hai request song song vẫn có thể cùng vượt qua chỗ
      // này — bên thua nhận lỗi transient từ `insertEvent` và cả transaction
      // của nó chạy lại, lần đó thì thấy khoá đã có.
      const recorded = await repository.findEventByKey({
        userId,
        eventKey: occurrenceKey,
        session,
      });
      if (recorded) {
        const latest = await repository.findByUser({ userId, session });
        return {
          currentStreak: latest?.current_streak ?? 0,
          isNewDay: false,
          xpAwarded: 0,
          duplicate: true,
          milestonesReached: [],
          achievementsAwarded: [],
          freezesGifted: [],
        };
      }

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
          achievementsAwarded: [],
          freezesGifted: [],
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
          achievementsAwarded: [],
          freezesGifted: [],
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
          // phải lúc mở app. Bỏ trống nhánh này nghĩa là `frozenDays` được ghi
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
      for (const frozenDay of next.frozenDays) {
        await repository.upsertDay({ userId, dayKey: frozenDay, status: 'frozen', session });
      }

      const crossed = policy.milestonesCrossed(previousStreak, next.currentStreak);
      const milestonesReached = await markMilestones({
        userId,
        milestones: crossed,
        occurredAt: now,
        todayKey,
        session,
      });
      const freezesGifted = await giftFreezes({
        userId,
        milestones: crossed,
        occurredAt: now,
        todayKey,
        session,
      });
      const achievementsAwarded = await awardAchievements({
        userId,
        snapshot: { currentStreak: summary.current_streak ?? 0, totalXp: summary.total_xp ?? 0 },
        occurredAt: now,
        todayKey,
        session,
      });

      return {
        currentStreak: summary.current_streak ?? next.currentStreak,
        isNewDay: next.isNewDay,
        xpAwarded: xp,
        duplicate: false,
        milestonesReached,
        achievementsAwarded,
        freezesGifted,
      };
    },

    /**
     * Xét và cấp huy hiệu **ngoài** một hoạt động học — cho lịch sử vừa được
     * nhập hoặc dựng sẵn (seed demo), khi chưa có lượt học nào kích hoạt việc xét.
     *
     * Dùng đúng phép chiếu của đường đọc (chuỗi đã đứt tính là 0) và cùng cơ chế
     * cấp một lần như `recordActivity`; không ghi ngày học, không cộng XP học.
     */
    async awardEarnedAchievements(userId, { session, now = new Date() } = {}) {
      const todayKey = rules.dayKey(now);
      const summary = await repository.ensureSummary({ userId, session });
      const { currentStreak } = rules.projectStreak(
        {
          currentStreak: summary.current_streak ?? 0,
          lastActivityDay: summary.last_activity_day ?? null,
          freezesAvailable: summary.freezes_available ?? 0,
        },
        todayKey,
      );
      return awardAchievements({
        userId,
        snapshot: { currentStreak, totalXp: summary.total_xp ?? 0 },
        occurredAt: now,
        todayKey,
        session,
      });
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

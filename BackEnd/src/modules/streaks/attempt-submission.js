import { createHash } from 'node:crypto';

import { unitOfWork as defaultUnitOfWork } from '../../shared/db/unit-of-work.js';
import { ApiError } from '../../shared/http/api-error.js';
import { streakRepository } from './streak.repository.js';
import { streakService } from './streak.service.js';

/**
 * Nộp bài **đúng một lần** cho mỗi lượt làm, dùng chung cho bài tập và JLPT.
 *
 * Client sinh `attempt_id` khi bắt đầu một lượt làm và gửi lại **đúng** ID đó
 * khi thử lại (spec §3.3). Server không tin ID suông: nó lưu cùng với dấu vân
 * tay của bài làm trong `receipt` của event, nên
 *
 * - cùng ID **và** cùng bài làm → trả lại kết quả đã chấm, không chấm lại và
 *   không cộng XP lần hai;
 * - cùng ID **nhưng** bài làm khác → 409, vì một lượt làm chỉ có một bài nộp.
 *
 * Chống trùng nằm ở unique index `(user, event_key)`, không ở phép đọc trước:
 * hai request song song đều đọc "chưa có" rồi mới ghi, nên phép đọc chỉ là
 * đường tắt cho trường hợp thường gặp.
 */

/** Ném ra để rollback transaction của bên thua cuộc đua ghi event. */
class DuplicateAttemptError extends Error {}

/**
 * JSON ổn định: khoá sắp xếp ở mọi cấp.
 *
 * Không có bước này thì cùng một bài làm gửi lại với thứ tự khoá khác — điều
 * client hoàn toàn có thể làm — sẽ ra dấu vân tay khác và bị chặn nhầm 409.
 */
const stableStringify = (value) => {
  if (Array.isArray(value)) return `[${value.map(stableStringify).join(',')}]`;
  if (value && typeof value === 'object') {
    const entries = Object.keys(value)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${stableStringify(value[key])}`);
    return `{${entries.join(',')}}`;
  }
  return JSON.stringify(value ?? null);
};

export const fingerprintOf = (payload) =>
  createHash('sha256').update(stableStringify(payload)).digest('hex');

export const createAttemptSubmitter = ({
  streak = streakService,
  repository = streakRepository,
  unitOfWork = defaultUnitOfWork,
  clock = () => new Date(),
} = {}) => {
  /** Trả lại kết quả đã ghi, hoặc 409 nếu bài làm không khớp lượt làm đó. */
  const replay = (event, fingerprint) => {
    const receipt = event?.receipt;
    if (!receipt || receipt.fingerprint !== fingerprint) {
      throw ApiError.conflict(
        'Lượt làm này đã được nộp với một bài làm khác. Hãy bắt đầu lượt mới.',
        { code: 'ATTEMPT_PAYLOAD_MISMATCH' },
      );
    }
    return { result: receipt.result, replayed: true, xpAwarded: 0 };
  };

  return {
    /**
     * @param persist Ghi kết quả nghiệp vụ trong session và trả về
     *   `{ result, outcome }` — `result` là thứ trả cho client và lưu vào
     *   receipt, `outcome` là kết quả đã chấm để chính sách tính XP.
     */
    async submit({ userId, type, sourceId, attemptId, payload, persist }) {
      const eventKey = `${type}:${attemptId}`;
      const fingerprint = fingerprintOf(payload);

      const known = await repository.findEventByKey({ userId, eventKey });
      if (known) return replay(known, fingerprint);

      try {
        return await unitOfWork.run(async ({ session }) => {
          const { result, outcome } = await persist({ session });

          const recorded = await streak.recordActivity(
            {
              userId,
              type,
              sourceId: sourceId === undefined ? undefined : String(sourceId),
              occurrenceKey: eventKey,
              context: { outcome, receipt: { fingerprint, result } },
            },
            { session, now: clock() },
          );

          // Có người vừa ghi xong đúng lượt làm này. Kết quả vừa tạo ở trên
          // phải biến mất cùng transaction, nếu không sẽ có hai bản ghi kết
          // quả cho một lượt.
          if (recorded.duplicate) throw new DuplicateAttemptError();

          return { result, replayed: false, xpAwarded: recorded.xpAwarded };
        });
      } catch (error) {
        if (!(error instanceof DuplicateAttemptError)) throw error;
        return replay(await repository.findEventByKey({ userId, eventKey }), fingerprint);
      }
    },
  };
};

export const attemptSubmitter = createAttemptSubmitter();

export default attemptSubmitter;

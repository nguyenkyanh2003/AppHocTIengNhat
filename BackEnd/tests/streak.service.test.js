import assert from 'node:assert/strict';
import test from 'node:test';

import { XP_BY_ACTIVITY, STREAK_MILESTONES, createStreakService } from '../src/modules/streaks/streak.service.js';

const NOW = new Date('2026-09-10T03:00:00Z'); // 10:00 giờ VN

/**
 * Repository giả dùng chung cho phần lớn test: `state` là "document" duy
 * nhất, `casUpdate` mô phỏng đúng ngữ nghĩa CAS **nguyên tử** thật của
 * `streak.repository.js` sau Vòng sửa 1 — filter khoá theo cả
 * `last_activity_day` (expectedDay) LẪN `reward_keys` (nếu có `rewardKey`)
 * trong cùng một điều kiện; ghi `total_xp` bằng cộng dồn (`$inc`) và
 * `reward_keys` bằng thêm-nếu-chưa-có (`$addToSet`) thay vì set tuyệt đối.
 *
 * `ensureFor`/`findByUser` trả về **bản sao** (không phải tham chiếu `state`
 * gốc) — bắt buộc cho test đồng thời bên dưới: nếu trả thẳng `state`, một
 * lần đọc trước đó sẽ "nhìn thấy" luôn những thay đổi ghi sau đó (vì cùng
 * một object), che mất chính lỗi mà Vòng sửa 1 phải phơi ra.
 */
const fakeRepository = (streak = {}) => {
  const state = {
    user: 'u1',
    current_streak: 0,
    longest_streak: 0,
    last_activity_day: null,
    freezes_available: 0,
    total_xp: 0,
    reward_keys: [],
    ...streak,
  };
  const snapshot = () => ({ ...state, reward_keys: [...state.reward_keys] });
  const calls = [];
  return {
    calls,
    state,
    ensureFor: async () => snapshot(),
    findByUser: async () => snapshot(),
    casUpdate: async ({ expectedDay, patch, xpDelta, rewardKey, session }) => {
      calls.push(['casUpdate', { expectedDay, patch, xpDelta, rewardKey, session }]);
      const dayMatches = state.last_activity_day === (expectedDay ?? null);
      const rewardFree = !rewardKey || !state.reward_keys.includes(rewardKey);
      if (!dayMatches || !rewardFree) return null;

      Object.assign(state, patch);
      if (xpDelta) state.total_xp += xpDelta;
      if (rewardKey && !state.reward_keys.includes(rewardKey)) state.reward_keys.push(rewardKey);
      return snapshot();
    },
    appendXpEvent: async (args) => calls.push(['appendXpEvent', args]),
    markDay: async (args) => calls.push(['markDay', args]),
  };
};

test('ôn SRS lần đầu trong ngày: cộng 2 XP và tăng chuỗi', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });

  const result = await service.recordActivity({
    userId: 'u1',
    type: 'srs.review',
    sourceId: 'p1',
    now: NOW,
  });

  assert.equal(result.xpAwarded, XP_BY_ACTIVITY['srs.review']);
  assert.equal(result.xpAwarded, 2);
  assert.equal(result.currentStreak, 1);
  assert.equal(result.isNewDay, true);
});

test('lượt ôn thứ hai cùng ngày vẫn cộng XP nhưng không tăng ngày', async () => {
  const repository = fakeRepository({
    current_streak: 4,
    last_activity_day: '2026-09-10',
  });
  const service = createStreakService({ repository });

  const result = await service.recordActivity({
    userId: 'u1',
    type: 'srs.review',
    sourceId: 'p2',
    now: NOW,
  });

  assert.equal(result.xpAwarded, 2, 'mỗi lượt đến hạn đều được 2 XP');
  assert.equal(result.currentStreak, 4);
  assert.equal(result.isNewDay, false);
});

test('client không quyết định XP — số lấy từ bảng theo type', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });

  const result = await service.recordActivity({
    userId: 'u1',
    type: 'jlpt.submit',
    sourceId: 'r1',
    now: NOW,
    amount: 999_999, // cố tình truyền vào, phải bị bỏ qua
  });

  assert.equal(result.xpAwarded, XP_BY_ACTIVITY['jlpt.submit']);
});

test('type lạ bị từ chối thay vì cộng XP mặc định', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });

  await assert.rejects(
    service.recordActivity({ userId: 'u1', type: 'khong-ton-tai', sourceId: 'x', now: NOW }),
    (error) => error.status === 400,
  );
});

test('hoạt động một-lần gửi lại cùng sourceId chỉ cộng XP một lần', async () => {
  const repository = fakeRepository({ reward_keys: ['lesson.complete:l1'] });
  const service = createStreakService({ repository });

  const result = await service.recordActivity({
    userId: 'u1',
    type: 'lesson.complete',
    sourceId: 'l1',
    now: NOW,
  });

  assert.equal(result.xpAwarded, 0, 'đã thưởng rồi thì không cộng nữa');
});

test('ôn SRS không sinh reward_key — nếu không mảng sẽ phình vô hạn', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });

  await service.recordActivity({
    userId: 'u1',
    type: 'srs.review',
    sourceId: 'p1',
    now: NOW,
  });

  const [, args] = repository.calls.find(([name]) => name === 'casUpdate');
  assert.equal(args.rewardKey, undefined, 'lượt ôn lặp lại không được sinh rewardKey');
  assert.ok(!('reward_keys' in args.patch), 'patch streak không bao giờ chứa reward_keys tuyệt đối');
  assert.ok(!('total_xp' in args.patch), 'total_xp cộng qua $inc (xpDelta), không set tuyệt đối trong patch');
});

test('CAS thua thì không ghi XP và không ghi ngày', async () => {
  const repository = fakeRepository({ last_activity_day: '2026-09-09' });
  repository.casUpdate = async () => null; // ai đó đã cập nhật trước

  const service = createStreakService({ repository });
  const result = await service.recordActivity({
    userId: 'u1',
    type: 'srs.review',
    sourceId: 'p1',
    now: NOW,
  });

  assert.equal(result.xpAwarded, 0);
  assert.equal(
    repository.calls.some(([name]) => name === 'appendXpEvent'),
    false,
  );
});

// ---------------------------------------------------------------------------
// Các nhánh brief bỏ sót — thêm để phủ đủ hành vi đã chốt trong task-4-brief.
// ---------------------------------------------------------------------------

test('ôn SRS hai lượt khác nhau trong cùng ngày: cộng XP hai lần, isNewDay chỉ true ở lượt đầu', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });

  const first = await service.recordActivity({
    userId: 'u1',
    type: 'srs.review',
    sourceId: 'card-1',
    now: NOW,
  });
  const second = await service.recordActivity({
    userId: 'u1',
    type: 'srs.review',
    sourceId: 'card-2', // thẻ khác — không phải gửi lại cùng sourceId
    now: NOW,
  });

  assert.equal(first.isNewDay, true, 'lượt đầu trong ngày mới tăng streak');
  assert.equal(first.xpAwarded, 2);
  assert.equal(second.isNewDay, false, 'lượt thứ hai cùng ngày không tăng thêm ngày nào nữa');
  assert.equal(second.xpAwarded, 2, 'lượt thứ hai vẫn được cộng XP — srs.review không phải one-shot');
  assert.equal(second.currentStreak, 1, 'chuỗi không tăng thêm trong cùng một ngày');

  const appendCalls = repository.calls.filter(([name]) => name === 'appendXpEvent');
  assert.equal(appendCalls.length, 2, 'mỗi lượt ôn đều ghi một bản ghi XP riêng');
});

test('trả lời sai vẫn được ghi nhận hoạt động — service không có khái niệm đúng/sai', async () => {
  // recordActivity không nhận tham số "đúng/sai": quyết định có gọi hàm này
  // hay không thuộc về tầng xử lý đáp án (vd. srs.service khi chấm lượt ôn).
  // Một tham số lạ như `correct: false` không được service đọc, nhưng cũng
  // không được vì thế mà chặn ghi nhận — trả lời sai vẫn là học.
  const repository = fakeRepository();
  const service = createStreakService({ repository });

  const result = await service.recordActivity({
    userId: 'u1',
    type: 'srs.review',
    sourceId: 'p1',
    now: NOW,
    correct: false,
  });

  assert.equal(result.xpAwarded, XP_BY_ACTIVITY['srs.review']);
  assert.equal(result.currentStreak, 1);
  assert.equal(result.isNewDay, true);
});

test('nghỉ 1 ngày có băng: ngày băng được markDay(frozen) và không cộng XP riêng', async () => {
  // last_activity_day cách "hôm nay" 2 ngày lịch (08 -> 10), có đúng 1 băng
  // để che ngày 09 — applyActivity phải tiêu đúng 1 băng, chuỗi tiếp tục
  // thay vì đứt (xem streak-rules.js).
  const repository = fakeRepository({
    current_streak: 3,
    longest_streak: 5,
    last_activity_day: '2026-09-08',
    freezes_available: 1,
  });
  const service = createStreakService({ repository });

  const result = await service.recordActivity({
    userId: 'u1',
    type: 'srs.review',
    sourceId: 'p1',
    now: NOW, // dayKey = 2026-09-10
  });

  assert.equal(result.currentStreak, 4, 'băng che được nên chuỗi vẫn tiếp tục, không đứt');
  assert.equal(result.xpAwarded, 2, 'chỉ hoạt động thật hôm nay được cộng XP');
  assert.equal(repository.state.freezes_available, 0, 'băng đã bị tiêu cho ngày nó bảo vệ');

  // So sánh không phụ thuộc thứ tự gọi thật (chi tiết cài đặt) — chỉ quan
  // tâm đúng ngày nào được đánh dấu đúng trạng thái nào.
  const markDayCalls = repository.calls
    .filter(([name]) => name === 'markDay')
    .map(([, args]) => [args.dayKey, args.status])
    .sort(([a], [b]) => a.localeCompare(b));
  assert.deepEqual(markDayCalls, [
    ['2026-09-09', 'frozen'], // ngày nghỉ được băng che
    ['2026-09-10', 'studied'], // ngày hoạt động thật
  ]);

  // Chỉ đúng một bản ghi XP — ngày băng không tự sinh thêm XP nào.
  const appendCalls = repository.calls.filter(([name]) => name === 'appendXpEvent');
  assert.equal(appendCalls.length, 1);
  assert.equal(appendCalls[0][1].amount, 2);
});

test('chạm mốc 7 ngày: milestonesReached chứa đúng [7], chỉ một lần', async () => {
  const repository = fakeRepository({
    current_streak: 6,
    longest_streak: 6,
    last_activity_day: '2026-09-09', // hôm qua — hôm nay học tiếp là ngày thứ 7
  });
  const service = createStreakService({ repository });

  const first = await service.recordActivity({
    userId: 'u1',
    type: 'lesson.progress',
    sourceId: 'l1',
    now: NOW,
  });
  assert.equal(first.currentStreak, 7);
  assert.deepEqual(first.milestonesReached, [7]);

  // Lượt thứ hai trong cùng ngày không được tính là "chạm mốc" lần nữa —
  // isNewDay false nên milestonesReached phải rỗng.
  const second = await service.recordActivity({
    userId: 'u1',
    type: 'exercise.submit',
    sourceId: 'ex1',
    now: NOW,
  });
  assert.deepEqual(second.milestonesReached, []);

  // Mốc không nằm trong thang chuẩn không bao giờ xuất hiện.
  assert.ok(STREAK_MILESTONES.includes(7));
});

test('session truyền vào recordActivity được chuyển tiếp xuống mọi lệnh repository khi CAS thắng', async () => {
  const session = { marker: 'sess-1' };
  const seen = {};
  const state = {
    user: 'u1',
    current_streak: 0,
    longest_streak: 0,
    last_activity_day: null,
    freezes_available: 0,
    total_xp: 0,
    reward_keys: [],
  };
  const repository = {
    ensureFor: async ({ session: s }) => {
      seen.ensureFor = s;
      return state;
    },
    findByUser: async ({ session: s }) => {
      seen.findByUser = s;
      return state;
    },
    casUpdate: async ({ expectedDay, patch, session: s }) => {
      seen.casUpdate = s;
      if (state.last_activity_day !== (expectedDay ?? null)) return null;
      Object.assign(state, patch);
      return state;
    },
    appendXpEvent: async ({ session: s }) => {
      seen.appendXpEvent = s;
    },
    markDay: async ({ session: s }) => {
      seen.markDay = (seen.markDay ?? []).concat(s);
    },
  };
  const service = createStreakService({ repository });

  await service.recordActivity({
    userId: 'u1',
    type: 'srs.review',
    sourceId: 'p1',
    now: NOW,
    session,
  });

  assert.equal(seen.ensureFor, session, 'ensureFor phải nhận session');
  assert.equal(seen.casUpdate, session, 'casUpdate phải nhận session');
  assert.equal(seen.appendXpEvent, session, 'appendXpEvent phải nhận session');
  assert.ok(seen.markDay.every((s) => s === session), 'mọi lệnh markDay phải nhận session');
  // CAS thắng ngay lượt đầu nên nhánh đọc lại (findByUser) không được gọi.
  assert.equal(seen.findByUser, undefined);
});

test('session vẫn được chuyển tiếp xuống findByUser khi CAS thua', async () => {
  const session = { marker: 'sess-2' };
  const seen = {};
  const repository = fakeRepository({ last_activity_day: '2026-09-09' });
  repository.casUpdate = async ({ session: s }) => {
    seen.casUpdate = s;
    return null; // giả lập một request khác đã ghi trước
  };
  const originalFindByUser = repository.findByUser;
  repository.findByUser = async ({ session: s }) => {
    seen.findByUser = s;
    return originalFindByUser();
  };
  const service = createStreakService({ repository });

  await service.recordActivity({
    userId: 'u1',
    type: 'srs.review',
    sourceId: 'p1',
    now: NOW,
    session,
  });

  assert.equal(seen.casUpdate, session);
  assert.equal(seen.findByUser, session);
});

// ---------------------------------------------------------------------------
// readSummary — đường đọc, không được phép tiêu băng hay ghi bất cứ gì.
// ---------------------------------------------------------------------------

test('readSummary chiếu streak hiện tại mà không ghi gì (dùng projectStreak)', async () => {
  // Repository cố tình KHÔNG có casUpdate/appendXpEvent/markDay/ensureFor —
  // nếu readSummary lỡ gọi nhầm một trong các hàm ghi, test sẽ crash ngay vì
  // gọi hàm không tồn tại thay vì âm thầm trôi qua.
  const repository = {
    findByUser: async () => ({
      user: 'u1',
      current_streak: 5,
      longest_streak: 5,
      last_activity_day: '2026-09-07', // nghỉ 2 ngày trọn (08, 09), không băng
      freezes_available: 0,
      total_xp: 40,
    }),
  };
  const service = createStreakService({ repository });

  const summary = await service.readSummary({ userId: 'u1', now: NOW });

  assert.equal(summary.current_streak, 0, 'nghỉ quá số băng thì đường đọc phải chiếu chuỗi về 0');
  assert.equal(summary.total_xp, 40, 'các trường khác giữ nguyên từ document');
});

test('readSummary trả về mặc định khi user chưa từng có streak', async () => {
  const repository = { findByUser: async () => null };
  const service = createStreakService({ repository });

  const summary = await service.readSummary({ userId: 'u1', now: NOW });

  assert.deepEqual(summary, {
    current_streak: 0,
    longest_streak: 0,
    total_xp: 0,
    freezes_available: 0,
  });
});

// ---------------------------------------------------------------------------
// Vòng sửa 1 — mất cập nhật khi hai hoạt động one-shot cùng ngày chạy đồng
// thời. `casUpdate` cũ chỉ khoá theo `last_activity_day`; hoạt động "lặp
// trong ngày" (gap <= 0) không đổi ngày đó nên CAS cũ khớp cho cả hai
// request, và `$set` tuyệt đối khiến bản ghi sau đè mất XP + reward_keys
// của bản ghi trước. Ba test dưới đây phủ đúng ba nhánh reviewer yêu cầu.
// ---------------------------------------------------------------------------

test('[Vòng sửa 1] hai hoạt động one-shot khác nhau, cùng ngày, chạy đồng thời: cả hai cộng XP, không đè nhau', async () => {
  // repository.ensureFor/casUpdate không có await nội bộ nào (xem fakeRepository
  // ở đầu file) nên Promise.all dưới đây tái hiện đúng race thật: cả hai lời
  // gọi recordActivity đọc xong `current` (qua ensureFor) TRƯỚC KHI bên nào
  // ghi xong — đúng kịch bản gây lỗi trước khi sửa.
  const repository = fakeRepository({
    current_streak: 5,
    longest_streak: 5,
    last_activity_day: '2026-09-10', // đã học hôm nay rồi — cả hai hoạt động chỉ lặp trong ngày
    total_xp: 100,
  });
  const service = createStreakService({ repository });

  const [lessonResult, exerciseResult] = await Promise.all([
    service.recordActivity({ userId: 'u1', type: 'lesson.complete', sourceId: 'l1', now: NOW }),
    service.recordActivity({ userId: 'u1', type: 'exercise.submit', sourceId: 'e1', now: NOW }),
  ]);

  assert.equal(lessonResult.xpAwarded, XP_BY_ACTIVITY['lesson.complete']);
  assert.equal(exerciseResult.xpAwarded, XP_BY_ACTIVITY['exercise.submit']);
  assert.equal(
    repository.state.total_xp,
    100 + XP_BY_ACTIVITY['lesson.complete'] + XP_BY_ACTIVITY['exercise.submit'],
    '$inc cộng dồn cho cả hai — bản ghi sau không được đè mất XP của bản ghi trước',
  );
  assert.ok(
    repository.state.reward_keys.includes('lesson.complete:l1'),
    'reward_keys của bên thắng trước không bị đè mất',
  );
  assert.ok(
    repository.state.reward_keys.includes('exercise.submit:e1'),
    'reward_keys của bên ghi sau cũng phải có mặt',
  );
});

test('[Vòng sửa 1] gửi lại đúng sourceId one-shot sau khi đã thưởng: lọc bằng $ne trong filter CAS, không cộng lần hai', async () => {
  const repository = fakeRepository({
    last_activity_day: '2026-09-10',
    total_xp: 50,
    reward_keys: ['lesson.complete:l1'],
  });
  const service = createStreakService({ repository });

  const result = await service.recordActivity({
    userId: 'u1',
    type: 'lesson.complete',
    sourceId: 'l1', // đã có trong reward_keys — double submit/retry
    now: NOW,
  });

  assert.equal(result.xpAwarded, 0);
  assert.equal(repository.state.total_xp, 50, 'không được cộng thêm lần hai');
  assert.deepEqual(repository.state.reward_keys, ['lesson.complete:l1'], 'không thêm bản sao vào mảng');

  // Xác nhận CAS thua đi đúng qua nhánh reward_keys $ne, không phải trùng
  // hợp do lệch ngày — ở đây expectedDay khớp thật, chỉ có rewardKey là lý
  // do duy nhất khiến filter không match.
  const [, args] = repository.calls.find(([name]) => name === 'casUpdate');
  assert.equal(args.expectedDay, '2026-09-10');
  assert.equal(args.rewardKey, 'lesson.complete:l1');

  assert.equal(repository.calls.some(([name]) => name === 'appendXpEvent'), false);
  assert.equal(repository.calls.some(([name]) => name === 'markDay'), false);
});

test('[Vòng sửa 1] CAS thua vì last_activity_day đã bị request khác đẩy đi: vẫn xpAwarded 0, không ghi gì', async () => {
  const repository = fakeRepository({ last_activity_day: '2026-09-08' });
  const originalCasUpdate = repository.casUpdate;
  // Mô phỏng một request khác chen vào và đẩy last_activity_day sang hôm nay
  // đúng lúc request này chuẩn bị ghi — request này vẫn cầm expectedDay cũ
  // (đọc trước đó) nên chắc chắn thua, và thua vì NGÀY chứ không phải
  // reward_keys (type lặp lại nên rewardKey luôn undefined, cô lập đúng một
  // nguyên nhân duy nhất).
  repository.casUpdate = async (args) => {
    repository.state.last_activity_day = '2026-09-10';
    return originalCasUpdate(args);
  };
  const service = createStreakService({ repository });

  const result = await service.recordActivity({
    userId: 'u1',
    type: 'srs.review',
    sourceId: 'p1',
    now: NOW,
  });

  assert.equal(result.xpAwarded, 0);
  assert.equal(repository.calls.some(([name]) => name === 'appendXpEvent'), false);
  assert.equal(repository.calls.some(([name]) => name === 'markDay'), false);
});

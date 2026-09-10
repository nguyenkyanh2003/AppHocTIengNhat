# Mốc 1 — SRS sống lại + nền streak Phần A

> **Cho người thực thi:** dùng skill `superpowers:subagent-driven-development` (khuyến nghị)
> hoặc `superpowers:executing-plans` để làm từng task. Các bước dùng checkbox `- [ ]`.

**Goal:** Người học đánh dấu một từ đã học, hôm sau ôn lại được theo lịch, mỗi lượt ôn ghi
đúng một lần hoạt động ngày và 2 XP — trên nền ghi nhận hoạt động dùng chung.

**Architecture:** Giữ scheduler Leitner và repository đã đúng của Giai đoạn 1; xoá controller
SRS cũ và dựng lại module theo bốn tầng. Trước đó phải có nền streak Phần A (unit of work,
`recordActivity`, bảng XP, `dayKey`) vì SRS ghi hoạt động qua nền này chứ không tự viết. Ghi
lịch ôn dùng compare-and-set trong transaction cùng với ghi hoạt động.

**Tech Stack:** Node 22 + Express 5 + Mongoose 8 + zod 4, test bằng `node --test` + supertest;
Flutter 3.29 + Provider + go_router 17, test bằng `flutter_test`.

**Spec:**
- [spec SRS](../specs/2026-09-09-srs-revival-design.md)
- [spec streak](../specs/2026-09-09-streak-integrity-design.md) — Phần A
- [spec chương trình](../specs/2026-09-09-learning-loop-program-design.md)

## Global Constraints

- Controller **không** `try/catch`; service ném `ApiError`; `asyncHandler` + `error.middleware.js`
  xử lý phần còn lại.
- Service nhận repository qua tham số. **Không test nào chạm MongoDB hay mạng.**
- Response: một tài nguyên `{ data }`; danh sách `{ data, total }`. Danh sách rỗng luôn là
  **200 với mảng rỗng**, không bao giờ 404.
- Đổi route công khai → cập nhật `BackEnd/tests/route-contract.test.js` (`expectedCount`,
  `expectedSignatureHash`) **trong cùng commit**, có chủ đích.
- Đổi điều hướng Flutter → cập nhật `FrontEnd/test/navigation_contract_test.dart` cùng commit.
- Model mới dùng **snake_case tiếng Anh**.
- Múi giờ streak: hằng số một chỗ, `Asia/Ho_Chi_Minh`.
- Mỗi lượt ôn đến hạn được commit: **2 XP**, đúng hay sai như nhau.
- Screen Flutter dưới 250 dòng, dùng `AppScaffold` + `ContentPane` + `AsyncView` + token.
- Cổng trước khi coi task xong: `cd BackEnd && npm test`; `cd FrontEnd && dart analyze
  --fatal-infos && flutter test`.

---

## Task 0: Dữ liệu mẫu và audit dữ liệu — ĐÃ XONG

Task này đã hoàn thành ngày 2026-09-09; ghi lại để người thực thi không làm lại.

**Files:**
- Đã tạo: `BackEnd/scripts/demo-dataset.js` — dữ liệu thuần, không chạm DB
- Đã tạo: `BackEnd/scripts/seed-demo.js` — nạp idempotent, có `--reset`, `--no-progress`
- Đã tạo: `BackEnd/scripts/audit-srs-progress.js` — audit chỉ đọc theo spec SRS §3.7
- Đã tạo: `BackEnd/tests/demo-dataset.test.js` — 17 test, không chạm DB

**Interfaces:**
- Produces: `DEMO_USERS`, `DEMO_LESSONS`, `DEMO_VOCABULARIES`, `DEMO_EXERCISES`,
  `DEMO_SRS_PROGRESS`, `DEMO_DUE_COUNT` từ `scripts/demo-dataset.js`

Bộ dữ liệu: 2 tài khoản (`demo_hocvien` / `DemoHocVien123!`, `demo_admin` / `DemoAdmin123!`),
2 bài học N5 (tự giới thiệu, sinh hoạt hằng ngày), 15 từ vựng, 2 bài tập (7 câu, có một câu
2 đáp án để chạm biên dưới validator), 8 thẻ SRS trong đó **5 thẻ đến hạn**.

Kết quả audit trên `AppHocTiengNhat.srsprogresses` ngày 2026-09-09: 8 bản ghi, **0 bất
thường** ở mọi nhóm. Không cần script migration.

- [x] Chạy `node scripts/seed-demo.js` — dữ liệu đã nạp, chạy lại hai lần cho cùng kết quả
- [x] Chạy `node scripts/audit-srs-progress.js` — 0 bất thường
- [x] `node --test tests/demo-dataset.test.js` — 17/17 đạt

---

## Task 1: Hàm thuần `dayKey` và luật streak

**Files:**
- Create: `BackEnd/src/modules/streaks/streak-rules.js`
- Test: `BackEnd/tests/streak-rules.test.js`

**Interfaces:**
- Produces: `STREAK_TIMEZONE`, `dayKey(date, timeZone?) -> 'YYYY-MM-DD'`,
  `daysBetween(fromKey, toKey) -> number`,
  `applyActivity({ currentStreak, longestStreak, lastActivityDay, freezesAvailable }, todayKey)
  -> { currentStreak, longestStreak, lastActivityDay, freezesUsed, frozenDays, isNewDay, broken }`,
  `projectStreak(state, todayKey) -> { currentStreak, broken }`

Đặt toàn bộ luật ngày ở một file hàm thuần, cùng khuôn với `srs-scheduling.js` đã có. Lý do:
lỗi streak hiện tại nằm ở phép đổi múi giờ và phép so ngày, hai thứ chỉ test được rẻ khi
chúng không chạm DB.

- [ ] **Step 1: Viết test thất bại**

```js
// BackEnd/tests/streak-rules.test.js
import assert from 'node:assert/strict';
import test from 'node:test';

import {
  applyActivity,
  dayKey,
  daysBetween,
  projectStreak,
} from '../src/modules/streaks/streak-rules.js';

test('dayKey trả YYYY-MM-DD theo giờ Việt Nam', () => {
  // 2026-09-09T17:30:00Z = 2026-09-10 00:30 giờ VN → đã sang ngày mới
  assert.equal(dayKey(new Date('2026-09-09T17:30:00Z')), '2026-09-10');
  // 2026-09-09T16:30:00Z = 2026-09-09 23:30 giờ VN → vẫn là hôm trước
  assert.equal(dayKey(new Date('2026-09-09T16:30:00Z')), '2026-09-09');
});

test('daysBetween đếm theo ngày lịch, không theo giờ', () => {
  assert.equal(daysBetween('2026-09-09', '2026-09-09'), 0);
  assert.equal(daysBetween('2026-09-09', '2026-09-10'), 1);
  assert.equal(daysBetween('2026-02-28', '2026-03-01'), 1); // 2026 không nhuận
});

test('học lần đầu bắt đầu chuỗi từ 1', () => {
  const next = applyActivity(
    { currentStreak: 0, longestStreak: 0, lastActivityDay: null, freezesAvailable: 0 },
    '2026-09-09',
  );
  assert.equal(next.currentStreak, 1);
  assert.equal(next.isNewDay, true);
});

test('học lại trong cùng ngày không tăng chuỗi', () => {
  const next = applyActivity(
    { currentStreak: 3, longestStreak: 5, lastActivityDay: '2026-09-09', freezesAvailable: 0 },
    '2026-09-09',
  );
  assert.equal(next.currentStreak, 3);
  assert.equal(next.isNewDay, false);
  assert.equal(next.freezesUsed, 0);
});

test('ngày liên tiếp tăng chuỗi và nâng kỷ lục', () => {
  const next = applyActivity(
    { currentStreak: 5, longestStreak: 5, lastActivityDay: '2026-09-09', freezesAvailable: 0 },
    '2026-09-10',
  );
  assert.equal(next.currentStreak, 6);
  assert.equal(next.longestStreak, 6);
});

test('nghỉ một ngày, có băng thì chuỗi tiếp tục', () => {
  const next = applyActivity(
    { currentStreak: 5, longestStreak: 9, lastActivityDay: '2026-09-09', freezesAvailable: 2 },
    '2026-09-11',
  );
  assert.equal(next.currentStreak, 6);
  assert.equal(next.freezesUsed, 1);
  assert.deepEqual(next.frozenDays, ['2026-09-10']);
  assert.equal(next.broken, false);
});

test('nghỉ ba ngày với hai băng thì chuỗi đứt', () => {
  const next = applyActivity(
    { currentStreak: 40, longestStreak: 40, lastActivityDay: '2026-09-09', freezesAvailable: 2 },
    '2026-09-13',
  );
  assert.equal(next.currentStreak, 1);
  assert.equal(next.longestStreak, 40, 'kỷ lục phải giữ nguyên');
  assert.equal(next.freezesUsed, 0, 'đứt rồi thì không tiêu băng');
  assert.equal(next.broken, true);
});

test('projectStreak không tiêu băng — chỉ mở app chưa học', () => {
  const view = projectStreak(
    { currentStreak: 5, lastActivityDay: '2026-09-09', freezesAvailable: 2 },
    '2026-09-11',
  );
  assert.equal(view.currentStreak, 5, 'chưa học thì chưa được trừ băng');
  assert.equal(view.broken, false);
});
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd BackEnd && node --test tests/streak-rules.test.js`
Expected: FAIL — `Cannot find module '../src/modules/streaks/streak-rules.js'`

- [ ] **Step 3: Viết cài đặt tối thiểu**

```js
// BackEnd/src/modules/streaks/streak-rules.js
/**
 * Luật ngày của streak, viết dưới dạng hàm thuần.
 *
 * Không chạm DB và không đọc đồng hồ hệ thống (ngày "hôm nay" luôn được truyền
 * vào), nên test chạy được mọi tình huống nghỉ dài mà không phải chờ thời gian.
 */
export const STREAK_TIMEZONE = 'Asia/Ho_Chi_Minh';

export const MAX_FREEZES = 2;

/**
 * Khoá ngày dạng `YYYY-MM-DD` theo múi giờ chỉ định.
 *
 * Dùng `en-CA` vì locale này trả thẳng định dạng ISO, nên không phải parse lại
 * chuỗi như cách cũ (`new Date(d.toLocaleString('en-US', …))`) — cách đó phụ
 * thuộc định dạng en-US và múi giờ của server để parse.
 */
export const dayKey = (date, timeZone = STREAK_TIMEZONE) =>
  new Intl.DateTimeFormat('en-CA', { timeZone }).format(date);

/** Số ngày lịch giữa hai khoá ngày. */
export const daysBetween = (fromKey, toKey) => {
  const from = Date.parse(`${fromKey}T00:00:00Z`);
  const to = Date.parse(`${toKey}T00:00:00Z`);
  return Math.round((to - from) / 86_400_000);
};

/**
 * Áp một lần hoạt động học lên trạng thái streak.
 *
 * Băng chỉ bị tiêu ở đây — tức là chỉ khi người học thật sự học. Xem
 * [projectStreak] cho đường đọc.
 */
export const applyActivity = (state, todayKey) => {
  const { currentStreak = 0, longestStreak = 0, freezesAvailable = 0 } = state;
  const unchanged = {
    currentStreak,
    longestStreak,
    lastActivityDay: state.lastActivityDay,
    freezesUsed: 0,
    frozenDays: [],
    isNewDay: false,
    broken: false,
  };

  if (!state.lastActivityDay) {
    return {
      ...unchanged,
      currentStreak: 1,
      longestStreak: Math.max(longestStreak, 1),
      lastActivityDay: todayKey,
      isNewDay: true,
    };
  }

  const gap = daysBetween(state.lastActivityDay, todayKey);
  if (gap <= 0) return unchanged;

  const missed = gap - 1;
  if (missed > 0 && freezesAvailable < missed) {
    return {
      ...unchanged,
      currentStreak: 1,
      lastActivityDay: todayKey,
      isNewDay: true,
      broken: true,
    };
  }

  const frozenDays = Array.from({ length: missed }, (_, index) => {
    const day = new Date(Date.parse(`${state.lastActivityDay}T00:00:00Z`));
    day.setUTCDate(day.getUTCDate() + index + 1);
    return day.toISOString().slice(0, 10);
  });

  const next = currentStreak + 1;
  return {
    currentStreak: next,
    longestStreak: Math.max(longestStreak, next),
    lastActivityDay: todayKey,
    freezesUsed: missed,
    frozenDays,
    isNewDay: true,
    broken: false,
  };
};

/**
 * Trạng thái streak để **hiển thị**, không ghi gì và không tiêu băng.
 *
 * Đường đọc phải dùng hàm này: nếu dùng `applyActivity` thì chỉ mở ứng dụng
 * sau kỳ nghỉ đã bị trừ băng, dù người học chưa ôn thẻ nào.
 */
export const projectStreak = (state, todayKey) => {
  if (!state.lastActivityDay) return { currentStreak: 0, broken: false };

  const gap = daysBetween(state.lastActivityDay, todayKey);
  const missed = Math.max(0, gap - 1);
  if (missed === 0) return { currentStreak: state.currentStreak, broken: false };

  const covered = missed <= (state.freezesAvailable ?? 0);
  return {
    currentStreak: covered ? state.currentStreak : 0,
    broken: !covered,
  };
};
```

- [ ] **Step 4: Chạy lại cho pass**

Run: `cd BackEnd && node --test tests/streak-rules.test.js`
Expected: PASS, 8/8

- [ ] **Step 5: Commit**

```bash
git add BackEnd/src/modules/streaks/streak-rules.js BackEnd/tests/streak-rules.test.js
git commit -m "feat(streaks): add pure day and freeze rules"
```

---

## Task 2: Unit of work cho transaction

**Files:**
- Create: `BackEnd/src/shared/db/unit-of-work.js`
- Test: `BackEnd/tests/unit-of-work.test.js`

**Interfaces:**
- Produces: `createUnitOfWork({ connection, maxRetries? }) -> { run(fn) }` với
  `fn({ session })`; `unitOfWork` là bản dựng sẵn từ mongoose connection

Spec SRS §5 yêu cầu ghi lịch ôn và ghi hoạt động **trong cùng transaction**, và xử lý
write-conflict bằng retry có giới hạn. Tách ra một chỗ để service không tự quản session.

- [ ] **Step 1: Viết test thất bại**

```js
// BackEnd/tests/unit-of-work.test.js
import assert from 'node:assert/strict';
import test from 'node:test';

import { createUnitOfWork } from '../src/shared/db/unit-of-work.js';

/** Connection giả: ghi lại vòng đời session, không chạm MongoDB. */
const fakeConnection = () => {
  const events = [];
  return {
    events,
    startSession: async () => ({
      withTransaction: async (fn) => {
        events.push('begin');
        const result = await fn();
        events.push('commit');
        return result;
      },
      endSession: async () => events.push('end'),
    }),
  };
};

test('chạy hàm trong transaction rồi đóng session', async () => {
  const connection = fakeConnection();
  const uow = createUnitOfWork({ connection });

  const result = await uow.run(async ({ session }) => {
    assert.ok(session, 'phải truyền session xuống');
    return 'xong';
  });

  assert.equal(result, 'xong');
  assert.deepEqual(connection.events, ['begin', 'commit', 'end']);
});

test('đóng session cả khi hàm ném lỗi', async () => {
  const connection = fakeConnection();
  const uow = createUnitOfWork({ connection });

  await assert.rejects(
    uow.run(async () => {
      throw new Error('vỡ giữa chừng');
    }),
    /vỡ giữa chừng/,
  );
  assert.ok(connection.events.includes('end'), 'session phải được đóng');
});

test('thử lại khi gặp write conflict, tối đa số lần cho phép', async () => {
  const connection = fakeConnection();
  let attempts = 0;
  const uow = createUnitOfWork({ connection, maxRetries: 3 });

  const result = await uow.run(async () => {
    attempts += 1;
    if (attempts < 3) {
      const error = new Error('WriteConflict');
      error.errorLabels = ['TransientTransactionError'];
      throw error;
    }
    return attempts;
  });

  assert.equal(result, 3);
});

test('lỗi không phải transient thì không thử lại', async () => {
  const connection = fakeConnection();
  let attempts = 0;
  const uow = createUnitOfWork({ connection, maxRetries: 3 });

  await assert.rejects(
    uow.run(async () => {
      attempts += 1;
      throw new Error('lỗi nghiệp vụ');
    }),
  );
  assert.equal(attempts, 1);
});
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd BackEnd && node --test tests/unit-of-work.test.js`
Expected: FAIL — không tìm thấy module

- [ ] **Step 3: Viết cài đặt**

```js
// BackEnd/src/shared/db/unit-of-work.js
import mongoose from 'mongoose';

const TRANSIENT_LABEL = 'TransientTransactionError';

const isTransient = (error) =>
  Array.isArray(error?.errorLabels) && error.errorLabels.includes(TRANSIENT_LABEL);

/**
 * Gom nhiều lệnh ghi vào một transaction.
 *
 * Service gọi `run(fn)` và nhận `session` để truyền xuống repository. Nhờ vậy
 * lịch ôn và bản ghi hoạt động học không thể commit lệch nhau — spec SRS §5
 * yêu cầu lỗi ghi hoạt động phải rollback cả lịch.
 *
 * Write conflict của MongoDB được thử lại có giới hạn; mỗi lần chạy lại, hàm
 * `fn` đọc và kiểm tra lại từ đầu chứ không phát lại lệnh tính từ snapshot cũ.
 */
export const createUnitOfWork = ({ connection, maxRetries = 3 }) => ({
  async run(fn) {
    const session = await connection.startSession();
    try {
      for (let attempt = 1; ; attempt += 1) {
        try {
          return await session.withTransaction(() => fn({ session }));
        } catch (error) {
          if (!isTransient(error) || attempt >= maxRetries) throw error;
        }
      }
    } finally {
      await session.endSession();
    }
  },
});

export const unitOfWork = createUnitOfWork({ connection: mongoose.connection });

export default unitOfWork;
```

- [ ] **Step 4: Chạy lại cho pass**

Run: `cd BackEnd && node --test tests/unit-of-work.test.js`
Expected: PASS, 4/4

- [ ] **Step 5: Commit**

```bash
git add BackEnd/src/shared/db/unit-of-work.js BackEnd/tests/unit-of-work.test.js
git commit -m "feat(shared): add unit of work for multi-write transactions"
```

---

## Task 3: Model `XpEvent`, `StreakDay` và repository streak

**Files:**
- Create: `BackEnd/model/XpEvent.js`
- Create: `BackEnd/model/StreakDay.js`
- Create: `BackEnd/src/modules/streaks/streak.repository.js`
- Modify: `BackEnd/model/UserStreak.js` — bỏ `xp_history`, `activity_dates`; thêm
  `last_activity_day: String`, `freezes_available: Number`
- Test: `BackEnd/tests/streak.repository.test.js`

**Interfaces:**
- Consumes: không
- Produces: `createStreakRepository({ UserStreak, XpEvent, StreakDay })` với
  `findByUser({ userId, session })`, `casUpdate({ userId, expectedDay, patch, session })`,
  `appendXpEvent({ userId, amount, reason, type, sourceId, session })`,
  `markDay({ userId, dayKey, status, session })`, `listXpEvents({ userId, page, limit })`

Hai mảng `xp_history` và `activity_dates` nằm trong document được đọc mỗi lần xem streak và
tăng không có chặn trên. Tách ra collection riêng đồng thời cấp đúng dữ liệu mà lịch học ở
Phần B cần.

- [ ] **Step 1: Viết test thất bại**

```js
// BackEnd/tests/streak.repository.test.js
import assert from 'node:assert/strict';
import test from 'node:test';

import { createStreakRepository } from '../src/modules/streaks/streak.repository.js';

/** Model giả: ghi lại filter và update để khẳng định đúng tên trường. */
const fakeModel = (result = null) => {
  const calls = [];
  return {
    calls,
    findOne: (filter) => ({
      session: () => ({ lean: async () => (calls.push(['findOne', filter]), result) }),
    }),
    findOneAndUpdate: async (filter, update, options) => {
      calls.push(['findOneAndUpdate', filter, update, options]);
      return result;
    },
    create: async (docs) => (calls.push(['create', docs]), docs),
    updateOne: async (filter, update, options) => {
      calls.push(['updateOne', filter, update, options]);
      return { upsertedCount: 1 };
    },
  };
};

test('casUpdate so khớp last_activity_day đã đọc', async () => {
  const UserStreak = fakeModel({ _id: 's1' });
  const repository = createStreakRepository({
    UserStreak,
    XpEvent: fakeModel(),
    StreakDay: fakeModel(),
  });

  await repository.casUpdate({
    userId: 'u1',
    expectedDay: '2026-09-09',
    patch: { current_streak: 6, last_activity_day: '2026-09-10' },
    session: 'sess',
  });

  const [, filter, update] = UserStreak.calls.at(-1);
  assert.deepEqual(filter, { user: 'u1', last_activity_day: '2026-09-09' });
  assert.equal(update.$set.current_streak, 6);
});

test('casUpdate với expectedDay null khớp document chưa từng học', async () => {
  const UserStreak = fakeModel({ _id: 's1' });
  const repository = createStreakRepository({
    UserStreak,
    XpEvent: fakeModel(),
    StreakDay: fakeModel(),
  });

  await repository.casUpdate({
    userId: 'u1',
    expectedDay: null,
    patch: { current_streak: 1 },
  });

  const [, filter] = UserStreak.calls.at(-1);
  assert.deepEqual(filter, { user: 'u1', last_activity_day: null });
});

test('markDay upsert theo (user, day_key) nên gọi lại không sinh bản sao', async () => {
  const StreakDay = fakeModel();
  const repository = createStreakRepository({
    UserStreak: fakeModel(),
    XpEvent: fakeModel(),
    StreakDay,
  });

  await repository.markDay({ userId: 'u1', dayKey: '2026-09-10', status: 'studied' });

  const [, filter, , options] = StreakDay.calls.at(-1);
  assert.deepEqual(filter, { user: 'u1', day_key: '2026-09-10' });
  assert.equal(options.upsert, true);
});
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd BackEnd && node --test tests/streak.repository.test.js`
Expected: FAIL — không tìm thấy module

- [ ] **Step 3: Viết model và repository**

```js
// BackEnd/model/XpEvent.js
import mongoose from 'mongoose';

/**
 * Một lần cộng XP.
 *
 * Trước đây nằm trong mảng `xp_history` của `UserStreak`, tức là tăng vô hạn
 * trong một document được đọc ở mọi lần xem streak.
 */
const XpEventSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    amount: { type: Number, required: true },
    reason: { type: String, trim: true },
    type: { type: String, trim: true },
    source_id: { type: String, trim: true },
    earned_at: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

XpEventSchema.index({ user: 1, earned_at: -1 });

export default mongoose.model('XpEvent', XpEventSchema);
```

```js
// BackEnd/model/StreakDay.js
import mongoose from 'mongoose';

/**
 * Một ngày trong lịch học của người dùng.
 *
 * `status` phân biệt ngày đã học với ngày được băng bảo vệ; ngày nghỉ đơn giản
 * là không có bản ghi. Đây là nguồn dữ liệu của màn lịch ở Phần B.
 */
const StreakDaySchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    day_key: { type: String, required: true },
    status: { type: String, enum: ['studied', 'frozen'], required: true },
  },
  { timestamps: true },
);

StreakDaySchema.index({ user: 1, day_key: 1 }, { unique: true });

export default mongoose.model('StreakDay', StreakDaySchema);
```

```js
// BackEnd/src/modules/streaks/streak.repository.js
import StreakDay from '../../../model/StreakDay.js';
import UserStreak from '../../../model/UserStreak.js';
import XpEvent from '../../../model/XpEvent.js';

/**
 * Truy cập dữ liệu streak, XP và lịch học.
 *
 * `casUpdate` là điểm mấu chốt: nó chỉ ghi khi `last_activity_day` trong DB vẫn
 * đúng bằng giá trị vừa đọc. Nhờ vậy hai request đồng thời (hai thiết bị, một
 * lần gửi lại sau timeout) không thể cùng tiêu băng hoặc cùng tăng chuỗi.
 */
export const createStreakRepository = ({
  UserStreak: streakModel = UserStreak,
  XpEvent: xpModel = XpEvent,
  StreakDay: dayModel = StreakDay,
} = {}) => ({
  findByUser({ userId, session }) {
    return streakModel.findOne({ user: userId }).session(session).lean();
  },

  casUpdate({ userId, expectedDay, patch, session }) {
    return streakModel.findOneAndUpdate(
      { user: userId, last_activity_day: expectedDay ?? null },
      { $set: patch },
      { new: true, session },
    );
  },

  ensureFor({ userId, session }) {
    return streakModel.findOneAndUpdate(
      { user: userId },
      { $setOnInsert: { user: userId } },
      { upsert: true, new: true, setDefaultsOnInsert: true, session },
    );
  },

  appendXpEvent({ userId, amount, reason, type, sourceId, earnedAt, session }) {
    return xpModel.create(
      [
        {
          user: userId,
          amount,
          reason,
          type,
          source_id: sourceId,
          earned_at: earnedAt,
        },
      ],
      { session },
    );
  },

  markDay({ userId, dayKey, status, session }) {
    return dayModel.updateOne(
      { user: userId, day_key: dayKey },
      { $setOnInsert: { user: userId, day_key: dayKey, status } },
      { upsert: true, session },
    );
  },

  listXpEvents({ userId, page = 1, limit = 20 }) {
    return xpModel
      .find({ user: userId })
      .sort({ earned_at: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean();
  },

  countXpEvents({ userId }) {
    return xpModel.countDocuments({ user: userId });
  },
});

export const streakRepository = createStreakRepository();

export default streakRepository;
```

Sửa `BackEnd/model/UserStreak.js`: bỏ hai trường mảng `xp_history` và `activity_dates`, bỏ ba
method `updateStreakOnActivity`, `checkAndUpdateStreak`, `addXP` (luật đã chuyển sang
`streak-rules.js`), thêm:

```js
  last_activity_day: { type: String, default: null },
  freezes_available: { type: Number, default: 0, min: 0, max: 2 },
```

Giữ `reward_keys` — spec §3.3 vẫn dùng nó cho hoạt động một-lần.

- [ ] **Step 4: Chạy lại cho pass**

Run: `cd BackEnd && node --test tests/streak.repository.test.js`
Expected: PASS, 3/3

- [ ] **Step 5: Commit**

```bash
git add BackEnd/model/XpEvent.js BackEnd/model/StreakDay.js BackEnd/model/UserStreak.js \
  BackEnd/src/modules/streaks/streak.repository.js BackEnd/tests/streak.repository.test.js
git commit -m "feat(streaks): move xp history and activity days out of the streak document"
```

---

## Task 4: `recordActivity` — một đường ghi nhận duy nhất

**Files:**
- Create: `BackEnd/src/modules/streaks/streak.service.js`
- Test: `BackEnd/tests/streak.service.test.js`

**Interfaces:**
- Consumes: `streak-rules.js` (Task 1), `streak.repository.js` (Task 3)
- Produces: `XP_BY_ACTIVITY`, `STREAK_MILESTONES`,
  `createStreakService({ repository, rules, achievements })` với
  `recordActivity({ userId, type, sourceId, now, session }) ->
  { currentStreak, isNewDay, xpAwarded, milestonesReached }`,
  `readSummary({ userId, now })`

Hiện có ba cách ghi streak khác nhau và ba module import `UserStreak` trực tiếp; JLPT thì
viết một `findOneAndUpdate` không bao giờ tăng chuỗi. Task này tạo đường duy nhất.

- [ ] **Step 1: Viết test thất bại**

```js
// BackEnd/tests/streak.service.test.js
import assert from 'node:assert/strict';
import test from 'node:test';

import {
  XP_BY_ACTIVITY,
  createStreakService,
} from '../src/modules/streaks/streak.service.js';

const NOW = new Date('2026-09-10T03:00:00Z'); // 10:00 giờ VN

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
  const calls = [];
  return {
    calls,
    state,
    ensureFor: async () => state,
    findByUser: async () => state,
    casUpdate: async ({ expectedDay, patch }) => {
      calls.push(['casUpdate', expectedDay, patch]);
      if (state.last_activity_day !== (expectedDay ?? null)) return null;
      Object.assign(state, patch);
      return state;
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

  const patch = repository.calls.find(([name]) => name === 'casUpdate')?.[2] ?? {};
  assert.ok(!('reward_keys' in patch), 'lượt ôn lặp lại không được ghi khoá');
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
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd BackEnd && node --test tests/streak.service.test.js`
Expected: FAIL — không tìm thấy module

- [ ] **Step 3: Viết service**

```js
// BackEnd/src/modules/streaks/streak.service.js
import { ApiError } from '../../shared/http/api-error.js';
import { streakRepository } from './streak.repository.js';
import { applyActivity, dayKey, projectStreak } from './streak-rules.js';

/**
 * XP của từng loại hoạt động, quyết định ở server.
 *
 * Trước đây mỗi module tự chọn số XP và endpoint `/streak/add-xp` còn nhận
 * `amount` thẳng từ client mà không có trần. Bảng này là nguồn duy nhất.
 */
export const XP_BY_ACTIVITY = Object.freeze({
  'srs.review': 2,
  'lesson.progress': 5,
  'exercise.submit': 10,
  'lesson.complete': 15,
  'jlpt.submit': 20,
});

/** Hoạt động chỉ xảy ra một lần cho mỗi `sourceId`. */
const ONE_SHOT = new Set([
  'lesson.complete',
  'lesson.progress',
  'exercise.submit',
  'jlpt.submit',
]);

/** Một thang mốc duy nhất, dùng cho cả thưởng XP lẫn huy hiệu. */
export const STREAK_MILESTONES = Object.freeze([7, 14, 30, 50, 100, 365]);

export const createStreakService = ({
  repository = streakRepository,
  rules = { applyActivity, dayKey, projectStreak },
} = {}) => ({
  /**
   * Ghi nhận một hoạt động học đã hoàn thành.
   *
   * Chỉ gọi **sau khi** nghiệp vụ của hoạt động đã ghi thành công. Hàm nhận
   * `session` để chạy trong cùng transaction với lệnh ghi đó, nên lỗi ở đây
   * rollback luôn cả lịch ôn.
   */
  async recordActivity({ userId, type, sourceId, now = new Date(), session }) {
    const xp = XP_BY_ACTIVITY[type];
    if (xp === undefined) {
      throw ApiError.badRequest('Loại hoạt động không hợp lệ.', {
        code: 'UNKNOWN_ACTIVITY_TYPE',
      });
    }

    const current = await repository.ensureFor({ userId, session });
    const rewardKey = `${type}:${sourceId}`;
    const alreadyRewarded =
      ONE_SHOT.has(type) && (current.reward_keys ?? []).includes(rewardKey);

    if (alreadyRewarded) {
      return {
        currentStreak: current.current_streak,
        isNewDay: false,
        xpAwarded: 0,
        milestonesReached: [],
      };
    }

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

    const patch = {
      current_streak: next.currentStreak,
      longest_streak: next.longestStreak,
      last_activity_day: next.lastActivityDay,
      freezes_available: current.freezes_available - next.freezesUsed,
      total_xp: (current.total_xp ?? 0) + xp,
    };
    if (ONE_SHOT.has(type)) {
      patch.reward_keys = [...(current.reward_keys ?? []), rewardKey];
    }

    const saved = await repository.casUpdate({
      userId,
      expectedDay: current.last_activity_day,
      patch,
      session,
    });

    // Thua CAS nghĩa là một request khác đã xử lý trạng thái này rồi. Không ghi
    // XP và không ghi ngày lần nữa; trả về trạng thái hiện có.
    if (!saved) {
      const latest = await repository.findByUser({ userId, session });
      return {
        currentStreak: latest?.current_streak ?? current.current_streak,
        isNewDay: false,
        xpAwarded: 0,
        milestonesReached: [],
      };
    }

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
    for (const day of next.frozenDays) {
      await repository.markDay({ userId, dayKey: day, status: 'frozen', session });
    }

    const milestonesReached = next.isNewDay
      ? STREAK_MILESTONES.filter((m) => m === next.currentStreak)
      : [];

    return {
      currentStreak: next.currentStreak,
      isNewDay: next.isNewDay,
      xpAwarded: xp,
      milestonesReached,
    };
  },

  /** Tóm tắt để hiển thị. Không tiêu băng, không ghi gì. */
  async readSummary({ userId, now = new Date() }) {
    const streak = await repository.findByUser({ userId });
    if (!streak) return { current_streak: 0, longest_streak: 0, total_xp: 0 };

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

export const streakService = createStreakService();

export default streakService;
```

- [ ] **Step 4: Chạy lại cho pass**

Run: `cd BackEnd && node --test tests/streak.service.test.js`
Expected: PASS, 7/7

- [ ] **Step 5: Commit**

```bash
git add BackEnd/src/modules/streaks/streak.service.js BackEnd/tests/streak.service.test.js
git commit -m "feat(streaks): funnel every activity through one recorder"
```

---

## Task 5: Nối lại mọi nguồn ghi và đóng lỗ hổng

**Files:**
- Modify: `BackEnd/src/modules/users/user.repository.js:98` — `recordLoginStreak` →
  `readStreakSummary`, bỏ tăng chuỗi và bỏ 10 XP
- Modify: `BackEnd/src/modules/users/user-auth.service.js:87` — đổi tên hàm gọi
- Modify: `BackEnd/src/modules/jlpt/jlpt.controller.js:339` — thay khối `findOneAndUpdate`
- Modify: `BackEnd/src/modules/exercise/exercise.controller.js:157-166`
- Modify: `BackEnd/src/modules/lesson-progress/lesson-progress.repository.js:183`
- Modify: `BackEnd/src/modules/progress/progress.controller.js:124`
- Modify: `BackEnd/src/modules/streaks/streak.controller.js` — bỏ `postAddXp`,
  `postTestResetYesterday`, `getTestDebug`; `getXpHistory` đọc từ `XpEvent`
- Modify: `BackEnd/src/modules/streaks/streak.routes.js` — còn 3 route
- Modify: `BackEnd/src/modules/grammar/grammar.controller.js`,
  `BackEnd/src/modules/kanji/kanji.controller.js` — bỏ import `UserStreak` không dùng
- Modify: `BackEnd/tests/route-contract.test.js`
- Test: `BackEnd/tests/streak.routes.test.js`

**Interfaces:**
- Consumes: `streakService.recordActivity` (Task 4)
- Produces: route `/api/streak` còn `GET /my-streak`, `GET /xp-history`, `GET /leaderboard`

- [ ] **Step 1: Viết test HTTP thất bại**

```js
// BackEnd/tests/streak.routes.test.js
import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { createStreakRoutes } from '../src/modules/streaks/streak.routes.js';

const passthrough = (user) => (req, _res, next) => {
  req.user = user;
  next();
};

const buildApp = (service) => {
  const app = express();
  app.use(express.json());
  app.use(
    '/api/streak',
    createStreakRoutes({ service, authenticate: passthrough({ _id: 'u1' }) }),
  );
  app.use(errorHandler);
  return app;
};

const fakeService = {
  readSummary: async () => ({ current_streak: 3, longest_streak: 9, total_xp: 40 }),
  listXpEvents: async () => ({ items: [], total: 0, page: 1, limit: 20 }),
  leaderboard: async () => [],
};

test('đã bỏ endpoint cho phép client tự cấp XP', async () => {
  const response = await request(buildApp(fakeService))
    .post('/api/streak/add-xp')
    .send({ amount: 999999, reason: 'gian lận' });

  assert.equal(response.status, 404);
});

test('đã bỏ các endpoint test khỏi production', async () => {
  const app = buildApp(fakeService);
  assert.equal((await request(app).post('/api/streak/test/reset-yesterday')).status, 404);
  assert.equal((await request(app).get('/api/streak/test/debug')).status, 404);
});

test('my-streak trả tóm tắt theo contract { data }', async () => {
  const response = await request(buildApp(fakeService)).get('/api/streak/my-streak');

  assert.equal(response.status, 200);
  assert.equal(response.body.data.current_streak, 3);
});

test('xp-history vẫn chạy — màn xuất dữ liệu đang dùng', async () => {
  const response = await request(buildApp(fakeService)).get('/api/streak/xp-history');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body.data, []);
  assert.equal(response.body.total, 0);
});
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd BackEnd && node --test tests/streak.routes.test.js`
Expected: FAIL — `createStreakRoutes` chưa tồn tại

- [ ] **Step 3: Dựng lại routes/controller và nối các nguồn**

Trong `streak.routes.js`, đổi sang khuôn nhận dependency giống `vocabulary.routes.js`:

```js
export const createStreakRoutes = ({
  service = streakService,
  authenticate = authenticateUser,
} = {}) => {
  const controller = createStreakController(service);
  const router = express.Router();

  router.get('/my-streak', authenticate, asyncHandler(controller.mySummary));
  router.get(
    '/xp-history',
    authenticate,
    validate({ query: schema.xpHistoryQuery }),
    asyncHandler(controller.xpHistory),
  );
  router.get('/leaderboard', authenticate, asyncHandler(controller.leaderboard));

  return router;
};
```

Tại `jlpt.controller.js:339`, thay toàn bộ khối `UserStreak.findOneAndUpdate` bằng:

```js
await streakService.recordActivity({
  userId,
  type: 'jlpt.submit',
  sourceId: String(savedResult._id),
});
```

Làm tương tự cho `exercise.controller.js` (`exercise.submit`, `sourceId` là id kết quả),
`lesson-progress.repository.js` (`lesson.complete`) và `progress.controller.js`
(`lesson.progress`). Bỏ mọi `import UserStreak` còn lại ngoài `streak.repository.js`.

- [ ] **Step 4: Chạy lại cho pass và cập nhật route contract**

```bash
cd BackEnd && node --test tests/streak.routes.test.js && npm test
```

`route-contract.test.js` sẽ đỏ vì bớt 3 route. Chạy `npm test`, đọc số route và hash mới
trong thông báo lỗi, cập nhật `expectedCount` (261 → 258) và `expectedSignatureHash` **sau
khi** đã xác nhận danh sách route mới đúng ý.

- [ ] **Step 5: Commit**

```bash
git add BackEnd/src BackEnd/tests
git commit -m "fix(streaks): stop trusting the client for xp and streak days"
```

---

## Task 6: Mở rộng repository SRS

**Files:**
- Modify: `BackEnd/src/modules/srs/srs.repository.js`
- Test: `BackEnd/tests/srs.repository.test.js`

**Interfaces:**
- Consumes: không
- Produces: thêm vào repository hiện có —
  `findDueBatch({ userId, itemType, limit, excludeItemIds, now, session })`,
  `countDue({ userId, itemType, now })`,
  `casApplyAnswer({ userId, itemId, itemType, progressId, expected, patch, session })`,
  `casReset({ userId, itemId, itemType, progressId, expected, patch, session })`,
  `statsByBox({ userId, itemType })`

Giữ nguyên bốn hàm `findLearnedItemIds`, `findProgress`, `createProgress`, `deleteProgress`
mà `vocabulary.service.js` đang dùng — đổi chữ ký của chúng sẽ làm vỡ luồng đánh dấu đã học.

- [ ] **Step 1: Viết test thất bại**

```js
// BackEnd/tests/srs.repository.test.js
import assert from 'node:assert/strict';
import test from 'node:test';

import { createSrsRepository } from '../src/modules/srs/srs.repository.js';

const NOW = new Date('2026-09-10T03:00:00Z');

/** Model giả ghi lại đúng filter/sort/limit đã dựng. */
const fakeModel = () => {
  const calls = [];
  const chain = (result) => ({
    sort(sort) { calls.push(['sort', sort]); return chain(result); },
    limit(limit) { calls.push(['limit', limit]); return chain(result); },
    session() { return chain(result); },
    lean: async () => result,
  });
  return {
    calls,
    find(filter) { calls.push(['find', filter]); return chain([]); },
    countDocuments: async (filter) => (calls.push(['count', filter]), 7),
    findOneAndUpdate: async (filter, update, options) => {
      calls.push(['findOneAndUpdate', filter, update, options]);
      return { _id: 'p1' };
    },
    aggregate: async (pipeline) => (calls.push(['aggregate', pipeline]), []),
  };
};

test('findDueBatch lọc theo user, type, đến hạn và loại trừ', async () => {
  const model = fakeModel();
  const repository = createSrsRepository({ SRSProgress: model });

  await repository.findDueBatch({
    userId: 'u1',
    itemType: 'Vocabulary',
    limit: 20,
    excludeItemIds: ['i1', 'i2'],
    now: NOW,
  });

  const [, filter] = model.calls.find(([name]) => name === 'find');
  assert.equal(filter.user, 'u1');
  assert.equal(filter.item_type, 'Vocabulary');
  assert.deepEqual(filter.next_review, { $lte: NOW });
  assert.deepEqual(filter.item_id, { $nin: ['i1', 'i2'] });
});

test('findDueBatch sắp xếp ổn định rồi mới giới hạn', async () => {
  const model = fakeModel();
  const repository = createSrsRepository({ SRSProgress: model });

  await repository.findDueBatch({ userId: 'u1', itemType: 'Vocabulary', limit: 20, now: NOW });

  const names = model.calls.map(([name]) => name);
  assert.deepEqual(
    model.calls.find(([name]) => name === 'sort')[1],
    { next_review: 1, _id: 1 },
  );
  assert.ok(names.indexOf('sort') < names.indexOf('limit'), 'sort phải trước limit');
});

test('countDue không nhận danh sách loại trừ — badge đếm toàn bộ', async () => {
  const model = fakeModel();
  const repository = createSrsRepository({ SRSProgress: model });

  await repository.countDue({ userId: 'u1', itemType: 'Vocabulary', now: NOW });

  const [, filter] = model.calls.find(([name]) => name === 'count');
  assert.ok(!('item_id' in filter), 'countDue không được lọc theo exclude');
});

test('casApplyAnswer chỉ ghi khi trạng thái vẫn đúng như đã đọc', async () => {
  const model = fakeModel();
  const repository = createSrsRepository({ SRSProgress: model });

  await repository.casApplyAnswer({
    userId: 'u1',
    itemId: 'i1',
    itemType: 'Vocabulary',
    progressId: 'p1',
    expected: { box: 2, streak: 1, nextReview: new Date('2026-09-09T00:00:00Z') },
    patch: { box: 3, streak: 2, next_review: NOW },
    now: NOW,
  });

  const [, filter, , options] = model.calls.find(([n]) => n === 'findOneAndUpdate');
  assert.equal(filter._id, 'p1');
  assert.equal(filter.user, 'u1');
  assert.equal(filter.box, 2);
  assert.equal(filter.streak, 1);
  assert.deepEqual(filter.next_review, {
    $eq: new Date('2026-09-09T00:00:00Z'),
    $lte: NOW,
  });
  assert.notEqual(options.upsert, true, 'không được upsert — thẻ có thể vừa bị xoá');
});
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd BackEnd && node --test tests/srs.repository.test.js`
Expected: FAIL — `findDueBatch is not a function`

- [ ] **Step 3: Thêm năm hàm vào repository**

```js
  /**
   * Một đợt thẻ đến hạn.
   *
   * Cố ý **không** có `skip`: mọi thẻ được trả lời đều rời khỏi tập đến hạn
   * (đúng thì giãn ngày, sai thì hẹn sau 24 giờ), nên offset sẽ nhảy cóc qua
   * đúng số thẻ vừa ôn. Client làm hết đợt rồi lấy lại đợt đầu, kèm danh sách
   * thẻ đã xử lý trong phiên ở `excludeItemIds`.
   */
  findDueBatch({ userId, itemType, limit, excludeItemIds = [], now, session }) {
    const filter = {
      user: userId,
      item_type: itemType,
      next_review: { $lte: now },
    };
    if (excludeItemIds.length > 0) filter.item_id = { $nin: excludeItemIds };

    return model
      .find(filter)
      .sort({ next_review: 1, _id: 1 })
      .limit(limit)
      .session(session)
      .lean();
  },

  /** Tổng số thẻ đến hạn — badge, không trừ danh sách bỏ qua của phiên. */
  countDue({ userId, itemType, now }) {
    return model.countDocuments({
      user: userId,
      item_type: itemType,
      next_review: { $lte: now },
    });
  },

  /**
   * Ghi lịch mới, chỉ khi tiến độ vẫn đúng như lúc đọc **và** vẫn đến hạn.
   *
   * Điều kiện `_id` + `box` + `streak` + `next_review` chặn hai lượt trả lời
   * đồng thời cùng ghi, và chặn cả trường hợp thẻ vừa bị reset hoặc xoá.
   */
  casApplyAnswer({ userId, itemId, itemType, progressId, expected, patch, now, session }) {
    return model.findOneAndUpdate(
      {
        _id: progressId,
        user: userId,
        item_id: itemId,
        item_type: itemType,
        box: expected.box,
        streak: expected.streak,
        next_review: { $eq: expected.nextReview, $lte: now },
      },
      { $set: patch },
      { new: true, session },
    );
  },

  /** Như trên nhưng **không** đòi đến hạn — reset làm được lúc nào cũng được. */
  casReset({ userId, itemId, itemType, progressId, expected, patch, session }) {
    return model.findOneAndUpdate(
      {
        _id: progressId,
        user: userId,
        item_id: itemId,
        item_type: itemType,
        box: expected.box,
        streak: expected.streak,
        next_review: expected.nextReview,
      },
      { $set: patch },
      { new: true, session },
    );
  },

  statsByBox({ userId, itemType }) {
    return model.aggregate([
      { $match: { user: userId, item_type: itemType } },
      { $group: { _id: '$box', count: { $sum: 1 } } },
    ]);
  },
```

- [ ] **Step 4: Chạy lại cho pass**

Run: `cd BackEnd && node --test tests/srs.repository.test.js && node --test tests/vocabulary.service.test.js`
Expected: PASS cả hai — test vocabulary chứng minh bốn hàm cũ chưa đổi chữ ký

- [ ] **Step 5: Commit**

```bash
git add BackEnd/src/modules/srs/srs.repository.js BackEnd/tests/srs.repository.test.js
git commit -m "feat(srs): add due batch, conditional writes and box stats"
```

---

## Task 7: Schema zod cho sáu route

**Files:**
- Create: `BackEnd/src/modules/srs/srs.schema.js`
- Test: `BackEnd/tests/srs.schema.test.js`

**Interfaces:**
- Produces: `dueQuery`, `dueCountQuery`, `reviewBody`, `statsQuery`, `resetParams`,
  `resetBody`, `deleteParams`, `deleteQuery`

- [ ] **Step 1: Viết test thất bại**

```js
// BackEnd/tests/srs.schema.test.js
import assert from 'node:assert/strict';
import test from 'node:test';

import { dueQuery, reviewBody } from '../src/modules/srs/srs.schema.js';

const ID = '507f1f77bcf86cd799439011';

test('item_type phải đúng chữ hoa như enum của model', () => {
  assert.equal(dueQuery.safeParse({ item_type: 'vocabulary' }).success, false);
  assert.equal(dueQuery.safeParse({ item_type: 'Vocabulary' }).success, true);
});

test('limit mặc định 20 và chặn trên 100', () => {
  assert.equal(dueQuery.parse({}).limit, 20);
  assert.equal(dueQuery.safeParse({ limit: '101' }).success, false);
});

test('exclude_item_ids tách theo dấu phẩy, dedupe, tối đa 200', () => {
  const parsed = dueQuery.parse({ exclude_item_ids: `${ID},${ID}` });
  assert.deepEqual(parsed.exclude_item_ids, [ID]);

  const tooMany = Array.from({ length: 201 }, () => ID).join(',');
  assert.equal(dueQuery.safeParse({ exclude_item_ids: tooMany }).success, false);
});

test('review bắt buộc is_correct và expected_next_review', () => {
  assert.equal(reviewBody.safeParse({ item_id: ID }).success, false);
  assert.equal(
    reviewBody.safeParse({
      item_id: ID,
      is_correct: true,
      expected_next_review: '2026-09-09T00:00:00.000Z',
    }).success,
    true,
  );
});

test('review từ chối is_correct dạng chuỗi', () => {
  const result = reviewBody.safeParse({
    item_id: ID,
    is_correct: 'true',
    expected_next_review: '2026-09-09T00:00:00.000Z',
  });
  assert.equal(result.success, false);
});
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd BackEnd && node --test tests/srs.schema.test.js`
Expected: FAIL — không tìm thấy module

- [ ] **Step 3: Viết schema**

```js
// BackEnd/src/modules/srs/srs.schema.js
import { z } from 'zod';

const objectId = z
  .string()
  .regex(/^[0-9a-fA-F]{24}$/, 'Định danh không hợp lệ.');

/** Đúng bằng enum của `model/SRSProgress.js`; chữ thường bị từ chối. */
const itemType = z.enum(['Vocabulary', 'Kanji']).default('Vocabulary');

const MAX_EXCLUDED = 200;

/** `"a,b,a"` → `['a','b']`; chuỗi rỗng coi như không truyền. */
const excludeItemIds = z
  .preprocess(
    (value) =>
      typeof value === 'string' && value.length > 0
        ? [...new Set(value.split(','))]
        : [],
    z.array(objectId).max(MAX_EXCLUDED, `Tối đa ${MAX_EXCLUDED} thẻ bỏ qua.`),
  )
  .default([]);

export const dueQuery = z.object({
  item_type: itemType,
  limit: z.coerce.number().int().min(1).max(100).default(20),
  exclude_item_ids: excludeItemIds,
});

export const dueCountQuery = z.object({ item_type: itemType });
export const statsQuery = z.object({ item_type: itemType });

export const reviewBody = z.object({
  item_id: objectId,
  item_type: itemType,
  is_correct: z.boolean(),
  expected_next_review: z.coerce.date(),
});

export const resetParams = z.object({ itemId: objectId });
export const resetBody = z.object({
  item_type: itemType,
  expected_next_review: z.coerce.date(),
});

export const deleteParams = z.object({ itemId: objectId });
export const deleteQuery = z.object({ item_type: itemType });
```

- [ ] **Step 4: Chạy lại cho pass**

Run: `cd BackEnd && node --test tests/srs.schema.test.js`
Expected: PASS, 5/5

- [ ] **Step 5: Commit**

```bash
git add BackEnd/src/modules/srs/srs.schema.js BackEnd/tests/srs.schema.test.js
git commit -m "feat(srs): validate every srs request with zod"
```

---

## Task 8: Service SRS — review nguyên tử và ghi hoạt động

**Files:**
- Create: `BackEnd/src/modules/srs/srs.service.js`
- Test: `BackEnd/tests/srs.service.test.js`

**Interfaces:**
- Consumes: `srs.repository.js` (Task 6), `srs-scheduling.js` (có sẵn),
  `streakService.recordActivity` (Task 4), `unitOfWork` (Task 2)
- Produces: `createSrsService({ repository, contentRepository, streak, uow, scheduling })`
  với `listDue`, `countDue`, `review`, `reset`, `remove`, `stats`

- [ ] **Step 1: Viết test thất bại**

```js
// BackEnd/tests/srs.service.test.js
import assert from 'node:assert/strict';
import test from 'node:test';

import { createSrsService } from '../src/modules/srs/srs.service.js';

const NOW = new Date('2026-09-10T03:00:00Z');
const DUE = new Date('2026-09-09T00:00:00Z');
const ITEM = '507f1f77bcf86cd799439011';

const progress = (overrides = {}) => ({
  _id: 'p1',
  user: 'u1',
  item_id: ITEM,
  item_type: 'Vocabulary',
  box: 2,
  streak: 1,
  next_review: DUE,
  ...overrides,
});

const build = ({ found = progress(), cas = progress({ box: 3 }), content = { _id: ITEM, word: '学生' } } = {}) => {
  const recorded = [];
  const service = createSrsService({
    repository: {
      findProgress: async () => found,
      findDueBatch: async () => [progress()],
      countDue: async () => 5,
      casApplyAnswer: async () => cas,
      casReset: async () => cas,
      deleteProgress: async () => 1,
      statsByBox: async () => [{ _id: 1, count: 2 }],
    },
    contentRepository: { findManyByIds: async () => (content ? [content] : []) },
    streak: { recordActivity: async (args) => recorded.push(args) },
    uow: { run: async (fn) => fn({ session: 'sess' }) },
  });
  return { service, recorded };
};

test('không có tiến độ của user thì 404', async () => {
  const { service } = build({ found: null });
  await assert.rejects(
    service.review({ userId: 'u1', itemId: ITEM, itemType: 'Vocabulary', isCorrect: true, expectedNextReview: DUE, now: NOW }),
    (error) => error.status === 404,
  );
});

test('thẻ chưa đến hạn trả 409 SRS_NOT_DUE kèm tiến độ hiện tại', async () => {
  const future = new Date('2026-09-20T00:00:00Z');
  const { service } = build({ found: progress({ next_review: future }) });

  await assert.rejects(
    service.review({ userId: 'u1', itemId: ITEM, itemType: 'Vocabulary', isCorrect: true, expectedNextReview: future, now: NOW }),
    (error) => error.status === 409 && error.code === 'SRS_NOT_DUE'
      && error.details.current_progress.next_review === future,
  );
});

test('lịch đã đổi so với thẻ đang xem trả 409 SRS_PROGRESS_CHANGED', async () => {
  const { service } = build();
  await assert.rejects(
    service.review({
      userId: 'u1', itemId: ITEM, itemType: 'Vocabulary', isCorrect: true,
      expectedNextReview: new Date('2026-01-01T00:00:00Z'), now: NOW,
    }),
    (error) => error.status === 409 && error.code === 'SRS_PROGRESS_CHANGED',
  );
});

test('nội dung đã mất trả 409 ITEM_UNAVAILABLE, không tự xoá tiến độ', async () => {
  const { service } = build({ content: null });
  await assert.rejects(
    service.review({ userId: 'u1', itemId: ITEM, itemType: 'Vocabulary', isCorrect: true, expectedNextReview: DUE, now: NOW }),
    (error) => error.status === 409 && error.code === 'ITEM_UNAVAILABLE',
  );
});

test('trả lời thành công ghi hoạt động srs.review trong cùng session', async () => {
  const { service, recorded } = build();

  const result = await service.review({
    userId: 'u1', itemId: ITEM, itemType: 'Vocabulary', isCorrect: true,
    expectedNextReview: DUE, now: NOW,
  });

  assert.equal(result.box, 3);
  assert.equal(recorded.length, 1);
  assert.equal(recorded[0].type, 'srs.review');
  assert.equal(recorded[0].session, 'sess', 'phải nằm trong cùng transaction');
});

test('trả lời sai cũng ghi hoạt động — vẫn là học', async () => {
  const { service, recorded } = build({ cas: progress({ box: 1, streak: 0 }) });

  await service.review({
    userId: 'u1', itemId: ITEM, itemType: 'Vocabulary', isCorrect: false,
    expectedNextReview: DUE, now: NOW,
  });

  assert.equal(recorded.length, 1);
});

test('thua CAS thì báo 409, không ghi hoạt động', async () => {
  const { service, recorded } = build({ cas: null });

  await assert.rejects(
    service.review({ userId: 'u1', itemId: ITEM, itemType: 'Vocabulary', isCorrect: true, expectedNextReview: DUE, now: NOW }),
    (error) => error.status === 409,
  );
  assert.equal(recorded.length, 0);
});

test('reset không cần đến hạn và không ghi hoạt động', async () => {
  const future = new Date('2026-09-20T00:00:00Z');
  const { service, recorded } = build({ found: progress({ next_review: future }) });

  await service.reset({ userId: 'u1', itemId: ITEM, itemType: 'Vocabulary', expectedNextReview: future, now: NOW });

  assert.equal(recorded.length, 0, 'reset không phải hoạt động học');
});

test('danh sách rỗng trả mảng rỗng, không ném', async () => {
  const { service } = build();
  service.__repository = null;
  const result = await service.listDue({ userId: 'u1', itemType: 'Vocabulary', limit: 20, excludeItemIds: [], now: NOW });
  assert.ok(Array.isArray(result.items));
});
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd BackEnd && node --test tests/srs.service.test.js`
Expected: FAIL — không tìm thấy module

- [ ] **Step 3: Viết service theo đúng thứ tự §3.5 của spec**

Trình tự bắt buộc: đọc → kiểm 404 → kiểm `SRS_NOT_DUE` → kiểm `SRS_PROGRESS_CHANGED` →
kiểm `ITEM_UNAVAILABLE` → `applyAnswer` → CAS → `recordActivity` (trước commit, cùng
`session`) → commit. Thua CAS thì đọc lại **vẫn theo user** để phân loại 404 / 409.

- [ ] **Step 4: Chạy lại cho pass**

Run: `cd BackEnd && node --test tests/srs.service.test.js`
Expected: PASS, 9/9

- [ ] **Step 5: Commit**

```bash
git add BackEnd/src/modules/srs/srs.service.js BackEnd/tests/srs.service.test.js
git commit -m "feat(srs): apply answers atomically and record the study day with them"
```

---

## Task 9: Controller, routes và xoá module cũ

**Files:**
- Create: `BackEnd/src/modules/srs/srs.controller.js`, `BackEnd/src/modules/srs/srs.routes.js`
- Delete: `BackEnd/src/modules/srs/srs-progress.controller.js`,
  `BackEnd/src/modules/srs/srs-progress.routes.js`
- Modify: `BackEnd/src/app.js:22` — import `./modules/srs/srs.routes.js`
- Modify: `BackEnd/tests/route-contract.test.js`
- Test: `BackEnd/tests/srs.routes.test.js`

**Interfaces:**
- Consumes: `srs.service.js` (Task 8), `srs.schema.js` (Task 7)
- Produces: sáu route dưới `/api/srs` theo bảng ở spec §3.3

- [ ] **Step 1: Viết test HTTP thất bại**

```js
// BackEnd/tests/srs.routes.test.js
import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { ApiError } from '../src/shared/http/api-error.js';
import { createSrsRoutes } from '../src/modules/srs/srs.routes.js';

const ID = '507f1f77bcf86cd799439011';
const passthrough = (user) => (req, _res, next) => { req.user = user; next(); };

const buildApp = (service) => {
  const app = express();
  app.use(express.json());
  app.use('/api/srs', createSrsRoutes({ service, authenticate: passthrough({ _id: 'u1' }) }));
  app.use(errorHandler);
  return app;
};

test('due trả { data, limit }, không có page/totalPages', async () => {
  const app = buildApp({ listDue: async () => ({ items: [], limit: 20 }) });
  const response = await request(app).get('/api/srs/due');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body.data, []);
  assert.equal(response.body.limit, 20);
  assert.ok(!('page' in response.body), 'batch không dùng phân trang chung');
});

test('item_type chữ thường bị chặn ở tầng validate', async () => {
  const app = buildApp({ listDue: async () => ({ items: [], limit: 20 }) });
  const response = await request(app).get('/api/srs/due?item_type=vocabulary');

  assert.equal(response.status, 400);
  assert.equal(response.body.code, 'VALIDATION_ERROR');
});

test('409 giữ nguyên code và details cho client', async () => {
  const app = buildApp({
    review: async () => {
      throw ApiError.conflict('Thẻ chưa đến hạn ôn.', {
        code: 'SRS_NOT_DUE',
        details: { current_progress: { _id: 'p1', box: 2 } },
      });
    },
  });

  const response = await request(app).post('/api/srs/review').send({
    item_id: ID,
    is_correct: true,
    expected_next_review: '2026-09-09T00:00:00.000Z',
  });

  assert.equal(response.status, 409);
  assert.equal(response.body.code, 'SRS_NOT_DUE');
  assert.equal(response.body.details.current_progress.box, 2);
});

test('xoá lần thứ hai trả 200 với deleted=false', async () => {
  const app = buildApp({ remove: async () => ({ deleted: false }) });
  const response = await request(app).delete(`/api/srs/items/${ID}`);

  assert.equal(response.status, 200);
  assert.equal(response.body.data.deleted, false);
});

test('route cũ đã biến mất', async () => {
  const app = buildApp({});
  assert.equal((await request(app).get('/api/srs/my-cards')).status, 404);
  assert.equal((await request(app).get('/api/srs/admin/all')).status, 404);
});
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd BackEnd && node --test tests/srs.routes.test.js`
Expected: FAIL — `createSrsRoutes` chưa tồn tại

- [ ] **Step 3: Viết controller + routes, xoá hai file cũ, đổi import trong `app.js`**

- [ ] **Step 4: Chạy toàn bộ và cập nhật route contract**

Run: `cd BackEnd && npm test`
Contract sẽ đỏ: 12 route SRS → 6. Đối chiếu danh sách route mới với bảng ở spec §3.3, rồi
cập nhật `expectedCount` (258 → 252) và `expectedSignatureHash`.

- [ ] **Step 5: Commit**

```bash
git add BackEnd/src BackEnd/tests
git commit -m "feat(srs): replace the legacy controller with a four-layer module"
```

---

## Task 10: Chi tiết từ vựng trả kèm tiến độ SRS

**Files:**
- Modify: `BackEnd/src/modules/vocabulary/vocabulary.service.js` — `getById` thêm
  `srs_progress`
- Test: `BackEnd/tests/vocabulary.service.test.js` — thêm case

**Interfaces:**
- Produces: `GET /api/vocabulary/:id` → `data.srs_progress: SrsProgress | null`

Màn chi tiết từ vựng cần reset/xoá lịch cho thẻ **chưa đến hạn**. Spec §4 chọn mở rộng
response sẵn có thay vì thêm route SRS thứ bảy, vì `getById` đã truy vấn progress rồi.

- [ ] **Step 1: Thêm test thất bại**

```js
test('chi tiết từ vựng trả kèm tiến độ SRS của chính user', async () => {
  const service = createVocabularyService({
    vocabularyRepository: fakeVocabularyRepository(),
    srsRepository: {
      ...fakeSrsRepository(),
      findProgress: async () => ({ _id: 'p1', box: 2, next_review: new Date() }),
    },
  });

  const detail = await service.getById({ id: 'v1', userId: 'u1' });
  assert.equal(detail.srs_progress._id, 'p1');
});

test('chưa học thì srs_progress là null, không phải thiếu field', async () => {
  const service = createVocabularyService({
    vocabularyRepository: fakeVocabularyRepository(),
    srsRepository: { ...fakeSrsRepository(), findProgress: async () => null },
  });

  const detail = await service.getById({ id: 'v1', userId: 'u1' });
  assert.equal(detail.srs_progress, null);
});
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd BackEnd && node --test tests/vocabulary.service.test.js`
Expected: FAIL — `srs_progress` undefined

- [ ] **Step 3: Thêm field vào `getById`, giữ nguyên mọi field cũ**

- [ ] **Step 4: Chạy lại cho pass**

Run: `cd BackEnd && npm test`

- [ ] **Step 5: Commit**

```bash
git add BackEnd/src/modules/vocabulary BackEnd/tests/vocabulary.service.test.js
git commit -m "feat(vocabulary): expose the learner's srs progress on detail"
```

---

## Task 11: `ApiException` mang được statusCode, code và details

**Files:**
- Modify: `FrontEnd/lib/core/network/api_client.dart:332-360`
- Test: `FrontEnd/test/api_exception_test.dart`

**Interfaces:**
- Produces: `ApiException(message, {int? statusCode, String? code, Map<String, dynamic>? details})`

Hiện `ApiException` chỉ có `message`, nên Flutter không phân biệt được `SRS_NOT_DUE` với
`SRS_PROGRESS_CHANGED` — hai lỗi cần hai cách xử lý khác nhau trên màn ôn tập.

- [ ] **Step 1: Viết test thất bại**

```dart
// FrontEnd/test/api_exception_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';

void main() {
  test('giữ được statusCode, code và details từ response lỗi', () {
    final error = ApiException(
      'Thẻ chưa đến hạn ôn.',
      statusCode: 409,
      code: 'SRS_NOT_DUE',
      details: const {
        'current_progress': {'box': 2},
      },
    );

    expect(error.statusCode, 409);
    expect(error.code, 'SRS_NOT_DUE');
    expect(error.details?['current_progress']['box'], 2);
  });

  test('vẫn dựng được chỉ với message — không phá chỗ gọi cũ', () {
    final error = ApiException('Đã có lỗi xảy ra.');
    expect(error.message, 'Đã có lỗi xảy ra.');
    expect(error.code, isNull);
  });
}
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd FrontEnd && flutter test test/api_exception_test.dart`
Expected: FAIL — không có tham số `statusCode`

- [ ] **Step 3: Thêm ba field tuỳ chọn và điền chúng khi map lỗi HTTP**

```dart
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code, this.details});

  final String message;

  /// Mã HTTP, để phân biệt 404 với 409 mà không phải so khớp chuỗi.
  final int? statusCode;

  /// Mã lỗi nghiệp vụ của backend (`SRS_NOT_DUE`, `ITEM_UNAVAILABLE`…).
  final String? code;

  /// Dữ liệu kèm theo; với 409 của SRS là `{ current_progress: {...} }`.
  final Map<String, dynamic>? details;

  @override
  String toString() => message;
}
```

Sửa chỗ dựng exception trong `ApiClient` để đọc `code` và `details` từ body JSON.

- [ ] **Step 4: Chạy lại cho pass**

Run: `cd FrontEnd && flutter test test/api_exception_test.dart && flutter test`
Expected: PASS, và toàn bộ 98 test cũ vẫn xanh

- [ ] **Step 5: Commit**

```bash
git add FrontEnd/lib/core/network/api_client.dart FrontEnd/test/api_exception_test.dart
git commit -m "feat(core): carry error code and details through ApiException"
```

---

## Task 12: Model và service SRS phía Flutter

**Files:**
- Modify: `FrontEnd/lib/features/srs/models/srs_progress.dart`
- Create: `FrontEnd/lib/features/srs/models/srs_card.dart`,
  `FrontEnd/lib/features/srs/models/srs_stats.dart`
- Modify: `FrontEnd/lib/features/srs/services/srs_service.dart` — viết lại theo sáu endpoint
- Test: `FrontEnd/test/srs_service_test.dart`

**Interfaces:**
- Consumes: `ApiException` (Task 11)
- Produces: `SrsService` với `fetchDue({itemType, limit, excludeItemIds})`,
  `fetchDueCount()`, `review({itemId, isCorrect, expectedNextReview})`,
  `reset({itemId, expectedNextReview})`, `remove({itemId})`, `fetchStats()`

Service hiện tại gọi ba endpoint không tồn tại, gửi `rating` 1–4 trong khi backend là
đúng/sai, và nuốt mọi lỗi bằng `debugPrint` rồi trả `null`.

- [ ] **Step 1: Viết test thất bại**

```dart
// FrontEnd/test/srs_service_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/srs/services/srs_service.dart';

void main() {
  test('dựng query loại trừ bằng dấu phẩy', () {
    final query = SrsService.buildDueQuery(
      itemType: 'Vocabulary',
      limit: 20,
      excludeItemIds: const ['a1', 'b2'],
    );

    expect(query['item_type'], 'Vocabulary');
    expect(query['limit'], '20');
    expect(query['exclude_item_ids'], 'a1,b2');
  });

  test('không gửi exclude_item_ids khi danh sách rỗng', () {
    final query = SrsService.buildDueQuery(
      itemType: 'Vocabulary',
      limit: 20,
      excludeItemIds: const [],
    );

    expect(query.containsKey('exclude_item_ids'), isFalse);
  });

  test('gửi is_correct dạng boolean, không phải rating 1..4', () {
    final body = SrsService.buildReviewBody(
      itemId: 'v1',
      isCorrect: false,
      expectedNextReview: DateTime.utc(2026, 9, 9),
    );

    expect(body['is_correct'], isA<bool>());
    expect(body['is_correct'], false);
    expect(body['expected_next_review'], '2026-09-09T00:00:00.000Z');
    expect(body.containsKey('rating'), isFalse);
  });
}
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd FrontEnd && flutter test test/srs_service_test.dart`
Expected: FAIL — `SrsService.buildDueQuery` chưa tồn tại

- [ ] **Step 3: Viết model và service; xoá `StreakService.addXP` cùng
`StreakProvider.addXP`** (spec streak §3.5 yêu cầu xoá cùng commit bỏ route)

- [ ] **Step 4: Chạy lại cho pass**

Run: `cd FrontEnd && flutter test test/srs_service_test.dart`

- [ ] **Step 5: Commit**

```bash
git add FrontEnd/lib/features/srs FrontEnd/lib/features/streaks FrontEnd/test/srs_service_test.dart
git commit -m "feat(srs): rewrite the flutter service against the real contract"
```

---

## Task 13: Provider giữ trạng thái phiên ôn

**Files:**
- Create: `FrontEnd/lib/features/srs/providers/srs_provider.dart`
- Test: `FrontEnd/test/srs_provider_test.dart`

**Interfaces:**
- Consumes: `SrsService` (Task 12)
- Produces: `SrsProvider` với `ViewState<List<SrsCard>> batchState`, `int dueCount`,
  `Set<String> handledItemIds`, `loadBatch()`, `answer(card, isCorrect)`, `skip(card)`,
  `refreshBadge()`

- [ ] **Step 1: Viết test thất bại**

```dart
// FrontEnd/test/srs_provider_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/srs/providers/srs_provider.dart';

void main() {
  test('trả lời xong thì thẻ vào danh sách đã xử lý của phiên', () async {
    final provider = SrsProvider(service: _FakeSrsService());
    await provider.loadBatch();

    await provider.answer(provider.currentCard!, isCorrect: true);

    expect(provider.handledItemIds, contains('v1'));
  });

  test('bỏ qua cũng vào danh sách đã xử lý nhưng không gọi mạng', () async {
    final service = _FakeSrsService();
    final provider = SrsProvider(service: service);
    await provider.loadBatch();

    provider.skip(provider.currentCard!);

    expect(provider.handledItemIds, contains('v1'));
    expect(service.reviewCalls, 0);
  });

  test('lỗi mạng khi gửi câu trả lời không làm mất danh sách đang có', () async {
    final service = _FakeSrsService()..reviewError = NetworkException('mất mạng');
    final provider = SrsProvider(service: service);
    await provider.loadBatch();

    await provider.answer(provider.currentCard!, isCorrect: true);

    expect(provider.batchState.hasData, isTrue, 'không được thay bằng ViewFailure');
    expect(provider.mutationError, isNotNull);
    expect(
      provider.handledItemIds,
      isNot(contains('v1')),
      'lỗi mạng chưa xác định kết quả thì không đánh dấu đã xử lý',
    );
  });

  test('409 SRS_NOT_DUE thì đánh dấu đã xử lý và chuyển thẻ', () async {
    final service = _FakeSrsService()
      ..reviewError = ApiException('chưa đến hạn', statusCode: 409, code: 'SRS_NOT_DUE');
    final provider = SrsProvider(service: service);
    await provider.loadBatch();

    await provider.answer(provider.currentCard!, isCorrect: true);

    expect(provider.handledItemIds, contains('v1'));
  });

  test('badge lấy từ countDue, không lấy độ dài danh sách', () async {
    final provider = SrsProvider(service: _FakeSrsService(dueCount: 42, batchSize: 3));
    await provider.loadBatch();
    await provider.refreshBadge();

    expect(provider.dueCount, 42);
  });
}
```

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd FrontEnd && flutter test test/srs_provider_test.dart`

- [ ] **Step 3: Viết provider theo luật ở spec §3.4**

`handledItemIds` chỉ thêm khi: review/reset/xoá thành công, bỏ qua, hoặc lỗi 404/409 đã
xử lý xong. **Không** thêm khi lỗi mạng hoặc 5xx. Giới hạn 200 ID.

- [ ] **Step 4: Chạy lại cho pass**

- [ ] **Step 5: Commit**

```bash
git add FrontEnd/lib/features/srs/providers FrontEnd/test/srs_provider_test.dart
git commit -m "feat(srs): keep the review session state in one provider"
```

---

## Task 14: Màn ôn tập

**Files:**
- Create: `FrontEnd/lib/features/srs/screens/srs_review_screen.dart` (dưới 250 dòng)
- Create: `FrontEnd/lib/features/srs/widgets/srs_review_card.dart`,
  `srs_answer_bar.dart`, `srs_session_summary.dart`
- Test: `FrontEnd/test/srs_review_screen_test.dart`

**Interfaces:**
- Consumes: `SrsProvider` (Task 13)

- [ ] **Step 1: Viết test thất bại**

```dart
// FrontEnd/test/srs_review_screen_test.dart — bốn nhánh AsyncView + hành vi lật thẻ
void main() {
  testWidgets('không có thẻ đến hạn thì hiện trạng thái rỗng', (tester) async {
    await tester.pumpWidget(_host(_FakeSrsProvider(cards: const [])));
    await tester.pumpAndSettle();

    expect(find.textContaining('Không có thẻ'), findsOneWidget);
  });

  testWidgets('mặt trước ẩn đáp án cho tới khi lật', (tester) async {
    await tester.pumpWidget(_host(_FakeSrsProvider(cards: [_card()])));
    await tester.pumpAndSettle();

    expect(find.text('học sinh'), findsNothing);
    await tester.tap(find.byKey(const Key('srs-flip')));
    await tester.pumpAndSettle();
    expect(find.text('học sinh'), findsOneWidget);
  });

  testWidgets('nút Nhớ/Chưa nhớ bị khoá khi đang gửi', (tester) async {
    final provider = _FakeSrsProvider(cards: [_card()], submitting: true);
    await tester.pumpWidget(_host(provider));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byKey(const Key('srs-remember')));
    expect(button.onPressed, isNull);
  });

  testWidgets('thẻ mất nội dung không cho trả lời', (tester) async {
    await tester.pumpWidget(_host(_FakeSrsProvider(cards: [_unavailableCard()])));
    await tester.pumpAndSettle();

    expect(find.textContaining('không còn tồn tại'), findsOneWidget);
    expect(find.byKey(const Key('srs-remember')), findsNothing);
  });
}
```

- [ ] **Step 2: Chạy để chắc nó fail**

- [ ] **Step 3: Viết màn hình và widget, dùng `AppScaffold` + `ContentPane` + `AsyncView`**

- [ ] **Step 4: Chạy lại cho pass**

- [ ] **Step 5: Commit**

```bash
git add FrontEnd/lib/features/srs FrontEnd/test/srs_review_screen_test.dart
git commit -m "feat(srs): add the daily review screen"
```

---

## Task 15: Điều hướng, badge và kiểm chứng cuối

**Files:**
- Modify: `FrontEnd/lib/app/router/app_router.dart` — thêm `/srs` vào `contract` và cây route
- Modify: `FrontEnd/lib/app/shell/app_navigation.dart` — thêm "Ôn tập hôm nay" đầu hub `/review`
- Modify: `FrontEnd/lib/app/shell/hub_screen.dart` — hiện badge số thẻ đến hạn
- Modify: `FrontEnd/test/navigation_contract_test.dart`
- Modify: `FrontEnd/test/breakpoint_overflow_test.dart` — thêm `/srs`

**Interfaces:**
- Consumes: `SrsProvider.dueCount` (Task 13)

- [ ] **Step 1: Cập nhật contract test trước (nó sẽ đỏ)**

Thêm `'/srs'` vào tập kỳ vọng trong `navigation_contract_test.dart`.

- [ ] **Step 2: Chạy để chắc nó fail**

Run: `cd FrontEnd && flutter test test/navigation_contract_test.dart`
Expected: FAIL — cây route thật chưa có `/srs`

- [ ] **Step 3: Đăng ký route và mục hub**

Badge lấy từ provider, **không** đặt số động vào metadata `app_navigation.dart`.

- [ ] **Step 4: Chạy toàn bộ cổng**

```bash
cd FrontEnd && dart analyze --fatal-infos && flutter test && flutter build web --release
cd ../BackEnd && npm test
```

- [ ] **Step 5: Kiểm thử tay trên dữ liệu demo**

```bash
cd BackEnd && node scripts/seed-demo.js
npm run dev
```

Đăng nhập `demo_hocvien` / `DemoHocVien123!` rồi kiểm:

| Kiểm | Kỳ vọng |
| --- | --- |
| Mở `/review` | Badge "Ôn tập hôm nay" hiện **5** |
| Ôn hết 5 thẻ | Danh sách rỗng, badge về 0 |
| Trả lời sai một thẻ | Thẻ về box 1, hẹn sau 24 giờ |
| Bấm "Nhớ" hai lần thật nhanh | Lượt thứ hai báo 409, hộp không tăng hai lần |
| Reset một thẻ ở màn chi tiết từ vựng | Box về 1, vẫn còn dấu đã học |
| Đăng nhập lại nhiều lần | `current_streak` **không** đổi |
| Xem `/streak/xp-history` qua màn xuất dữ liệu | Có bản ghi 2 XP cho mỗi lượt ôn |

- [ ] **Step 6: Commit**

```bash
git add FrontEnd/lib/app FrontEnd/test
git commit -m "feat(srs): put today's review behind a navigable route with a due badge"
```

---

## Tự soát plan

**Độ phủ spec:** §3.1 → Task 9; §3.2 → Task 6, 9; §3.3 → Task 7, 9; §3.4 → Task 6, 13;
§3.5 → Task 8; §3.6 → Task 8; §3.7 → Task 0 (đã audit, không cần migrate); §4 → Task 11–15;
§5 → Task 2, 4, 8; §6 → Task 7, 9; §7 → mọi task. Spec streak Phần A §3.1–3.8 → Task 1–5.

**Chưa thuộc plan này (đúng theo spec):** Kanji SRS, băng/lịch/mục tiêu ngày (Phần B),
vacation mode, `/my-cards` và bốn route admin.

**Rủi ro cần theo dõi:** transaction đòi replica set — MongoDB Atlas có sẵn, nhưng nếu ai đó
chạy Mongo standalone thì `unitOfWork` sẽ lỗi; khi đó phải chạy Atlas hoặc replica set cục bộ.

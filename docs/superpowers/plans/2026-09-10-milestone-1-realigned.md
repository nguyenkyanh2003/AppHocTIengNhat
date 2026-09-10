# Mốc 1 — Vòng ôn tập và nền ghi hoạt động (bản chỉnh theo spec)

> **Cho người thực thi:** dùng `superpowers:subagent-driven-development` hoặc
> `superpowers:executing-plans`. Các bước dùng checkbox `- [ ]`.

**Goal:** Người học đánh dấu một từ đã học, hôm sau ôn lại được theo lịch; mỗi lượt ôn hợp lệ
ghi đúng một sự kiện, đúng một ngày học và 2 XP — qua một cổng ghi duy nhất mà client không
tự cấp XP được.

**Architecture:** `ActivityEvent` là nhật ký nguồn: mọi hoạt động được chấp nhận sinh đúng một
event có `event_key` ổn định, và unique index `(user, event_key)` **chính là** cơ chế chống
trùng — không còn mảng khoá trong document tóm tắt. `StreakDay` và `UserStreak` là hai bảng
suy ra, cập nhật trong cùng transaction với event. SRS gọi cổng chung, không tự viết chính
sách XP hay timezone.

**Tech Stack:** Node 22, Express 5, Mongoose 8, zod 4, `node --test` + supertest;
Flutter 3.29, Provider, go_router 17.

**Spec (nguồn ràng buộc — plan chỉ là lập luận, spec thắng khi mâu thuẫn):**
- [streak-integrity](../specs/2026-09-09-streak-integrity-design.md) — Phần A là mốc 1
- [srs-revival](../specs/2026-09-09-srs-revival-design.md)
- [learning-loop-program §4.0](../specs/2026-09-09-learning-loop-program-design.md) — thứ tự
  triển khai bắt buộc; plan này bám đúng khung đó

## Vì sao có bản chỉnh này

[Plan cũ](2026-09-09-srs-revival-and-streak-foundation.md) viết trước khi spec được viết lại.
Đối chiếu 2026-09-10 (6 agent đọc, 12 agent phản biện hai lăng kính) tìm ra **79 sai lệch,
45 blocking**; trong 37 khẳng định được phản biện thì **36 đứng vững**.

Task 0–4 của plan cũ đã commit ở `1081b65`. Bảng dưới nói rõ số phận từng phần:

| Đã có ở `1081b65` | Số phận |
| --- | --- |
| `scripts/demo-dataset.js`, `seed-demo.js`, `audit-srs-progress.js`, `tests/demo-dataset.test.js` | **Giữ nguyên.** Không phụ thuộc phần lệch |
| `streak-rules.js` | Giữ khung; sửa `dayKey` và rà lại luật băng (Bước 1) |
| `shared/db/unit-of-work.js` | Giữ khung; sửa lỗi retry (Bước 1) |
| `model/XpEvent.js` | **Bỏ.** Spec cấm model XP song song |
| `model/StreakDay.js`, `model/UserStreak.js` | Mở rộng theo §3.2 |
| `streak.repository.js`, `streak.service.js` | **Viết lại phần lõi**: chống trùng, chữ ký, chính sách |

## Global Constraints

Giá trị lấy nguyên văn từ spec. Mọi task đều chịu ràng buộc này.

- Cổng ghi duy nhất:
  `recordActivity({ userId, type, sourceId, occurrenceKey, context }, { session, now })`
  (streak §3.1). **Không** endpoint nào cho client gửi activity, XP, ngày học hay trạng thái
  huy hiệu.
- Chống trùng bằng unique `ActivityEvent(user, event_key)`. **Không** thêm khoá vào
  `UserStreak.reward_keys` ở đường ghi mới (streak §3.3).
- Thứ tự trong transaction: ghi kết quả nghiệp vụ (hoặc thắng CAS SRS) → ghi event → ghi
  ngày/tóm tắt/XP/huy hiệu → commit. Lỗi bất kỳ bước nào rollback tất cả (streak §3.1).
- XP do server quyết từ **kết quả đã chấm** (streak §3.4):
  SRS đến hạn đúng/sai `2` · mục bài học mới hoàn thành `2` · hoàn thành bài lần đầu `20` ·
  bài tập đã nộp hợp lệ `10` nếu chấm đạt / `5` nếu chưa đạt · JLPT đã nộp hợp lệ `20` ·
  login / mở bài / đánh dấu từ / reset / xoá / bỏ qua `0` và **không tạo event học**.
- Bỏ thưởng mở bài 3 XP và login 10 XP từ cutover; **không trừ XP đã có**.
- Thang mốc huy hiệu `[7, 14, 30, 50, 100, 365]`; bỏ bonus `%7`/`%30`.
- Event thưởng có `counts_as_study=false`, không tăng XP mục tiêu ngày, không gọi lại
  `recordActivity`.
- `dayKey(now)`: `Intl.DateTimeFormat` với `timeZone: 'Asia/Ho_Chi_Minh'`,
  `calendar: 'gregory'`, `numberingSystem: 'latn'`, lấy `formatToParts()` rồi ghép
  `YYYY-MM-DD`. **Không** dựa vào `format('en-CA')` (streak §3.5).
- CAS chỉ trên `last_activity_day` là **chưa đủ** — phải dùng `revision` (streak §3.5).
- Response theo `shared/http/respond.js`; danh sách rỗng là **200 với mảng rỗng**.
- Controller không `try/catch`; service ném `ApiError`; service nhận repository/clock/policy
  qua tham số.
- Đổi route công khai → cập nhật `BackEnd/tests/route-contract.test.js` cùng commit, sau khi
  **đọc bằng mắt** danh sách route mới.
- Không test nào chạm MongoDB hay mạng.
- `freezes_available` và mọi thứ về freeze/goal/nhắc học thuộc **Phần B (mốc 1B)** — không
  làm trong plan này.
- Cổng trước khi coi task xong: `cd BackEnd && npm test`; `cd FrontEnd && dart analyze
  --fatal-infos && flutter test`.

---

# Bước 0 — Baseline và fixture

## Task 0.1: Fixture và audit SRS — ĐÃ XONG

Commit `1081b65`. Không làm lại.

- [x] `scripts/demo-dataset.js` + `seed-demo.js` (2 tài khoản, 2 bài học, 15 từ, 2 bài tập,
      8 thẻ SRS trong đó 5 đến hạn), idempotent, có `--reset`
- [x] `scripts/audit-srs-progress.js` — chạy trên `AppHocTiengNhat`: 8 bản ghi, **0 bất
      thường**; SRS không cần migration
- [x] `tests/demo-dataset.test.js` — 17 test, không chạm DB

## Task 0.2: Bộ 40 thẻ sinh tự động

**Files:** Modify `BackEnd/scripts/demo-dataset.js`, `BackEnd/scripts/seed-demo.js`,
`BackEnd/tests/demo-dataset.test.js`

Spec chương trình §4.0 bước 0 đòi "bộ 40 thẻ sinh tự động cho test nhiều đợt". Bộ hiện tại
có 8 thẻ nên không kiểm được luồng lấy đợt (`limit` mặc định 20) qua nhiều đợt, cũng không
kiểm được giới hạn 200 ID loại trừ.

- [ ] **B1** Thêm `buildBulkProgress(count)` vào `demo-dataset.js`: sinh `count` bản ghi tiến
      độ trỏ vào các từ có sẵn (lặp lại khi hết từ, dùng `item_type: 'Vocabulary'`), `dueInDays`
      trải từ `-3` đến `0` để tất cả đều đến hạn. Không dùng `Math.random` — chia đều theo chỉ số.
- [ ] **B2** Test: `buildBulkProgress(40)` trả 40 phần tử, tất cả đến hạn, `box` trong 1..5.
- [ ] **B3** `seed-demo.js` nhận cờ `--bulk=<n>` (mặc định không bật) để nạp thêm bộ này.
- [ ] **B4** `npm test` xanh.

## Task 0.3: Audit UserStreak (chỉ đọc)

**Files:** Create `BackEnd/scripts/audit-user-streak.js`

Spec streak §4.1 bước 1–2 bắt buộc audit **trước** migration. Bám khuôn
`audit-srs-progress.js` đã có: đọc qua native collection, không ghi gì, không in nội dung
document, chỉ in tên DB/collection/thời điểm/số lượng theo nhóm.

- [ ] **B1** Đếm theo nhóm: tổng document; `user` thiếu/sai kiểu/không còn tồn tại; trùng
      `user`; `last_activity_date` thiếu/null/sai kiểu Date; `total_xp` âm hoặc sai kiểu;
      độ dài `xp_history`, `activity_dates`, `reward_keys` (min/max/tổng); phần tử
      `xp_history` thiếu `amount`/`earned_at`; `current_streak`/`longest_streak` âm hoặc
      `current > longest`.
- [ ] **B2** In **phân phối giờ:phút UTC** của `activity_dates` và `last_activity_date`.
      Đây là cách duy nhất suy ra timezone host từng ghi dữ liệu legacy (§4.1 bước 2); nếu
      phân phối không tụ về một mốc nửa đêm nào thì báo "không xác định được" chứ đừng đoán.
- [ ] **B3** Audit `UserAchievement`: số bản ghi `is_completed=true` (migration phải sinh
      khoá đánh dấu cho từng cái, §4.1 bước 5).
- [ ] **B4** In index hiện có của cả ba collection.
- [ ] **B5** Chạy thật, dán kết quả vào spec streak §4.1 giống cách đã làm với audit SRS.

**Chặn:** không viết migration trước khi bước này chạy xong trên DB thật.

---

# Bước 1 — Luật, chính sách, model, repository, transaction

## Task 1.1: Sửa `dayKey` sang `formatToParts`

**Files:** Modify `BackEnd/src/modules/streaks/streak-rules.js`,
`BackEnd/tests/streak-rules.test.js`

Đóng: **DEP-6**. Spec §3.5 cấm thẳng cách đang dùng.

`format('en-CA')` phụ thuộc vào việc ICU luôn trả `YYYY-MM-DD` với đúng dấu `-`. Đó là chi
tiết cài đặt, không phải hợp đồng — bản ICU khác có thể đổi dấu phân cách hoặc thứ tự và
`dayKey` sẽ trả chuỗi sai mà không lỗi.

- [ ] **B1** Test mới (thêm, không sửa test cũ): với một `Intl.DateTimeFormat` giả trả
      `parts` theo thứ tự đảo (`day, month, year`) và dấu phân cách `/`, `dayKey` vẫn phải
      trả `YYYY-MM-DD`. Cách làm: cho `dayKey` nhận formatter qua tham số tuỳ chọn.
- [ ] **B2** Chạy, thấy fail.
- [ ] **B3** Viết lại bằng `formatToParts()` + `{ calendar: 'gregory', numberingSystem: 'latn' }`,
      lấy `part.type === 'year'|'month'|'day'`, `padStart(2,'0')`, ghép bằng `-`.
- [ ] **B4** `node --test tests/streak-rules.test.js` — 6 test cũ vẫn xanh, test mới xanh.
- [ ] **B5** `npm test` xanh.

## Task 1.2: Sửa retry của unit of work

**Files:** Modify `BackEnd/src/shared/db/unit-of-work.js`,
`BackEnd/tests/unit-of-work.test.js`

Đóng: **DEP-11**. Lỗi này lọt qua cả review Task 2 lẫn phản biện vì bộ test chỉ phủ
`UnknownTransactionCommitResult` ở commit.

`commitWithRetry` nằm ngoài khối `catch` của `fn`, nên `TransientTransactionError` ném từ
chính `commitTransaction()` thoát thẳng ra ngoài. Khuôn retry chuẩn của MongoDB đòi lỗi
transient — kể cả phát sinh ở commit — phải chạy lại **cả** transaction.

- [ ] **B1** Test mới: `commitTransaction` ném lỗi nhãn `TransientTransactionError` ở lần
      1, thành công ở lần 2 → hàm nghiệp vụ được gọi **2 lần** (chạy lại cả transaction),
      không phải 1.
- [ ] **B2** Chạy, thấy fail.
- [ ] **B3** Đưa `commitWithRetry` vào trong khối `try` chung, hoặc bắt lỗi của nó và phân
      loại: nhãn `UnknownTransactionCommitResult` → chỉ lặp commit; nhãn
      `TransientTransactionError` → `continue` vòng ngoài; không nhãn → ném.
- [ ] **B4** 4 test cũ + test mới đều xanh; `npm test` xanh.

## Task 1.3: `streak-policy.js`

**Files:** Create `BackEnd/src/modules/streaks/streak-policy.js`,
`BackEnd/tests/streak-policy.test.js`

Đóng: **XP-1, XP-2, XP-3, XP-4, SIG-2**.

Spec §3.4 gọi tên module này và đòi XP tính từ **kết quả đã chấm**, không từ `amount` hay
`isPassed` client khai. Bảng XP đang nằm trong `streak.service.js` với ba con số sai
(`lesson.progress: 5` phải là `2`; `lesson.complete: 15` phải là `20`; `exercise.submit`
phẳng `10` phải là `10` đạt / `5` chưa đạt).

**Produces:**
- `POLICY_VERSION` (chuỗi, ghi vào mọi event và tóm tắt)
- `xpFor(type, outcome) -> number` — `outcome` là kết quả server đã chấm, ví dụ
  `{ passed: boolean }`; type lạ ném `ApiError.badRequest`
- `countsAsStudy(type) -> boolean` — `false` cho event thưởng
- `STREAK_MILESTONES = [7,14,30,50,100,365]`

- [ ] **B1** Test: từng dòng bảng §3.4 ra đúng số; `exercise.submit` với `{passed:true}` →
      10, `{passed:false}` → 5; `login`/`lesson.open` → 0 và `countsAsStudy` false; type lạ
      → ném 400; không có đường nào để tham số ngoài ảnh hưởng con số.
- [ ] **B2** Chạy, thấy fail. **B3** Viết module. **B4** `npm test` xanh.

## Task 1.4: `ActivityEvent` thay `XpEvent`

**Files:** Create `BackEnd/model/ActivityEvent.js`; Delete `BackEnd/model/XpEvent.js`;
Test `BackEnd/tests/activity-event.model.test.js`

Đóng: **MODEL-1, MODEL-2, MODEL-4, MODEL-5, DUP-3, MIG-5**.

Mười trường theo §3.2 dòng 93: `user, event_key, type, source_id, occurred_at, day_key,
xp_delta, reason, counts_as_study, policy_version`, cộng một trường `receipt` tuỳ chọn cho
retry nộp bài (§3.3).

Hai index bắt buộc:

```js
ActivityEventSchema.index({ user: 1, event_key: 1 }, { unique: true });
ActivityEventSchema.index({ user: 1, occurred_at: -1, _id: -1 });
```

Index thứ hai phải có `_id` vì cursor của `xp-history?mode=page` sort
`occurred_at DESC, _id DESC` (§4.2).

**Không đặt TTL** — khoá sự kiện đang bảo vệ việc không phát thưởng lại (§3.2).

- [ ] **B1** Test khai báo: đủ 10 trường; hai index đúng tên trường và đúng cờ `unique`;
      không có TTL. Đọc `schema.indexes()` và `schema.paths`, không cần DB.
- [ ] **B2** Chạy, thấy fail. **B3** Viết model, xoá `XpEvent.js`.
- [ ] **B4** `grep -rn "XpEvent" BackEnd/` chỉ còn ở chỗ sẽ sửa ở Task 1.6.

## Task 1.5: Mở rộng `StreakDay` và `UserStreak`

**Files:** Modify `BackEnd/model/StreakDay.js`, `BackEnd/model/UserStreak.js`;
Test `BackEnd/tests/streak-models.test.js`

Đóng: **MODEL-6, MODEL-7, MODEL-8, MODEL-9, MIG-3, MIG-4, XP-8**.

`StreakDay` thêm: `origin` (enum gồm ít nhất `activity`, `legacy_unverified`), `direct_xp`,
`review_count`, `correct_self_reports`, `wrong_self_reports`; `status` mở thành
`['studied','frozen','legacy']`.

`UserStreak` thêm: `total_active_days`, `legacy_day_count`, `tracking_started_day`,
`revision`, `policy_version`. **Giữ** `xp_history`, `activity_dates`, `reward_keys` — chúng
là dữ liệu legacy chờ migration, chỉ bỏ ở Bước 4 sau khi §4.1 bước 8 kiểm đạt.
**Không** thêm `freezes_available` (Phần B).

- [ ] **B1** Test khai báo trường + enum. **B2** fail. **B3** Sửa model. **B4** `npm test` xanh.

## Task 1.6: Viết lại repository — event trước, revision CAS

**Files:** Modify `BackEnd/src/modules/streaks/streak.repository.js`,
`BackEnd/tests/streak.repository.test.js`

Đóng: **MODEL-3, DUP-1, TX-1, CAS-1, CAS-2, CAS-3, DEP-2, DEP-4, DEP-8, DEP-9, MIG-6**.

Đây là task đảo ngược thiết kế, không phải sửa vặt. Thứ tự cũ là *CAS tóm tắt trước, ghi
event sau*; spec §3.1 đòi *ghi event trước, cập nhật tóm tắt sau*, và chính lần insert event
là bước quyết định trùng hay không.

**Produces:**
- `insertEvent({ userId, eventKey, type, sourceId, occurredAt, dayKey, xpDelta, reason,
  countsAsStudy, policyVersion, receipt, session })` → document mới, hoặc `null` khi trùng
  khoá (bắt E11000, **không** để lỗi thoát ra ngoài)
- `casSummary({ userId, expectedRevision, patch, inc, session })` → chỉ ghi khi `revision`
  khớp; `$inc: { revision: 1, ...inc }`
- `ensureSummary({ userId, session })` → upsert theo unique `user`, bắt E11000 và đọc lại
- `upsertDay({ userId, dayKey, status, origin, incDirectXp, incReviewCount, incCorrect,
  incWrong, session })` — ngày `studied` phải `$set` được status kể cả khi bản ghi cũ là
  `legacy` (§3.2), ngày `frozen` thì `$setOnInsert`
- `listEvents({ userId, cursor, limit, asOf, withXpOnly })` → cursor trên
  `(occurred_at, _id)` giảm dần, **không** `skip`
- `listDays({ userId, from, to, cursor, limit })`
- `sumXpBetween({ userId, fromDay, toDay })` — cho leaderboard kỳ

- [ ] **B1** Test (model giả): insert trùng `event_key` trả `null` chứ không ném;
      `casSummary` filter chứa `revision` đã đọc và update có `$inc: {revision: 1}`;
      `upsertDay` với `studied` nâng được bản ghi `legacy` lên `studied` và `$inc` đúng
      counter; `listEvents` dựng filter cursor hai khoá chứ không `skip`; `listEvents` với
      `withXpOnly` lọc `xp_delta != 0`.
- [ ] **B2** fail. **B3** Viết lại. **B4** `npm test` xanh.

## Task 1.7: Viết lại `recordActivity`

**Files:** Modify `BackEnd/src/modules/streaks/streak.service.js`,
`BackEnd/tests/streak.service.test.js`

Đóng: **SIG-1, DUP-2, TX-1, TX-3, KEY-1, CTX-1, DEP-1, XP-5**.

**Chữ ký đúng spec §3.1:**

```js
recordActivity({ userId, type, sourceId, occurrenceKey, context }, { session, now })
```

Bỏ hẳn khái niệm `ONE_SHOT`. **Mọi** type đều bắt buộc có `occurrenceKey` — caller là service
nghiệp vụ đã xác thực, nó biết định danh lần xảy ra; service streak không tự bịa khoá từ
`type:sourceId` nữa.

**Trình tự bắt buộc:**

1. `policy.xpFor(type, context?.outcome)` và `policy.countsAsStudy(type)` — ném 400 nếu type lạ.
2. `dayKey(now)`.
3. `repository.insertEvent(...)` với `event_key = occurrenceKey`.
   - Trả `null` → **đã ghi rồi**. Trả về trạng thái hiện tại, `xpAwarded: 0`, không làm gì thêm.
     Đây là toàn bộ cơ chế chống trùng; không đọc mảng khoá nào.
4. Event mới → vòng lặp có giới hạn: đọc tóm tắt (lấy `revision`), tính
   `applyActivity(...)`, `casSummary` với `expectedRevision`. Thua thì đọc lại và thử lại,
   **không** bỏ event đã ghi.
5. `upsertDay` cho ngày hôm nay (`studied`, `$inc direct_xp` nếu `countsAsStudy`); các ngày
   băng ghi `frozen` (Phần B mới có băng, hiện luôn rỗng).
6. Mốc huy hiệu: chỉ xét mốc **vừa vượt qua** (`previous < m <= next`); cấp trong cùng
   `session` bằng một event riêng khoá theo user+loại thưởng+mốc, `counts_as_study=false`,
   **không** gọi lại `recordActivity`.

- [ ] **B1** Test: gửi lại cùng `occurrenceKey` → `xpAwarded: 0`, `insertEvent` trả null,
      không `casSummary`, không `upsertDay`; hai `occurrenceKey` khác nhau cùng ngày → cả hai
      cộng XP, ngày chỉ tăng một lần; thua CAS `revision` → thử lại và cuối cùng vẫn ghi đủ
      (không mất event); `session` truyền xuống **mọi** lệnh repository; mốc 7 nổ đúng một
      lần và event thưởng có `counts_as_study=false`; type lạ → 400.
- [ ] **B2** fail. **B3** Viết lại. **B4** `npm test` xanh.

---

# Bước 2 — Chuyển nguồn ghi, đóng đường tự cấp, sửa đường đọc

Spec §3.1: "Mọi writer users, lesson-progress, exercise, JLPT, achievements phải chuyển
**cùng đợt cutover**. Không để một đường cũ tiếp tục đọc/sửa/save đè lên tóm tắt mới."
Vì vậy Task 2.1–2.5 là **một đợt**, không tách commit deploy được.

## Task 2.1: Login và `my-streak` thành đường đọc thuần

**Files:** Modify `BackEnd/src/modules/users/user.repository.js`,
`user-auth.service.js`, `BackEnd/src/modules/streaks/streak.controller.js`

Đóng: **XP-7, SRC-2, READ-1**.

`recordLoginStreak` hiện gọi `updateStreakOnActivity()` + `addXP(10)`. `GET /my-streak` hiện
có thể **tạo** document và **reset** khi đọc. Cả hai thành projection thuần: user mới nhận
tóm tắt 0 và `last_activity_day: null` **mà không tạo document**.

- [ ] **B1** Test HTTP: đăng nhập 3 lần không đổi `current_streak`; GET `/my-streak` của user
      chưa có document trả số 0 và không tạo gì (repository giả khẳng định không có lệnh ghi).
- [ ] **B2** fail. **B3** Đổi tên thành `readStreakSummary`, bỏ mọi lệnh ghi.
- [ ] **B4** `npm test` xanh.

## Task 2.2: lesson-progress và progress

**Files:** Modify `BackEnd/src/modules/lesson-progress/lesson-progress.service.js`,
`lesson-progress.repository.js`, `BackEnd/src/modules/progress/progress.controller.js`

Đóng: **XP-6, SRC-4, MIG-7, MIG-14, CUT-1**.

Bỏ `START_XP` và lời gọi `grantXpOnce` cho việc **mở** bài (spec: mở bài 0 XP). Giữ nguyên
ngữ nghĩa khoá đang có — `lesson-item:<lesson>:<type>:<item>` và `lesson-complete:<lesson>`
— nhưng giờ chúng là `occurrenceKey` truyền vào `recordActivity`, không còn là phần tử của
`reward_keys`.

**Quyết định cần chốt trước khi code:** spec §3.1 liệt kê 5 writer nhưng không nêu
`progress.controller`. Nó cũng cộng XP và ghi streak. Plan này xử lý nó **cùng đợt** — để
sót một writer cũ là đúng điều spec cấm.

- [ ] **B1** Test: hoàn thành cùng một mục hai lần → XP một lần; hoàn thành bài lần đầu →
      20 XP; mở bài → 0 XP và không tạo event học.
- [ ] **B2** fail. **B3** Sửa. **B4** `npm test` xanh.

## Task 2.3: exercise và JLPT — `attempt_id` và receipt

**Files:** Modify `BackEnd/src/modules/exercise/exercise.controller.js`,
`BackEnd/src/modules/jlpt/jlpt.controller.js`, schema tương ứng;
Modify Flutter service gửi bài

Đóng: **XP-3, SRC-1, SRC-5, TX-2, KEY-2**.

Đây là task nặng nhất Bước 2. Spec §3.3: client sinh `attempt_id` UUID khi **bắt đầu** lượt
làm và gửi lại **đúng** ID khi retry. Server kiểm schema, quyền, bài làm và fingerprint nội
dung đã chuẩn hoá:

- cùng ID **và** cùng payload → trả kết quả đã ghi (đọc từ receipt)
- cùng ID **nhưng** payload khác → **409**

Kiểm receipt **trước khi** tạo/cập nhật kết quả, rồi commit receipt và kết quả cùng transaction.

JLPT hiện upsert `LearningHistory` theo `(user, exam)` nên `_id` của nó **không** định danh
một lần nộp — giữ điểm của từng lần trong receipt nhỏ ở `ActivityEvent`, để retry lần A
không nhận kết quả lần B. Không đổi unique index của history chỉ để làm streak.

- [ ] **B1** Test HTTP: nộp lần đầu ghi kết quả + 1 event; gửi lại cùng `attempt_id` cùng
      payload trả **cùng** kết quả và **không** cộng XP lần hai; cùng `attempt_id` payload
      khác → 409; JLPT nộp lần 2 khác điểm không ghi đè kết quả retry của lần 1.
- [ ] **B2** fail. **B3** Cài đặt. **B4** `npm test` xanh + Flutter gửi `attempt_id`.

## Task 2.4: Đóng đường tự cấp thưởng của achievements

**Files:** Modify `BackEnd/src/modules/achievements/achievement.controller.js`, routes;
Modify Flutter service/provider tương ứng

Đóng: **XP-5, SRC-3 (phần achievement)**.

Spec §3.6: bỏ `POST /api/achievement/update-progress` — nó nhận progress do client gửi và có
thể dẫn tới cấp XP. Giữ nguyên các đường đọc và CRUD admin. Huy hiệu nào chưa có tiêu chí
server xác minh thì **chưa tự cấp**.

- [ ] **B1** Test HTTP: route trả 404; đường đọc và CRUD admin vẫn chạy.
- [ ] **B2** fail. **B3** Xoá route + hàm service/provider Flutter sau khi rà consumer.
- [ ] **B4** `npm test` xanh.

## Task 2.5: Route, contract đọc và export

**Files:** Modify `BackEnd/src/modules/streaks/streak.routes.js`, `streak.controller.js`;
Create `BackEnd/src/modules/streaks/streak.schema.js`;
Modify `BackEnd/tests/route-contract.test.js`;
Modify `FrontEnd/lib/features/streaks/**`, `FrontEnd/lib/features/settings/screens/export_screen.dart`

Đóng: **SRC-3, READ-2..READ-11, MIG-11**.

**Số route phải đúng:** module streaks `6 − 3 + 1 = 4`; achievements giảm 1. Tổng toàn app
giảm **4**. Không dùng grep "không còn addXP" làm bằng chứng.

| Endpoint | Hợp đồng |
| --- | --- |
| `GET /my-streak` | Tóm tắt **phẳng**, giữ `current/longest/total_xp/level` và virtual đang dùng; thêm `last_activity_day`, `total_active_days`, `legacy_day_count`, `studied_today`. Bỏ hai mảng khỏi response **cùng lúc** sửa model/provider/screen/export |
| `GET /xp-history` **không query** | **Giữ array đầy đủ** với `amount, reason, earned_at`, đọc từ ActivityEvent có XP. Đường tương thích cũ — **không** mặc định giới hạn 20/100 làm thiếu export |
| `GET /xp-history?mode=page&limit=&cursor=` | `{ data, next_cursor, as_of }`; default 20, max 100; sort `occurred_at DESC, _id DESC` |
| `GET /leaderboard` | Giữ path/envelope; `period=all` dùng `total_xp`, `week`/`month` cộng XP event trong 7/30 ngày lịch VN gồm hôm nay; thêm `period_xp`; hạng và danh sách dùng **cùng** filter/sort |
| `GET /days?from=&to=&cursor=` | **Mới.** `{ data, next_cursor }`; khoảng tối đa 366 ngày, trang tối đa 100 |
| `POST /add-xp`, `POST /test/reset-yesterday`, `GET /test/debug` | **Bỏ** |

`last_activity_date` giữ được như alias ISO cho client cũ, nhưng không còn là nguồn tính ngày.

Flutter: `StreakService`/provider/screen theo hợp đồng mới; `export_screen.dart` dùng
`mode=page` đọc **hết** từng trang tới `next_cursor=null` rồi ghép thành mảng `xp_history`
như hiện tại, có hủy và có lỗi — lỗi trang giữa **không** được báo xuất thành công một phần.
Xoá `StreakService.addXP`/`StreakProvider.addXP`.

- [ ] **B1** Test HTTP cho từng dòng bảng trên + test Flutter cho export nhiều trang.
- [ ] **B2** fail. **B3** Cài đặt. **B4** Đọc bằng mắt danh sách route mới rồi cập nhật
      `expectedCount`/`expectedSignatureHash`. **B5** Cả hai suite xanh.

---

# Bước 3 — SRS

Phần này bám [spec SRS](../specs/2026-09-09-srs-revival-design.md) §3.2–3.6, §4, §5.
Nội dung kỹ thuật của spec SRS **không đổi** giữa hai lần viết plan — 6 route, batch có
`exclude_item_ids`, `expected_next_review`, ba mã 409 — nên phần task ở plan cũ vẫn dùng
được **sau khi** thay chỗ gọi streak:

| Task | Nội dung | Khác plan cũ ở chỗ |
| --- | --- | --- |
| 3.1 | Mở rộng `srs.repository.js`: `findDueBatch`, `countDue`, `casApplyAnswer`, `casReset`, `statsByBox` | Không đổi |
| 3.2 | `srs.schema.js` (zod cho 6 route) | Không đổi |
| 3.3 | `srs.service.js`: đọc → 404 → `SRS_NOT_DUE` → `SRS_PROGRESS_CHANGED` → `ITEM_UNAVAILABLE` → `applyAnswer` → CAS → **`recordActivity` với `occurrenceKey = <SRSProgress._id>:<expected_next_review>`** → commit | `occurrenceKey` bắt buộc; 2 XP do policy quyết |
| 3.4 | Controller + routes; xoá `srs-progress.*`; `app.js`; route contract 12 → 6 | Cập nhật contract **sau** Bước 2 |
| 3.5 | `GET /api/vocabulary/:id` trả kèm `data.srs_progress` | Không đổi |
| 3.6 | Flutter: `ApiException` mang `statusCode`/`code`/`details` | Không đổi |
| 3.7 | Flutter: model + service 6 endpoint | Không đổi |
| 3.8 | Flutter: provider giữ `handledItemIds`, badge từ `countDue` | Không đổi |
| 3.9 | Flutter: màn ôn tập + widget | Không đổi |
| 3.10 | Điều hướng `/srs`, mục hub, contract test | `navigation_contract_test.dart` đã có `/srs` |

Khoá lượt ôn là `SRSProgress._id` ghép `expected_next_review` **của lượt vừa thắng CAS** —
ID thẻ một mình không đủ định danh một lượt (spec streak §3.3).

Chi tiết từng bước của Bước 3 viết khi Bước 2 xong, vì hình dạng `recordActivity` phải đứng
yên trước.

---

# Bước 4 — Migration và cutover

Chỉ bắt đầu khi Task 0.3 đã chạy trên DB thật và Bước 1–3 đã xanh trên fixture.

Tám bước của spec §4.1, theo đúng thứ tự: audit → xác định timezone legacy → backup có kiểm
tra khôi phục → chọn `cutover_at` và **dừng writer cũ** (không dual-write ngầm) → copy
`xp_history` thành event `legacy.xp` (khoá theo `UserStreak._id` + vị trí trong snapshot) và
`reward_keys` thành event đánh dấu XP 0 **giữ nguyên `event_key`** writer mới sẽ kiểm → copy
`activity_dates` thành `StreakDay(status=legacy, origin=legacy_unverified)` → đối chiếu số
lượng/khoá trùng/số dư → chỉ bỏ ba mảng legacy khi kiểm đạt.

Ràng buộc: migration chạy lại **không** tạo thêm event/XP; **không** tự sửa `total_xp` theo
phép cộng lịch sử — chênh lệch thì ghi báo cáo; **không** hạ chuỗi đang còn hiệu lực chỉ vì
ngày cũ là login; **không** phục hồi chuỗi đã hết hiệu lực trước cutover.

Test bắt buộc (fixture, không chạm DB): `last_activity_day` = hôm nay / hôm qua / đã đứt
trước cutover.

---

## Tự soát plan

**Độ phủ spec streak Phần A:** §3.1 → 1.7, 2.1–2.5; §3.2 → 1.4, 1.5; §3.3 → 1.6, 1.7, 2.3;
§3.4 → 1.3, 1.7; §3.5 → 1.1, 1.6; §3.6 → 2.4, 2.5; §4.1 → 0.3, Bước 4; §4.2 → 2.5;
§4.3 → 2.5. Spec SRS → Bước 3. Program §4.0 bước 0–4 → Bước 0–4 của plan này.

**Ngoài phạm vi (đúng spec):** toàn bộ Phần B (freeze, mục tiêu ngày, lịch, nhắc học),
Kanji SRS, vacation mode, `/my-cards`, bốn route admin SRS.

**Rủi ro:** transaction đòi replica set — Atlas có sẵn, nhưng chạy Mongo standalone sẽ lỗi ở
`unitOfWork`. Bước 2 là một đợt cutover không tách deploy được, nên phải xanh toàn bộ trước
khi merge.

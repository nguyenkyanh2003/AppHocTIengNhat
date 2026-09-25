# Khoá tự nhiên nội dung + Streak Phần B — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** (1) DB tự chặn trùng Grammar/Exercise/JLPT bằng unique index khoá tự nhiên, API admin trả 409 rõ ràng thay vì 500; (2) Streak Phần B: mục tiêu ngày, băng bảo vệ, màn lịch, nhắc học trong app.

**Architecture:** Index khai báo ở model, tạo và xác minh trên Atlas bằng một script có rà trùng trước (không trông vào `autoIndex` vì nó nuốt lỗi). Phần B giữ nguyên cổng ghi duy nhất `recordActivity`: quà băng là event 0 XP khoá riêng theo mốc, ghi trong cùng transaction; cài đặt nằm ở model `StreakSettings` riêng, CAS trên `revision`. Đường đọc chỉ chiếu, không ghi. Flutter: tách màn streak thành widget nhỏ, thêm màn `/streak/calendar`, sheet cài đặt, và bộ nhắc gắn ở `ShellRoute`.

**Tech Stack:** Node 22, Express 5, Mongoose 8, zod 4, `node --test`; Flutter 3.29, Provider, go_router, shared_preferences.

**Spec:** [streak-integrity §2, §5, §7](../specs/2026-09-09-streak-integrity-design.md); checklist P0 0.1 (unique index + rà trùng + xác nhận trên Atlas).

## Global Constraints

- Mục tiêu ngày: mặc định **20**; chọn **10/20/30/50**; tính bằng `direct_xp` học đã xác thực trong `StreakDay`; không gồm login, legacy, huy hiệu, băng; **không chặn streak**; đổi mức có hiệu lực **từ ngày Việt Nam tiếp theo**.
- Băng: kho **0..2**; tặng **1** ở mốc **7/14/30/50/100/365**, mỗi mốc một lần/user, chỉ khi **vừa vượt qua** bằng hoạt động mới (`previous < m <= next`); tặng **sau** khi xử lý ngày và khoảng nghỉ; kho đầy thì bỏ phần thưởng, không lưu để lĩnh sau; không bán; khoá quà băng **tách** khỏi khoá huy hiệu/mốc.
- Thiếu băng vẫn tiêu số đã bảo vệ các ngày đầu; sau ngày đầu không được bảo vệ thì chuỗi đứt.
- GET chỉ chiếu: trả current chiếu, ngày bảo vệ dự kiến, `pending_freezes`, tồn kho đã ghi và số còn sau dự kiến; không ghi, không tiêu băng.
- Settings: `GET/PUT /api/streak/settings`; GET trả mặc định nếu chưa có; PUT validate, ghi, tăng `revision`; `reminder_enabled` mặc định false, `reminder_time` mặc định 20:00, chỉ trong **08:00–21:59**.
- Nhắc: opt-in, trong ứng dụng khi đang mở, tối đa **một lần/ngày/thiết bị**, kiểm `studied_today` sau khi đồng bộ; mất mạng thì hoãn, không tự coi là đã học; không nhắc bù ngày cũ; nội dung **không khẳng định chuỗi sẽ đứt**; không hứa nhắc khi đóng app.
- Lịch: phân biệt đã học / băng đã ghi / băng dự kiến / nghỉ / legacy chưa xác minh / hôm nay chưa học; **không tô tương lai là bỏ học**.
- Khoá tự nhiên: Grammar `(level, title)`, Exercise `(lesson_id, title)`, JLPT `(title)` — đúng khoá các script nhập đang dùng.
- Controller không thêm logic nghiệp vụ mới; route mới đi qua `validate` + `asyncHandler`; response `{ data }`.
- Đổi route công khai → cập nhật `route-contract.test.js` / `navigation_contract_test.dart` cùng commit, đọc danh sách bằng mắt.
- Không test nào chạm MongoDB; smoke chạy trên DB tạm riêng, xoá sau khi chạy.
- `dart analyze` sạch tuyệt đối; không thêm `fontSize: <số>` hay `Colors.grey/blue/red/green/orange`.

## Review Focus

1. Đổi mục tiêu lúc 23:59 và 00:00 giờ VN — ngày hiệu lực phải theo ngày VN của server lúc ghi (test ở Task 5).
2. Mở app sau 22:00 hoặc sau nửa đêm — không được nhắc, không nhắc bù ngày cũ (test ở Task 12).
3. Chuỗi đứt nhưng còn băng — băng vẫn bị tiêu cho các ngày đầu, UI không được nói "chuỗi vẫn giữ" (test ở Task 4, Task 10).
4. Bấm chuyển tháng liên tục trên màn lịch — phản hồi của tháng cũ không được ghi đè tháng đang xem (test ở Task 11).
5. Hai thiết bị lưu cài đặt cùng lúc — thua CAS thì đọc lại và thử lại; hết lượt thì 409 có câu báo (test ở Task 6).

---

### Task 1: Khoá tự nhiên khai báo ở model

**Files:** Create `BackEnd/scripts/content-indexes.js`; Modify `BackEnd/model/Grammar.js`, `Exercise.js`, `JLPT.js`; Test `BackEnd/tests/content-indexes.test.js`

**Produces:** `NATURAL_KEYS: {label, collection, name, key}[]`, `duplicatePipeline(key)`, `findNaturalKeyIndex(indexes, spec)`.

- [x] Test: mỗi model khai báo index `unique` đúng `name`/`key` như `NATURAL_KEYS`; `duplicatePipeline` gom theo đủ trường khoá và chỉ giữ nhóm >1; `findNaturalKeyIndex` chỉ nhận index **unique** đúng khoá.
- [x] Chạy thấy fail → viết module + thêm `Schema.index(key, { unique: true, name })` vào 3 model (JLPT `title` thêm `trim: true`) → xanh.

### Task 2: API admin trả 409; ngữ pháp đã xoá mềm thì tạo lại là khôi phục

**Files:** Create `BackEnd/src/shared/db/duplicate-key.js`, `BackEnd/src/modules/grammar/grammar-natural-key.js`; Modify `grammar.controller.js` (`postRoot`, `putById`), `exercise.controller.js` (`createExercise`, `updateExercise`), `jlpt.controller.js` (`createExam`, `updateExam`); Test `BackEnd/tests/content-duplicate.test.js`

**Produces:** `isDuplicateKeyError(error)`, `createOrReviveGrammar({ data, model }) -> { grammar, revived }`.

Quyết định: màn admin tạo được ngữ pháp nhưng không có chỗ hiện bản đã xoá, nên tạo lại đúng `(level, title)` của bản đã xoá mềm sẽ **khôi phục** bản đó với nội dung mới (giữ `_id`, tiến độ học nối lại). Trùng bản đang hoạt động → 409. Bài tập/JLPT chỉ có API, trùng → 409 kèm câu "kể cả bản đã xoá".

- [x] Test (stub static của model, `fakeRes`): nhận E11000 ở `code` và `cause.code`; khôi phục bản xoá mềm (lọc theo title đã trim, `is_active:false`, không gọi `create`); tạo mới khi không có gì để khôi phục (bỏ trường `undefined`); `postRoot` trùng → 409 `DUPLICATE_GRAMMAR`; `putById` trùng → 409; `createExercise`/`updateExercise` trùng → 409 `DUPLICATE_EXERCISE`; `createExam`/`updateExam` trùng → 409 `DUPLICATE_EXAM`; lỗi khác vẫn 500.
- [x] Fail → cài đặt → xanh.

### Task 3: Script rà trùng, tạo và xác minh index trên Atlas

**Files:** Create `BackEnd/scripts/ensure-content-indexes.js`

- [x] Chế độ mặc định chỉ đọc: số nhóm trùng + index đang có. `--apply`: còn trùng thì dừng, không tạo gì; không thì `createIndex(key, {unique, name})` rồi đọc lại xác minh. `--smoke`: trên DB `<db>_index_smoke` (khác DB chính), tạo index, chèn hai bản cùng khoá → bản thứ hai phải E11000, xoá DB tạm.
- [x] Chạy: rà (0 trùng) → `--smoke` (3/3) → `--apply` → rà lại (đủ 3 index).

### Task 4: Chính sách và phép chiếu băng

**Files:** Modify `streak-policy.js`, `streak-rules.js`; Test `streak-policy.test.js`, `streak-rules.test.js`

**Produces:** `FREEZE_GIFT_TYPE='streak.freeze_gift'` (0 XP, không học), `DAILY_GOAL_OPTIONS=[10,20,30,50]`, `DEFAULT_DAILY_GOAL=20`, `REMINDER_WINDOW={start:'08:00',end:'21:59'}`, `DEFAULT_REMINDER_TIME='20:00'`; `projectStreak` trả thêm `pendingFrozenDays: string[]`, `freezesAfter: number`.

- [x] Test: hằng số đúng spec; phép chiếu 1/2/3 ngày nghỉ với 0/1/2 băng; thiếu băng vẫn liệt kê ngày sẽ bị che; **phép chiếu khớp đúng cái `applyActivity` sẽ tiêu** (vòng lặp đối chiếu). Sửa hai assert cũ so khớp chặt kết quả `projectStreak`.
- [x] Fail → cài đặt → xanh. Nâng `POLICY_VERSION`.

### Task 5: Model `StreakSettings` và luật cài đặt thuần

**Files:** Create `BackEnd/model/StreakSettings.js`, `BackEnd/src/modules/streaks/streak-settings.js`; Test `BackEnd/tests/streak-settings.test.js`

**Produces:** `effectiveGoal(settings, todayKey)`, `planGoalChange(settings, goal, todayKey)`, `settingsView(settings, todayKey)`, `isReminderTime(value)`, `isDailyGoal(value)`.

Biểu diễn: `daily_goal_xp` (lựa chọn mới nhất), `previous_goal_xp` + `goal_effective_from` (mục tiêu còn hiệu lực trước ngày đó).

- [x] Test: mặc định 20; đổi 30 hôm nay → hôm nay vẫn 20, mai 30; đổi hai lần trong ngày giữ mốc hôm nay; chọn lại mục tiêu hôm nay huỷ thay đổi chờ; sau ngày hiệu lực không còn "chờ"; giờ nhắc `08:00`/`21:59` hợp lệ, `07:59`/`22:00`/`8:00`/`20:60` không; validator model khớp hằng số chính sách; unique `user`.
- [x] Fail → cài đặt → xanh.

### Task 6: Repository + service + route `GET/PUT /api/streak/settings`

**Files:** Create `streak-settings.repository.js`, `streak-settings.service.js`; Modify `streak.schema.js`, `streak.controller.js`, `streak.routes.js`, `tests/route-contract.test.js`; Test `tests/streak-settings.service.test.js`, `tests/streak-settings.repository.test.js`, `tests/streak.routes.test.js`

**Produces:** `settingsService.get(userId)`, `settingsService.update(userId, { daily_goal_xp?, reminder_enabled?, reminder_time? })` → `settingsView`.

- [x] Test: GET không ghi gì và trả mặc định; PUT tạo document (revision 1) khi chưa có; CAS theo `revision`; thua CAS thì đọc lại; hết 5 lượt → 409 `STREAK_SETTINGS_CONFLICT`; đổi mục tiêu lúc 23:59:59 VN hiệu lực ngày kế, lúc 00:00 VN hiệu lực ngày sau nữa; route: body lạ (`freezes_available`), mục tiêu 25, giờ `22:30`, body rỗng → 400.
- [x] Fail → cài đặt → xanh → cập nhật contract route (+2) sau khi đọc bằng mắt.

### Task 7: Tặng băng trong `recordActivity`

**Files:** Modify `streak.service.js`; Test `tests/streak.service.test.js`

**Produces:** kết quả `recordActivity` có thêm `freezesGifted: number[]`.

- [x] Test: vượt mốc 7 → +1 băng, event `streak-freeze:<user>:7` receipt `{granted:true}`; kho đầy → vẫn ghi event `{granted:false}`, kho giữ 2; mốc đã tặng không tặng lại khi leo lại; băng được tiêu trước rồi mới tặng (CAS thứ nhất trừ, CAS sau cộng); gửi lại cùng hoạt động không tặng. Sửa assert cũ đếm 2 event ở mốc 7 thành đếm theo loại.
- [x] Fail → cài đặt → xanh.

### Task 8: Tóm tắt có mục tiêu ngày và dự báo băng

**Files:** Modify `streak.repository.js` (`findDay`), `streak-read.service.js`; Test `tests/streak-read.service.test.js`, `tests/streak.repository.test.js`

**Produces:** `/my-streak` thêm `freezes_available`, `max_freezes`, `pending_freezes`, `pending_frozen_days`, `freezes_after_pending`, `tracking_started_day`, `daily_goal: { target_xp, today_xp, reached, next_target_xp, next_target_from }`.

- [x] Test: mặc định 20 XP, `today_xp` lấy từ ngày hôm nay; mục tiêu chờ hiện `next_*`; chuỗi còn băng hiện ngày dự kiến, không ghi gì; chuỗi đứt vẫn liệt kê băng sẽ bị tiêu.
- [x] Fail → cài đặt → xanh; `npm test` toàn bộ xanh.

### Task 9: Flutter — model, service, provider

**Files:** Create `lib/features/streaks/models/streak_settings.dart`, `lib/features/streaks/models/day_key.dart`; Modify `user_streak.dart`, `streak_service.dart`, `streak_provider.dart`; Test `test/streak_models_test.dart`, `test/streak_provider_test.dart`

**Produces:** `DailyGoalProgress`, `StreakSettings` (+ `reminderTimeOptions`), `StreakService.getSettings/updateSettings`, `StreakProvider({StreakService? service})`, `Future<bool> loadStreak()`, `ViewState<StreakSettings> settings`, `loadSettings()`, `Future<String?> saveSettings(...)`; `vietnamWallClock`, `vietnamDayKey`, `dayKeyOf`, `formatDayKey`.

- [x] Test: parse đủ trường mới, thiếu trường thì mặc định; mốc giờ nhắc 08:00…21:30 + giờ đang đặt; `loadStreak` lỗi giữ dữ liệu cũ và trả false; `saveSettings` trả câu lỗi khi server từ chối, thành công thì tải lại tóm tắt.
- [x] Fail → cài đặt → xanh.

### Task 10: Màn streak, thẻ mục tiêu/băng, sheet cài đặt

**Files:** Create `lib/features/streaks/widgets/{streak_hero_card,daily_goal_card,freeze_card,xp_level_card,xp_history_card,streak_settings_sheet}.dart`; Rewrite `lib/features/streaks/screens/streak_screen.dart` (<250 dòng); Modify `app_tokens.dart` (`AppColors.freeze`); Test `test/streak_screen_test.dart`

- [x] Test: màn hiện tiến độ mục tiêu, kho băng, ngày băng dự kiến; chuỗi đứt không nói "vẫn giữ"; sheet: chọn mục tiêu khác hiện "áp dụng từ ngày mai", bật nhắc hiện chọn giờ trong khung, lưu gửi đúng trường đã đổi, lỗi server hiện trong sheet.
- [x] Fail → cài đặt → xanh.

### Task 11: Màn lịch `/streak/calendar`

**Files:** Create `lib/features/streaks/models/calendar_day.dart`, `providers/streak_calendar_provider.dart`, `screens/streak_calendar_screen.dart`, `widgets/calendar_month_grid.dart`; Modify `app_router.dart`, `test/navigation_contract_test.dart`; Test `test/streak_calendar_test.dart`

- [x] Test: phân loại ngày (tương lai, đã học, băng, băng dự kiến, legacy, hôm nay chưa học, nghỉ, trước khi theo dõi); lưới bắt đầu thứ Hai; provider bỏ phản hồi của tháng đã rời; màn hiện chú thích và chi tiết ngày khi chạm.
- [x] Fail → cài đặt → xanh; contract điều hướng thêm `/streak/calendar`.

### Task 12: Nhắc học trong ứng dụng

**Files:** Create `lib/features/streaks/services/streak_reminder.dart`, `lib/features/streaks/widgets/streak_reminder_host.dart`; Modify `app_router.dart` (ShellRoute builder); Test `test/streak_reminder_test.dart`

**Produces:** `decideReminder(...) -> ReminderOff | ReminderShowNow | ReminderWait(delay)`, `StreakReminderScheduler`, `StreakReminderHost`.

- [x] Test: tắt → không làm gì; trước giờ → đợi đúng khoảng; sau giờ trong khung → nhắc ngay; sau 22:00 → đợi tới mai; đã xử lý hôm nay → đợi tới mai; mất mạng → không nhắc, không đánh dấu, thử lại sau; đã học → không nhắc nhưng đánh dấu; widget: banner hiện một lần, không hiện lại khi dựng lại cùng ngày.
- [x] Fail → cài đặt → xanh.

### Task 13: Lối vào ở Cài đặt, smoke trên DB tạm, kiểm chứng

**Files:** Modify `settings_screen.dart`, `app_localizations.dart`; Create `BackEnd/scripts/smoke-streak-part-b.js`; Update spec §5 trạng thái.

- [x] Smoke (DB `<db>_smoke_streak`, transaction thật): học 7 ngày → 1 băng; nghỉ 1 ngày rồi học → ngày đó `frozen`, băng về 0, chuỗi 8; gửi lại không tặng thêm; đổi mục tiêu hiệu lực ngày kế; xoá DB tạm.
- [x] `npm test`, `dart analyze`, `flutter test`, `flutter build web`; thử API thật với tài khoản demo.

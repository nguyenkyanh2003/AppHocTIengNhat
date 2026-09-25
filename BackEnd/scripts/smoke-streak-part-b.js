/**
 * Smoke test streak Phần B trên **MongoDB thật** (spec streak §5): băng bảo vệ
 * được tặng rồi tiêu đúng một lần qua transaction thật, dự báo khi đọc khớp
 * với thứ thực sự được ghi, và cài đặt mục tiêu chịu được hai lần lưu đồng
 * thời — những thứ repository giả trong test đơn vị không chứng minh được.
 *
 * Chạy trên database **riêng** `<DB_NAME>_smoke_streak` cùng cluster (cần
 * replica set để có transaction — Atlas có sẵn). Database đó bị xoá lúc bắt
 * đầu và lúc kết thúc; dữ liệu thật không bị đụng tới.
 *
 *   node scripts/smoke-streak-part-b.js          # chạy rồi dọn
 *   node scripts/smoke-streak-part-b.js --keep   # giữ database smoke để xem lại
 */
import dotenv from 'dotenv';
import mongoose from 'mongoose';

import Achievement from '../model/Achievement.js';
import ActivityEvent from '../model/ActivityEvent.js';
import StreakDay from '../model/StreakDay.js';
import StreakSettings from '../model/StreakSettings.js';
import UserAchievement from '../model/UserAchievement.js';
import UserStreak from '../model/UserStreak.js';
import { unitOfWork } from '../src/shared/db/unit-of-work.js';
import { FREEZE_GIFT_TYPE } from '../src/modules/streaks/streak-policy.js';
import { createStreakReadService } from '../src/modules/streaks/streak-read.service.js';
import { addDays, dayKey } from '../src/modules/streaks/streak-rules.js';
import { streakService } from '../src/modules/streaks/streak.service.js';
import { createStreakSettingsService } from '../src/modules/streaks/streak-settings.service.js';

dotenv.config({ quiet: true });

const MODELS = [Achievement, ActivityEvent, StreakDay, StreakSettings, UserAchievement, UserStreak];

let failures = 0;
const check = (label, condition, detail = '') => {
  if (!condition) failures += 1;
  console.log(`${condition ? '✅' : '❌'} ${label}${!condition && detail ? ` — ${detail}` : ''}`);
};

/** 12:00 giờ Việt Nam của ngày `key`. */
const noonOf = (key) => new Date(`${key}T12:00:00+07:00`);

/** Học một bài vào ngày `key`, qua transaction thật như controller làm. */
const studyOn = (userId, key, occurrenceKey = `smoke-lesson:${key}`) =>
  unitOfWork.run(({ session }) =>
    streakService.recordActivity(
      { userId, type: 'lesson.complete', sourceId: key, occurrenceKey },
      { session, now: noonOf(key) },
    ),
  );

const summaryAt = (userId, key) => createStreakReadService({ clock: () => noonOf(key) }).summary(userId);

const giftEvents = (userId) => ActivityEvent.find({ user: userId, type: FREEZE_GIFT_TYPE }).lean();

const freezeFlow = async (today) => {
  const userId = new mongoose.Types.ObjectId();
  // Ngày 0–6 học, ngày 7 nghỉ, ngày 8–14 học; ngày 14 là hôm qua.
  const day = (index) => addDays(today, index - 15);

  // 1. Bảy ngày liền: đạt mốc 7, được tặng đúng một băng.
  let last;
  for (let index = 0; index <= 6; index += 1) last = await studyOn(userId, day(index));
  let summary = await UserStreak.findOne({ user: userId }).lean();
  check('bảy ngày liền: chuỗi 7', summary?.current_streak === 7, `current=${summary?.current_streak}`);
  check('mốc 7 tặng một băng', summary?.freezes_available === 1, `freezes=${summary?.freezes_available}`);
  check('kết quả ghi báo đã tặng băng ở mốc 7', JSON.stringify(last?.freezesGifted) === '[7]');
  let gifts = await giftEvents(userId);
  check('đúng một event tặng băng, ghi nhận đã nhận', gifts.length === 1 && gifts[0].receipt?.granted === true);

  // 2. Gửi lại đúng lượt học ngày 6: không tặng thêm.
  const replay = await studyOn(userId, day(6));
  gifts = await giftEvents(userId);
  check('gửi lại lượt cũ là trùng, không tặng thêm', replay.duplicate === true && gifts.length === 1);

  // 3. Đọc vào ngày 8 (ngày 7 bỏ trống): dự báo băng sẽ che ngày 7.
  const projected = await summaryAt(userId, day(8));
  check('dự báo: chuỗi vẫn 7', projected.current_streak === 7, `current=${projected.current_streak}`);
  check(
    'dự báo: băng sẽ che đúng ngày 7',
    JSON.stringify(projected.pending_frozen_days) === JSON.stringify([day(7)]) &&
      projected.pending_freezes === 1 &&
      projected.freezes_after_pending === 0,
    JSON.stringify(projected.pending_frozen_days),
  );
  check('đọc không ghi gì', (await StreakDay.countDocuments({ user: userId, status: 'frozen' })) === 0);

  // 4. Học ngày 8: dự báo thành sự thật.
  await studyOn(userId, day(8));
  summary = await UserStreak.findOne({ user: userId }).lean();
  const frozen = await StreakDay.find({ user: userId, status: 'frozen' }).lean();
  check(
    'ngày 7 được ghi là băng đã che',
    frozen.length === 1 && frozen[0].day_key === day(7),
    JSON.stringify(frozen.map((row) => row.day_key)),
  );
  check('tiêu hết băng', summary?.freezes_available === 0, `freezes=${summary?.freezes_available}`);
  check('chuỗi 8: ngày băng che giữ chuỗi nhưng không cộng', summary?.current_streak === 8);

  // 5. Học tiếp tới ngày 14: đạt mốc 14, được tặng băng thứ hai.
  for (let index = 9; index <= 14; index += 1) await studyOn(userId, day(index));
  summary = await UserStreak.findOne({ user: userId }).lean();
  gifts = await giftEvents(userId);
  check('mốc 14: chuỗi 14, có lại một băng', summary?.current_streak === 14 && summary?.freezes_available === 1);
  check('mỗi mốc tặng một lần', gifts.map((event) => event.source_id).sort().join(',') === '14,7');

  // 6. Tóm tắt hôm nay (chưa học): chuỗi còn sống, không có ngày chờ băng.
  const live = await summaryAt(userId, today);
  check('hôm nay chưa học: chuỗi 14 vẫn còn', live.current_streak === 14 && live.studied_today === false);
  check('hôm nay chưa học không phải ngày nghỉ', live.pending_frozen_days.length === 0);
  check(
    'mục tiêu ngày mặc định 20, hôm nay 0 XP',
    live.daily_goal.target_xp === 20 && live.daily_goal.today_xp === 0 && live.daily_goal.reached === false,
    JSON.stringify(live.daily_goal),
  );

  // 7. Học hôm nay: đạt mục tiêu (bài học = 20 XP).
  await studyOn(userId, today);
  const done = await summaryAt(userId, today);
  check(
    'học một bài hôm nay: đạt mục tiêu 20',
    done.daily_goal.today_xp === 20 && done.daily_goal.reached === true && done.current_streak === 15,
    JSON.stringify(done.daily_goal),
  );
};

const settingsFlow = async (today) => {
  const userId = new mongoose.Types.ObjectId();
  const tomorrow = addDays(today, 1);
  const serviceAt = (key) => createStreakSettingsService({ clock: () => noonOf(key) });

  // 1. Người chưa lưu gì: đọc ra mặc định, không tạo document.
  const initial = await serviceAt(today).get(userId);
  check(
    'mặc định: mục tiêu 20, tắt nhắc, 20:00',
    initial.daily_goal_xp === 20 && initial.reminder_enabled === false && initial.reminder_time === '20:00',
  );
  check('đọc không tạo cài đặt', (await StreakSettings.countDocuments({ user: userId })) === 0);

  // 2. Hai lần lưu đầu tiên cùng lúc: một document, không mất trường nào.
  await Promise.all([
    serviceAt(today).update(userId, { reminder_enabled: true }),
    serviceAt(today).update(userId, { reminder_time: '21:30' }),
  ]);
  const stored = await StreakSettings.find({ user: userId }).lean();
  check('lưu đồng thời: đúng một document', stored.length === 1, `${stored.length} document`);
  check(
    'lưu đồng thời: giữ cả hai thay đổi',
    stored[0]?.reminder_enabled === true && stored[0]?.reminder_time === '21:30' && stored[0]?.revision === 2,
    JSON.stringify(stored[0]),
  );

  // 3. Đổi mục tiêu: hôm nay giữ 20, từ mai là 50.
  const changed = await serviceAt(today).update(userId, { daily_goal_xp: 50 });
  check(
    'đổi mục tiêu có hiệu lực từ mai',
    changed.daily_goal_xp === 20 && changed.next_daily_goal_xp === 50 && changed.next_goal_from === tomorrow,
    JSON.stringify(changed),
  );
  const todaySummary = await summaryAt(userId, today);
  check('tóm tắt hôm nay vẫn tính mục tiêu 20', todaySummary.daily_goal.target_xp === 20);
  const next = await serviceAt(tomorrow).get(userId);
  check('sang ngày mới: mục tiêu 50', next.daily_goal_xp === 50 && next.next_daily_goal_xp === null);

  // 4. Đổi ý trong ngày về đúng mục tiêu hôm nay: huỷ thay đổi đang chờ.
  const reverted = await serviceAt(today).update(userId, { daily_goal_xp: 20 });
  check('đổi về mục tiêu hôm nay: huỷ lịch đổi', reverted.next_daily_goal_xp === null);

  // 5. Giá trị ngoài danh sách bị chặn ở service, không lọt xuống DB.
  const invalid = await serviceAt(today)
    .update(userId, { reminder_time: '23:00' })
    .catch((error) => error);
  check('giờ nhắc ngoài khung bị từ chối', invalid?.code === 'INVALID_STREAK_SETTINGS', invalid?.code);
};

const main = async () => {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong .env');
  const mainDb = process.env.DB_NAME || 'AppHocTiengNhat';
  const dbName = `${mainDb}_smoke_streak`;
  if (dbName === mainDb) throw new Error('Database smoke trùng database thật — dừng.');
  await mongoose.connect(uri, { dbName });
  console.log(`🧪 Smoke test streak Phần B trên ${dbName}\n`);

  try {
    await mongoose.connection.dropDatabase();
    // Unique index là một nửa của cơ chế chống trùng — phải có trước khi chạy.
    for (const model of MODELS) await model.createIndexes();
    const today = dayKey(new Date());
    await freezeFlow(today);
    await settingsFlow(today);
  } finally {
    if (!process.argv.includes('--keep')) await mongoose.connection.dropDatabase();
    await mongoose.disconnect();
  }

  console.log(failures === 0 ? '\n✅ Smoke test đạt.' : `\n❌ ${failures} kiểm tra không đạt.`);
  if (failures > 0) process.exitCode = 1;
};

main().catch((error) => {
  console.error('❌ Lỗi smoke test:', error);
  process.exitCode = 1;
});

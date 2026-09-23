/**
 * Chép dữ liệu streak cũ (`xp_history`, `reward_keys`, `activity_dates`, huy
 * hiệu đã có) sang nhật ký `ActivityEvent` và lịch `StreakDay` — spec streak
 * §4.1 bước 5–8. Quyết định chép gì nằm ở `streak-legacy.js`; file này chỉ
 * đọc, ghi và đối chiếu.
 *
 * Mặc định là **chạy thử**: in kế hoạch và số liệu, không ghi gì. Ghi thật cần
 * `--apply` cùng một bản sao lưu đã khôi phục thử thành công.
 *
 * Chạy lại an toàn: event và ngày đã có thì bỏ qua (khoá tự nhiên), trường tóm
 * tắt chỉ được điền khi còn trống, và `total_xp` không bao giờ bị sửa.
 *
 *   node scripts/audit-user-streak.js                       # 1. xem dữ liệu và múi giờ gợi ý
 *   node scripts/backup-collections.js                      # 2. sao lưu
 *   node scripts/restore-collections.js --dir backups/<t> --target-db AppHocTiengNhat_restore_check
 *   node scripts/migrate-streak-legacy.js --legacy-tz Asia/Ho_Chi_Minh              # 3. chạy thử
 *   node scripts/migrate-streak-legacy.js --legacy-tz Asia/Ho_Chi_Minh --apply --backup backups/<t>
 *   node scripts/migrate-streak-legacy.js --legacy-tz Asia/Ho_Chi_Minh --apply --backup backups/<t> --drop-legacy-arrays
 *
 * Cờ:
 *   --legacy-tz <IANA>     Múi giờ máy chủ đã ghi `activity_dates`. Thiếu cờ này thì
 *                          bỏ qua phần ngày và `last_activity_day` — không đoán.
 *   --cutover YYYY-MM-DD   Ngày bắt đầu luật mới (mặc định 2026-09-20).
 *   --apply                Ghi thật. Cần --backup.
 *   --backup <thư mục>     Bản sao lưu của `backup-collections.js` đã khôi phục thử.
 *   --drop-legacy-arrays   Sau khi đối chiếu đạt, gỡ ba mảng cũ khỏi `UserStreak`.
 *   --remove-orphans       Gỡ tóm tắt streak (và nhật ký, lịch) của tài khoản đã bị xoá —
 *                          chúng hiện thành dòng "user: null" trên bảng xếp hạng.
 */
import { readFile } from 'node:fs/promises';
import path from 'node:path';

import dotenv from 'dotenv';
import mongoose from 'mongoose';

import ActivityEvent from '../model/ActivityEvent.js';
import StreakDay from '../model/StreakDay.js';
import User from '../model/User.js';
import UserAchievement from '../model/UserAchievement.js';
import UserStreak from '../model/UserStreak.js';
import { createUnitOfWork } from '../src/shared/db/unit-of-work.js';
import { LEGACY_XP_TYPE } from '../src/modules/streaks/streak.repository.js';
import { backupProblems } from './backup-format.js';
import {
  DEFAULT_CUTOVER_DAY,
  LEGACY_REWARD_TYPE,
  planUserMigration,
  verifyUserMigration,
} from './streak-legacy.js';

dotenv.config({ quiet: true });

const parseArgs = (argv) => {
  const args = {
    apply: false,
    drop: false,
    removeOrphans: false,
    cutoverDay: DEFAULT_CUTOVER_DAY,
    legacyTimeZone: null,
    backup: null,
  };
  for (let index = 0; index < argv.length; index += 1) {
    const flag = argv[index];
    const next = () => argv[(index += 1)];
    if (flag === '--apply') args.apply = true;
    else if (flag === '--drop-legacy-arrays') args.drop = true;
    else if (flag === '--remove-orphans') args.removeOrphans = true;
    else if (flag === '--legacy-tz') args.legacyTimeZone = next();
    else if (flag === '--cutover') args.cutoverDay = next();
    else if (flag === '--backup') args.backup = next();
    else throw new Error(`Cờ không nhận ra: ${flag}`);
  }

  if (args.legacyTimeZone) {
    // Ném RangeError ngay nếu tên múi giờ sai, trước khi chạm DB.
    new Intl.DateTimeFormat('en-US', { timeZone: args.legacyTimeZone });
  }
  if (args.apply && !args.backup) throw new Error('--apply cần --backup <thư mục sao lưu đã khôi phục thử>.');
  if (args.removeOrphans && !args.apply) throw new Error('--remove-orphans cần --apply.');
  if (args.drop && (!args.apply || !args.legacyTimeZone)) {
    throw new Error('--drop-legacy-arrays cần --apply và --legacy-tz: gỡ mảng khi ngày cũ chưa được chép là mất lịch sử.');
  }
  return args;
};

const assertBackup = async (dir) => {
  const manifest = JSON.parse(await readFile(path.join(dir, 'manifest.json'), 'utf8'));
  const problems = backupProblems(manifest);
  if (manifest.database !== mongoose.connection.name) {
    problems.push(`Bản sao lưu của ${manifest.database}, không phải ${mongoose.connection.name}.`);
  }
  if (problems.length > 0) throw new Error(problems.join('\n'));
};

const storedKeysOf = async (user, keys, session) =>
  new Set(
    (await ActivityEvent.find({ user, event_key: { $in: keys } }).select('event_key').session(session).lean()).map(
      (event) => event.event_key,
    ),
  );

const storedDaysOf = async (user, days, session) =>
  new Set(
    (await StreakDay.find({ user, day_key: { $in: days } }).select('day_key').session(session).lean()).map(
      (day) => day.day_key,
    ),
  );

/** XP đã ghi qua đường mới (không tính dòng chép từ mảng cũ), để đối chiếu số dư. */
const activityXpOf = async (user) => {
  const [row] = await ActivityEvent.aggregate([
    { $match: { user, type: { $nin: [LEGACY_XP_TYPE, LEGACY_REWARD_TYPE] } } },
    { $group: { _id: null, total: { $sum: '$xp_delta' } } },
  ]);
  return row?.total ?? 0;
};

/** Điền một trường tóm tắt **chỉ khi còn trống**, không đè lên thứ đường ghi mới đã đặt. */
const fillIfEmpty = (streakId, field, value, session) =>
  UserStreak.updateOne(
    { _id: streakId, [field]: null },
    { $set: { [field]: value }, $inc: { revision: 1 } },
    { session },
  );

const applyUser = async ({ streak, plan, legacyTimeZone, unitOfWork }) =>
  unitOfWork.run(async ({ session }) => {
    const stored = await storedKeysOf(streak.user, plan.events.map((event) => event.event_key), session);
    const missing = plan.events.filter((event) => !stored.has(event.event_key));
    if (missing.length > 0) await ActivityEvent.insertMany(missing, { session });

    if (plan.days.length > 0) {
      // `$setOnInsert`: ngày đã là `studied` giữ nguyên, không bị hạ xuống legacy.
      await StreakDay.bulkWrite(
        plan.days.map((day) => ({
          updateOne: {
            filter: { user: streak.user, day_key: day },
            update: {
              $setOnInsert: { user: streak.user, day_key: day, status: 'legacy', origin: 'legacy_unverified' },
            },
            upsert: true,
          },
        })),
        { session },
      );
    }

    for (const [field, value] of Object.entries(plan.summaryPatch)) {
      await fillIfEmpty(streak._id, field, value, session);
    }
    if (legacyTimeZone) {
      const legacyDays = await StreakDay.countDocuments({ user: streak.user, status: 'legacy' }).session(session);
      await UserStreak.updateOne(
        { _id: streak._id },
        { $set: { legacy_day_count: legacyDays }, $inc: { revision: 1 } },
        { session },
      );
    }
    return missing.length;
  });

/** Gỡ dữ liệu streak của một tài khoản không còn tồn tại, trong một transaction. */
const removeOrphan = (streak, unitOfWork) =>
  unitOfWork.run(async ({ session }) => {
    const byUser = { user: streak.user };
    await ActivityEvent.deleteMany(byUser, { session });
    await StreakDay.deleteMany(byUser, { session });
    await UserStreak.deleteOne({ _id: streak._id }, { session });
  });

const main = async () => {
  const args = parseArgs(process.argv.slice(2));
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong .env');
  await mongoose.connect(uri, { dbName: process.env.DB_NAME || 'AppHocTiengNhat' });
  const unitOfWork = createUnitOfWork({ connection: mongoose.connection });

  try {
    if (args.apply) await assertBackup(args.backup);
    console.log(`database : ${mongoose.connection.name}`);
    console.log(`chế độ   : ${args.apply ? 'GHI THẬT' : 'chạy thử (không ghi)'}`);
    console.log(`cutover  : ${args.cutoverDay}`);
    console.log(`múi giờ  : ${args.legacyTimeZone ?? '(chưa chọn — bỏ qua ngày cũ và last_activity_day)'}\n`);

    const [streaks, completed, users] = await Promise.all([
      UserStreak.find({}).lean(),
      UserAchievement.find({ is_completed: true }).select('user achievement').lean(),
      User.find({}).select('_id').lean(),
    ]);
    const existingUsers = new Set(users.map((user) => String(user._id)));
    const achievementsByUser = new Map();
    for (const row of completed) {
      const key = String(row.user);
      achievementsByUser.set(key, [...(achievementsByUser.get(key) ?? []), row.achievement]);
    }

    const totals = { users: 0, events: 0, inserted: 0, days: 0, failed: 0, dropped: 0, orphaned: 0 };
    for (const streak of streaks) {
      // Tài khoản đã xoá: chép lịch sử của nó chỉ tạo thêm dữ liệu mồ côi.
      if (!streak.user || !existingUsers.has(String(streak.user))) {
        totals.orphaned += 1;
        if (args.removeOrphans) await removeOrphan(streak, unitOfWork);
        continue;
      }
      const plan = planUserMigration({
        streak,
        completedAchievementIds: achievementsByUser.get(String(streak.user)) ?? [],
        legacyTimeZone: args.legacyTimeZone,
        cutoverDay: args.cutoverDay,
      });
      totals.users += 1;
      totals.events += plan.events.length;
      totals.days += plan.days.length;
      if (args.apply) totals.inserted += await applyUser({ streak, plan, legacyTimeZone: args.legacyTimeZone, unitOfWork });

      const check = verifyUserMigration({
        plan,
        streak,
        storedEventKeys: await storedKeysOf(streak.user, plan.events.map((event) => event.event_key)),
        storedDayKeys: await storedDaysOf(streak.user, plan.days),
        activityXpTotal: await activityXpOf(streak.user),
      });
      const label = `user ${String(streak.user)}`;
      console.log(
        `${check.ok ? '✅' : args.apply ? '❌' : '•'} ${label}: ${plan.events.length} event, ${plan.days.length} ngày` +
          `${check.ok ? '' : ` — thiếu ${check.missingEvents} event, ${check.missingDays} ngày`}` +
          `${check.xpDifference !== 0 ? ` — total_xp lệch lịch sử ${check.xpDifference} (chỉ báo, không sửa)` : ''}`,
      );
      for (const problem of plan.problems) console.log(`     ⚠️  ${problem}`);
      if (args.apply && !check.ok) totals.failed += 1;

      if (args.drop && check.ok) {
        await UserStreak.updateOne(
          { _id: streak._id },
          { $unset: { xp_history: '', activity_dates: '', reward_keys: '' }, $inc: { revision: 1 } },
        );
        totals.dropped += 1;
      }
    }

    console.log(`\n📊 ${totals.users} user · ${totals.events} event trong kế hoạch · ${totals.days} ngày cũ`);
    if (totals.orphaned > 0) {
      console.log(
        `   ${args.removeOrphans ? 'đã gỡ' : 'bỏ qua'} ${totals.orphaned} streak của tài khoản không còn tồn tại`,
      );
    }
    if (args.apply) {
      console.log(`   đã ghi mới ${totals.inserted} event · đối chiếu lỗi ${totals.failed} user`);
      if (args.drop) console.log(`   đã gỡ mảng cũ của ${totals.dropped} user`);
    } else {
      console.log('   🔍 Chạy thử: không ghi gì. Thêm --apply --backup <thư mục> để ghi.');
    }
    if (totals.failed > 0) process.exitCode = 1;
  } finally {
    await mongoose.disconnect();
  }
};

main().catch((error) => {
  console.error('❌ Lỗi migration:', error.message);
  process.exitCode = 1;
});

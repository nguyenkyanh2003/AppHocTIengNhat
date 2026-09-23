/**
 * Nạp đề JLPT N4 rút gọn — upsert theo `title`, không xoá gì.
 *
 * Bản cũ gọi `JLPT.deleteMany({})`: xoá luôn cả đề N3 nhập bằng script khác,
 * và mỗi lần chạy đề có `_id` mới nên `LearningHistory.exam` của mọi lượt thi
 * trỏ vào đề không còn tồn tại. Đề đã có mà khác nội dung chỉ bị ghi đè khi
 * chạy `--overwrite`; đáp án chấm theo **vị trí** câu, nên ghi đè làm đổi thứ tự
 * câu sẽ lệch với bài làm đã lưu.
 *
 *   node scripts/seed-jlpt.js --dry-run
 *   node scripts/seed-jlpt.js [--overwrite]
 */
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import JLPT from '../model/JLPT.js';
import { applyPlan, parseFlags, planUpserts, printPlan } from './content-upsert.js';

dotenv.config({ quiet: true });

const sampleExam = {
  title: "Đề mẫu JLPT N4 - Mini Test",
  description: "Đề luyện tập rút gọn gồm từ vựng, ngữ pháp, đọc hiểu, nghe hiểu",
  level: "N4",
  year: 2024,
  month: 7,
  time_limit: 20,
  pass_score: 18,
  total_score: 30,
  is_published: true,
  is_active: true,
  sections: {
    moji_goi: [
      {
        mondai: 1,
        question_text: "『食べる』の尊敬語はどれですか。",
        choices: ["いただく", "召し上がる", "食べさせる", "ご馳走する"],
        correct_answer: 1,
        explanation: "『召し上がる』は尊敬語。『いただく』は謙譲語。",
        score: 2,
      },
      {
        mondai: 2,
        question_text: "『簡単』の反対語はどれですか。",
        choices: ["複雑", "静か", "下手", "難解"],
        correct_answer: 0,
        explanation: "簡単⇔複雑",
        score: 2,
      },
    ],
    bunpou: [
      {
        mondai: 1,
        question_text: "明日までにレポートを（ ）。",
        choices: ["出させます", "出しておきます", "出されます", "出されておきます"],
        correct_answer: 1,
        explanation: "期限に間に合うよう準備＝〜ておく",
        score: 2,
      },
      {
        mondai: 2,
        question_text: "日本へ来て（ ）、寿司が好きになりました。",
        choices: ["いらい", "いこう", "からには", "ところで"],
        correct_answer: 0,
        explanation: "来て以来＝since",
        score: 2,
      },
    ],
    dokkai: [
      {
        mondai: 1,
        group_content: "駅の掲示：『明日から工事のため、北口を閉鎖します』",
        questions: [
          {
            mondai: 1,
            question_text: "何が閉鎖されますか。",
            choices: ["南口", "北口", "改札", "ホーム"],
            correct_answer: 1,
            explanation: "掲示に北口とある",
            score: 2,
          },
        ],
      },
    ],
    choukai: [
      {
        mondai: 1,
        group_content: "（会話）男：明日の会議は10時からですよね？ 女：いいえ、30分早くなりました。",
        questions: [
          {
            mondai: 1,
            question_text: "会議は何時に始まりますか。",
            choices: ["9時", "9時半", "10時", "10時半"],
            correct_answer: 1,
            explanation: "30分早く＝9時30分",
            score: 2,
          },
        ],
      },
    ],
  },
};

const run = async () => {
  const flags = parseFlags();
  await mongoose.connect(process.env.MONGODB_URI, { dbName: process.env.DB_NAME || 'AppHocTiengNhat' });
  console.log(`✅ Đã kết nối MongoDB${flags.dryRun ? ' (--dry-run, không ghi)' : ''}`);

  try {
    const existing = await JLPT.find({ title: sampleExam.title }).lean();
    const plan = planUpserts({ rows: [sampleExam], existing, keyOf: (exam) => exam.title });
    if (!flags.dryRun) await applyPlan({ model: JLPT, plan, overwrite: flags.overwrite });
    printPlan('Đề JLPT', plan, flags);
  } finally {
    await mongoose.connection.close();
  }
};

run().catch((error) => {
  console.error('❌ Lỗi:', error.message);
  process.exit(1);
});

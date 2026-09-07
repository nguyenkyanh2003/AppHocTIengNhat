import mongoose from "mongoose";
import dotenv from "dotenv";
import JLPT from "../model/JLPT.js";

dotenv.config();

const mongoURI = process.env.MONGODB_URI;
if (!mongoURI) {
  console.error("❌ MONGODB_URI không được cấu hình trong .env");
  process.exit(1);
}

async function connectDB() {
  await mongoose.connect(mongoURI, {
    dbName: process.env.DB_NAME || "AppHocTiengNhat",
  });
  console.log("✅ Đã kết nối MongoDB để seed JLPT");
}

async function seed() {
  await connectDB();
  await JLPT.deleteMany({});
  console.log("ℹ️ Đã xoá tất cả đề JLPT cũ");

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

  await JLPT.insertMany([sampleExam]);
  console.log("✅ Đã seed 1 đề JLPT N4 sample");
  await mongoose.connection.close();
  console.log("✅ Đã đóng kết nối MongoDB");
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});

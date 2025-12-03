import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import mongoose from "mongoose";
import path from "path";
import { fileURLToPath } from "url";
import { dirname } from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

import UserRoutes from "./routes/UserManager.js";
import VocabularyRoutes from "./routes/Vocabulary.js";
import KanjiRoutes from "./routes/Kanji.js";
import LessonRoutes from "./routes/Lesson.js";
import ExerciseRoutes from "./routes/Exercise.js";
import ProgressRoutes from "./routes/Progress.js";
import GroupRoutes from "./routes/Group.js";
import GroupChatRoutes from "./routes/GroupChat.js";
import JLPTRoutes from "./routes/JLPT.js";
import GrammarRoutes from "./routes/Grammar.js";
import NotificationRoutes from "./routes/Notification.js";
import TransactionRoutes from "./routes/Transaction.js";
import NewsRoutes from "./routes/News.js";
import NoteBookRoutes from "./routes/NoteBook.js";
import ReportRoutes from "./routes/Report.js";
import SRSProgressRoutes from "./routes/SRSProgress.js";
import LessonProgressRoutes from "./routes/LessonProgress.js";
import StreakRoutes from "./routes/Streak.js";
import AchievementRoutes from "./routes/Achievement.js";
import timezoneMiddleware from "./middleware/timezoneMiddleware.js";

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());
app.use(timezoneMiddleware); // Tự động convert tất cả dates sang giờ Việt Nam

// Serve static files (uploaded images)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI;
    if (!mongoURI) {
      throw new Error('MONGODB_URI không được định nghĩa trong file .env');
    }
    
    await mongoose.connect(mongoURI, {
      dbName: process.env.DB_NAME || 'AppHocTiengNhat'
    });
    console.log(`✅ Kết nối MongoDB Database '${mongoose.connection.name}' thành công!`);
  } catch (error) {
    console.error('❌ Lỗi kết nối MongoDB:', error.message);
    process.exit(1);
  }
};

app.use("/api/users", UserRoutes);
app.use("/api/vocabulary", VocabularyRoutes);
app.use("/api/kanji", KanjiRoutes);
app.use("/api/lesson", LessonRoutes);
app.use("/api/exercise", ExerciseRoutes);
app.use("/api/progress", ProgressRoutes);
app.use("/api/group", GroupRoutes);
app.use("/api/group-chat", GroupChatRoutes);
app.use("/api/jlpt", JLPTRoutes);
app.use("/api/grammar", GrammarRoutes);
app.use("/api/notification", NotificationRoutes);
app.use("/api/transactions", TransactionRoutes);
app.use("/api/news", NewsRoutes);
app.use("/api/notebook", NoteBookRoutes);
app.use("/api/report", ReportRoutes);
app.use("/api/srs", SRSProgressRoutes);
app.use("/api/lesson-progress", LessonProgressRoutes);
app.use("/api/streak", StreakRoutes);
app.use("/api/achievement", AchievementRoutes);

// Route mặc định
app.get("/", (req, res) => {
  res.json({ 
    message: "API App Học Tiếng Nhật", 
    version: "1.0.0",
    endpoints: [
      "/api/users",
      "/api/vocabulary",
      "/api/kanji",
      "/api/lesson",
      "/api/exercise",
      "/api/progress",
      "/api/group",
      "/api/group-chat",
      "/api/jlpt",
      "/api/grammar",
      "/api/notification",
      "/api/news",
      "/api/notebook",
      "/api/report",
      "/api/srs",
      "/api/lesson-progress",
      "/api/streak",
      "/api/achievement"
    ]
  });
});

app.use((req, res, next) => {
  res.status(404).json({ message: "API không tồn tại" });
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: "Đã có lỗi xảy ra ở máy chủ", error: err.message });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, async () => {
  console.log(`🚀 Server đang chạy trên cổng ${PORT}`);
  await connectDB();
});

process.on('SIGINT', async () => {
  console.log('\n🛑 Đang đóng kết nối MongoDB...');
  await mongoose.connection.close();
  console.log('✅ Đã đóng kết nối MongoDB');
  process.exit(0);
});
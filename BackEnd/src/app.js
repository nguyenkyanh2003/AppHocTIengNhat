import express from 'express';
import cors from 'cors';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

import UserRoutes from './modules/users/user.routes.js';
import VocabularyRoutes from './modules/vocabulary/vocabulary.routes.js';
import KanjiRoutes from './modules/kanji/kanji.routes.js';
import LessonRoutes from './modules/lessons/lesson.routes.js';
import ExerciseRoutes from './modules/exercise/exercise.routes.js';
import ProgressRoutes from './modules/progress/progress.routes.js';
import GroupRoutes from './modules/study-groups/group.routes.js';
import GroupChatRoutes from './modules/chat/group-chat.routes.js';
import JLPTRoutes from './modules/jlpt/jlpt.routes.js';
import GrammarRoutes from './modules/grammar/grammar.routes.js';
import NotificationRoutes from './modules/notifications/notification.routes.js';
import TransactionRoutes from './modules/transactions/transaction.routes.js';
import NewsRoutes from './modules/news/news.routes.js';
import NoteBookRoutes from './modules/notebook/notebook.routes.js';
import ReportRoutes from './modules/reports/report.routes.js';
import SRSProgressRoutes from './modules/srs/srs-progress.routes.js';
import LessonProgressRoutes from './modules/lesson-progress/lesson-progress.routes.js';
import StreakRoutes from './modules/streaks/streak.routes.js';
import AchievementRoutes from './modules/achievements/achievement.routes.js';
import SettingsRoutes from './modules/settings/settings.routes.js';
import FlashcardRoutes from './modules/flashcards/flashcard.routes.js';
import timezoneMiddleware from './middleware/timezone.middleware.js';
import { errorHandler, notFoundHandler } from './middleware/error.middleware.js';
import { productionResponseSanitizer, securityHeaders } from './middleware/security.middleware.js';
import env from './config/env.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();

app.disable('x-powered-by');
app.use(securityHeaders);
app.use(productionResponseSanitizer(env.nodeEnv));
app.use(cors({
  origin(origin, callback) {
    if (!origin || env.nodeEnv !== 'production' || env.corsOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(Object.assign(new Error('Origin không được CORS cho phép.'), { status: 403 }));
  },
}));
app.use(express.json({ limit: '1mb' }));
app.use(timezoneMiddleware);
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.use('/api/users', UserRoutes);
app.use('/api/vocabulary', VocabularyRoutes);
app.use('/api/kanji', KanjiRoutes);
app.use('/api/lesson', LessonRoutes);
app.use('/api/exercise', ExerciseRoutes);
app.use('/api/progress', ProgressRoutes);
app.use('/api/group', GroupRoutes);
app.use('/api/group-chat', GroupChatRoutes);
app.use('/api/jlpt', JLPTRoutes);
app.use('/api/grammar', GrammarRoutes);
app.use('/api/notifications', NotificationRoutes);
app.use('/api/transactions', TransactionRoutes);
app.use('/api/news', NewsRoutes);
app.use('/api/notebook', NoteBookRoutes);
app.use('/api/report', ReportRoutes);
app.use('/api/srs', SRSProgressRoutes);
app.use('/api/lesson-progress', LessonProgressRoutes);
app.use('/api/streak', StreakRoutes);
app.use('/api/achievement', AchievementRoutes);
app.use('/api/settings', SettingsRoutes);
app.use('/api/flashcard', FlashcardRoutes);

app.get('/', (req, res) => {
  res.json({
    message: 'API App Học Tiếng Nhật',
    version: '1.0.0',
    endpoints: [
      '/api/users',
      '/api/vocabulary',
      '/api/kanji',
      '/api/lesson',
      '/api/exercise',
      '/api/progress',
      '/api/group',
      '/api/group-chat',
      '/api/jlpt',
      '/api/grammar',
      '/api/notifications',
      '/api/news',
      '/api/notebook',
      '/api/report',
      '/api/srs',
      '/api/lesson-progress',
      '/api/streak',
      '/api/achievement',
      '/api/settings',
      '/api/flashcard',
    ],
  });
});

app.use(notFoundHandler);
app.use(errorHandler);

export default app;

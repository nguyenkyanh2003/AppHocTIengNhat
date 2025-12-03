import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Achievement from '../model/Achievement.js';

dotenv.config();

const achievements = [
  // Streak achievements
  {
    name: 'First Step',
    name_vi: 'Bước Đầu Tiên',
    description: 'Log in for 7 consecutive days',
    description_vi: 'Đăng nhập 7 ngày liên tiếp',
    icon: '🔥',
    category: 'streak',
    requirement_type: 'streak',
    requirement_value: 7,
    xp_reward: 100,
    rarity: 'common',
  },
  {
    name: 'Two Week Warrior',
    name_vi: 'Chiến Binh Hai Tuần',
    description: 'Log in for 14 consecutive days',
    description_vi: 'Đăng nhập 14 ngày liên tiếp',
    icon: '🔥',
    category: 'streak',
    requirement_type: 'streak',
    requirement_value: 14,
    xp_reward: 200,
    rarity: 'rare',
  },
  {
    name: 'Monthly Master',
    name_vi: 'Bậc Thầy Tháng',
    description: 'Log in for 30 consecutive days',
    description_vi: 'Đăng nhập 30 ngày liên tiếp',
    icon: '🔥',
    category: 'streak',
    requirement_type: 'streak',
    requirement_value: 30,
    xp_reward: 500,
    rarity: 'epic',
  },
  {
    name: 'Dedication Legend',
    name_vi: 'Huyền Thoại Kiên Trì',
    description: 'Log in for 100 consecutive days',
    description_vi: 'Đăng nhập 100 ngày liên tiếp',
    icon: '🔥',
    category: 'streak',
    requirement_type: 'streak',
    requirement_value: 100,
    xp_reward: 2000,
    rarity: 'legendary',
  },

  // Vocabulary achievements
  {
    name: 'Word Beginner',
    name_vi: 'Người Mới Học Từ',
    description: 'Learn 50 vocabulary words',
    description_vi: 'Học 50 từ vựng',
    icon: '📚',
    category: 'vocabulary',
    requirement_type: 'count',
    requirement_value: 50,
    xp_reward: 150,
    rarity: 'common',
  },
  {
    name: 'Word Collector',
    name_vi: 'Người Sưu Tập Từ',
    description: 'Learn 100 vocabulary words',
    description_vi: 'Học 100 từ vựng',
    icon: '📚',
    category: 'vocabulary',
    requirement_type: 'count',
    requirement_value: 100,
    xp_reward: 300,
    rarity: 'rare',
  },
  {
    name: 'Word Master',
    name_vi: 'Bậc Thầy Từ Vựng',
    description: 'Learn 500 vocabulary words',
    description_vi: 'Học 500 từ vựng',
    icon: '📚',
    category: 'vocabulary',
    requirement_type: 'count',
    requirement_value: 500,
    xp_reward: 1000,
    rarity: 'epic',
  },
  {
    name: 'Vocabulary Sage',
    name_vi: 'Hi현 Nhân Từ Vựng',
    description: 'Learn 1000 vocabulary words',
    description_vi: 'Học 1000 từ vựng',
    icon: '📚',
    category: 'vocabulary',
    requirement_type: 'count',
    requirement_value: 1000,
    xp_reward: 3000,
    rarity: 'legendary',
  },

  // Grammar achievements
  {
    name: 'Grammar Novice',
    name_vi: 'Người Mới Học Ngữ Pháp',
    description: 'Learn 20 grammar points',
    description_vi: 'Học 20 điểm ngữ pháp',
    icon: '📝',
    category: 'grammar',
    requirement_type: 'count',
    requirement_value: 20,
    xp_reward: 150,
    rarity: 'common',
  },
  {
    name: 'Grammar Expert',
    name_vi: 'Chuyên Gia Ngữ Pháp',
    description: 'Learn 50 grammar points',
    description_vi: 'Học 50 điểm ngữ pháp',
    icon: '📝',
    category: 'grammar',
    requirement_type: 'count',
    requirement_value: 50,
    xp_reward: 400,
    rarity: 'rare',
  },
  {
    name: 'Grammar Master',
    name_vi: 'Bậc Thầy Ngữ Pháp',
    description: 'Learn 100 grammar points',
    description_vi: 'Học 100 điểm ngữ pháp',
    icon: '📝',
    category: 'grammar',
    requirement_type: 'count',
    requirement_value: 100,
    xp_reward: 1200,
    rarity: 'epic',
  },

  // Kanji achievements
  {
    name: 'Kanji Starter',
    name_vi: 'Người Bắt Đầu Kanji',
    description: 'Learn 50 kanji characters',
    description_vi: 'Học 50 chữ Kanji',
    icon: '🈯',
    category: 'kanji',
    requirement_type: 'count',
    requirement_value: 50,
    xp_reward: 200,
    rarity: 'common',
  },
  {
    name: 'Kanji Scholar',
    name_vi: 'Học Giả Kanji',
    description: 'Learn 200 kanji characters',
    description_vi: 'Học 200 chữ Kanji',
    icon: '🈯',
    category: 'kanji',
    requirement_type: 'count',
    requirement_value: 200,
    xp_reward: 600,
    rarity: 'rare',
  },
  {
    name: 'Kanji Master',
    name_vi: 'Bậc Thầy Kanji',
    description: 'Learn 500 kanji characters',
    description_vi: 'Học 500 chữ Kanji',
    icon: '🈯',
    category: 'kanji',
    requirement_type: 'count',
    requirement_value: 500,
    xp_reward: 2000,
    rarity: 'epic',
  },

  // Lesson achievements
  {
    name: 'Lesson Beginner',
    name_vi: 'Người Mới Học Bài',
    description: 'Complete 5 lessons',
    description_vi: 'Hoàn thành 5 bài học',
    icon: '📖',
    category: 'lesson',
    requirement_type: 'count',
    requirement_value: 5,
    xp_reward: 100,
    rarity: 'common',
  },
  {
    name: 'Lesson Enthusiast',
    name_vi: 'Người Đam Mê Bài Học',
    description: 'Complete 20 lessons',
    description_vi: 'Hoàn thành 20 bài học',
    icon: '📖',
    category: 'lesson',
    requirement_type: 'count',
    requirement_value: 20,
    xp_reward: 400,
    rarity: 'rare',
  },
  {
    name: 'Lesson Master',
    name_vi: 'Bậc Thầy Bài Học',
    description: 'Complete 50 lessons',
    description_vi: 'Hoàn thành 50 bài học',
    icon: '📖',
    category: 'lesson',
    requirement_type: 'count',
    requirement_value: 50,
    xp_reward: 1500,
    rarity: 'epic',
  },

  // XP achievements
  {
    name: 'Point Starter',
    name_vi: 'Người Mới Kiếm Điểm',
    description: 'Earn 500 XP',
    description_vi: 'Kiếm được 500 XP',
    icon: '⭐',
    category: 'xp',
    requirement_type: 'xp',
    requirement_value: 500,
    xp_reward: 100,
    rarity: 'common',
  },
  {
    name: 'Point Collector',
    name_vi: 'Người Sưu Tập Điểm',
    description: 'Earn 1000 XP',
    description_vi: 'Kiếm được 1000 XP',
    icon: '⭐',
    category: 'xp',
    requirement_type: 'xp',
    requirement_value: 1000,
    xp_reward: 200,
    rarity: 'rare',
  },
  {
    name: 'Point Master',
    name_vi: 'Bậc Thầy Kiếm Điểm',
    description: 'Earn 5000 XP',
    description_vi: 'Kiếm được 5000 XP',
    icon: '⭐',
    category: 'xp',
    requirement_type: 'xp',
    requirement_value: 5000,
    xp_reward: 500,
    rarity: 'epic',
  },
  {
    name: 'XP Legend',
    name_vi: 'Huyền Thoại XP',
    description: 'Earn 10000 XP',
    description_vi: 'Kiếm được 10000 XP',
    icon: '⭐',
    category: 'xp',
    requirement_type: 'xp',
    requirement_value: 10000,
    xp_reward: 2000,
    rarity: 'legendary',
  },

  // Practice achievements
  {
    name: 'Practice Newbie',
    name_vi: 'Người Mới Luyện Tập',
    description: 'Complete 10 practice exercises',
    description_vi: 'Hoàn thành 10 bài luyện tập',
    icon: '🎯',
    category: 'practice',
    requirement_type: 'count',
    requirement_value: 10,
    xp_reward: 100,
    rarity: 'common',
  },
  {
    name: 'Practice Regular',
    name_vi: 'Người Luyện Tập Thường Xuyên',
    description: 'Complete 50 practice exercises',
    description_vi: 'Hoàn thành 50 bài luyện tập',
    icon: '🎯',
    category: 'practice',
    requirement_type: 'count',
    requirement_value: 50,
    xp_reward: 300,
    rarity: 'rare',
  },
  {
    name: 'Practice Master',
    name_vi: 'Bậc Thầy Luyện Tập',
    description: 'Complete 100 practice exercises',
    description_vi: 'Hoàn thành 100 bài luyện tập',
    icon: '🎯',
    category: 'practice',
    requirement_type: 'count',
    requirement_value: 100,
    xp_reward: 1000,
    rarity: 'epic',
  },
];

async function seedAchievements() {
  try {
    const mongoURI = process.env.MONGODB_URI;
    if (!mongoURI) {
      throw new Error('MONGODB_URI not defined in .env');
    }

    await mongoose.connect(mongoURI, {
      dbName: process.env.DB_NAME || 'AppHocTiengNhat',
    });

    console.log('✅ Connected to MongoDB');

    // Clear existing achievements
    await Achievement.deleteMany({});
    console.log('🗑️  Cleared existing achievements');

    // Insert new achievements
    const result = await Achievement.insertMany(achievements);
    console.log(`✨ Inserted ${result.length} achievements`);

    // Display summary
    const summary = await Achievement.aggregate([
      {
        $group: {
          _id: '$category',
          count: { $sum: 1 },
          total_xp: { $sum: '$xp_reward' },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    console.log('\n📊 Achievement Summary:');
    summary.forEach((cat) => {
      console.log(`   ${cat._id}: ${cat.count} achievements, ${cat.total_xp} XP`);
    });

    await mongoose.connection.close();
    console.log('\n✅ Seeding completed successfully!');
  } catch (error) {
    console.error('❌ Error seeding achievements:', error);
    process.exit(1);
  }
}

seedAchievements();

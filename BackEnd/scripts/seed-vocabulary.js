import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Vocabulary from '../model/Vocabulary.js';
import Lesson from '../model/Lesson.js';

dotenv.config();

const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI;
    await mongoose.connect(mongoURI, {
      dbName: process.env.DB_NAME || 'AppHocTiengNhat'
    });
    console.log('✅ Kết nối MongoDB thành công!');
  } catch (error) {
    console.error('❌ Lỗi kết nối MongoDB:', error.message);
    process.exit(1);
  }
};

const seedVocabulary = async () => {
  try {
    await connectDB();

    // Lấy một bài học làm mẫu
    const lessons = await Lesson.find().limit(5);
    
    if (lessons.length === 0) {
      console.log('⚠️ Chưa có bài học nào. Vui lòng chạy seed-lessons.js trước!');
      process.exit(1);
    }

    // Xóa dữ liệu cũ
    await Vocabulary.deleteMany({});
    console.log('🗑️ Đã xóa dữ liệu từ vựng cũ');

    const vocabularies = [
      // N5 - Bài 1: Chào hỏi
      {
        word: '学生',
        hiragana: 'がくせい',
        meaning: 'Học sinh, sinh viên',
        level: 'N5',
        usage_context: 'Dùng để chỉ người đang học tập ở trường',
        lesson: lessons[0]._id,
        examples: [
          {
            sentence: '私は学生です。',
            meaning: 'Tôi là học sinh.',
          },
          {
            sentence: '彼は大学の学生です。',
            meaning: 'Anh ấy là sinh viên đại học.',
          }
        ]
      },
      {
        word: '先生',
        hiragana: 'せんせい',
        meaning: 'Giáo viên, thầy cô',
        level: 'N5',
        usage_context: 'Dùng để gọi hoặc nói về giáo viên, bác sĩ',
        lesson: lessons[0]._id,
        examples: [
          {
            sentence: '田中先生は日本語の先生です。',
            meaning: 'Thầy Tanaka là giáo viên tiếng Nhật.',
          }
        ]
      },
      {
        word: '友達',
        hiragana: 'ともだち',
        meaning: 'Bạn bè',
        level: 'N5',
        usage_context: 'Dùng để nói về bạn bè thân thiết',
        lesson: lessons[0]._id,
        examples: [
          {
            sentence: '友達と映画を見ます。',
            meaning: 'Tôi xem phim với bạn.',
          }
        ]
      },
      {
        word: '会社',
        hiragana: 'かいしゃ',
        meaning: 'Công ty',
        level: 'N5',
        usage_context: 'Nơi làm việc',
        lesson: lessons[0]._id,
        examples: [
          {
            sentence: '父は会社で働いています。',
            meaning: 'Bố tôi làm việc ở công ty.',
          }
        ]
      },
      {
        word: '家族',
        hiragana: 'かぞく',
        meaning: 'Gia đình',
        level: 'N5',
        usage_context: 'Các thành viên trong gia đình',
        lesson: lessons[0]._id,
        examples: [
          {
            sentence: '家族は4人です。',
            meaning: 'Gia đình tôi có 4 người.',
          }
        ]
      },

      // N5 - Bài 2: Số đếm
      {
        word: '今日',
        hiragana: 'きょう',
        meaning: 'Hôm nay',
        level: 'N5',
        usage_context: 'Thời gian hiện tại',
        lesson: lessons[1]._id,
        examples: [
          {
            sentence: '今日は暑いです。',
            meaning: 'Hôm nay nóng quá.',
          }
        ]
      },
      {
        word: '明日',
        hiragana: 'あした',
        meaning: 'Ngày mai',
        level: 'N5',
        usage_context: 'Ngày tiếp theo',
        lesson: lessons[1]._id,
        examples: [
          {
            sentence: '明日、学校に行きます。',
            meaning: 'Ngày mai tôi đi học.',
          }
        ]
      },
      {
        word: '昨日',
        hiragana: 'きのう',
        meaning: 'Hôm qua',
        level: 'N5',
        usage_context: 'Ngày trước đó',
        lesson: lessons[1]._id,
        examples: [
          {
            sentence: '昨日は雨でした。',
            meaning: 'Hôm qua trời mưa.',
          }
        ]
      },

      // N4
      {
        word: '電車',
        hiragana: 'でんしゃ',
        meaning: 'Tàu điện',
        level: 'N4',
        usage_context: 'Phương tiện giao thông',
        lesson: lessons[2]._id,
        examples: [
          {
            sentence: '毎日電車で会社に行きます。',
            meaning: 'Mỗi ngày tôi đi làm bằng tàu điện.',
          }
        ]
      },
      {
        word: '自転車',
        hiragana: 'じてんしゃ',
        meaning: 'Xe đạp',
        level: 'N4',
        usage_context: 'Phương tiện đi lại',
        lesson: lessons[2]._id,
        examples: [
          {
            sentence: '自転車で学校に行きます。',
            meaning: 'Tôi đi học bằng xe đạp.',
          }
        ]
      },
      {
        word: '運転',
        hiragana: 'うんてん',
        meaning: 'Lái xe, điều khiển',
        level: 'N4',
        usage_context: 'Hành động điều khiển xe',
        lesson: lessons[2]._id,
        examples: [
          {
            sentence: '車を運転します。',
            meaning: 'Tôi lái xe ô tô.',
          }
        ]
      },

      // N3
      {
        word: '努力',
        hiragana: 'どりょく',
        meaning: 'Nỗ lực, cố gắng',
        level: 'N3',
        usage_context: 'Hành động cố gắng làm việc gì đó',
        lesson: lessons[3]._id,
        examples: [
          {
            sentence: '努力すれば、夢が叶います。',
            meaning: 'Nếu cố gắng thì ước mơ sẽ thành hiện thực.',
          }
        ]
      },
      {
        word: '成功',
        hiragana: 'せいこう',
        meaning: 'Thành công',
        level: 'N3',
        usage_context: 'Kết quả tích cực',
        lesson: lessons[3]._id,
        examples: [
          {
            sentence: '試験に成功しました。',
            meaning: 'Tôi đã đỗ kỳ thi.',
          }
        ]
      },

      // N2
      {
        word: '敬語',
        hiragana: 'けいご',
        meaning: 'Kính ngữ',
        level: 'N2',
        usage_context: 'Ngôn ngữ lịch sự trong tiếng Nhật',
        lesson: lessons[4]._id,
        examples: [
          {
            sentence: '会社では敬語を使います。',
            meaning: 'Ở công ty chúng ta sử dụng kính ngữ.',
          }
        ]
      },
      {
        word: '丁寧',
        hiragana: 'ていねい',
        meaning: 'Lịch sự, cẩn thận',
        level: 'N2',
        usage_context: 'Thái độ hoặc cách nói chuyện',
        lesson: lessons[4]._id,
        examples: [
          {
            sentence: '彼女は丁寧に説明しました。',
            meaning: 'Cô ấy đã giải thích một cách cẩn thận.',
          }
        ]
      }
    ];

    const result = await Vocabulary.insertMany(vocabularies);
    console.log(`✅ Đã thêm ${result.length} từ vựng thành công!`);

    // Hiển thị thống kê
    const stats = await Vocabulary.aggregate([
      { $group: { _id: '$level', count: { $sum: 1 } } },
      { $sort: { _id: 1 } }
    ]);

    console.log('\n📊 Thống kê từ vựng theo level:');
    stats.forEach(stat => {
      console.log(`   ${stat._id}: ${stat.count} từ`);
    });

    process.exit(0);
  } catch (error) {
    console.error('❌ Lỗi khi seed vocabulary:', error);
    process.exit(1);
  }
};

seedVocabulary();

import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Lesson from '../model/Lesson.js';
import Vocabulary from '../model/Vocabulary.js';
import Grammar from '../model/Grammar.js';
import Kanji from '../model/Kanji.js';

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

const syncLessonRelations = async () => {
  try {
    await connectDB();
    console.log('🔄 Bắt đầu đồng bộ dữ liệu bài học...\n');

    // Lấy tất cả bài học
    const lessons = await Lesson.find();
    console.log(`📚 Tìm thấy ${lessons.length} bài học\n`);

    for (const lesson of lessons) {
      // Tìm từ vựng thuộc bài học này
      const vocabularies = await Vocabulary.find({ lesson: lesson._id });
      
      // Tìm ngữ pháp cùng level (tạm thời theo level vì chưa có lesson field trong Grammar)
      const grammars = await Grammar.find({ level: lesson.level }).limit(5);
      
      // Tìm kanji cùng level
      const kanjis = await Kanji.find({ level: lesson.level }).limit(5);

      // Cập nhật bài học với các ID
      await Lesson.findByIdAndUpdate(lesson._id, {
        vocabularies: vocabularies.map(v => v._id),
        grammars: grammars.map(g => g._id),
        kanjis: kanjis.map(k => k._id)
      });

      console.log(`✅ ${lesson.title}:`);
      console.log(`   - Từ vựng: ${vocabularies.length}`);
      console.log(`   - Ngữ pháp: ${grammars.length}`);
      console.log(`   - Kanji: ${kanjis.length}`);
    }

    console.log('\n🎉 Đồng bộ hoàn tất!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Lỗi:', error.message);
    process.exit(1);
  }
};

syncLessonRelations();

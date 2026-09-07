import mongoose from 'mongoose';
import dotenv from 'dotenv';
import StudyGroup from '../model/StudyGroup.js';
import User from '../model/User.js';

dotenv.config();

// Nhóm mẫu cho kịch bản demo: chỉ dùng ở mức xem danh sách/chi tiết.
// Chat đã được gỡ khỏi client nên seeder không tạo tin nhắn.
const groups = [
  {
    name: 'N5 - Giao tiếp cơ bản',
    description:
      'Nhóm luyện hội thoại và từ vựng N5 cho người mới bắt đầu. Mục tiêu: học đều mỗi ngày và ôn lại bằng SRS.',
    level: 'N5',
    is_private: false,
    max_members: 50,
  },
  {
    name: 'N4 - Luyện đề JLPT',
    description:
      'Nhóm cùng luyện đề JLPT N4, tập trung vào ngữ pháp và đọc hiểu. Mục tiêu: hoàn thành một đề mỗi tuần.',
    level: 'N4',
    is_private: false,
    max_members: 30,
  },
];

async function seedStudyGroups() {
  try {
    const mongoURI = process.env.MONGODB_URI;
    if (!mongoURI) {
      throw new Error('MONGODB_URI not defined in .env');
    }

    await mongoose.connect(mongoURI, {
      dbName: process.env.DB_NAME || 'AppHocTiengNhat',
    });

    console.log('✅ Connected to MongoDB');

    // Lấy user có sẵn làm thành viên; sắp xếp theo _id để chạy lại cho kết quả ổn định.
    const users = await User.find({}).sort({ _id: 1 }).limit(4).select('_id TenDangNhap');

    if (users.length === 0) {
      throw new Error(
        'Chưa có user nào trong database. Hãy đăng ký vài tài khoản hoặc seed user trước khi chạy script này.'
      );
    }

    const now = new Date();
    const creator = users[0];
    const members = users.map((user, index) => ({
      user_id: user._id,
      role: index === 0 ? 'admin' : 'member',
      joined_at: now,
    }));

    // Idempotent: lọc theo name, chỉ ghi khi document chưa tồn tại.
    // name nằm ở filter nên không lặp lại trong $setOnInsert để tránh xung đột path.
    const result = await StudyGroup.bulkWrite(
      groups.map((group) => ({
        updateOne: {
          filter: { name: group.name },
          update: {
            $setOnInsert: {
              description: group.description,
              level: group.level,
              creator_id: creator._id,
              members,
              member_count: members.length,
              is_active: true,
              is_private: group.is_private,
              max_members: group.max_members,
            },
          },
          upsert: true,
        },
      }))
    );

    console.log(
      `✨ Đã tạo mới ${result.upsertedCount} nhóm, bỏ qua ${groups.length - result.upsertedCount} nhóm đã tồn tại`
    );
    console.log(`👥 Mỗi nhóm có ${members.length} thành viên, admin: ${creator.TenDangNhap}`);

    const summary = await StudyGroup.find({ name: { $in: groups.map((g) => g.name) } })
      .select('name level member_count is_active')
      .sort({ name: 1 });

    console.log('\n📊 Study group hiện có:');
    summary.forEach((group) => {
      console.log(
        `   ${group.name} | ${group.level} | ${group.member_count} thành viên | active: ${group.is_active}`
      );
    });

    await mongoose.connection.close();
    console.log('\n✅ Seeding completed successfully!');
  } catch (error) {
    console.error('❌ Error seeding study groups:', error);
    process.exit(1);
  }
}

seedStudyGroups();

import mongoose from 'mongoose';
import dotenv from 'dotenv';
import User from '../model/User.js';

dotenv.config();

// Nâng quyền admin cho một tài khoản đã đăng ký.
//   node scripts/make-admin.js <TenDangNhap>
//
// POST /api/users/register luôn gán VaiTro 'user', còn endpoint tạo user dành cho
// admin lại đòi sẵn một admin, nên admin đầu tiên phải được nâng quyền ở đây.

async function makeAdmin() {
  const username = process.argv[2];

  try {
    if (!username) {
      throw new Error('Thiếu tên đăng nhập. Dùng: node scripts/make-admin.js <TenDangNhap>');
    }

    const mongoURI = process.env.MONGODB_URI;
    if (!mongoURI) {
      throw new Error('MONGODB_URI không được định nghĩa trong file .env');
    }

    await mongoose.connect(mongoURI, {
      dbName: process.env.DB_NAME || 'AppHocTiengNhat',
    });

    console.log('✅ Connected to MongoDB');

    const existing = await User.findOne({ TenDangNhap: username }).select('TenDangNhap VaiTro');
    if (!existing) {
      const all = await User.find({}).select('TenDangNhap').limit(20);
      const names = all.map((u) => u.TenDangNhap).join(', ') || '(chưa có user nào)';
      throw new Error(
        `Không tìm thấy user '${username}'. Hãy đăng ký qua POST /api/users/register trước.\n` +
        `   User hiện có: ${names}`
      );
    }

    if (existing.VaiTro === 'admin') {
      console.log(`ℹ️  '${username}' đã là admin, không cần đổi gì.`);
    } else {
      await User.updateOne({ TenDangNhap: username }, { $set: { VaiTro: 'admin' } });
      console.log(`✨ Đã nâng '${username}' từ '${existing.VaiTro}' lên 'admin'`);
    }

    const user = await User.findOne({ TenDangNhap: username }).select(
      'TenDangNhap Email VaiTro TrangThai'
    );
    console.log(
      `👤 ${user.TenDangNhap} | ${user.Email} | VaiTro: ${user.VaiTro} | TrangThai: ${user.TrangThai}`
    );

    await mongoose.connection.close();
    console.log('\n✅ Hoàn tất!');
  } catch (error) {
    console.error('❌ Lỗi khi nâng quyền admin:', error.message);
    process.exit(1);
  }
}

makeAdmin();

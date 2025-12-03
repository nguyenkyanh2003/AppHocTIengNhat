import express from "express";
import dotenv from "dotenv";
import bcrypt from "bcrypt";
import nodemailer from "nodemailer";
import jwt from "jsonwebtoken";
import User from "../model/User.js";
import UserStreak from "../model/UserStreak.js";
import { authenticateUser, authenticateAdmin } from "./auth.js";
import { uploadUserAvatar } from "../middleware/upload.js";
import { getVietnamTime, convertUserDatesToVietnam } from "../utils/timezone.js";

const router = express.Router();
dotenv.config();

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD,
  },
});

const withoutPassword = (user) => {
  if (!user) return null;
  
  const userObject = user.toJSON ? user.toJSON() : user;
  
  const convertToVN = (date) => {
    if (!date) return null;
    const vnTime = new Date(date.getTime() + 7 * 60 * 60 * 1000);
    return vnTime.toISOString().replace('T', ' ').substring(0, 19);
  };

  const dateFields = ['NgayTao', 'LanDangNhapCuoi', 'createdAt', 'updatedAt', 'NgaySinh', 'NgayHocGanNhat'];

  dateFields.forEach(field => {
    if (userObject[field]) {
      userObject[field] = convertToVN(new Date(userObject[field]));
    }
  });
  
  delete userObject.MatKhau;
  delete userObject.__v;
  delete userObject.id; 
  
  return userObject;
};

// API Đăng nhập
router.post("/login", async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ message: "Vui lòng nhập đầy đủ thông tin." });
    }

    const user = await User.findOne({ TenDangNhap: username });
    if (!user) {
      return res.status(401).json({ message: "Tên đăng nhập không tồn tại." });
    }

    const match = await bcrypt.compare(password, user.MatKhau);
    if (!match) {
      return res.status(401).json({ message: "Mật khẩu không đúng." });
    }

    // Lưu thời gian đăng nhập theo giờ Việt Nam
    user.LanDangNhapCuoi = getVietnamTime();
    await user.save();

    // Cập nhật streak khi đăng nhập (Duolingo style)
    let streak = await UserStreak.findOne({ user: user._id });
    if (!streak) {
      // Tạo streak mới nếu chưa có
      streak = await UserStreak.create({ 
        user: user._id,
        current_streak: 0,
        longest_streak: 0,
        total_xp: 0,
        level: 1
      });
    }

    // Cập nhật streak và thêm 10 XP cho daily login
    const streakResult = streak.updateStreakOnActivity();
    if (streakResult.is_new_day) {
      streak.addXP(10, 'Daily login');
      await streak.save();
      console.log(`✅ Daily login streak updated for user ${user._id}: ${streak.current_streak} days (+10 XP)`);
    } else {
      console.log(`ℹ️ User ${user._id} already logged in today. Streak: ${streak.current_streak} days`);
    }

    const token = jwt.sign(
      { id: user._id, username: user.TenDangNhap, role: user.VaiTro },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      message: "Đăng nhập thành công",
      user: convertUserDatesToVietnam(withoutPassword(user)),
      token: token,
      streak: {
        current: streak.current_streak,
        longest: streak.longest_streak,
        total_xp: streak.total_xp,
        is_new_day: streakResult.is_new_day,
        streak_broken: streakResult.streak_broken || false
      }
    });
  } catch (error) {
    console.error("Lỗi đăng nhập:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// API Đăng xuất
router.post("/logout", authenticateUser, (req, res) => {
  res.json({ message: "Đăng xuất thành công" });
});

// API Đăng ký
router.post("/register", async (req, res) => {
  try {
    const { username, hoTen, password, email, trinhDo } = req.body;
    if (!username || !hoTen || !password || !email) {
      return res.status(400).json({ message: "Vui lòng nhập đầy đủ thông tin bắt buộc." });
    }

    const existingUser = await User.findOne({ TenDangNhap: username });
    if (existingUser) {
      return res.status(409).json({ message: "Tên đăng nhập đã tồn tại." });
    }

    const existingEmail = await User.findOne({ Email: email });
    if (existingEmail) {
      return res.status(409).json({ message: "Email đã được sử dụng." });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const vietnamTime = getVietnamTime();
    const newUser = await User.create({
      TenDangNhap: username,
      HoTen: hoTen,
      MatKhau: hashedPassword,
      Email: email,
      TrinhDo: trinhDo || 'N5',
      VaiTro: 'user',
      role: 'user',
      NgayTao: vietnamTime,
      LanDangNhapCuoi: vietnamTime
    });

    res.status(201).json({
      message: "Đăng ký thành công",
      user: convertUserDatesToVietnam(withoutPassword(newUser)),
    });
  } catch (error) {
    console.error("Lỗi đăng ký:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// API Quên mật khẩu
router.post("/forgot-password", async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: "Vui lòng nhập email." });

    const user = await User.findOne({ Email: email });
    if (!user)
      return res.status(404).json({ message: "Email không tồn tại trong hệ thống." });

    const token = jwt.sign(
      { id: user._id },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );

    const resetLink = `${process.env.FRONTEND_URL}/reset-password?token=${token}`;

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: "Yêu cầu đặt lại mật khẩu",
      html: `
        <h2>Yêu cầu khôi phục mật khẩu</h2>
        <p>Xin chào ${user.HoTen},</p>
        <p>Để đặt lại mật khẩu, vui lòng click vào link bên dưới:</p>
        <a href="${resetLink}" style="padding: 10px 15px; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px;">Đặt lại mật khẩu</a>
        <p>Link này sẽ hết hạn sau 1 giờ.</p>
        <p>Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.</p>
      `,
    };

    await transporter.sendMail(mailOptions);
    res.json({ message: "Đã gửi email đặt lại mật khẩu thành công." });
  } catch (error) {
    console.error("Lỗi quên mật khẩu:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// API Đặt lại mật khẩu
router.post("/reset-password", async (req, res) => {
  try {
    const { token, newPassword } = req.body;
    if (!token || !newPassword || newPassword.length < 6)
      return res.status(400).json({ message: "Vui lòng cung cấp token và mật khẩu mới (ít nhất 6 ký tự)." });

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      return res.status(401).json({ message: "Token không hợp lệ hoặc đã hết hạn." });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    const user = await User.findByIdAndUpdate(
      decoded.id,
      { MatKhau: hashedPassword },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ message: "Người dùng không tồn tại." });
    }

    res.json({ message: "Đặt lại mật khẩu thành công." });
  } catch (error) {
    console.error("Lỗi đặt lại mật khẩu:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// xem profile
router.get("/profile/:id", authenticateUser, async (req, res) => {
  try {
    const requestUserId = req.user._id.toString();
    const targetUserId = req.params.id;
    const userRole = req.user?.role || req.user?.VaiTro;

    console.log(`📋 Profile request - Requester: ${requestUserId} (${req.user.TenDangNhap}), Target: ${targetUserId}, Role: ${userRole}`);

    if (userRole !== 'admin' && requestUserId !== targetUserId) {
      console.log(`⛔ Access denied: User ${requestUserId} trying to access ${targetUserId}'s profile`);
      return res.status(403).json({ message: "Bạn không có quyền xem profile này." });
    }

    const user = await User.findById(targetUserId).select('-MatKhau');

    if (!user) {
      console.log(`❌ User not found: ${targetUserId}`);
      return res.status(404).json({ message: "Người dùng không tồn tại." });
    }
    
    console.log(`✅ Profile loaded: ${user.TenDangNhap} (${user._id})`);
    res.json({ 
      message: "Lấy thông tin người dùng thành công", 
      profile: convertUserDatesToVietnam(withoutPassword(user)) 
    });
  } catch (error) {
    console.error("Lỗi lấy thông tin người dùng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// xem profile hiện tại
router.get("/me", authenticateUser, async (req, res) => {
  try {
    console.log("1. Req.user từ middleware:", req.user);
    
    const userId = req.user._id;
    console.log("2. ID lấy được để tìm kiếm:", userId);
    if (!userId) {
       return res.status(400).json({ message: "Lỗi: Không tìm thấy ID trong Token" });
    }

    const user = await User.findById(userId).select('-MatKhau');
    console.log("3. Kết quả tìm trong DB:", user);

    if (!user) {
      return res.status(404).json({ message: "Người dùng không tồn tại." });
    }

    res.json({ 
      message: "Lấy thông tin thành công", 
      user: withoutPassword(user)
    });
  } catch (error) {
    console.error("Lỗi lấy thông tin người dùng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// sửa profile
router.put("/profile/:id", authenticateUser, async (req, res) => {
  try {
    const requestUserId = req.user._id.toString();
    const targetUserId = req.params.id;

    if (req.user.role !== 'admin' && requestUserId !== targetUserId) {
      return res.status(403).json({ message: "Bạn không có quyền sửa profile này." });
    }

    const { hoTen, email, trinhDo, anhDaiDien, soDienThoai, diaChi, gioiTinh, ngaySinh } = req.body;

    if (email) {
      const existingEmail = await User.findOne({ 
        Email: email, 
        _id: { $ne: targetUserId } 
      });
      if (existingEmail) {
        return res.status(409).json({ message: "Email đã được sử dụng." });
      }
    }

    const updateData = {};
    if (hoTen) updateData.HoTen = hoTen;
    if (email) updateData.Email = email;
    if (trinhDo) updateData.TrinhDo = trinhDo;
    if (anhDaiDien !== undefined) updateData.AnhDaiDien = anhDaiDien;
    if (soDienThoai !== undefined) updateData.SoDienThoai = soDienThoai;
    if (diaChi !== undefined) updateData.DiaChi = diaChi;
    if (gioiTinh !== undefined) updateData.GioiTinh = gioiTinh;
    if (ngaySinh !== undefined) updateData.NgaySinh = ngaySinh;

    const updatedUser = await User.findByIdAndUpdate(
      targetUserId,
      updateData,
      { new: true, runValidators: true }
    ).select('-MatKhau');

    if (!updatedUser) {
      return res.status(404).json({ message: "Người dùng không tồn tại." });
    }

    res.json({
      message: "Cập nhật thông tin thành công",
      profile: withoutPassword(updatedUser),
    });
  } catch (error) {
    console.error("Lỗi cập nhật thông tin:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// API đổi mật khẩu
router.put("/change-password/:id", authenticateUser, async (req, res) => {
  try {
    const requestUserId = req.user._id.toString();
    const targetUserId = req.params.id;

    if (req.user.role !== 'admin' && requestUserId !== targetUserId) {
      return res.status(403).json({ message: "Bạn không có quyền đổi mật khẩu." });
    }

    const { oldPassword, newPassword } = req.body;

    const user = await User.findById(targetUserId);
    if (!user) {
      return res.status(404).json({ message: "Người dùng không tồn tại." });
    }

    if (req.user.role !== 'admin') {
      if (!oldPassword || !newPassword || newPassword.length < 6) {
        return res.status(400).json({ 
          message: "Vui lòng cung cấp mật khẩu cũ và mật khẩu mới (mật khẩu tối thiểu 6 ký tự.)" 
        });
      }
      const isValidPassword = await bcrypt.compare(oldPassword, user.MatKhau);
      if (!isValidPassword) {
        return res.status(401).json({ message: "Mật khẩu cũ không chính xác." });
      }
    } else {
      if (!newPassword || newPassword.length < 6) {
        return res.status(400).json({ 
          message: "Vui lòng cung cấp mật khẩu mới (mật khẩu tối thiểu 6 ký tự)." 
        });
      }
    }

    user.MatKhau = await bcrypt.hash(newPassword, 10);
    await user.save();

    res.json({ message: "Đổi mật khẩu thành công." });
  } catch (error) {
    console.error("Lỗi đổi mật khẩu:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// Lấy danh sách tất cả người dùng 
router.get("/admin/users", authenticateAdmin, async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const { search, role, trinhDo } = req.query;

    const query = {};
    
    if (search) {
      query.$or = [
        { HoTen: { $regex: search, $options: 'i' } },
        { Email: { $regex: search, $options: 'i' } },
        { TenDangNhap: { $regex: search, $options: 'i' } }
      ];
    }
    
    if (role) {
      query.VaiTro = role;
    }
    
    if (trinhDo) {
      query.TrinhDo = trinhDo;
    }

    const skip = (page - 1) * limit;

    const [users, total] = await Promise.all([
      User.find(query)
        .select('-MatKhau')
        .sort({ NgayTao: -1 })
        .skip(skip)
        .limit(limit),
      User.countDocuments(query)
    ]);

    res.json({
      totalItems: total,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      data: users.map(user => withoutPassword(user))
    });
  } catch (error) {
    console.error("Lỗi lấy danh sách người dùng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// Lấy thông tin chi tiết người dùng 
router.get("/admin/users/:id", authenticateAdmin, async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-MatKhau');
    
    if (!user) {
      return res.status(404).json({ message: "Người dùng không tồn tại." });
    }

    res.json({ data: withoutPassword(user) });
  } catch (error) {
    console.error("Lỗi lấy thông tin người dùng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// Tạo người dùng mới 
router.post("/admin/users", authenticateAdmin, async (req, res) => {
  try {
    const { username, hoTen, password, email, trinhDo, vaiTro } = req.body;
    
    if (!username || !hoTen || !password || !email) {
      return res.status(400).json({ message: "Vui lòng nhập đầy đủ thông tin bắt buộc." });
    }

    const existingUser = await User.findOne({ TenDangNhap: username });
    if (existingUser) {
      return res.status(409).json({ message: "Tên đăng nhập đã tồn tại." });
    }

    const existingEmail = await User.findOne({ Email: email });
    if (existingEmail) {
      return res.status(409).json({ message: "Email đã được sử dụng." });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = await User.create({
      TenDangNhap: username,
      HoTen: hoTen,
      MatKhau: hashedPassword,
      Email: email,
      TrinhDo: trinhDo || 'N5',
      VaiTro: vaiTro || 'user',
      role: vaiTro || 'user',
      NgayTao: new Date()
    });

    res.status(201).json({
      message: "Tạo người dùng thành công",
      user: withoutPassword(newUser)
    });
  } catch (error) {
    console.error("Lỗi tạo người dùng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// Cập nhật thông tin người dùng 
router.put("/admin/users/:id", authenticateAdmin, async (req, res) => {
  try {
    const { hoTen, email, trinhDo, vaiTro, anhDaiDien, soDienThoai, diaChi } = req.body;

    if (email) {
      const existingEmail = await User.findOne({ 
        Email: email, 
        _id: { $ne: req.params.id } 
      });
      if (existingEmail) {
        return res.status(409).json({ message: "Email đã được sử dụng." });
      }
    }

    const updateData = {};
    if (hoTen) updateData.HoTen = hoTen;
    if (email) updateData.Email = email;
    if (trinhDo) updateData.TrinhDo = trinhDo;
    if (vaiTro) {
      updateData.VaiTro = vaiTro;
      updateData.role = vaiTro;
    }
    if (anhDaiDien !== undefined) updateData.AnhDaiDien = anhDaiDien;
    if (soDienThoai !== undefined) updateData.SoDienThoai = soDienThoai;
    if (diaChi !== undefined) updateData.DiaChi = diaChi;

    const updatedUser = await User.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    ).select('-MatKhau');

    if (!updatedUser) {
      return res.status(404).json({ message: "Người dùng không tồn tại." });
    }

    res.json({
      message: "Cập nhật người dùng thành công",
      user: withoutPassword(updatedUser)
    });
  } catch (error) {
    console.error("Lỗi cập nhật người dùng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// Xóa người dùng
router.delete("/admin/users/:id", authenticateAdmin, async (req, res) => {
  try {
    const deletedUser = await User.findByIdAndDelete(req.params.id);

    if (!deletedUser) {
      return res.status(404).json({ message: "Người dùng không tồn tại." });
    }

    res.json({ 
      message: "Xóa người dùng thành công",
      user: withoutPassword(deletedUser)
    });
  } catch (error) {
    console.error("Lỗi xóa người dùng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// Xóa nhiều người dùng 
router.delete("/admin/users", authenticateAdmin, async (req, res) => {
  try {
    const { ids } = req.body;
    
    if (!Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({ message: "Danh sách ID không hợp lệ." });
    }

    const result = await User.deleteMany({ _id: { $in: ids } });

    res.json({ 
      message: `Đã xóa ${result.deletedCount} người dùng.`,
      deletedCount: result.deletedCount
    });
  } catch (error) {
    console.error("Lỗi xóa nhiều người dùng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// Thống kê người dùng 
router.get("/admin/stats", authenticateAdmin, async (req, res) => {
  try {
    const [
      totalUsers,
      byRole,
      byLevel,
      recentUsers,
      activeUsers
    ] = await Promise.all([
      User.countDocuments(),
      User.aggregate([
        { $group: { _id: "$VaiTro", count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]),
      User.aggregate([
        { $group: { _id: "$TrinhDo", count: { $sum: 1 } } },
        { $sort: { _id: 1 } }
      ]),
      User.find()
        .select('-MatKhau')
        .sort({ NgayTao: -1 })
        .limit(10),
      User.find()
        .select('-MatKhau')
        .sort({ LanDangNhapCuoi: -1 })
        .limit(10)
    ]);

    res.json({
      totalUsers,
      byRole,
      byLevel,
      recentUsers: recentUsers.map(user => withoutPassword(user)),
      activeUsers: activeUsers.map(user => withoutPassword(user))
    });
  } catch (error) {
    console.error("Lỗi lấy thống kê người dùng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// Khóa/Mở khóa tài khoản 
router.put("/admin/users/:id/toggle-status", authenticateAdmin, async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    
    if (!user) {
      return res.status(404).json({ message: "Người dùng không tồn tại." });
    }

    user.TrangThai = user.TrangThai === 'active' ? 'locked' : 'active';
    await user.save();

    res.json({ 
      message: `Đã ${user.TrangThai === 'locked' ? 'khóa' : 'mở khóa'} tài khoản thành công`,
      user: withoutPassword(user)
    });
  } catch (error) {
    console.error("Lỗi thay đổi trạng thái tài khoản:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// API Upload avatar
router.put("/profile/:userID/avatar", authenticateUser, uploadUserAvatar, async (req, res) => {
  try {
    const { userID } = req.params;

    // Kiểm tra quyền: chỉ được upload avatar của chính mình
    if (req.user._id.toString() !== userID) {
      return res.status(403).json({ message: "Không có quyền cập nhật avatar của người dùng khác" });
    }

    if (!req.file) {
      return res.status(400).json({ message: "Vui lòng chọn file ảnh" });
    }

    // Lấy URL của avatar (sử dụng relative path)
    const avatarUrl = `/uploads/avatars/${req.file.filename}`;

    // Cập nhật avatar trong database
    const user = await User.findByIdAndUpdate(
      userID,
      { AnhDaiDien: avatarUrl },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ message: "Không tìm thấy người dùng" });
    }

    res.json({
      message: "Cập nhật avatar thành công",
      profile: withoutPassword(user)
    });
  } catch (error) {
    console.error("Lỗi upload avatar:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

export default router;

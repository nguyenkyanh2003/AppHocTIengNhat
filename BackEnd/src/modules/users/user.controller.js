import bcrypt from "bcrypt";
import nodemailer from "nodemailer";
import jwt from "jsonwebtoken";
import User from "../../../model/User.js";
import UserStreak from "../../../model/UserStreak.js";
import { getVietnamTime, convertUserDatesToVietnam } from "../../shared/utils/timezone.js";
import env from '../../config/env.js';

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: env.emailUser,
    pass: env.emailPassword,
  },
});

const withoutPassword = (user) => {
  if (!user) return null;
  const userObject = user.toJSON ? user.toJSON() : { ...user };
  
  delete userObject.MatKhau;
  delete userObject.__v;
  delete userObject.id; 
  
  return userObject;
};

// API Đăng nhập
export const postLogin = async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ message: "Vui lòng nhập đầy đủ thông tin." });
    }

    const user = await User.findOne({ TenDangNhap: username });
    if (!user) {
      return res.status(401).json({ message: "Tên đăng nhập không tồn tại." });
    }

    if (user.TrangThai !== 'active') {
      return res.status(403).json({ message: 'Tài khoản hiện không hoạt động.' });
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
    }

    const token = jwt.sign(
      { id: user._id, username: user.TenDangNhap, role: user.VaiTro, type: 'access' },
      env.jwtSecret,
      { expiresIn: '24h', subject: user._id.toString() }
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
};

// API Đăng xuất
export const postLogout = (req, res) => {
  res.json({ message: "Đăng xuất thành công" });
};

// API Đăng ký
export const postRegister = async (req, res) => {
  try {
    const { username, hoTen, password, email, trinhDo } = req.body;
    if (!username || !hoTen || !password || !email) {
      return res.status(400).json({ message: "Vui lòng nhập đầy đủ thông tin bắt buộc." });
    }
    if (password.length < 8) {
      return res.status(400).json({ message: 'Mật khẩu phải có ít nhất 8 ký tự.' });
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
};

// API Quên mật khẩu
export const postForgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: "Vui lòng nhập email." });

    const user = await User.findOne({ Email: email }).select('+tokenVersion');
    const acceptedMessage = 'Nếu email tồn tại, hướng dẫn đặt lại mật khẩu sẽ được gửi.';
    if (!user) return res.json({ message: acceptedMessage });

    if (!env.emailUser || !env.emailPassword) {
      return res.status(503).json({ message: 'Dịch vụ email chưa được cấu hình.' });
    }

    const token = jwt.sign(
      { id: user._id, type: 'password-reset', tokenVersion: user.tokenVersion || 0 },
      env.jwtSecret,
      { expiresIn: "1h" }
    );

    const resetLink = `${env.frontendUrl}/reset-password?token=${encodeURIComponent(token)}`;

    const mailOptions = {
      from: env.emailUser,
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
    res.json({ message: acceptedMessage });
  } catch (error) {
    console.error("Lỗi quên mật khẩu:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// API Đặt lại mật khẩu
export const postResetPassword = async (req, res) => {
  try {
    const { token, newPassword } = req.body;
    if (!token || !newPassword || newPassword.length < 8)
      return res.status(400).json({ message: "Vui lòng cung cấp token và mật khẩu mới (ít nhất 8 ký tự)." });

    let decoded;
    try {
      decoded = jwt.verify(token, env.jwtSecret);
      if (decoded.type !== 'password-reset') throw new Error('Sai loại token');
    } catch (err) {
      return res.status(401).json({ message: "Token không hợp lệ hoặc đã hết hạn." });
    }

    const user = await User.findById(decoded.id).select('+tokenVersion');

    if (!user) {
      return res.status(404).json({ message: "Người dùng không tồn tại." });
    }

    if ((user.tokenVersion || 0) !== decoded.tokenVersion) {
      return res.status(401).json({ message: 'Token đã được sử dụng hoặc không còn hợp lệ.' });
    }

    user.MatKhau = await bcrypt.hash(newPassword, 10);
    user.tokenVersion = (user.tokenVersion || 0) + 1;
    await user.save();

    res.json({ message: "Đặt lại mật khẩu thành công." });
  } catch (error) {
    console.error("Lỗi đặt lại mật khẩu:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// xem profile
export const getProfileById = async (req, res) => {
  try {
    const requestUserId = req.user._id.toString();
    const targetUserId = req.params.id;
    const userRole = req.user?.VaiTro || req.user?.role;

    if (userRole !== 'admin' && requestUserId !== targetUserId) {
      return res.status(403).json({ message: "Bạn không có quyền xem profile này." });
    }

    const user = await User.findById(targetUserId).select('-MatKhau');

    if (!user) {
      return res.status(404).json({ message: "Người dùng không tồn tại." });
    }

    res.json({ 
      message: "Lấy thông tin người dùng thành công", 
      profile: convertUserDatesToVietnam(withoutPassword(user)) 
    });
  } catch (error) {
    console.error("Lỗi lấy thông tin người dùng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// xem profile hiện tại
export const getMe = async (req, res) => {
  try {
    const userId = req.user._id;
    if (!userId) {
       return res.status(400).json({ message: "Lỗi: Không tìm thấy ID trong Token" });
    }

    const user = await User.findById(userId).select('-MatKhau');

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
};

// sửa profile
export const putProfileById = async (req, res) => {
  try {
    const requestUserId = req.user._id.toString();
    const targetUserId = req.params.id;

    if (req.user.VaiTro !== 'admin' && requestUserId !== targetUserId) {
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
};

// API đổi mật khẩu
export const putChangePasswordById = async (req, res) => {
  try {
    const requestUserId = req.user._id.toString();
    const targetUserId = req.params.id;

    if (req.user.VaiTro !== 'admin' && requestUserId !== targetUserId) {
      return res.status(403).json({ message: "Bạn không có quyền đổi mật khẩu." });
    }

    const { oldPassword, newPassword } = req.body;

    const user = await User.findById(targetUserId).select('+tokenVersion');
    if (!user) {
      return res.status(404).json({ message: "Người dùng không tồn tại." });
    }

    if (req.user.VaiTro !== 'admin') {
      if (!oldPassword || !newPassword || newPassword.length < 8) {
        return res.status(400).json({ 
          message: "Vui lòng cung cấp mật khẩu cũ và mật khẩu mới (mật khẩu tối thiểu 8 ký tự.)" 
        });
      }
      const isValidPassword = await bcrypt.compare(oldPassword, user.MatKhau);
      if (!isValidPassword) {
        return res.status(401).json({ message: "Mật khẩu cũ không chính xác." });
      }
    } else {
      if (!newPassword || newPassword.length < 8) {
        return res.status(400).json({ 
          message: "Vui lòng cung cấp mật khẩu mới (mật khẩu tối thiểu 8 ký tự)." 
        });
      }
    }

    user.MatKhau = await bcrypt.hash(newPassword, 10);
    user.tokenVersion = (user.tokenVersion || 0) + 1;
    await user.save();

    res.json({ message: "Đổi mật khẩu thành công." });
  } catch (error) {
    console.error("Lỗi đổi mật khẩu:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// Lấy danh sách tất cả người dùng 
export const getAdminUsers = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const { search, role, status, trinhDo } = req.query;

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

    if (status) {
      query.TrangThai = status;
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
};

// Lấy thông tin chi tiết người dùng 
export const getAdminUsersById = async (req, res) => {
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
};

// Tạo người dùng mới 
export const postAdminUsers = async (req, res) => {
  try {
    const { username, hoTen, password, email, trinhDo, vaiTro } = req.body;
    
    if (!username || !hoTen || !password || !email) {
      return res.status(400).json({ message: "Vui lòng nhập đầy đủ thông tin bắt buộc." });
    }
    if (password.length < 8) {
      return res.status(400).json({ message: "Mật khẩu phải có ít nhất 8 ký tự." });
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
};

// Cập nhật thông tin người dùng 
export const putAdminUsersById = async (req, res) => {
  try {
    const {
      hoTen,
      email,
      trinhDo,
      vaiTro,
      trangThai,
      anhDaiDien,
      soDienThoai,
      diaChi,
    } = req.body;

    if (vaiTro && !['user', 'admin'].includes(vaiTro)) {
      return res.status(400).json({ message: "Vai trò không hợp lệ." });
    }
    if (trangThai && !['active', 'inactive', 'locked', 'banned'].includes(trangThai)) {
      return res.status(400).json({ message: "Trạng thái không hợp lệ." });
    }

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
    }
    if (trangThai) updateData.TrangThai = trangThai;
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
};

// Xóa người dùng
export const deleteAdminUsersById = async (req, res) => {
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
};

// Xóa nhiều người dùng 
export const deleteAdminUsers = async (req, res) => {
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
};

// Thống kê người dùng 
export const getAdminStats = async (req, res) => {
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
};

// Khóa/Mở khóa tài khoản 
export const putAdminUsersByIdToggleStatus = async (req, res) => {
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
};

// API Upload avatar
export const putProfileByUserIDAvatar = async (req, res) => {
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
};


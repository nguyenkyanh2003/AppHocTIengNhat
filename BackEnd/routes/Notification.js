import express from 'express';
import Notification from '../model/Notification.js';
import { authenticateUser, authenticateAdmin } from './auth.js';

const router = express.Router();

// Lấy danh sách thông báo của người dùng
router.get('/', authenticateUser, async (req, res) => {
  try {
    const userID = req.user?.NguoiHocID || req.user?.id || req.user?._id;
    if (!userID) {
        return res.status(401).json({ message: "Không tìm thấy ID người dùng." });
    }

    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const { status } = req.query;

    const query = { NguoiHocID: userID };

    if (status === 'read') {
        query.TrangThai = 'DaDoc';
    } else if (status === 'unread') {
        query.TrangThai = 'ChuaDoc';
    }

    const skip = (page - 1) * limit;

    const [notifications, total] = await Promise.all([
        Notification.find(query)
            .sort({ NgayTao: -1 })
            .skip(skip)
            .limit(limit)
            .lean(),
        Notification.countDocuments(query)
    ]);
    
    res.json({
      totalItems: total,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      data: notifications,
    });
  } catch (error) {
    console.error("Lỗi khi lấy thông báo:", error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
});

// Lấy chi tiết một thông báo
router.get('/:id', authenticateUser, async (req, res) => {
  try {
    const { id } = req.params;
    const userID = req.user?.NguoiHocID || req.user?.id || req.user?._id;

    const notification = await Notification.findOne({
      _id: id,
      NguoiHocID: userID
    }).lean();

    if (!notification) {
      return res.status(404).json({ message: 'Không tìm thấy thông báo.' });
    }

    res.json({ data: notification });
  } catch (error) {
    console.error("Lỗi khi lấy chi tiết thông báo:", error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
});

// Lấy số lượng thông báo chưa đọc
router.get('/count/unread', authenticateUser, async (req, res) => {
  try {
    const userID = req.user?.NguoiHocID || req.user?.id || req.user?._id;

    const unreadCount = await Notification.countDocuments({
      NguoiHocID: userID,
      TrangThai: 'ChuaDoc'
    });

    res.json({ unreadCount });
  } catch (error) {
    console.error("Lỗi khi đếm thông báo chưa đọc:", error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
});

// Đánh dấu một thông báo là đã đọc
router.put('/read/:id', authenticateUser, async (req, res) => {
  try {
    const { id } = req.params;
    const userID = req.user?.NguoiHocID || req.user?.id || req.user?._id;

    const updatedNotification = await Notification.findOneAndUpdate(
        { _id: id, NguoiHocID: userID },
        { TrangThai: 'DaDoc' },
        { new: true }
    );

    if (!updatedNotification) {
      return res.status(404).json({ message: 'Không tìm thấy thông báo.' });
    }

    res.json({ 
      message: 'Cập nhật thành công', 
      data: updatedNotification 
    });
  } catch (error) {
    console.error("Lỗi khi cập nhật thông báo:", error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
});

// Đánh dấu tất cả thông báo là đã đọc
router.put('/read-all', authenticateUser, async (req, res) => {
    try {
      const userID = req.user?.NguoiHocID || req.user?.id || req.user?._id;
      
      const result = await Notification.updateMany(
        { NguoiHocID: userID, TrangThai: 'ChuaDoc' },
        { TrangThai: 'DaDoc' }
      );

      if (result.modifiedCount === 0) {
        return res.status(404).json({ message: 'Không có thông báo chưa đọc.' });
      }

      res.json({ 
        message: `Đã đánh dấu ${result.modifiedCount} thông báo là đã đọc.`,
        modifiedCount: result.modifiedCount
      });
    } catch (error) {
      console.error("Lỗi khi đánh dấu tất cả đã đọc:", error);
      res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
});

// Xóa một thông báo
router.delete('/:id', authenticateUser, async (req, res) => {
    try {
      const { id } = req.params;
      const userID = req.user?.NguoiHocID || req.user?.id || req.user?._id;

      const deletedNotification = await Notification.findOneAndDelete({
        _id: id,
        NguoiHocID: userID
      });

      if (!deletedNotification) {
        return res.status(404).json({ message: 'Không tìm thấy thông báo.' });
      }

      res.json({ 
        message: 'Xóa thành công.',
        data: deletedNotification
      });
    } catch (error) {
      console.error("Lỗi khi xóa thông báo:", error);
      res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
});

// Xóa tất cả thông báo đã đọc
router.delete('/clear/read', authenticateUser, async (req, res) => {
    try {
      const userID = req.user?.NguoiHocID || req.user?.id || req.user?._id;

      const result = await Notification.deleteMany({
        NguoiHocID: userID,
        TrangThai: 'DaDoc'
      });

      res.json({ 
        message: `Đã xóa ${result.deletedCount} thông báo đã đọc.`,
        deletedCount: result.deletedCount
      });
    } catch (error) {
      console.error("Lỗi khi xóa thông báo đã đọc:", error);
      res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
});

// Gửi thông báo cho một người dùng
router.post('/', authenticateUser, authenticateAdmin, async (req, res) => {
  try {
    const { TieuDe, NoiDung, NguoiHocID, Link } = req.body;

    if (!TieuDe || !NoiDung || !NguoiHocID) {
      return res.status(400).json({ message: "Thiếu thông tin bắt buộc." });
    }

    const newNotification = await Notification.create({
      NguoiHocID,
      TieuDe,
      NoiDung,
      Link: Link || null,
      TrangThai: 'ChuaDoc',
      NgayTao: new Date()
    });

    res.status(201).json({ 
      message: "Gửi thông báo thành công", 
      data: newNotification 
    });
  } catch (error) {
    console.error("Lỗi khi tạo thông báo:", error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
});

// Gửi thông báo cho nhiều người dùng
router.post('/broadcast', authenticateUser, authenticateAdmin, async (req, res) => {
  try {
    const { TieuDe, NoiDung, NguoiHocIDs, Link } = req.body;

    if (!TieuDe || !NoiDung || !Array.isArray(NguoiHocIDs) || NguoiHocIDs.length === 0) {
      return res.status(400).json({ message: "Thiếu thông tin bắt buộc." });
    }

    const notifications = NguoiHocIDs.map(userId => ({
      NguoiHocID: userId,
      TieuDe,
      NoiDung,
      Link: Link || null,
      TrangThai: 'ChuaDoc',
      NgayTao: new Date()
    }));

    const createdNotifications = await Notification.insertMany(notifications);

    res.status(201).json({ 
      message: `Gửi thông báo thành công cho ${createdNotifications.length} người dùng`, 
      count: createdNotifications.length,
      data: createdNotifications 
    });
  } catch (error) {
    console.error("Lỗi khi gửi thông báo hàng loạt:", error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
});

// Gửi thông báo cho tất cả người dùng
router.post('/broadcast/all', authenticateUser, authenticateAdmin, async (req, res) => {
  try {
    const { TieuDe, NoiDung, Link } = req.body;

    if (!TieuDe || !NoiDung) {
      return res.status(400).json({ message: "Thiếu thông tin bắt buộc." });
    }

    const User = (await import('../model/User.js')).default;
    const users = await User.find({}, { _id: 1 }).lean();

    if (users.length === 0) {
      return res.status(404).json({ message: "Không tìm thấy người dùng nào." });
    }

    const notifications = users.map(user => ({
      NguoiHocID: user._id,
      TieuDe,
      NoiDung,
      Link: Link || null,
      TrangThai: 'ChuaDoc',
      NgayTao: new Date()
    }));

    const createdNotifications = await Notification.insertMany(notifications);

    res.status(201).json({ 
      message: `Gửi thông báo thành công cho tất cả ${createdNotifications.length} người dùng`, 
      count: createdNotifications.length
    });
  } catch (error) {
    console.error("Lỗi khi gửi thông báo cho tất cả:", error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
});

// Lấy tất cả thông báo
router.get('/admin/all', authenticateUser, authenticateAdmin, async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const { status, userId } = req.query;

    const query = {};

    if (status) {
      query.TrangThai = status === 'read' ? 'DaDoc' : 'ChuaDoc';
    }
    if (userId) {
      query.NguoiHocID = userId;
    }

    const skip = (page - 1) * limit;

    const [notifications, total] = await Promise.all([
        Notification.find(query)
            .sort({ NgayTao: -1 })
            .skip(skip)
            .limit(limit)
            .populate('NguoiHocID', 'HoTen Email')
            .lean(),
        Notification.countDocuments(query)
    ]);
    
    res.json({
      totalItems: total,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      data: notifications,
    });
  } catch (error) {
    console.error("Lỗi khi lấy tất cả thông báo:", error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
});

// Thống kê thông báo
router.get('/admin/stats', authenticateUser, authenticateAdmin, async (req, res) => {
  try {
    const [total, unread, read, byUser] = await Promise.all([
      Notification.countDocuments(),
      Notification.countDocuments({ TrangThai: 'ChuaDoc' }),
      Notification.countDocuments({ TrangThai: 'DaDoc' }),
      Notification.aggregate([
        { $group: { _id: "$NguoiHocID", count: { $sum: 1 }, unread: { $sum: { $cond: [{ $eq: ["$TrangThai", "ChuaDoc"] }, 1, 0] } } } },
        { $sort: { count: -1 } },
        { $limit: 10 }
      ])
    ]);

    res.json({
      total,
      unread,
      read,
      readRate: total > 0 ? ((read / total) * 100).toFixed(2) : 0,
      topUsers: byUser
    });
  } catch (error) {
    console.error("Lỗi khi lấy thống kê thông báo:", error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
});

// Cập nhật thông báo 
router.put('/admin/:id', authenticateUser, authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const updatedNotification = await Notification.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!updatedNotification) {
      return res.status(404).json({ message: 'Không tìm thấy thông báo.' });
    }

    res.json({ 
      message: 'Cập nhật thành công', 
      data: updatedNotification 
    });
  } catch (error) {
    console.error("Lỗi khi cập nhật thông báo:", error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
});

// Xóa thông báo 
router.delete('/admin/:id', authenticateUser, authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    const deletedNotification = await Notification.findByIdAndDelete(id);

    if (!deletedNotification) {
      return res.status(404).json({ message: 'Không tìm thấy thông báo.' });
    }

    res.json({ 
      message: 'Xóa thành công.',
      data: deletedNotification
    });
  } catch (error) {
    console.error("Lỗi khi xóa thông báo:", error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
});

// Xóa nhiều thông báo 
router.delete('/admin/bulk/delete', authenticateUser, authenticateAdmin, async (req, res) => {
  try {
    const { ids } = req.body;

    if (!Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({ message: "Danh sách ID không hợp lệ." });
    }

    const result = await Notification.deleteMany({ _id: { $in: ids } });

    res.json({ 
      message: `Đã xóa ${result.deletedCount} thông báo.`,
      deletedCount: result.deletedCount
    });
  } catch (error) {
    console.error("Lỗi khi xóa nhiều thông báo:", error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
});

export default router;
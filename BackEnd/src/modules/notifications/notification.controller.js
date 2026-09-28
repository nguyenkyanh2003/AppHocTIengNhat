import Notification from '../../../model/Notification.js';


// Lấy danh sách thông báo của người dùng
export const getRoot = async (req, res) => {
  try {
    const userID = req.user._id;
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
};

// Lấy số lượng thông báo chưa đọc
export const getCountUnread = async (req, res) => {
  try {
    const userID = req.user._id;

    const unreadCount = await Notification.countDocuments({
      NguoiHocID: userID,
      TrangThai: 'ChuaDoc'
    });

    res.json({ unreadCount });
  } catch (error) {
    console.error("Lỗi khi đếm thông báo chưa đọc:", error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

// Đánh dấu một thông báo là đã đọc
export const putReadById = async (req, res) => {
  try {
    const { id } = req.params;
    const userID = req.user._id;

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
};

// Đánh dấu tất cả thông báo là đã đọc
export const putReadAll = async (req, res) => {
    try {
      const userID = req.user._id;
      
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
};

// Xóa một thông báo
export const deleteById = async (req, res) => {
    try {
      const { id } = req.params;
      const userID = req.user._id;

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
};

// Gửi thông báo cho một người dùng
export const postRoot = async (req, res) => {
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
};

// Gửi thông báo cho tất cả người dùng
export const postBroadcastAll = async (req, res) => {
  try {
    const { TieuDe, NoiDung, Link } = req.body;

    if (!TieuDe || !NoiDung) {
      return res.status(400).json({ message: "Thiếu thông tin bắt buộc." });
    }

    const User = (await import('../../../model/User.js')).default;
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
};

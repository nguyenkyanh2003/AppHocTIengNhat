import express from "express";
import Transaction from "../model/Transaction.js";
import User from "../model/User.js";
import { authenticateUser, authenticateAdmin } from "./auth.js";

const router = express.Router();

// USER ROUTES

// Lấy lịch sử giao dịch của người dùng hiện tại
router.get("/my-transactions", authenticateUser, async (req, res) => {
    try {
        const userId = req.user._id;
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 10;
        const { status, type } = req.query;

        const query = { NguoiDungID: userId };
        
        if (status) query.TrangThai = status;
        if (type) query.LoaiGiaoDich = type;

        const skip = (page - 1) * limit;

        const [transactions, total] = await Promise.all([
            Transaction.find(query)
                .sort({ NgayGiaoDich: -1 })
                .skip(skip)
                .limit(limit)
                .lean(),
            Transaction.countDocuments(query)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / limit),
            currentPage: page,
            data: transactions
        });
    } catch (error) {
        console.error("Lỗi lấy lịch sử giao dịch:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});
 
// Lấy chi tiết một giao dịch
router.get("/:id", authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;

        const transaction = await Transaction.findOne({
            _id: id,
            NguoiDungID: userId
        }).lean();

        if (!transaction) {
            return res.status(404).json({ message: "Không tìm thấy giao dịch." });
        }

        res.json({ data: transaction });
    } catch (error) {
        console.error("Lỗi lấy chi tiết giao dịch:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Tạo giao dịch mới (thanh toán)
router.post("/create", authenticateUser, async (req, res) => {
    try {
        const userId = req.user._id;
        const { 
            LoaiGiaoDich, 
            SoTien, 
            NoiDung, 
            PhuongThucThanhToan,
            ThongTinThanhToan 
        } = req.body;

        if (!LoaiGiaoDich || !SoTien || !PhuongThucThanhToan) {
            return res.status(400).json({ 
                message: "Vui lòng nhập đầy đủ thông tin (LoaiGiaoDich, SoTien, PhuongThucThanhToan)." 
            });
        }

        if (SoTien <= 0) {
            return res.status(400).json({ message: "Số tiền phải lớn hơn 0." });
        }

        const newTransaction = await Transaction.create({
            NguoiDungID: userId,
            LoaiGiaoDich,
            SoTien,
            NoiDung: NoiDung || null,
            PhuongThucThanhToan,
            ThongTinThanhToan: ThongTinThanhToan || null,
            TrangThai: 'pending',
            NgayGiaoDich: new Date()
        });

        res.status(201).json({
            message: "Tạo giao dịch thành công",
            data: newTransaction
        });
    } catch (error) {
        console.error("Lỗi tạo giao dịch:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Hủy giao dịch (chỉ với trạng thái pending)
router.put("/:id/cancel", authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;

        const transaction = await Transaction.findOne({
            _id: id,
            NguoiDungID: userId
        });

        if (!transaction) {
            return res.status(404).json({ message: "Không tìm thấy giao dịch." });
        }

        if (transaction.TrangThai !== 'pending') {
            return res.status(400).json({ 
                message: "Chỉ có thể hủy giao dịch đang chờ xử lý." 
            });
        }

        transaction.TrangThai = 'cancelled';
        await transaction.save();

        res.json({
            message: "Hủy giao dịch thành công",
            data: transaction
        });
    } catch (error) {
        console.error("Lỗi hủy giao dịch:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Thống kê giao dịch cá nhân
router.get("/stats/me", authenticateUser, async (req, res) => {
    try {
        const userId = req.user._id;

        const [totalTransactions, totalAmount, byStatus, byType, recentTransactions] = await Promise.all([
            Transaction.countDocuments({ NguoiDungID: userId }),
            Transaction.aggregate([
                { $match: { NguoiDungID: userId, TrangThai: 'completed' } },
                { $group: { _id: null, total: { $sum: "$SoTien" } } }
            ]),
            Transaction.aggregate([
                { $match: { NguoiDungID: userId } },
                { $group: { _id: "$TrangThai", count: { $sum: 1 }, total: { $sum: "$SoTien" } } }
            ]),
            Transaction.aggregate([
                { $match: { NguoiDungID: userId } },
                { $group: { _id: "$LoaiGiaoDich", count: { $sum: 1 }, total: { $sum: "$SoTien" } } }
            ]),
            Transaction.find({ NguoiDungID: userId })
                .sort({ NgayGiaoDich: -1 })
                .limit(5)
                .lean()
        ]);

        res.json({
            totalTransactions,
            totalAmount: totalAmount[0]?.total || 0,
            byStatus,
            byType,
            recentTransactions
        });
    } catch (error) {
        console.error("Lỗi thống kê giao dịch:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// ADMIN ROUTES

// Lấy tất cả giao dịch (admin)
router.get("/admin/all", authenticateAdmin, async (req, res) => {
    try {
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 10;
        const { status, type, userId, startDate, endDate } = req.query;

        const query = {};
        
        if (status) query.TrangThai = status;
        if (type) query.LoaiGiaoDich = type;
        if (userId) query.NguoiDungID = userId;
        
        if (startDate || endDate) {
            query.NgayGiaoDich = {};
            if (startDate) query.NgayGiaoDich.$gte = new Date(startDate);
            if (endDate) query.NgayGiaoDich.$lte = new Date(endDate);
        }

        const skip = (page - 1) * limit;

        const [transactions, total] = await Promise.all([
            Transaction.find(query)
                .populate('NguoiDungID', 'HoTen Email')
                .sort({ NgayGiaoDich: -1 })
                .skip(skip)
                .limit(limit)
                .lean(),
            Transaction.countDocuments(query)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / limit),
            currentPage: page,
            data: transactions
        });
    } catch (error) {
        console.error("Lỗi lấy danh sách giao dịch:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Lấy chi tiết giao dịch (admin)
router.get("/admin/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;

        const transaction = await Transaction.findById(id)
            .populate('NguoiDungID', 'HoTen Email SoDienThoai')
            .lean();

        if (!transaction) {
            return res.status(404).json({ message: "Không tìm thấy giao dịch." });
        }

        res.json({ data: transaction });
    } catch (error) {
        console.error("Lỗi lấy chi tiết giao dịch:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Cập nhật trạng thái giao dịch (admin)
router.put("/admin/:id/status", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const { TrangThai, GhiChu } = req.body;

        const validStatuses = ['pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded'];
        if (!validStatuses.includes(TrangThai)) {
            return res.status(400).json({ 
                message: `Trạng thái không hợp lệ. Chọn: ${validStatuses.join(', ')}` 
            });
        }

        const updateData = { TrangThai };
        if (GhiChu) updateData.GhiChu = GhiChu;

        const transaction = await Transaction.findByIdAndUpdate(
            id,
            updateData,
            { new: true }
        ).populate('NguoiDungID', 'HoTen Email');

        if (!transaction) {
            return res.status(404).json({ message: "Không tìm thấy giao dịch." });
        }

        res.json({
            message: "Cập nhật trạng thái thành công",
            data: transaction
        });
    } catch (error) {
        console.error("Lỗi cập nhật trạng thái:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Cập nhật thông tin giao dịch (admin)
router.put("/admin/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;

        const transaction = await Transaction.findByIdAndUpdate(
            id,
            updateData,
            { new: true, runValidators: true }
        ).populate('NguoiDungID', 'HoTen Email');

        if (!transaction) {
            return res.status(404).json({ message: "Không tìm thấy giao dịch." });
        }

        res.json({
            message: "Cập nhật giao dịch thành công",
            data: transaction
        });
    } catch (error) {
        console.error("Lỗi cập nhật giao dịch:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Xóa giao dịch (admin)
router.delete("/admin/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;

        const transaction = await Transaction.findByIdAndDelete(id);

        if (!transaction) {
            return res.status(404).json({ message: "Không tìm thấy giao dịch." });
        }

        res.json({
            message: "Xóa giao dịch thành công",
            data: transaction
        });
    } catch (error) {
        console.error("Lỗi xóa giao dịch:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Xóa nhiều giao dịch (admin)
router.delete("/admin/bulk/delete", authenticateAdmin, async (req, res) => {
    try {
        const { ids } = req.body;

        if (!Array.isArray(ids) || ids.length === 0) {
            return res.status(400).json({ message: "Danh sách ID không hợp lệ." });
        }

        const result = await Transaction.deleteMany({ _id: { $in: ids } });

        res.json({
            message: `Đã xóa ${result.deletedCount} giao dịch.`,
            deletedCount: result.deletedCount
        });
    } catch (error) {
        console.error("Lỗi xóa nhiều giao dịch:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Thống kê giao dịch tổng quan (admin)
router.get("/admin/stats/overview", authenticateAdmin, async (req, res) => {
    try {
        const { startDate, endDate } = req.query;
        const dateQuery = {};
        
        if (startDate || endDate) {
            dateQuery.NgayGiaoDich = {};
            if (startDate) dateQuery.NgayGiaoDich.$gte = new Date(startDate);
            if (endDate) dateQuery.NgayGiaoDich.$lte = new Date(endDate);
        }

        const [
            totalTransactions,
            totalRevenue,
            byStatus,
            byType,
            byPaymentMethod,
            dailyRevenue,
            topUsers
        ] = await Promise.all([
            Transaction.countDocuments(dateQuery),
            Transaction.aggregate([
                { $match: { ...dateQuery, TrangThai: 'completed' } },
                { $group: { _id: null, total: { $sum: "$SoTien" } } }
            ]),
            Transaction.aggregate([
                { $match: dateQuery },
                { $group: { _id: "$TrangThai", count: { $sum: 1 }, total: { $sum: "$SoTien" } } },
                { $sort: { count: -1 } }
            ]),
            Transaction.aggregate([
                { $match: dateQuery },
                { $group: { _id: "$LoaiGiaoDich", count: { $sum: 1 }, total: { $sum: "$SoTien" } } },
                { $sort: { count: -1 } }
            ]),
            Transaction.aggregate([
                { $match: dateQuery },
                { $group: { _id: "$PhuongThucThanhToan", count: { $sum: 1 }, total: { $sum: "$SoTien" } } },
                { $sort: { count: -1 } }
            ]),
            Transaction.aggregate([
                { $match: { ...dateQuery, TrangThai: 'completed' } },
                {
                    $group: {
                        _id: { 
                            $dateToString: { format: "%Y-%m-%d", date: "$NgayGiaoDich" }
                        },
                        revenue: { $sum: "$SoTien" },
                        count: { $sum: 1 }
                    }
                },
                { $sort: { _id: 1 } },
                { $limit: 30 }
            ]),
            Transaction.aggregate([
                { $match: { ...dateQuery, TrangThai: 'completed' } },
                { $group: { _id: "$NguoiDungID", total: { $sum: "$SoTien" }, count: { $sum: 1 } } },
                { $sort: { total: -1 } },
                { $limit: 10 },
                {
                    $lookup: {
                        from: 'users',
                        localField: '_id',
                        foreignField: '_id',
                        as: 'user'
                    }
                },
                { $unwind: '$user' }
            ])
        ]);

        res.json({
            overview: {
                totalTransactions,
                totalRevenue: totalRevenue[0]?.total || 0,
                averageTransactionValue: totalTransactions > 0 
                    ? ((totalRevenue[0]?.total || 0) / totalTransactions).toFixed(2) 
                    : 0
            },
            byStatus,
            byType,
            byPaymentMethod,
            dailyRevenue,
            topUsers
        });
    } catch (error) {
        console.error("Lỗi thống kê giao dịch:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Lấy giao dịch của một người dùng (admin)
router.get("/admin/user/:userId", authenticateAdmin, async (req, res) => {
    try {
        const { userId } = req.params;
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 10;

        const skip = (page - 1) * limit;

        const [transactions, total] = await Promise.all([
            Transaction.find({ NguoiDungID: userId })
                .sort({ NgayGiaoDich: -1 })
                .skip(skip)
                .limit(limit)
                .lean(),
            Transaction.countDocuments({ NguoiDungID: userId })
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / limit),
            currentPage: page,
            data: transactions
        });
    } catch (error) {
        console.error("Lỗi lấy giao dịch người dùng:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Hoàn tiền (admin)
router.post("/admin/:id/refund", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const { reason } = req.body;

        const transaction = await Transaction.findById(id);

        if (!transaction) {
            return res.status(404).json({ message: "Không tìm thấy giao dịch." });
        }

        if (transaction.TrangThai !== 'completed') {
            return res.status(400).json({ 
                message: "Chỉ có thể hoàn tiền cho giao dịch đã hoàn thành." 
            });
        }

        transaction.TrangThai = 'refunded';
        transaction.GhiChu = reason || 'Đã hoàn tiền';
        await transaction.save();

        res.json({
            message: "Hoàn tiền thành công",
            data: transaction
        });
    } catch (error) {
        console.error("Lỗi hoàn tiền:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

export default router;

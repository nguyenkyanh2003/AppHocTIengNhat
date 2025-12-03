import express from "express";
import NoteBook from "../model/NoteBook.js";
import { authenticateUser, authenticateAdmin } from "./auth.js";

const router = express.Router();

// USER ROUTES

// Lấy danh sách ghi chú của user
router.get("/", authenticateUser, async (req, res) => {
    try {
        const userId = req.user._id;
        const { type, page = 1, limit = 20, search } = req.query;

        const query = { user_id: userId };
        
        if (type) {
            query.type = type;
        }
        
        if (search) {
            query.$or = [
                { title: { $regex: search, $options: 'i' } },
                { content: { $regex: search, $options: 'i' } }
            ];
        }

        const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);

        const [notes, total] = await Promise.all([
            NoteBook.find(query)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit, 10))
                .lean(),
            NoteBook.countDocuments(query)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / parseInt(limit, 10)),
            currentPage: parseInt(page, 10),
            data: notes
        });
    } catch (error) {
        console.error("Lỗi lấy danh sách ghi chú:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Lấy chi tiết ghi chú
router.get("/:id", authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;

        const note = await NoteBook.findOne({
            _id: id,
            user_id: userId
        }).lean();

        if (!note) {
            return res.status(404).json({ message: "Không tìm thấy ghi chú." });
        }

        res.json({ data: note });
    } catch (error) {
        console.error("Lỗi lấy chi tiết ghi chú:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Tạo ghi chú mới
router.post("/", authenticateUser, async (req, res) => {
    try {
        const userId = req.user._id;
        const { title, content, type, related_item_id, related_item_type, tags } = req.body;
        
        if (!title || !content) {
            return res.status(400).json({ 
                message: "Vui lòng nhập tiêu đề và nội dung." 
            });
        }

        const newNote = await NoteBook.create({
            user_id: userId,
            title,
            content,
            type: type || 'general',
            related_item_id: related_item_id || null,
            related_item_type: related_item_type || null,
            tags: tags || []
        });

        res.status(201).json({
            message: "Tạo ghi chú thành công",
            data: newNote
        });
    } catch (error) {
        console.error("Lỗi tạo ghi chú:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Cập nhật ghi chú
router.put("/:id", authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;
        const updateData = req.body;

        const updatedNote = await NoteBook.findOneAndUpdate(
            { _id: id, user_id: userId },
            updateData,
            { new: true, runValidators: true }
        );

        if (!updatedNote) {
            return res.status(404).json({ message: "Không tìm thấy ghi chú." });
        }

        res.json({
            message: "Cập nhật ghi chú thành công",
            data: updatedNote
        });
    } catch (error) {
        console.error("Lỗi cập nhật ghi chú:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Xóa ghi chú
router.delete("/:id", authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;

        const deletedNote = await NoteBook.findOneAndDelete({
            _id: id,
            user_id: userId
        });

        if (!deletedNote) {
            return res.status(404).json({ message: "Không tìm thấy ghi chú." });
        }

        res.json({
            message: "Xóa ghi chú thành công",
            data: deletedNote
        });
    } catch (error) {
        console.error("Lỗi xóa ghi chú:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Xóa nhiều ghi chú
router.delete("/", authenticateUser, async (req, res) => {
    try {
        const { ids } = req.body;
        const userId = req.user._id;
        
        if (!Array.isArray(ids) || ids.length === 0) {
            return res.status(400).json({ message: "Danh sách ID không hợp lệ." });
        }

        const result = await NoteBook.deleteMany({
            _id: { $in: ids },
            user_id: userId
        });

        res.json({
            message: `Đã xóa ${result.deletedCount} ghi chú.`,
            deletedCount: result.deletedCount
        });
    } catch (error) {
        console.error("Lỗi xóa nhiều ghi chú:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Lấy ghi chú theo item liên quan
router.get("/related/:item_type/:item_id", authenticateUser, async (req, res) => {
    try {
        const { item_type, item_id } = req.params;
        const userId = req.user._id;

        const notes = await NoteBook.find({
            user_id: userId,
            related_item_type: item_type,
            related_item_id: item_id
        })
            .sort({ createdAt: -1 })
            .lean();

        res.json({
            total: notes.length,
            data: notes
        });
    } catch (error) {
        console.error("Lỗi lấy ghi chú theo item:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Lấy danh sách tags
router.get("/tags/all", authenticateUser, async (req, res) => {
    try {
        const userId = req.user._id;

        const tags = await NoteBook.distinct('tags', { user_id: userId });

        res.json({
            total: tags.length,
            data: tags.sort()
        });
    } catch (error) {
        console.error("Lỗi lấy danh sách tags:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Thống kê ghi chú cá nhân
router.get("/stats/me", authenticateUser, async (req, res) => {
    try {
        const userId = req.user._id;

        const [total, byType, recentNotes] = await Promise.all([
            NoteBook.countDocuments({ user_id: userId }),
            NoteBook.aggregate([
                { $match: { user_id: userId } },
                { $group: { _id: "$type", count: { $sum: 1 } } }
            ]),
            NoteBook.find({ user_id: userId })
                .sort({ createdAt: -1 })
                .limit(5)
                .lean()
        ]);

        res.json({
            total,
            byType,
            recentNotes
        });
    } catch (error) {
        console.error("Lỗi lấy thống kê ghi chú:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// ADMIN ROUTES

// Lấy tất cả ghi chú (admin)
router.get("/admin/all", authenticateAdmin, async (req, res) => {
    try {
        const { page = 1, limit = 20, user_id, type } = req.query;

        const query = {};
        if (user_id) query.user_id = user_id;
        if (type) query.type = type;

        const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);

        const [notes, total] = await Promise.all([
            NoteBook.find(query)
                .populate('user_id', 'HoTen Email')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit, 10))
                .lean(),
            NoteBook.countDocuments(query)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / parseInt(limit, 10)),
            currentPage: parseInt(page, 10),
            data: notes
        });
    } catch (error) {
        console.error("Lỗi lấy danh sách ghi chú (admin):", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Thống kê ghi chú (admin)
router.get("/admin/stats", authenticateAdmin, async (req, res) => {
    try {
        const [
            total,
            totalUsers,
            byType,
            topUsers
        ] = await Promise.all([
            NoteBook.countDocuments(),
            NoteBook.distinct('user_id').then(ids => ids.length),
            NoteBook.aggregate([
                { $group: { _id: "$type", count: { $sum: 1 } } }
            ]),
            NoteBook.aggregate([
                { $group: { _id: "$user_id", count: { $sum: 1 } } },
                { $sort: { count: -1 } },
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
            total,
            totalUsers,
            byType,
            topUsers
        });
    } catch (error) {
        console.error("Lỗi lấy thống kê ghi chú (admin):", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Xóa ghi chú (admin)
router.delete("/admin/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;

        const deletedNote = await NoteBook.findByIdAndDelete(id);

        if (!deletedNote) {
            return res.status(404).json({ message: "Không tìm thấy ghi chú." });
        }

        res.json({
            message: "Xóa ghi chú thành công",
            data: deletedNote
        });
    } catch (error) {
        console.error("Lỗi xóa ghi chú (admin):", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

export default router;


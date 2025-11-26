import express from "express";
import News from "../model/News.js";
import { authenticateUser, authenticateAdmin } from "./auth.js";

const router = express.Router();

// USER ROUTES

router.get("/", async (req, res) => {
    try {
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 10;
        const { category, search } = req.query;

        const query = { is_published: true };
        
        if (category) {
            query.category = category;
        }
        
        if (search) {
            query.$or = [
                { title: { $regex: search, $options: 'i' } },
                { content: { $regex: search, $options: 'i' } }
            ];
        }

        const skip = (page - 1) * limit;

        const [newsList, total] = await Promise.all([
            News.find(query)
                .sort({ published_date: -1 })
                .skip(skip)
                .limit(limit)
                .lean(),
            News.countDocuments(query)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / limit),
            currentPage: page,
            data: newsList
        });
    } catch (error) {
        console.error("Lỗi lấy danh sách tin tức:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Lấy chi tiết tin tức
router.get("/:id", async (req, res) => {
    try {
        const { id } = req.params;
        
        const news = await News.findById(id).lean();

        if (!news) {
            return res.status(404).json({ message: "Không tìm thấy tin tức." });
        }

        // Tăng lượt xem
        await News.findByIdAndUpdate(id, { $inc: { views: 1 } });

        res.json({ data: news });
    } catch (error) {
        console.error("Lỗi lấy chi tiết tin tức:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Lấy tin tức liên quan
router.get("/:id/related", async (req, res) => {
    try {
        const { id } = req.params;
        const limit = parseInt(req.query.limit, 10) || 5;
        
        const currentNews = await News.findById(id);
        if (!currentNews) {
            return res.status(404).json({ message: "Không tìm thấy tin tức." });
        }

        const relatedNews = await News.find({
            _id: { $ne: id },
            category: currentNews.category,
            is_published: true
        })
            .sort({ published_date: -1 })
            .limit(limit)
            .lean();

        res.json({
            total: relatedNews.length,
            data: relatedNews
        });
    } catch (error) {
        console.error("Lỗi lấy tin tức liên quan:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Lấy danh sách category
router.get("/categories/all", async (req, res) => {
    try {
        const categories = await News.distinct('category', { is_published: true });
        
        res.json({
            total: categories.length,
            data: categories.sort()
        });
    } catch (error) {
        console.error("Lỗi lấy danh sách category:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// ADMIN ROUTES

// Lấy tất cả tin tức (admin)
router.get("/admin/all", authenticateAdmin, async (req, res) => {
    try {
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 10;
        const { category, is_published, search } = req.query;

        const query = {};
        
        if (category) query.category = category;
        if (is_published !== undefined) query.is_published = is_published === 'true';
        
        if (search) {
            query.$or = [
                { title: { $regex: search, $options: 'i' } },
                { content: { $regex: search, $options: 'i' } }
            ];
        }

        const skip = (page - 1) * limit;

        const [newsList, total] = await Promise.all([
            News.find(query)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit)
                .lean(),
            News.countDocuments(query)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / limit),
            currentPage: page,
            data: newsList
        });
    } catch (error) {
        console.error("Lỗi lấy danh sách tin tức (admin):", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Tạo tin tức mới
router.post("/", authenticateAdmin, async (req, res) => {
    try {
        const { title, content, category, thumbnail, tags, is_published } = req.body;
        
        if (!title || !content || !category) {
            return res.status(400).json({ 
                message: "Vui lòng nhập đầy đủ thông tin bắt buộc (title, content, category)." 
            });
        }

        const newNews = await News.create({
            title,
            content,
            category,
            thumbnail: thumbnail || null,
            tags: tags || [],
            is_published: is_published !== undefined ? is_published : false,
            published_date: is_published ? new Date() : null,
            views: 0
        });

        res.status(201).json({
            message: "Tạo tin tức thành công",
            data: newNews
        });
    } catch (error) {
        console.error("Lỗi tạo tin tức:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Cập nhật tin tức
router.put("/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;

        // Nếu chuyển sang published, cập nhật published_date
        if (updateData.is_published && !updateData.published_date) {
            updateData.published_date = new Date();
        }

        const updatedNews = await News.findByIdAndUpdate(
            id,
            updateData,
            { new: true, runValidators: true }
        );

        if (!updatedNews) {
            return res.status(404).json({ message: "Không tìm thấy tin tức." });
        }

        res.json({
            message: "Cập nhật tin tức thành công",
            data: updatedNews
        });
    } catch (error) {
        console.error("Lỗi cập nhật tin tức:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Xóa tin tức
router.delete("/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        
        const deletedNews = await News.findByIdAndDelete(id);

        if (!deletedNews) {
            return res.status(404).json({ message: "Không tìm thấy tin tức." });
        }

        res.json({
            message: "Xóa tin tức thành công",
            data: deletedNews
        });
    } catch (error) {
        console.error("Lỗi xóa tin tức:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Xóa nhiều tin tức
router.delete("/", authenticateAdmin, async (req, res) => {
    try {
        const { ids } = req.body;
        
        if (!Array.isArray(ids) || ids.length === 0) {
            return res.status(400).json({ message: "Danh sách ID không hợp lệ." });
        }

        const result = await News.deleteMany({ _id: { $in: ids } });

        res.json({
            message: `Đã xóa ${result.deletedCount} tin tức.`,
            deletedCount: result.deletedCount
        });
    } catch (error) {
        console.error("Lỗi xóa nhiều tin tức:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Thống kê tin tức
router.get("/admin/stats", authenticateAdmin, async (req, res) => {
    try {
        const [
            total,
            published,
            draft,
            byCategory,
            topViewed,
            recentNews
        ] = await Promise.all([
            News.countDocuments(),
            News.countDocuments({ is_published: true }),
            News.countDocuments({ is_published: false }),
            News.aggregate([
                { $group: { _id: "$category", count: { $sum: 1 } } },
                { $sort: { count: -1 } }
            ]),
            News.find({ is_published: true })
                .sort({ views: -1 })
                .limit(10)
                .lean(),
            News.find()
                .sort({ createdAt: -1 })
                .limit(10)
                .lean()
        ]);

        res.json({
            total,
            published,
            draft,
            byCategory,
            topViewed,
            recentNews
        });
    } catch (error) {
        console.error("Lỗi lấy thống kê tin tức:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

export default router;
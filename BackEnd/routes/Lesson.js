import express from "express";
import Lesson from "../model/Lesson.js";
import Vocabulary from "../model/Vocabulary.js";
import Kanji from "../model/Kanji.js";
import Grammar from "../model/Grammar.js";
import { authenticateUser, authenticateAdmin } from "./auth.js";

const router = express.Router();

// Lấy danh sách bài học (có phân trang, lọc theo cấp độ, loại bài học, tìm kiếm)
router.get("/", authenticateUser, async (req, res) => {
    try {
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 10;
        const { capDo, loaiBaiHoc, search } = req.query;

        const query = {};
        
        if (capDo) {
            query.CapDo = capDo;
        }
        if (loaiBaiHoc) {
            query.LoaiBaiHoc = { $regex: loaiBaiHoc, $options: 'i' };
        }
        if (search) {
            query.TenBaiHoc = { $regex: search, $options: 'i' };
        }

        const skip = (page - 1) * limit;
        
        // Sắp xếp theo level (N5->N4->N3->N2->N1) và order tăng dần
        const levelOrder = { 'N5': 1, 'N4': 2, 'N3': 3, 'N2': 4, 'N1': 5 };
        
        const [lessons, total] = await Promise.all([
            Lesson.find(query)
                .sort({ order: 1 })  // Sắp xếp theo thứ tự bài học
                .skip(skip)
                .limit(limit)
                .lean()
                .then(docs => {
                    // Sắp xếp thêm theo level nếu cần
                    return docs.sort((a, b) => {
                        const levelDiff = (levelOrder[a.level] || 99) - (levelOrder[b.level] || 99);
                        if (levelDiff !== 0) return levelDiff;
                        return (a.order || 0) - (b.order || 0);
                    });
                }),
            Lesson.countDocuments(query)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / limit),
            currentPage: page,
            data: lessons
        });
    } catch (error) {
        console.error("Lỗi khi lấy danh sách bài học:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
});

// Lấy chi tiết 1 bài học theo ID (bao gồm từ vựng, kanji, ngữ pháp)
router.get("/:id", authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        
        const baiHoc = await Lesson.findById(id).lean();

        if (!baiHoc) {
            return res.status(404).json({ message: "Bài học không tồn tại" });
        }

        const [tuvungs, kanjis, nguphaps] = await Promise.all([
            Vocabulary.find({ BaiHocID: id }).lean(),
            Kanji.find({ BaiHocID: id }).lean(),
            Grammar.find({ BaiHocID: id }).lean()
        ]);

        res.json({
            ...baiHoc,
            tuvungs,
            kanjis,
            nguphaps
        });
    } catch (error) {
        console.error("Lỗi khi lấy chi tiết bài học:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
});

// Lấy danh sách bài học theo cấp độ
router.get("/level/:capDo", authenticateUser, async (req, res) => {
    try {
        const { capDo } = req.params;
        
        const lessons = await Lesson.find({ CapDo: capDo })
            .sort({ createdAt: -1 })
            .lean();

        res.json({
            total: lessons.length,
            data: lessons
        });
    } catch (error) {
        console.error("Lỗi khi lấy bài học theo cấp độ:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
});

// Lấy danh sách bài học theo loại
router.get("/type/:loaiBaiHoc", authenticateUser, async (req, res) => {
    try {
        const { loaiBaiHoc } = req.params;
        
        const lessons = await Lesson.find({ 
            LoaiBaiHoc: { $regex: loaiBaiHoc, $options: 'i' } 
        })
            .sort({ createdAt: -1 })
            .lean();

        res.json({
            total: lessons.length,
            data: lessons
        });
    } catch (error) {
        console.error("Lỗi khi lấy bài học theo loại:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
});

// Lấy thống kê bài học
router.get("/stats/overview", authenticateAdmin, async (req, res) => {
    try {
        const [totalLessons, byLevel, byType] = await Promise.all([
            Lesson.countDocuments(),
            Lesson.aggregate([
                { $group: { _id: "$CapDo", count: { $sum: 1 } } },
                { $sort: { _id: 1 } }
            ]),
            Lesson.aggregate([
                { $group: { _id: "$LoaiBaiHoc", count: { $sum: 1 } } },
                { $sort: { count: -1 } }
            ])
        ]);

        res.json({
            totalLessons,
            byLevel,
            byType
        });
    } catch (error) {
        console.error("Lỗi khi lấy thống kê:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
});

// Tạo mới bài học
router.post("/", authenticateAdmin, async (req, res) => {
    try {
        const { TenBaiHoc, CapDo, LoaiBaiHoc, NoiDung } = req.body;
        
        if (!TenBaiHoc || !CapDo || !LoaiBaiHoc || !NoiDung) {
            return res.status(400).json({ message: "Vui lòng nhập đầy đủ thông tin." });
        }

        const newBaiHoc = await Lesson.create({
            TenBaiHoc,
            LoaiBaiHoc,
            CapDo,
            NoiDung
        });

        res.status(201).json({
            message: "Thêm bài học thành công",
            data: newBaiHoc
        });
    } catch (error) {
        console.error("Lỗi khi tạo bài học:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
});

// Tạo nhiều bài học cùng lúc
router.post("/bulk", authenticateAdmin, async (req, res) => {
    try {
        const { lessons } = req.body;
        
        if (!Array.isArray(lessons) || lessons.length === 0) {
            return res.status(400).json({ message: "Danh sách bài học không hợp lệ." });
        }

        const createdLessons = await Lesson.insertMany(lessons);

        res.status(201).json({
            message: `Thêm thành công ${createdLessons.length} bài học`,
            data: createdLessons
        });
    } catch (error) {
        console.error("Lỗi khi tạo nhiều bài học:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
});

// Cập nhật bài học
router.put("/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const { TenBaiHoc, CapDo, LoaiBaiHoc, NoiDung } = req.body;
        
        const baiHoc = await Lesson.findByIdAndUpdate(
            id,
            {
                TenBaiHoc,
                LoaiBaiHoc,
                NoiDung,
                CapDo,
                updatedAt: Date.now()
            },
            { new: true, runValidators: true }
        );

        if (!baiHoc) {
            return res.status(404).json({ message: "Bài học không tồn tại." });
        }

        res.json({ 
            message: "Cập nhật bài học thành công.", 
            data: baiHoc 
        });
    } catch (error) {
        console.error("Lỗi cập nhật bài học:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Cập nhật một phần bài học (PATCH)
router.patch("/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = { ...req.body, updatedAt: Date.now() };
        
        const baiHoc = await Lesson.findByIdAndUpdate(
            id,
            updateData,
            { new: true, runValidators: true }
        );

        if (!baiHoc) {
            return res.status(404).json({ message: "Bài học không tồn tại." });
        }

        res.json({ 
            message: "Cập nhật bài học thành công.", 
            data: baiHoc 
        });
    } catch (error) {
        console.error("Lỗi cập nhật bài học:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Xóa bài học
router.delete("/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        
        const [vocabCount, kanjiCount, grammarCount] = await Promise.all([
            Vocabulary.countDocuments({ BaiHocID: id }),
            Kanji.countDocuments({ BaiHocID: id }),
            Grammar.countDocuments({ BaiHocID: id })
        ]);

        if (vocabCount > 0 || kanjiCount > 0 || grammarCount > 0) {
            return res.status(400).json({
                message: "Không thể xóa bài học này vì có dữ liệu liên quan (từ vựng, kanji, ngữ pháp). Vui lòng xóa dữ liệu liên quan trước.",
                relatedData: {
                    vocabulary: vocabCount,
                    kanji: kanjiCount,
                    grammar: grammarCount
                }
            });
        }

        const deletedLesson = await Lesson.findByIdAndDelete(id);

        if (!deletedLesson) {
            return res.status(404).json({
                message: "Không tìm thấy bài học để xóa."
            });
        }

        res.json({ 
            message: "Xóa bài học thành công",
            data: deletedLesson
        });
    } catch (error) {
        console.error("Lỗi xóa bài học:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Xóa nhiều bài học cùng lúc
router.delete("/", authenticateAdmin, async (req, res) => {
    try {
        const { ids } = req.body;
        
        if (!Array.isArray(ids) || ids.length === 0) {
            return res.status(400).json({ message: "Danh sách ID không hợp lệ." });
        }

        const result = await Lesson.deleteMany({ _id: { $in: ids } });

        res.json({ 
            message: `Xóa thành công ${result.deletedCount} bài học`,
            deletedCount: result.deletedCount
        });
    } catch (error) {
        console.error("Lỗi xóa nhiều bài học:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Sao chép bài học
router.post("/:id/duplicate", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        
        const originalLesson = await Lesson.findById(id).lean();
        
        if (!originalLesson) {
            return res.status(404).json({ message: "Bài học không tồn tại." });
        }

        delete originalLesson._id;
        originalLesson.TenBaiHoc = `${originalLesson.TenBaiHoc} (Copy)`;

        const duplicatedLesson = await Lesson.create(originalLesson);

        res.status(201).json({
            message: "Sao chép bài học thành công",
            data: duplicatedLesson
        });
    } catch (error) {
        console.error("Lỗi sao chép bài học:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

export default router;
import express from 'express';
import Grammar from '../model/Grammar.js';
import Lesson from '../model/Lesson.js';
import { authenticateUser, authenticateAdmin } from './auth.js';
import mongoose from 'mongoose';

const router = express.Router();

// Lấy danh sách ngữ pháp với phân trang và lọc
router.get('/', authenticateUser, async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;
        
        const { level, search, lessonID, sortBy } = req.query;
        
        const filter = { is_active: true };
        
        if (level) filter.level = level;
        if (lessonID) {
            if (!mongoose.Types.ObjectId.isValid(lessonID)) {
                return res.status(400).json({ message: "ID bài học không hợp lệ." });
            }
            filter.lesson_id = lessonID;
        }
        
        if (search) {
            filter.$text = { $search: search };
        }

        //  Dynamic sorting
        let sortOptions = { title: 1 };
        if (sortBy === 'popular') sortOptions = { view_count: -1 };
        if (sortBy === 'newest') sortOptions = { createdAt: -1 };

        const [grammars, total] = await Promise.all([
            Grammar.find(filter)
                .populate('lesson_id', 'title level')
                .sort(sortOptions)
                .limit(limit)
                .skip(skip)
                .lean(),
            Grammar.countDocuments(filter)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / limit),
            currentPage: page,
            data: grammars
        });
    } catch (error) {
        console.error("Lỗi khi lấy danh sách ngữ pháp:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
});

//  Lấy chi tiết ngữ pháp và tăng view count
router.get('/:id', authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: "ID ngữ pháp không hợp lệ." });
        }

        const grammar = await Grammar.findById(id)
            .populate('lesson_id', 'title level')
            .populate('related_grammar', 'title structure level');

        if (!grammar || !grammar.is_active) {
            return res.status(404).json({ message: "Ngữ pháp không tồn tại." });
        }

        // Tăng lượt xem
        await grammar.incrementViewCount();

        res.json(grammar);
    } catch (error) {
        console.error("Lỗi khi lấy chi tiết ngữ pháp:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
});

//  Lấy ngữ pháp phổ biến theo cấp độ
router.get('/popular/:level', authenticateUser, async (req, res) => {
    try {
        const { level } = req.params;
        const limit = parseInt(req.query.limit) || 10;

        const grammars = await Grammar.findByLevel(level, limit);

        res.json(grammars);
    } catch (error) {
        console.error("Lỗi khi lấy ngữ pháp phổ biến:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
});

// Tạo mới ngữ pháp
router.post('/', authenticateAdmin, async (req, res) => {
    try {
        const { 
            title, structure, meaning, usage, examples, 
            level, lessonID, notes, difficulty, relatedGrammar 
        } = req.body;

        if (!title || !structure || !meaning || !level) {
            return res.status(400).json({ 
                message: "Vui lòng điền đầy đủ: Tiêu đề, Cấu trúc, Ý nghĩa, Cấp độ." 
            });
        }

        if (lessonID && !mongoose.Types.ObjectId.isValid(lessonID)) {
            return res.status(400).json({ message: "ID bài học không hợp lệ." });
        }

        const newGrammar = await Grammar.create({
            title,
            structure,
            meaning,
            usage,
            examples: examples || [],
            level,
            lesson_id: lessonID,
            notes,
            difficulty: difficulty || 3,
            related_grammar: relatedGrammar || []
        });

        res.status(201).json({
            message: "Thêm ngữ pháp thành công.",
            data: newGrammar
        });
    } catch (error) {
        console.error("Lỗi khi tạo ngữ pháp:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
});

// Cập nhật ngữ pháp
router.put('/:id', authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: "ID ngữ pháp không hợp lệ." });
        }

        const updateData = { ...req.body };
        delete updateData._id;
        delete updateData.createdAt;
        delete updateData.updatedAt;

        const updatedGrammar = await Grammar.findByIdAndUpdate(
            id,
            updateData,
            { new: true, runValidators: true }
        );

        if (!updatedGrammar) {
            return res.status(404).json({ message: "Ngữ pháp không tồn tại." });
        }

        res.json({ 
            message: "Cập nhật ngữ pháp thành công.", 
            data: updatedGrammar 
        });
    } catch (error) {
        console.error("Lỗi khi cập nhật ngữ pháp:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
});

// Xóa ngữ pháp (soft delete)
router.delete('/:id', authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: "ID ngữ pháp không hợp lệ." });
        }

        const deletedGrammar = await Grammar.findByIdAndUpdate(
            id,
            { is_active: false },
            { new: true }
        );

        if (!deletedGrammar) {
            return res.status(404).json({ message: "Ngữ pháp không tồn tại." });
        }

        res.json({ message: "Xóa ngữ pháp thành công." });
    } catch (error) {
        console.error("Lỗi khi xóa ngữ pháp:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
});

export default router;
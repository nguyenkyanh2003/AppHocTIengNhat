import express from "express";
import SRSProgress from "../model/SRSProgress.js";
import Vocabulary from "../model/Vocabulary.js";
import Kanji from "../model/Kanji.js";
import Grammar from "../model/Grammar.js";
import UserStreak from "../model/UserStreak.js";
import { authenticateUser, authenticateAdmin } from "./auth.js";

const router = express.Router();

// Lấy danh sách thẻ cần ôn hôm nay
router.get('/due', authenticateUser, async (req, res) => {
    try {
        const userId = req.user._id;
        const { item_type, limit = 20 } = req.query;
        
        const query = {
            user_id: userId,
            next_review_date: { $lte: new Date() },
            status: { $in: ['learning', 'review'] }
        };
        
        if (item_type) {
            query.item_type = item_type;
        }

        const dueCards = await SRSProgress.find(query)
            .sort({ next_review_date: 1 })
            .limit(parseInt(limit, 10))
            .lean();

        for (let card of dueCards) {
            if (card.item_type === 'vocabulary') {
                card.item = await Vocabulary.findById(card.item_id).lean();
            } else if (card.item_type === 'kanji') {
                card.item = await Kanji.findById(card.item_id).lean();
            } else if (card.item_type === 'grammar') {
                card.item = await Grammar.findById(card.item_id).lean();
            }
        }

        res.json({
            total: dueCards.length,
            data: dueCards
        });
    } catch (error) {
        console.error("Lỗi lấy thẻ cần ôn:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Lấy số lượng thẻ cần ôn
router.get("/due/count", authenticateUser, async (req, res) => {
    try {
        const userId = req.user._id;
        
        const [total, byType, byStatus] = await Promise.all([
            SRSProgress.countDocuments({
                user_id: userId,
                next_review_date: { $lte: new Date() }
            }),
            SRSProgress.aggregate([
                {
                    $match: {
                        user_id: userId,
                        next_review_date: { $lte: new Date() }
                    }
                },
                {
                    $group: {
                        _id: "$item_type",
                        count: { $sum: 1 }
                    }
                }
            ]),
            SRSProgress.aggregate([
                {
                    $match: {
                        user_id: userId,
                        next_review_date: { $lte: new Date() }
                    }
                },
                {
                    $group: {
                        _id: "$status",
                        count: { $sum: 1 }
                    }
                }
            ])
        ]);

        res.json({
            total,
            byType,
            byStatus
        });
    } catch (error) {
        console.error("Lỗi đếm thẻ cần ôn:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Trả lời câu hỏi SRS
router.post("/answer/:id", authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;
        const { quality } = req.body; 
        
        if (quality === undefined || quality < 0 || quality > 5) {
            return res.status(400).json({ 
                message: "Quality phải từ 0-5 (0=hoàn toàn quên, 5=nhớ rất rõ)" 
            });
        }

        const card = await SRSProgress.findOne({ _id: id, user_id: userId });
        
        if (!card) {
            return res.status(404).json({ message: "Không tìm thấy thẻ SRS." });
        }

        let newInterval = card.interval;
        let newEaseFactor = card.ease_factor;
        let newRepetitions = card.repetitions;
        let newStatus = card.status;

        if (quality >= 3) {
            newRepetitions++;
            
            if (card.status === 'new') {
                newStatus = 'learning';
                newInterval = 1; 
            } else if (card.status === 'learning' && newRepetitions >= 2) {
                newStatus = 'review';
                newInterval = 1;
            } else {
                newInterval = Math.round(card.interval * newEaseFactor);
            }
            
            newEaseFactor = newEaseFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
            if (newEaseFactor < 1.3) newEaseFactor = 1.3;
            
        } else {
            newRepetitions = 0;
            newStatus = 'learning';
            newInterval = 1;
        }

        if (newInterval >= 21 && newEaseFactor >= 2.5) {
            newStatus = 'mastered';
        }

        card.interval = newInterval;
        card.ease_factor = newEaseFactor;
        card.repetitions = newRepetitions;
        card.status = newStatus;
        card.last_review_date = new Date();
        card.next_review_date = new Date(Date.now() + newInterval * 24 * 60 * 60 * 1000);
        card.correct_count = quality >= 3 ? card.correct_count + 1 : card.correct_count;
        card.incorrect_count = quality < 3 ? card.incorrect_count + 1 : card.incorrect_count;
        
        await card.save();

        // Cập nhật streak khi ôn tập SRS
        try {
            const streak = await UserStreak.findOne({ user: userId });
            if (streak) {
                const updated = streak.updateStreakOnActivity();
                if (updated.is_new_day) {
                    console.log(`✅ Streak updated for user ${userId}: ${streak.current_streak} days`);
                }
                
                // Thêm XP dựa trên quality (0-5 points -> 1-6 XP)
                const xpEarned = quality >= 3 ? quality + 1 : 1;
                streak.addXP(xpEarned, 'Ôn tập SRS');
                await streak.save();
            }
        } catch (streakError) {
            console.error('⚠️ Lỗi cập nhật streak:', streakError);
        }

        res.json({
            message: "Cập nhật thành công",
            data: card
        });
    } catch (error) {
        console.error("Lỗi trả lời SRS:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Thêm item vào SRS
router.post('/review', authenticateUser, async (req, res) => {
    try {
        const userId = req.user._id;
        const { item_id, item_type } = req.body;
        
        if (!item_id || !item_type) {
            return res.status(400).json({ 
                message: "Vui lòng cung cấp item_id và item_type (vocabulary/kanji/grammar)" 
            });
        }

        let itemExists = false;
        if (item_type === 'vocabulary') {
            itemExists = await Vocabulary.exists({ _id: item_id });
        } else if (item_type === 'kanji') {
            itemExists = await Kanji.exists({ _id: item_id });
        } else if (item_type === 'grammar') {
            itemExists = await Grammar.exists({ _id: item_id });
        }

        if (!itemExists) {
            return res.status(404).json({ message: "Item không tồn tại." });
        }

        const existing = await SRSProgress.findOne({
            user_id: userId,
            item_id,
            item_type
        });

        if (existing) {
            return res.status(409).json({ 
                message: "Item đã có trong hệ thống SRS.",
                data: existing
            });
        }

        const newCard = await SRSProgress.create({
            user_id: userId,
            item_id,
            item_type,
            status: 'new',
            interval: 0,
            ease_factor: 2.5,
            repetitions: 0,
            last_review_date: null,
            next_review_date: new Date(),
            correct_count: 0,
            incorrect_count: 0
        });

        // Cập nhật streak khi thêm từ/kanji/grammar vào ôn tập
        try {
            const streak = await UserStreak.findOne({ user: userId });
            if (streak) {
                const updated = streak.updateStreakOnActivity();
                if (updated.is_new_day) {
                    console.log(`✅ Streak updated for user ${userId}: ${streak.current_streak} days`);
                }
                streak.addXP(3, 'Thêm vào SRS');
                await streak.save();
            }
        } catch (streakError) {
            console.error('⚠️ Lỗi cập nhật streak:', streakError);
        }

        res.status(201).json({
            message: "Thêm vào SRS thành công",
            data: newCard
        });
    } catch (error) {
        console.error("Lỗi thêm vào SRS:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

router.get("/my-cards", authenticateUser, async (req, res) => {
    try {
        const userId = req.user._id;
        const { item_type, status, page = 1, limit = 20 } = req.query;
        
        const query = { user_id: userId };
        if (item_type) query.item_type = item_type;
        if (status) query.status = status;

        const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);

        const [cards, total] = await Promise.all([
            SRSProgress.find(query)
                .sort({ next_review_date: 1 })
                .skip(skip)
                .limit(parseInt(limit, 10))
                .lean(),
            SRSProgress.countDocuments(query)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / parseInt(limit, 10)),
            currentPage: parseInt(page, 10),
            data: cards
        });
    } catch (error) {
        console.error("Lỗi lấy danh sách thẻ SRS:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

router.get('/stats', authenticateUser, async (req, res) => {
    try {
        const userId = req.user._id;

        const [
            totalCards,
            byStatus,
            byType,
            dueToday,
            accuracy
        ] = await Promise.all([
            SRSProgress.countDocuments({ user_id: userId }),
            SRSProgress.aggregate([
                { $match: { user_id: userId } },
                { $group: { _id: "$status", count: { $sum: 1 } } }
            ]),
            SRSProgress.aggregate([
                { $match: { user_id: userId } },
                { $group: { _id: "$item_type", count: { $sum: 1 } } }
            ]),
            SRSProgress.countDocuments({
                user_id: userId,
                next_review_date: { $lte: new Date() }
            }),
            SRSProgress.aggregate([
                { $match: { user_id: userId } },
                {
                    $group: {
                        _id: null,
                        totalCorrect: { $sum: "$correct_count" },
                        totalIncorrect: { $sum: "$incorrect_count" }
                    }
                }
            ])
        ]);

        const totalReviews = accuracy[0]?.totalCorrect + accuracy[0]?.totalIncorrect || 0;
        const accuracyRate = totalReviews > 0 
            ? ((accuracy[0]?.totalCorrect / totalReviews) * 100).toFixed(2) 
            : 0;

        res.json({
            totalCards,
            byStatus,
            byType,
            dueToday,
            accuracy: {
                correct: accuracy[0]?.totalCorrect || 0,
                incorrect: accuracy[0]?.totalIncorrect || 0,
                rate: accuracyRate
            }
        });
    } catch (error) {
        console.error("Lỗi lấy thống kê SRS:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

router.delete("/:id", authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;
        
        const deletedCard = await SRSProgress.findOneAndDelete({
            _id: id,
            user_id: userId
        });

        if (!deletedCard) {
            return res.status(404).json({ message: "Không tìm thấy thẻ SRS." });
        }

        res.json({
            message: "Xóa thẻ SRS thành công",
            data: deletedCard
        });
    } catch (error) {
        console.error("Lỗi xóa thẻ SRS:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Reset thẻ SRS về trạng thái mới
router.put("/reset/:id", authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;
        
        const card = await SRSProgress.findOneAndUpdate(
            { _id: id, user_id: userId },
            {
                status: 'new',
                interval: 0,
                ease_factor: 2.5,
                repetitions: 0,
                last_review_date: null,
                next_review_date: new Date()
            },
            { new: true }
        );

        if (!card) {
            return res.status(404).json({ message: "Không tìm thấy thẻ SRS." });
        }

        res.json({
            message: "Reset thẻ SRS thành công",
            data: card
        });
    } catch (error) {
        console.error("Lỗi reset thẻ SRS:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Lấy tất cả thẻ SRS (admin)
router.get("/admin/all", authenticateAdmin, async (req, res) => {
    try {
        const { page = 1, limit = 20, user_id, item_type, status } = req.query;
        
        const query = {};
        if (user_id) query.user_id = user_id;
        if (item_type) query.item_type = item_type;
        if (status) query.status = status;

        const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);

        const [cards, total] = await Promise.all([
            SRSProgress.find(query)
                .populate('user_id', 'HoTen Email')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit, 10))
                .lean(),
            SRSProgress.countDocuments(query)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / parseInt(limit, 10)),
            currentPage: parseInt(page, 10),
            data: cards
        });
    } catch (error) {
        console.error("Lỗi lấy danh sách SRS (admin):", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Thống kê tổng quan SRS 
router.get("/admin/stats", authenticateAdmin, async (req, res) => {
    try {
        const [
            totalCards,
            totalUsers,
            byStatus,
            byType,
            topUsers
        ] = await Promise.all([
            SRSProgress.countDocuments(),
            SRSProgress.distinct('user_id').then(ids => ids.length),
            SRSProgress.aggregate([
                { $group: { _id: "$status", count: { $sum: 1 } } }
            ]),
            SRSProgress.aggregate([
                { $group: { _id: "$item_type", count: { $sum: 1 } } }
            ]),
            SRSProgress.aggregate([
                {
                    $group: {
                        _id: "$user_id",
                        totalCards: { $sum: 1 },
                        totalCorrect: { $sum: "$correct_count" },
                        masteredCards: {
                            $sum: { $cond: [{ $eq: ["$status", "mastered"] }, 1, 0] }
                        }
                    }
                },
                { $sort: { masteredCards: -1, totalCorrect: -1 } },
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
            totalCards,
            totalUsers,
            byStatus,
            byType,
            topUsers
        });
    } catch (error) {
        console.error("Lỗi lấy thống kê SRS (admin):", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Xóa thẻ SRS 
router.delete("/admin/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        
        const deletedCard = await SRSProgress.findByIdAndDelete(id);

        if (!deletedCard) {
            return res.status(404).json({ message: "Không tìm thấy thẻ SRS." });
        }

        res.json({
            message: "Xóa thẻ SRS thành công",
            data: deletedCard
        });
    } catch (error) {
        console.error("Lỗi xóa thẻ SRS (admin):", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Xóa tất cả thẻ của user 
router.delete("/admin/user/:userId/clear", authenticateAdmin, async (req, res) => {
    try {
        const { userId } = req.params;

        const result = await SRSProgress.deleteMany({ user_id: userId });

        res.json({
            message: `Đã xóa ${result.deletedCount} thẻ SRS của người dùng.`,
            deletedCount: result.deletedCount
        });
    } catch (error) {
        console.error("Lỗi xóa thẻ SRS của user:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

export default router;
import express from "express";
import LearningHistory from "../model/LearningHistory.js";
import Lesson from "../model/Lesson.js";
import User from "../model/User.js";
import { authenticateAdmin, authenticateUser } from "./auth.js";
import dotenv from "dotenv";

dotenv.config();
const router = express.Router();

// Lấy tiến độ cá nhân
router.get("/", authenticateUser, async (req, res) => {
    try {
        const nguoiHocID = req.user?.NguoiHocID || req.user?.id || req.user?._id;
        
        if (!nguoiHocID) {
            return res.status(401).json({ message: "Không tìm thấy ID người dùng." });
        }

        const progressList = await LearningHistory.find({ NguoiHocID: nguoiHocID })
            .populate('BaiHocID', 'TenBaiHoc CapDo LoaiBaiHoc')
            .sort({ NgayHoc: -1 })
            .lean();

        res.json({ 
            total: progressList.length,
            data: progressList 
        });
    } catch (error) {
        console.error("Lỗi khi lấy tiến độ cá nhân:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Lấy tiến độ của một bài học cụ thể
router.get("/lesson/:lessonID", authenticateUser, async (req, res) => {
    try {
        const { lessonID } = req.params;
        const nguoiHocID = req.user?.NguoiHocID || req.user?.id || req.user?._id;

        const progress = await LearningHistory.findOne({
            NguoiHocID: nguoiHocID,
            BaiHocID: lessonID
        })
            .populate('BaiHocID', 'TenBaiHoc CapDo LoaiBaiHoc')
            .lean();

        if (!progress) {
            return res.status(404).json({ 
                message: "Chưa có tiến độ cho bài học này.",
                data: null
            });
        }

        res.json({ data: progress });
    } catch (error) {
        console.error("Lỗi khi lấy tiến độ bài học:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Cập nhật tiến độ cho một bài học
router.post("/lesson/:lessonID/update", authenticateUser, async (req, res) => {
    try {
        const { lessonID } = req.params;
        const nguoiHocID = req.user?.NguoiHocID || req.user?.id || req.user?._id;
        const { TienDo, ThoiGianHoc, GhiChu } = req.body;
        
        let newProgress = parseInt(TienDo, 10);

        if (isNaN(newProgress) || newProgress < 0) {
            newProgress = 0;
        }
        if (newProgress > 100) newProgress = 100;

        const lesson = await Lesson.findById(lessonID);
        if (!lesson) {
            return res.status(404).json({ message: "Bài học không tồn tại." });
        }
        let progress = await LearningHistory.findOne({
            NguoiHocID: nguoiHocID,
            BaiHocID: lessonID
        });

        if (progress) {
            if (newProgress > progress.TienDo) {
                progress.TienDo = newProgress;
                progress.NgayHoc = new Date();
                
                if (ThoiGianHoc) {
                    progress.ThoiGianHoc = (progress.ThoiGianHoc || 0) + parseInt(ThoiGianHoc, 10);
                }
                if (GhiChu) {
                    progress.GhiChu = GhiChu;
                }
                
                await progress.save();
            }
        } else {
            progress = await LearningHistory.create({
                NguoiHocID: nguoiHocID,
                BaiHocID: lessonID,
                TienDo: newProgress,
                ThoiGianHoc: ThoiGianHoc || 0,
                GhiChu: GhiChu || null,
                NgayHoc: new Date()
            });
        }

        const populatedProgress = await LearningHistory.findById(progress._id)
            .populate('BaiHocID', 'TenBaiHoc CapDo LoaiBaiHoc')
            .lean();

        res.status(200).json({ 
            message: "Cập nhật tiến độ thành công.", 
            data: populatedProgress 
        });
    } catch (error) {
        console.error("Lỗi khi cập nhật tiến độ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Lấy thống kê tiến độ cá nhân
router.get("/stats", authenticateUser, async (req, res) => {
    try {
        const nguoiHocID = req.user?.NguoiHocID || req.user?.id || req.user?._id;

        const [totalLessons, completedLessons, inProgressLessons, avgProgress, byLevel] = await Promise.all([
            LearningHistory.countDocuments({ NguoiHocID: nguoiHocID }),
            LearningHistory.countDocuments({ NguoiHocID: nguoiHocID, TienDo: 100 }),
            LearningHistory.countDocuments({ 
                NguoiHocID: nguoiHocID, 
                TienDo: { $gt: 0, $lt: 100 } 
            }),
            LearningHistory.aggregate([
                { $match: { NguoiHocID: nguoiHocID } },
                { $group: { _id: null, avgProgress: { $avg: "$TienDo" } } }
            ]),
            LearningHistory.aggregate([
                { $match: { NguoiHocID: nguoiHocID } },
                { 
                    $lookup: {
                        from: 'lessons',
                        localField: 'BaiHocID',
                        foreignField: '_id',
                        as: 'lesson'
                    }
                },
                { $unwind: '$lesson' },
                { $group: { _id: "$lesson.CapDo", count: { $sum: 1 }, avgProgress: { $avg: "$TienDo" } } },
                { $sort: { _id: 1 } }
            ])
        ]);

        res.json({
            totalLessons,
            completedLessons,
            inProgressLessons,
            notStartedLessons: totalLessons - completedLessons - inProgressLessons,
            avgProgress: avgProgress[0]?.avgProgress || 0,
            completionRate: totalLessons > 0 ? ((completedLessons / totalLessons) * 100).toFixed(2) : 0,
            byLevel
        });
    } catch (error) {
        console.error("Lỗi khi lấy thống kê tiến độ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Lấy lịch sử học tập gần đây
router.get("/recent", authenticateUser, async (req, res) => {
    try {
        const nguoiHocID = req.user?.NguoiHocID || req.user?.id || req.user?._id;
        const limit = parseInt(req.query.limit, 10) || 10;

        const recentProgress = await LearningHistory.find({ NguoiHocID: nguoiHocID })
            .populate('BaiHocID', 'TenBaiHoc CapDo LoaiBaiHoc')
            .sort({ NgayHoc: -1 })
            .limit(limit)
            .lean();

        res.json({ 
            total: recentProgress.length,
            data: recentProgress 
        });
    } catch (error) {
        console.error("Lỗi khi lấy lịch sử học tập gần đây:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Xóa tiến độ của một bài học
router.delete("/lesson/:lessonID", authenticateUser, async (req, res) => {
    try {
        const { lessonID } = req.params;
        const nguoiHocID = req.user?.NguoiHocID || req.user?.id || req.user?._id;

        const deletedProgress = await LearningHistory.findOneAndDelete({
            NguoiHocID: nguoiHocID,
            BaiHocID: lessonID
        });

        if (!deletedProgress) {
            return res.status(404).json({ message: "Không tìm thấy tiến độ." });
        }

        res.json({ 
            message: "Xóa tiến độ thành công.",
            data: deletedProgress
        });
    } catch (error) {
        console.error("Lỗi khi xóa tiến độ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Lấy tiến độ của tất cả người dùng
router.get("/admin", authenticateAdmin, async (req, res) => {
    try {
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 10;
        const { userId, lessonId, minProgress, maxProgress } = req.query;

        const query = {};
        
        if (userId) {
            query.NguoiHocID = userId;
        }
        if (lessonId) {
            query.BaiHocID = lessonId;
        }
        if (minProgress) {
            query.TienDo = { ...query.TienDo, $gte: parseInt(minProgress, 10) };
        }
        if (maxProgress) {
            query.TienDo = { ...query.TienDo, $lte: parseInt(maxProgress, 10) };
        }

        const skip = (page - 1) * limit;

        const [progressList, total] = await Promise.all([
            LearningHistory.find(query)
                .populate('BaiHocID', 'TenBaiHoc CapDo LoaiBaiHoc')
                .populate('NguoiHocID', 'HoTen Email')
                .sort({ NgayHoc: -1 })
                .skip(skip)
                .limit(limit)
                .lean(),
            LearningHistory.countDocuments(query)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / limit),
            currentPage: page,
            data: progressList
        });
    } catch (error) {
        console.error("Lỗi khi lấy tiến độ của tất cả người dùng:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Lấy tiến độ của người dùng cụ thể
router.get("/admin/user/:userID", authenticateAdmin, async (req, res) => {
    try {
        const { userID } = req.params;
        
        const progressList = await LearningHistory.find({ NguoiHocID: userID })
            .populate('BaiHocID', 'TenBaiHoc CapDo LoaiBaiHoc')
            .sort({ NgayHoc: -1 })
            .lean();

        if (!progressList || progressList.length === 0) {
            return res.status(404).json({ message: "Không tìm thấy tiến độ học của người dùng này." });
        }

        res.json({ 
            total: progressList.length,
            data: progressList 
        });
    } catch (error) {
        console.error("Lỗi khi lấy tiến độ của người dùng cụ thể:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Lấy thống kê tổng quan
router.get("/admin/stats", authenticateAdmin, async (req, res) => {
    try {
        const [
            totalProgress,
            totalUsers,
            totalLessons,
            avgProgress,
            progressByLevel,
            topUsers,
            recentActivity
        ] = await Promise.all([
            LearningHistory.countDocuments(),
            LearningHistory.distinct('NguoiHocID').then(ids => ids.length),
            LearningHistory.distinct('BaiHocID').then(ids => ids.length),
            LearningHistory.aggregate([
                { $group: { _id: null, avgProgress: { $avg: "$TienDo" } } }
            ]),
            LearningHistory.aggregate([
                { 
                    $lookup: {
                        from: 'lessons',
                        localField: 'BaiHocID',
                        foreignField: '_id',
                        as: 'lesson'
                    }
                },
                { $unwind: '$lesson' },
                { $group: { 
                    _id: "$lesson.CapDo", 
                    count: { $sum: 1 }, 
                    avgProgress: { $avg: "$TienDo" },
                    completed: { $sum: { $cond: [{ $eq: ["$TienDo", 100] }, 1, 0] } }
                }},
                { $sort: { _id: 1 } }
            ]),
            LearningHistory.aggregate([
                { $group: { 
                    _id: "$NguoiHocID", 
                    totalLessons: { $sum: 1 },
                    completedLessons: { $sum: { $cond: [{ $eq: ["$TienDo", 100] }, 1, 0] } },
                    avgProgress: { $avg: "$TienDo" }
                }},
                { $sort: { completedLessons: -1, avgProgress: -1 } },
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
            ]),
            LearningHistory.find()
                .populate('NguoiHocID', 'HoTen')
                .populate('BaiHocID', 'TenBaiHoc')
                .sort({ NgayHoc: -1 })
                .limit(20)
                .lean()
        ]);

        res.json({
            overview: {
                totalProgress,
                totalUsers,
                totalLessons,
                avgProgress: avgProgress[0]?.avgProgress || 0
            },
            progressByLevel,
            topUsers,
            recentActivity
        });
    } catch (error) {
        console.error("Lỗi khi lấy thống kê tổng quan:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Cập nhật tiến độ cho người dùng (admin)
router.put("/admin/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;

        if (updateData.TienDo !== undefined) {
            updateData.TienDo = Math.max(0, Math.min(100, parseInt(updateData.TienDo, 10)));
        }

        const updatedProgress = await LearningHistory.findByIdAndUpdate(
            id,
            updateData,
            { new: true, runValidators: true }
        )
            .populate('BaiHocID', 'TenBaiHoc CapDo LoaiBaiHoc')
            .populate('NguoiHocID', 'HoTen Email');

        if (!updatedProgress) {
            return res.status(404).json({ message: "Không tìm thấy tiến độ." });
        }

        res.json({ 
            message: "Cập nhật tiến độ thành công.", 
            data: updatedProgress 
        });
    } catch (error) {
        console.error("Lỗi khi cập nhật tiến độ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Xóa tiến độ 
router.delete("/admin/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        
        const deletedProgress = await LearningHistory.findByIdAndDelete(id);

        if (!deletedProgress) {
            return res.status(404).json({ message: "Không tìm thấy bản ghi tiến độ." });
        }

        res.json({ 
            message: "Xóa tiến độ thành công.",
            data: deletedProgress
        });
    } catch (error) {
        console.error("Lỗi khi thực hiện xóa tiến độ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Xóa nhiều tiến độ 
router.delete("/admin/bulk/delete", authenticateAdmin, async (req, res) => {
    try {
        const { ids } = req.body;

        if (!Array.isArray(ids) || ids.length === 0) {
            return res.status(400).json({ message: "Danh sách ID không hợp lệ." });
        }

        const result = await LearningHistory.deleteMany({ _id: { $in: ids } });

        res.json({ 
            message: `Đã xóa ${result.deletedCount} tiến độ.`,
            deletedCount: result.deletedCount
        });
    } catch (error) {
        console.error("Lỗi khi xóa nhiều tiến độ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// Xóa tất cả tiến độ của người dùng 
router.delete("/admin/user/:userID/clear", authenticateAdmin, async (req, res) => {
    try {
        const { userID } = req.params;

        const result = await LearningHistory.deleteMany({ NguoiHocID: userID });

        res.json({ 
            message: `Đã xóa ${result.deletedCount} tiến độ của người dùng.`,
            deletedCount: result.deletedCount
        });
    } catch (error) {
        console.error("Lỗi khi xóa tiến độ người dùng:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

export default router;
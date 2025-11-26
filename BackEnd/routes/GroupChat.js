import express from 'express';
import { authenticateUser, authenticateAdmin } from './auth.js';
import GroupChat from '../model/GroupChat.js';
import StudyGroup from '../model/StudyGroup.js';
import mongoose from 'mongoose';
import multer from 'multer';
import path from 'path';
import fs from 'fs';

const router = express.Router();

// File upload configuration
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const uploadPath = 'uploads/group-chats/';
        if (!fs.existsSync(uploadPath)) {
            fs.mkdirSync(uploadPath, { recursive: true });
        }
        cb(null, uploadPath);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
    fileFilter: (req, file, cb) => {
        const allowedTypes = /jpeg|jpg|png|gif|pdf|doc|docx|txt/;
        const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
        const mimetype = allowedTypes.test(file.mimetype);
        
        if (mimetype && extname) {
            return cb(null, true);
        } else {
            cb(new Error('File không hợp lệ. Chỉ chấp nhận: image, pdf, doc, txt'));
        }
    }
});

// Kiểm tra user có phải thành viên của nhóm không
const isMember = async (req, res, next) => {
    try {
        const userId = req.user._id || req.user.id;
        const { groupID } = req.params;

        if (!mongoose.Types.ObjectId.isValid(groupID)) {
            return res.status(400).json({ message: "ID nhóm không hợp lệ." });
        }

        const group = await StudyGroup.findById(groupID);
        if (!group) {
            return res.status(404).json({ message: "Nhóm không tồn tại." });
        }

        if (!group.isMember(userId)) {
            return res.status(403).json({ 
                message: "Bạn không phải là thành viên của nhóm này." 
            });
        }

        req.group = group;
        next();
    } catch (error) {
        console.error("Error checking member:", error);
        return res.status(500).json({ message: "Lỗi server." });
    }
};

// API Gửi tin nhắn text
router.post("/:groupID", authenticateUser, isMember, async (req, res) => {
    try {
        const { groupID } = req.params;
        const userId = req.user._id || req.user.id;
        const { content, reply_to } = req.body;

        if (!content || content.trim() === '') {
            return res.status(400).json({ message: "Nội dung tin nhắn không được để trống." });
        }

        if (reply_to && mongoose.Types.ObjectId.isValid(reply_to)) {
            const replyMessage = await GroupChat.findOne({ 
                _id: reply_to, 
                group_id: groupID,
                is_deleted: false 
            });
            if (!replyMessage) {
                return res.status(404).json({ message: "Tin nhắn được trả lời không tồn tại." });
            }
        }

        const newMessage = await GroupChat.create({
            group_id: groupID,
            user_id: userId,
            content: content.trim(),
            type: 'TEXT',
            reply_to: reply_to || null
        });

        const populatedMessage = await GroupChat.findById(newMessage._id)
            .populate('user_id', 'full_name username avatar')
            .populate({
                path: 'reply_to',
                select: 'content user_id created_at',
                populate: {
                    path: 'user_id',
                    select: 'full_name username'
                }
            })
            .lean();

        res.status(201).json({
            message: "Gửi tin nhắn thành công.",
            data: populatedMessage
        });

    } catch (error) {
        console.error("Lỗi gửi tin nhắn:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// API Gửi tin nhắn có file đính kèm
router.post("/:groupID/upload", authenticateUser, isMember, upload.single('file'), async (req, res) => {
    try {
        const { groupID } = req.params;
        const userId = req.user._id || req.user.id;
        const { content } = req.body;

        if (!req.file) {
            return res.status(400).json({ message: "Vui lòng chọn file để upload." });
        }

        const fileType = req.file.mimetype.startsWith('image/') ? 'IMAGE' : 'FILE';

        const newMessage = await GroupChat.create({
            group_id: groupID,
            user_id: userId,
            content: content || 'Đã gửi file đính kèm',
            type: fileType,
            attachment_url: `/uploads/group-chats/${req.file.filename}`,
            attachment_name: req.file.originalname,
            attachment_size: req.file.size
        });

        const populatedMessage = await GroupChat.findById(newMessage._id)
            .populate('user_id', 'full_name username avatar')
            .lean();

        res.status(201).json({
            message: "Upload file thành công.",
            data: populatedMessage
        });

    } catch (error) {
        console.error("Lỗi upload file:", error);
        
        // Xóa file nếu có lỗi
        if (req.file) {
            fs.unlinkSync(req.file.path);
        }
        
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// API Lấy danh sách tin nhắn của nhóm 
router.get("/:groupID", authenticateUser, isMember, async (req, res) => {
    try {
        const { groupID } = req.params;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 50;
        const skip = (page - 1) * limit;

        const filter = { 
            group_id: groupID,
            is_deleted: false 
        };

        const [messages, total] = await Promise.all([
            GroupChat.find(filter)
                .populate('user_id', 'full_name username avatar')
                .populate({
                    path: 'reply_to',
                    select: 'content user_id created_at',
                    populate: {
                        path: 'user_id',
                        select: 'full_name username'
                    }
                })
                .sort({ created_at: -1 }) 
                .limit(limit)
                .skip(skip)
                .lean(),
            GroupChat.countDocuments(filter)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / limit),
            currentPage: page,
            data: messages.reverse() 
        });

    } catch (error) {
        console.error("Lỗi lấy tin nhắn:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// API Lấy tin nhắn mới nhất 
router.get("/:groupID/latest", authenticateUser, isMember, async (req, res) => {
    try {
        const { groupID } = req.params;
        const { after } = req.query; 

        const filter = { 
            group_id: groupID,
            is_deleted: false
        };

        if (after) {
            const afterDate = new Date(parseInt(after));
            filter.created_at = { $gt: afterDate };
        }

        const messages = await GroupChat.find(filter)
            .populate('user_id', 'full_name username avatar')
            .populate({
                path: 'reply_to',
                select: 'content user_id created_at',
                populate: {
                    path: 'user_id',
                    select: 'full_name username'
                }
            })
            .sort({ created_at: 1 })
            .limit(100) 
            .lean();

        res.json({
            count: messages.length,
            data: messages
        });

    } catch (error) {
        console.error("Lỗi lấy tin nhắn mới:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// API Chỉnh sửa tin nhắn
router.put("/:groupID/:messageID", authenticateUser, isMember, async (req, res) => {
    try {
        const { groupID, messageID } = req.params;
        const userId = req.user._id || req.user.id;
        const { content } = req.body;

        if (!content || content.trim() === '') {
            return res.status(400).json({ message: "Nội dung tin nhắn không được để trống." });
        }

        if (!mongoose.Types.ObjectId.isValid(messageID)) {
            return res.status(400).json({ message: "ID tin nhắn không hợp lệ." });
        }

        const message = await GroupChat.findOne({
            _id: messageID,
            group_id: groupID,
            is_deleted: false
        });

        if (!message) {
            return res.status(404).json({ message: "Tin nhắn không tồn tại." });
        }

        if (!message.canModify(userId)) {
            return res.status(403).json({ 
                message: "Bạn chỉ có thể chỉnh sửa tin nhắn của chính mình." 
            });
        }

        // chỉnh sửa tin nhắn trong vòng 15 phút
        const timeDiff = Date.now() - message.created_at.getTime();
        const fifteenMinutes = 15 * 60 * 1000;
        
        if (timeDiff > fifteenMinutes) {
            return res.status(400).json({ 
                message: "Chỉ có thể chỉnh sửa tin nhắn trong vòng 15 phút sau khi gửi." 
            });
        }

        message.content = content.trim();
        message.is_edited = true;
        message.edited_at = new Date();
        await message.save();

        const updatedMessage = await GroupChat.findById(messageID)
            .populate('user_id', 'full_name username avatar')
            .lean();

        res.json({
            message: "Chỉnh sửa tin nhắn thành công.",
            data: updatedMessage
        });

    } catch (error) {
        console.error("Lỗi chỉnh sửa tin nhắn:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// API Xóa tin nhắn 
router.delete("/:groupID/:messageID", authenticateUser, isMember, async (req, res) => {
    try {
        const { groupID, messageID } = req.params;
        const userId = req.user._id || req.user.id;

        if (!mongoose.Types.ObjectId.isValid(messageID)) {
            return res.status(400).json({ message: "ID tin nhắn không hợp lệ." });
        }

        const message = await GroupChat.findOne({
            _id: messageID,
            group_id: groupID,
            is_deleted: false
        });

        if (!message) {
            return res.status(404).json({ message: "Tin nhắn không tồn tại." });
        }

        const group = req.group;
        const isAdmin = group.isAdmin(userId) || group.isCreator(userId);

        // User chỉ xóa được tin nhắn của mình
        // Admin có thể xóa bất kỳ tin nhắn nào
        if (!message.canModify(userId) && !isAdmin) {
            return res.status(403).json({ 
                message: "Bạn không có quyền xóa tin nhắn này." 
            });
        }

        message.is_deleted = true;
        message.content = '[Tin nhắn đã bị xóa]';
        await message.save();

        res.json({ message: "Xóa tin nhắn thành công." });

    } catch (error) {
        console.error("Lỗi xóa tin nhắn:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// API Tìm kiếm tin nhắn trong nhóm
router.get("/:groupID/search", authenticateUser, isMember, async (req, res) => {
    try {
        const { groupID } = req.params;
        const { keyword, user_id, type, from_date, to_date } = req.query;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const filter = { 
            group_id: groupID,
            is_deleted: false
        };

        if (keyword) {
            filter.content = { $regex: keyword, $options: 'i' };
        }

        if (user_id && mongoose.Types.ObjectId.isValid(user_id)) {
            filter.user_id = user_id;
        }

        if (type && ['TEXT', 'IMAGE', 'FILE'].includes(type)) {
            filter.type = type;
        }

        if (from_date || to_date) {
            filter.created_at = {};
            if (from_date) filter.created_at.$gte = new Date(from_date);
            if (to_date) filter.created_at.$lte = new Date(to_date);
        }

        const [messages, total] = await Promise.all([
            GroupChat.find(filter)
                .populate('user_id', 'full_name username avatar')
                .sort({ created_at: -1 })
                .limit(limit)
                .skip(skip)
                .lean(),
            GroupChat.countDocuments(filter)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / limit),
            currentPage: page,
            data: messages
        });

    } catch (error) {
        console.error("Lỗi tìm kiếm tin nhắn:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// API Thống kê tin nhắn của nhóm
router.get("/:groupID/statistics", authenticateUser, isMember, async (req, res) => {
    try {
        const { groupID } = req.params;

        const [totalMessages, textMessages, imageMessages, fileMessages, topUsers] = await Promise.all([
            GroupChat.countDocuments({ group_id: groupID, is_deleted: false }),
            GroupChat.countDocuments({ group_id: groupID, type: 'TEXT', is_deleted: false }),
            GroupChat.countDocuments({ group_id: groupID, type: 'IMAGE', is_deleted: false }),
            GroupChat.countDocuments({ group_id: groupID, type: 'FILE', is_deleted: false }),
            GroupChat.aggregate([
                { 
                    $match: { 
                        group_id: new mongoose.Types.ObjectId(groupID), 
                        is_deleted: false 
                    } 
                },
                { 
                    $group: { 
                        _id: '$user_id', 
                        count: { $sum: 1 } 
                    } 
                },
                { $sort: { count: -1 } },
                { $limit: 5 },
                {
                    $lookup: {
                        from: 'users',
                        localField: '_id',
                        foreignField: '_id',
                        as: 'user'
                    }
                },
                { $unwind: '$user' },
                {
                    $project: {
                        user_id: '$_id',
                        full_name: '$user.full_name',
                        username: '$user.username',
                        avatar: '$user.avatar',
                        message_count: '$count'
                    }
                }
            ])
        ]);

        const stats = {
            total_messages: totalMessages,
            text_messages: textMessages,
            image_messages: imageMessages,
            file_messages: fileMessages,
            top_contributors: topUsers
        };

        res.json({ data: stats });

    } catch (error) {
        console.error("Lỗi thống kê tin nhắn:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

// API Xóa tất cả tin nhắn của nhóm (Admin hệ thống)
router.delete("/admin/:groupID/clear", authenticateAdmin, async (req, res) => {
    try {
        const { groupID } = req.params;

        if (!mongoose.Types.ObjectId.isValid(groupID)) {
            return res.status(400).json({ message: "ID nhóm không hợp lệ." });
        }

        const result = await GroupChat.updateMany(
            { group_id: groupID },
            { 
                is_deleted: true,
                content: '[Tin nhắn đã bị xóa bởi admin]'
            }
        );

        res.json({ 
            message: `Đã xóa ${result.modifiedCount} tin nhắn.`,
            count: result.modifiedCount
        });

    } catch (error) {
        console.error("Lỗi xóa tin nhắn:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

export default router;
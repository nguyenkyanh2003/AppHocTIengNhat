import StudyGroup from '../../../model/StudyGroup.js';
import User from '../../../model/User.js';
import GroupChat from '../../../model/GroupChat.js';
import mongoose from 'mongoose';

const populateUserFields = 'full_name display_name username user_name HoTen TenDangNhap email Email avatar AnhDaiDien';

// Kiểm tra user có phải admin của nhóm không
export const isGroupAdmin = async (req, res, next) => {
    try {
        const userId = req.user._id;
        const { groupID } = req.params;

        if (!mongoose.Types.ObjectId.isValid(groupID)) {
            return res.status(400).json({ message: "ID nhóm không hợp lệ." });
        }

        const group = await StudyGroup.findById(groupID);
        if (!group) {
            return res.status(404).json({ message: "Nhóm không tồn tại." });
        }

        if (!group.isAdmin(userId) && !group.isCreator(userId)) {
            return res.status(403).json({ 
                message: "Bạn không có quyền truy cập tài nguyên này." 
            });
        }

        req.group = group; 
        next();
    } catch (error) {
        console.error("Error checking group admin:", error);
        return res.status(500).json({ message: "Lỗi server." });
    }
};

//  USER ROUTES 

// API Tạo nhóm mới
export const createGroup = async (req, res) => {
    try {
        const { name, description, level, avatar, is_private, max_members } = req.body;
        const userId = req.user._id;

        if (!name) {
            return res.status(400).json({ message: "Tên nhóm không được để trống." });
        }

        // Kiểm tra tên nhóm đã tồn tại chưa
        const existingGroup = await StudyGroup.findOne({ name, is_active: true });
        if (existingGroup) {
            return res.status(400).json({ message: "Tên nhóm đã tồn tại." });
        }

        const newGroup = await StudyGroup.create({
            name,
            description,
            level: level || 'ALL',
            avatar,
            creator_id: userId,
            is_private: is_private || false,
            max_members: max_members || 50,
            members: [{
                user_id: userId,
                role: 'admin',
                joined_at: new Date()
            }],
            member_count: 1
        });

        const populatedGroup = await StudyGroup.findById(newGroup._id)
            .populate('creator_id', populateUserFields)
            .populate('members.user_id', populateUserFields);

        res.status(201).json({
            message: "Tạo nhóm thành công.",
            data: populatedGroup
        });

    } catch (error) {
        console.error("Error creating group:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// API Lấy danh sách tất cả các nhóm (có phân trang, tìm kiếm, lọc)
export const listGroups = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;
        
        const { search, level, is_private } = req.query;
        
        const filter = { is_active: true };
        
        if (level) filter.level = level;
        if (is_private !== undefined) filter.is_private = is_private === 'true';
        
        if (search) {
            filter.$text = { $search: search };
        }

        const [groups, total] = await Promise.all([
            StudyGroup.find(filter)
                .populate('creator_id', populateUserFields)
                .select('-members') 
                .sort({ createdAt: -1 })
                .limit(limit)
                .skip(skip)
                .lean(),
            StudyGroup.countDocuments(filter)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / limit),
            currentPage: page,
            data: groups
        });

    } catch (error) {
        console.error("Lỗi khi lấy danh sách nhóm:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// API Lấy danh sách nhóm mà user đã tham gia
export const listMyGroups = async (req, res) => {
    try {
        const userId = req.user._id;

        const groups = await StudyGroup.find({
            'members.user_id': userId,
            is_active: true
        })
        .populate('creator_id', populateUserFields)
        .select('-members')
        .sort({ createdAt: -1 })
        .lean();

        res.json({
            count: groups.length,
            data: groups
        });

    } catch (error) {
        console.error("Lỗi khi lấy danh sách nhóm:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// API Lấy thông tin chi tiết 1 nhóm
export const getGroup = async (req, res) => {
    try {
        const { groupID } = req.params;
        const userId = req.user._id;

        if (!mongoose.Types.ObjectId.isValid(groupID)) {
            return res.status(400).json({ message: "ID nhóm không hợp lệ." });
        }

        const group = await StudyGroup.findOne({ 
            _id: groupID, 
            is_active: true 
        })
        .populate('creator_id', populateUserFields)
        .populate('members.user_id', populateUserFields)
        .lean();

        if (!group) {
            return res.status(404).json({ message: "Nhóm không tồn tại." });
        }
        // nếu nhóm là private thì chỉ thành viên mới xem được
        if (group.is_private) {
            const isMember = group.members.some(
                m => m.user_id._id.toString() === userId.toString()
            );
            if (!isMember) {
                return res.status(403).json({ 
                    message: "Nhóm này ở chế độ riêng tư." 
                });
            }
        }
        // thêm thông tin user
        const currentMember = group.members.find(
            m => m.user_id._id.toString() === userId.toString()
        );

        res.json({
            data: {
                ...group,
                current_user_role: currentMember?.role || null,
                is_member: !!currentMember
            }
        });

    } catch (error) {
        console.error("Lỗi khi lấy thông tin nhóm:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API Cập nhật thông tin nhóm (chỉ admin)
export const updateGroup = async (req, res) => {
    try {
        const { groupID } = req.params;
        const { name, description, level, avatar, is_private, max_members } = req.body;

        const updateData = {};
        if (name) {
            // Kiểm tra tên mới có trùng không
            const existing = await StudyGroup.findOne({ 
                name, 
                _id: { $ne: groupID },
                is_active: true 
            });
            if (existing) {
                return res.status(400).json({ message: "Tên nhóm đã tồn tại." });
            }
            updateData.name = name;
        }
        if (description !== undefined) updateData.description = description;
        if (level) updateData.level = level;
        if (avatar) updateData.avatar = avatar;
        if (is_private !== undefined) updateData.is_private = is_private;
        if (max_members) updateData.max_members = max_members;

        const updatedGroup = await StudyGroup.findByIdAndUpdate(
            groupID,
            updateData,
            { new: true, runValidators: true }
        )
        .populate('creator_id', populateUserFields)
        .populate('members.user_id', populateUserFields);

        res.json({
            message: "Cập nhật thông tin nhóm thành công.",
            data: updatedGroup
        });

    } catch (error) {
        console.error("Lỗi cập nhật thông tin nhóm:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// API Xóa nhóm 
export const deleteGroup = async (req, res) => {
    try {
        const { groupID } = req.params;
        const userId = req.user._id;

        if (!mongoose.Types.ObjectId.isValid(groupID)) {
            return res.status(400).json({ message: "ID nhóm không hợp lệ." });
        }

        const group = await StudyGroup.findById(groupID);
        if (!group) {
            return res.status(404).json({ message: "Nhóm không tồn tại." });
        }

        if (!group.isCreator(userId)) {
            return res.status(403).json({ 
                message: "Chỉ người tạo nhóm mới có thể xóa nhóm." 
            });
        }

        // Soft delete
        group.is_active = false;
        await group.save();

        res.json({ message: "Xóa nhóm thành công." });

    } catch (error) {
        console.error("Lỗi khi xóa nhóm:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

//  QUẢN LÝ THÀNH VIÊN 

// API Tham gia nhóm
export const joinGroup = async (req, res) => {
    try {
        const { groupID } = req.params;
        const userId = req.user._id;

        if (!mongoose.Types.ObjectId.isValid(groupID)) {
            return res.status(400).json({ message: "ID nhóm không hợp lệ." });
        }

        const group = await StudyGroup.findOne({ 
            _id: groupID, 
            is_active: true 
        });

        if (!group) {
            return res.status(404).json({ message: "Nhóm không tồn tại." });
        }

        if (group.is_private) {
            return res.status(403).json({ 
                message: "Nhóm này ở chế độ riêu tư. Vui lòng liên hệ admin để được mời." 
            });
        }

        try {
            group.addMember(userId, 'member');
            await group.save();

            // Lấy thông tin user để hiển thị tên
            const user = await User.findById(userId);
            const userName = user?.full_name || user?.HoTen || user?.username || user?.TenDangNhap || 'Thành viên';

            // Tạo system message để thông báo thành viên mới tham gia
            await GroupChat.create({
                group_id: groupID,
                user_id: userId,
                content: `${userName} đã tham gia nhóm`,
                type: 'SYSTEM'
            });

            const updatedGroup = await StudyGroup.findById(groupID)
                .populate('members.user_id', populateUserFields);

            res.status(201).json({
                message: "Tham gia nhóm thành công.",
                data: updatedGroup
            });

        } catch (error) {
            if (error.message.includes('đã là thành viên')) {
                return res.status(400).json({ message: error.message });
            }
            if (error.message.includes('số lượng')) {
                return res.status(400).json({ message: error.message });
            }
            throw error;
        }

    } catch (error) {
        console.error("Lỗi khi tham gia nhóm:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// API Rời nhóm
export const leaveGroup = async (req, res) => {
    try {
        const { groupID } = req.params;
        const userId = req.user._id;

        if (!mongoose.Types.ObjectId.isValid(groupID)) {
            return res.status(400).json({ message: "ID nhóm không hợp lệ." });
        }

        const group = await StudyGroup.findById(groupID);
        if (!group) {
            return res.status(404).json({ message: "Nhóm không tồn tại." });
        }

        if (group.isCreator(userId)) {
            return res.status(400).json({ 
                message: "Người tạo nhóm không thể rời nhóm. Bạn chỉ có thể xóa nhóm." 
            });
        }

        try {
            group.removeMember(userId);
            await group.save();

            res.json({ message: "Rời nhóm thành công." });

        } catch (error) {
            if (error.message.includes('không phải là thành viên')) {
                return res.status(404).json({ message: error.message });
            }
            throw error;
        }

    } catch (error) {
        console.error("Lỗi khi rời nhóm:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// API Kick thành viên (admin)
export const kickMember = async (req, res) => {
    try {
        const { groupID, userID } = req.params;
        const currentUserId = req.user._id;

        if (!mongoose.Types.ObjectId.isValid(userID)) {
            return res.status(400).json({ message: "ID người dùng không hợp lệ." });
        }

        const group = req.group; // Từ middleware

        if (currentUserId.toString() === userID) {
            return res.status(400).json({ 
                message: "Bạn không thể tự kick chính mình." 
            });
        }

        if (group.isCreator(userID)) {
            return res.status(400).json({ 
                message: "Không thể kick người tạo nhóm." 
            });
        }

        try {
            group.removeMember(userID);
            await group.save();

            res.json({ message: "Đã kick thành viên ra khỏi nhóm." });

        } catch (error) {
            if (error.message.includes('không phải là thành viên')) {
                return res.status(404).json({ message: error.message });
            }
            throw error;
        }

    } catch (error) {
        console.error("Lỗi khi kick thành viên:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// API Thăng chức thành viên (admin)
export const promoteMember = async (req, res) => {
    try {
        const { groupID, userID } = req.params;

        if (!mongoose.Types.ObjectId.isValid(userID)) {
            return res.status(400).json({ message: "ID người dùng không hợp lệ." });
        }

        const group = req.group;

        const member = group.members.find(
            m => m.user_id.toString() === userID
        );

        if (!member) {
            return res.status(404).json({ 
                message: "Người dùng này không phải là thành viên của nhóm." 
            });
        }

        if (member.role === 'admin') {
            return res.status(400).json({ 
                message: "Người dùng đã là admin rồi." 
            });
        }

        member.role = 'admin';
        await group.save();

        const updatedGroup = await StudyGroup.findById(groupID)
            .populate('members.user_id', populateUserFields);

        res.json({
            message: "Thăng chức thành viên thành công.",
            data: updatedGroup
        });

    } catch (error) {
        console.error("Lỗi thăng chức:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API Hạ chức admin xuống member (chỉ creator)
export const demoteMember = async (req, res) => {
    try {
        const { groupID, userID } = req.params;
        const currentUserId = req.user._id;

        if (!mongoose.Types.ObjectId.isValid(groupID) || !mongoose.Types.ObjectId.isValid(userID)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        const group = await StudyGroup.findById(groupID);
        if (!group) {
            return res.status(404).json({ message: "Nhóm không tồn tại." });
        }

        if (!group.isCreator(currentUserId)) {
            return res.status(403).json({ 
                message: "Chỉ người tạo nhóm mới có thể hạ chức admin." 
            });
        }

        if (group.isCreator(userID)) {
            return res.status(400).json({ 
                message: "Không thể hạ chức người tạo nhóm." 
            });
        }

        const member = group.members.find(
            m => m.user_id.toString() === userID
        );

        if (!member) {
            return res.status(404).json({ 
                message: "Người dùng này không phải là thành viên của nhóm." 
            });
        }

        if (member.role === 'member') {
            return res.status(400).json({ 
                message: "Người dùng đã là member rồi." 
            });
        }

        member.role = 'member';
        await group.save();

        const updatedGroup = await StudyGroup.findById(groupID)
            .populate('members.user_id', populateUserFields);

        res.json({
            message: "Hạ chức thành viên thành công.",
            data: updatedGroup
        });

    } catch (error) {
        console.error("Lỗi hạ chức:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API Mời người dùng vào nhóm private (admin)
export const inviteMember = async (req, res) => {
    try {
        const { groupID, userID } = req.params;

        if (!mongoose.Types.ObjectId.isValid(userID)) {
            return res.status(400).json({ message: "ID người dùng không hợp lệ." });
        }

        const user = await User.findById(userID);
        if (!user) {
            return res.status(404).json({ message: "Người dùng không tồn tại." });
        }

        const group = req.group;

        try {
            group.addMember(userID, 'member');
            await group.save();

            // Tạo system message để thông báo thành viên mới tham gia
            const userName = user.full_name || user.HoTen || user.username || user.TenDangNhap || 'Thành viên';
            await GroupChat.create({
                group_id: groupID,
                user_id: userID,
                content: `${userName} đã tham gia nhóm`,
                type: 'SYSTEM'
            });

            res.status(201).json({
                message: `Đã mời ${user.full_name || user.HoTen || user.username || user.TenDangNhap} vào nhóm.`,
                data: { user_id: userID, group_id: groupID }
            });

        } catch (error) {
            if (error.message.includes('đã là thành viên')) {
                return res.status(400).json({ message: error.message });
            }
            if (error.message.includes('số lượng')) {
                return res.status(400).json({ message: error.message });
            }
            throw error;
        }

    } catch (error) {
        console.error("Lỗi mời thành viên:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// API Thống kê nhóm
export const getGroupStats = async (req, res) => {
    try {
        const { groupID } = req.params;

        if (!mongoose.Types.ObjectId.isValid(groupID)) {
            return res.status(400).json({ message: "ID nhóm không hợp lệ." });
        }

        const group = await StudyGroup.findById(groupID);
        if (!group) {
            return res.status(404).json({ message: "Nhóm không tồn tại." });
        }

        const startOfToday = new Date();
        startOfToday.setHours(0, 0, 0, 0);

        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        // Tính thống kê tin nhắn và người dùng hoạt động
        const [totalMessages, todayMessages, activeLogins] = await Promise.all([
            GroupChat.countDocuments({ group_id: groupID, is_deleted: false }),
            GroupChat.countDocuments({ group_id: groupID, is_deleted: false, created_at: { $gte: startOfToday } }),
            User.countDocuments({
                _id: { $in: group.members.map(m => m.user_id) },
                LanDangNhapCuoi: { $gte: startOfToday }
            })
        ]);

        const stats = {
            total_messages: totalMessages,
            today_messages: todayMessages,
            active_members: activeLogins,
            member_count: group.member_count,
            admin_count: group.members.filter(m => m.role === 'admin').length,
            created_at: group.createdAt,
            level: group.level,
            is_private: group.is_private
        };

        res.json({ data: stats });

    } catch (error) {
        console.error('Lỗi lấy thống kê:', error);
        res.status(500).json({ message: 'Lỗi máy chủ.', error: error.message });
    }
};
//  ADMIN ROUTES
// API Lấy tất cả nhóm (Admin hệ thống)
export const listAdminGroups = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const [groups, total] = await Promise.all([
            StudyGroup.find()
                .populate('creator_id', populateUserFields)
                .select('-members')
                .sort({ createdAt: -1 })
                .limit(limit)
                .skip(skip)
                .lean(),
            StudyGroup.countDocuments()
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / limit),
            currentPage: page,
            data: groups
        });

    } catch (error) {
        console.error("Lỗi khi admin lấy nhóm:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API Xóa nhóm (Admin hệ thống - hard delete)
export const deleteAdminGroup = async (req, res) => {
    try {
        const { groupID } = req.params;

        if (!mongoose.Types.ObjectId.isValid(groupID)) {
            return res.status(400).json({ message: "ID nhóm không hợp lệ." });
        }

        const group = await StudyGroup.findByIdAndDelete(groupID);
        if (!group) {
            return res.status(404).json({ message: "Nhóm không tồn tại." });
        }

        res.json({ message: "(Admin) Đã xóa nhóm thành công." });

    } catch (error) {
        console.error("Lỗi admin xóa nhóm:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API Thống kê tổng quan (Admin)
export const getAdminGroupStatistics = async (req, res) => {
    try {
        const [totalGroups, activeGroups, privateGroups, totalMembers] = await Promise.all([
            StudyGroup.countDocuments(),
            StudyGroup.countDocuments({ is_active: true }),
            StudyGroup.countDocuments({ is_private: true }),
            StudyGroup.aggregate([
                { $group: { _id: null, total: { $sum: '$member_count' } } }
            ])
        ]);

        const stats = {
            total_groups: totalGroups,
            active_groups: activeGroups,
            inactive_groups: totalGroups - activeGroups,
            private_groups: privateGroups,
            public_groups: totalGroups - privateGroups,
            total_members: totalMembers[0]?.total || 0,
            avg_members_per_group: totalGroups > 0 
                ? ((totalMembers[0]?.total || 0) / totalGroups).toFixed(2) 
                : 0
        };

        res.json({ data: stats });

    } catch (error) {
        console.error("Lỗi lấy thống kê:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// API Upload group avatar
export const updateGroupAvatar = async (req, res) => {
    try {
        const { groupID } = req.params;

        if (!req.file) {
            return res.status(400).json({ message: "Vui lòng chọn file ảnh" });
        }

        // Lấy URL của avatar (sử dụng relative path)
        const avatarUrl = `/uploads/group-avatars/${req.file.filename}`;

        // Cập nhật avatar trong database
        const group = await StudyGroup.findByIdAndUpdate(
            groupID,
            { avatar: avatarUrl },
            { new: true }
        );

        if (!group) {
            return res.status(404).json({ message: "Không tìm thấy nhóm" });
        }

        res.json({
            message: "Cập nhật avatar nhóm thành công",
            data: group
        });
    } catch (error) {
        console.error("Lỗi upload avatar nhóm:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};


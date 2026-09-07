import Report from "../../../model/Report.js";

const getPagination = (query, defaultLimit) => {
    const page = Math.max(parseInt(query.page || '1', 10), 1);
    const limit = Math.min(Math.max(parseInt(query.limit || `${defaultLimit}`, 10), 1), 100);
    return { page, limit, skip: (page - 1) * limit };
};


// USER ROUTES

// Tạo báo cáo mới
export const postCreate = async (req, res) => {
    try {
        const userId = req.user._id;
        const { type, related_id, related_type, title, description, priority } = req.body;
        
        if (!type || !title || !description) {
            return res.status(400).json({ 
                message: "Vui lòng nhập đầy đủ thông tin (type, title, description)." 
            });
        }

        const newReport = await Report.create({
            user_id: userId,
            type,
            related_id: related_id || null,
            related_type: related_type || null,
            title,
            description,
            priority: priority || 'medium',
            status: 'pending',
            admin_response: null,
            resolved_at: null
        });

        res.status(201).json({
            message: "Gửi báo cáo thành công. Chúng tôi sẽ xử lý trong thời gian sớm nhất.",
            data: newReport
        });
    } catch (error) {
        console.error("Lỗi tạo báo cáo:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Lấy danh sách báo cáo của user
export const getMyReports = async (req, res) => {
    try {
        const userId = req.user._id;
        const { status } = req.query;
        const { page, limit, skip } = getPagination(req.query, 10);

        const query = { user_id: userId };
        if (status) query.status = status;

        const [reports, total] = await Promise.all([
            Report.find(query)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit)
                .lean(),
            Report.countDocuments(query)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / limit),
            currentPage: page,
            data: reports
        });
    } catch (error) {
        console.error("Lỗi lấy danh sách báo cáo:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Lấy chi tiết báo cáo
export const getById = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;
        const isAdmin = req.user?.VaiTro === 'admin';

        const query = isAdmin ? { _id: id } : { _id: id, user_id: userId };

        const report = await Report.findOne(query)
            .populate('user_id', 'HoTen Email')
            .lean();

        if (!report) {
            return res.status(404).json({ message: "Không tìm thấy báo cáo." });
        }

        res.json({ data: report });
    } catch (error) {
        console.error("Lỗi lấy chi tiết báo cáo:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Hủy báo cáo (chỉ khi pending)
export const deleteById = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;

        const report = await Report.findOne({ _id: id, user_id: userId });

        if (!report) {
            return res.status(404).json({ message: "Không tìm thấy báo cáo." });
        }

        if (report.status !== 'pending') {
            return res.status(400).json({ 
                message: "Chỉ có thể hủy báo cáo đang chờ xử lý." 
            });
        }

        await Report.findByIdAndDelete(id);

        res.json({ message: "Hủy báo cáo thành công." });
    } catch (error) {
        console.error("Lỗi hủy báo cáo:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// ADMIN ROUTES

// Lấy tất cả báo cáo (admin)
export const getAdminAll = async (req, res) => {
    try {
        const { status, type, priority, user_id } = req.query;
        const { page, limit, skip } = getPagination(req.query, 20);

        const query = {};
        if (status) query.status = status;
        if (type) query.type = type;
        if (priority) query.priority = priority;
        if (user_id) query.user_id = user_id;

        const [reports, total] = await Promise.all([
            Report.find(query)
                .populate('user_id', 'HoTen Email')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit)
                .lean(),
            Report.countDocuments(query)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / limit),
            currentPage: page,
            data: reports
        });
    } catch (error) {
        console.error("Lỗi lấy danh sách báo cáo (admin):", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Cập nhật trạng thái báo cáo (admin)
export const putAdminByIdStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status, admin_response } = req.body;

        if (!status || !['pending', 'in_progress', 'resolved', 'rejected'].includes(status)) {
            return res.status(400).json({ 
                message: "Status phải là: pending, in_progress, resolved, hoặc rejected." 
            });
        }

        const updateData = { status };
        
        if (admin_response) {
            updateData.admin_response = admin_response;
        }
        
        if (status === 'resolved') {
            updateData.resolved_at = new Date();
        }

        const updatedReport = await Report.findByIdAndUpdate(
            id,
            updateData,
            { new: true }
        ).populate('user_id', 'HoTen Email');

        if (!updatedReport) {
            return res.status(404).json({ message: "Không tìm thấy báo cáo." });
        }

        res.json({
            message: "Cập nhật trạng thái báo cáo thành công",
            data: updatedReport
        });
    } catch (error) {
        console.error("Lỗi cập nhật trạng thái báo cáo:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Cập nhật độ ưu tiên (admin)
export const putAdminByIdPriority = async (req, res) => {
    try {
        const { id } = req.params;
        const { priority } = req.body;

        if (!priority || !['low', 'medium', 'high', 'urgent'].includes(priority)) {
            return res.status(400).json({ 
                message: "Priority phải là: low, medium, high, hoặc urgent." 
            });
        }

        const updatedReport = await Report.findByIdAndUpdate(
            id,
            { priority },
            { new: true }
        );

        if (!updatedReport) {
            return res.status(404).json({ message: "Không tìm thấy báo cáo." });
        }

        res.json({
            message: "Cập nhật độ ưu tiên thành công",
            data: updatedReport
        });
    } catch (error) {
        console.error("Lỗi cập nhật độ ưu tiên:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Xóa báo cáo (admin)
export const deleteAdminById = async (req, res) => {
    try {
        const { id } = req.params;

        const deletedReport = await Report.findByIdAndDelete(id);

        if (!deletedReport) {
            return res.status(404).json({ message: "Không tìm thấy báo cáo." });
        }

        res.json({
            message: "Xóa báo cáo thành công",
            data: deletedReport
        });
    } catch (error) {
        console.error("Lỗi xóa báo cáo:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Xóa nhiều báo cáo (admin)
export const deleteAdminBulkDelete = async (req, res) => {
    try {
        const { ids } = req.body;
        
        if (!Array.isArray(ids) || ids.length === 0) {
            return res.status(400).json({ message: "Danh sách ID không hợp lệ." });
        }

        const result = await Report.deleteMany({ _id: { $in: ids } });

        res.json({
            message: `Đã xóa ${result.deletedCount} báo cáo.`,
            deletedCount: result.deletedCount
        });
    } catch (error) {
        console.error("Lỗi xóa nhiều báo cáo:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Thống kê báo cáo (admin)
export const getAdminStats = async (req, res) => {
    try {
        const [
            total,
            byStatus,
            byType,
            byPriority,
            recentReports,
            avgResolutionTime
        ] = await Promise.all([
            Report.countDocuments(),
            Report.aggregate([
                { $group: { _id: "$status", count: { $sum: 1 } } }
            ]),
            Report.aggregate([
                { $group: { _id: "$type", count: { $sum: 1 } } }
            ]),
            Report.aggregate([
                { $group: { _id: "$priority", count: { $sum: 1 } } }
            ]),
            Report.find()
                .populate('user_id', 'HoTen Email')
                .sort({ createdAt: -1 })
                .limit(10)
                .lean(),
            Report.aggregate([
                {
                    $match: {
                        status: 'resolved',
                        resolved_at: { $ne: null }
                    }
                },
                {
                    $project: {
                        resolutionTime: {
                            $subtract: ['$resolved_at', '$createdAt']
                        }
                    }
                },
                {
                    $group: {
                        _id: null,
                        avgTime: { $avg: '$resolutionTime' }
                    }
                }
            ])
        ]);

        // Convert milliseconds to hours
        const avgTimeInHours = avgResolutionTime[0]?.avgTime 
            ? (avgResolutionTime[0].avgTime / (1000 * 60 * 60)).toFixed(2)
            : 0;

        res.json({
            total,
            byStatus,
            byType,
            byPriority,
            recentReports,
            avgResolutionTimeHours: parseFloat(avgTimeInHours)
        });
    } catch (error) {
        console.error("Lỗi lấy thống kê báo cáo:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};



import mongoose from 'mongoose';
import Transaction from '../../../model/Transaction.js';

const STATUSES = ['pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded'];
const TYPES = ['SUBSCRIPTION', 'DEPOSIT', 'SPEND', 'REWARD'];
const PAYMENT_METHODS = ['BANK', 'MOMO', 'VNPAY', 'CARD', 'NONE'];

const pagination = (query, defaultLimit = 20) => {
    const page = Math.max(Number.parseInt(query.page || '1', 10), 1);
    const limit = Math.min(Math.max(Number.parseInt(query.limit || `${defaultLimit}`, 10), 1), 100);
    return { page, limit, skip: (page - 1) * limit };
};

const objectId = (value) => new mongoose.Types.ObjectId(value.toString());

const transactionInput = (body) => ({
    type: body.type || body.LoaiGiaoDich,
    amount: Number(body.amount ?? body.SoTien),
    currency: body.currency || 'VND',
    description: body.description ?? body.NoiDung,
    payment_method: body.payment_method || body.paymentMethod || body.PhuongThucThanhToan || 'NONE',
    payment_ref_id: body.payment_ref_id || body.paymentRefId,
    package_id: body.package_id || body.packageId,
    metadata: body.metadata || body.ThongTinThanhToan
});

const sendError = (res, error, label) => {
    console.error(label, error);
    if (error instanceof mongoose.Error.ValidationError || error?.name === 'CastError') {
        return res.status(400).json({ message: 'Dữ liệu giao dịch không hợp lệ.' });
    }
    return res.status(500).json({ message: 'Lỗi máy chủ.' });
};

export const getMyTransactions = async (req, res) => {
    try {
        const { page, limit, skip } = pagination(req.query, 10);
        const query = { user: req.user._id };
        if (req.query.status) query.status = req.query.status;
        if (req.query.type) query.type = req.query.type;
        const [transactions, total] = await Promise.all([
            Transaction.find(query).sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
            Transaction.countDocuments(query)
        ]);
        return res.json({ totalItems: total, totalPages: Math.ceil(total / limit), currentPage: page, data: transactions });
    } catch (error) {
        return sendError(res, error, 'Lỗi lấy lịch sử giao dịch:');
    }
};

export const getById = async (req, res) => {
    try {
        const transaction = await Transaction.findOne({ _id: req.params.id, user: req.user._id }).lean();
        if (!transaction) return res.status(404).json({ message: 'Không tìm thấy giao dịch.' });
        return res.json({ data: transaction });
    } catch (error) {
        return sendError(res, error, 'Lỗi lấy chi tiết giao dịch:');
    }
};

export const postCreate = async (req, res) => {
    try {
        const input = transactionInput(req.body);
        if (!TYPES.includes(input.type)) {
            return res.status(400).json({ message: `Loại giao dịch phải là: ${TYPES.join(', ')}.` });
        }
        if (!Number.isFinite(input.amount) || input.amount <= 0) {
            return res.status(400).json({ message: 'Số tiền phải lớn hơn 0.' });
        }
        if (!PAYMENT_METHODS.includes(input.payment_method)) {
            return res.status(400).json({ message: 'Phương thức thanh toán không hợp lệ.' });
        }
        const transaction = await Transaction.create({ ...input, user: req.user._id, status: 'pending' });
        return res.status(201).json({ message: 'Đã tạo yêu cầu giao dịch.', data: transaction });
    } catch (error) {
        return sendError(res, error, 'Lỗi tạo giao dịch:');
    }
};

export const putByIdCancel = async (req, res) => {
    try {
        const transaction = await Transaction.findOne({ _id: req.params.id, user: req.user._id });
        if (!transaction) return res.status(404).json({ message: 'Không tìm thấy giao dịch.' });
        if (transaction.status !== 'pending') {
            return res.status(400).json({ message: 'Chỉ có thể hủy giao dịch đang chờ xử lý.' });
        }
        transaction.status = 'cancelled';
        await transaction.save();
        return res.json({ message: 'Hủy giao dịch thành công.', data: transaction });
    } catch (error) {
        return sendError(res, error, 'Lỗi hủy giao dịch:');
    }
};

export const getStatsMe = async (req, res) => {
    try {
        const user = objectId(req.user._id);
        const [totalTransactions, totalAmount, byStatus, byType, recentTransactions] = await Promise.all([
            Transaction.countDocuments({ user }),
            Transaction.aggregate([{ $match: { user, status: 'completed' } }, { $group: { _id: null, total: { $sum: '$amount' } } }]),
            Transaction.aggregate([{ $match: { user } }, { $group: { _id: '$status', count: { $sum: 1 }, total: { $sum: '$amount' } } }]),
            Transaction.aggregate([{ $match: { user } }, { $group: { _id: '$type', count: { $sum: 1 }, total: { $sum: '$amount' } } }]),
            Transaction.find({ user }).sort({ createdAt: -1 }).limit(5).lean()
        ]);
        return res.json({ totalTransactions, totalAmount: totalAmount[0]?.total || 0, byStatus, byType, recentTransactions });
    } catch (error) {
        return sendError(res, error, 'Lỗi thống kê giao dịch:');
    }
};

/** Dựng filter lịch sử giao dịch từ các giá trị đã tách sẵn, không đọc `req`. */
const buildTransactionFilter = ({ status, type, userId, startDate, endDate }) => {
    const filter = {};
    if (status) filter.status = status;
    if (type) filter.type = type;
    if (userId) filter.user = userId;
    if (startDate || endDate) {
        filter.createdAt = {};
        if (startDate) filter.createdAt.$gte = new Date(startDate);
        if (endDate) filter.createdAt.$lte = new Date(endDate);
    }
    return filter;
};

/** Một chỗ duy nhất trả danh sách: `find` và `countDocuments` dùng chung filter. */
const respondWithTransactionPage = async (res, { filter, page, limit, skip }) => {
    const [transactions, total] = await Promise.all([
        Transaction.find(filter).populate('user', 'HoTen Email TenDangNhap').sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
        Transaction.countDocuments(filter)
    ]);
    return res.json({ totalItems: total, totalPages: Math.ceil(total / limit), currentPage: page, data: transactions });
};

export const getAdminAll = async (req, res) => {
    try {
        const { page, limit, skip } = pagination(req.query);
        const filter = buildTransactionFilter(req.query);
        return await respondWithTransactionPage(res, { filter, page, limit, skip });
    } catch (error) {
        return sendError(res, error, 'Lỗi lấy danh sách giao dịch:');
    }
};

export const getAdminById = async (req, res) => {
    try {
        const transaction = await Transaction.findById(req.params.id).populate('user', 'HoTen Email SoDienThoai TenDangNhap').lean();
        if (!transaction) return res.status(404).json({ message: 'Không tìm thấy giao dịch.' });
        return res.json({ data: transaction });
    } catch (error) {
        return sendError(res, error, 'Lỗi lấy chi tiết giao dịch:');
    }
};

export const putAdminByIdStatus = async (req, res) => {
    try {
        const status = req.body.status || req.body.TrangThai;
        if (!STATUSES.includes(status)) {
            return res.status(400).json({ message: `Trạng thái phải là: ${STATUSES.join(', ')}.` });
        }
        const update = { status };
        if (req.body.notes || req.body.GhiChu) update.notes = req.body.notes || req.body.GhiChu;
        const transaction = await Transaction.findByIdAndUpdate(req.params.id, update, { new: true, runValidators: true })
            .populate('user', 'HoTen Email TenDangNhap');
        if (!transaction) return res.status(404).json({ message: 'Không tìm thấy giao dịch.' });
        return res.json({ message: 'Cập nhật trạng thái thành công.', data: transaction });
    } catch (error) {
        return sendError(res, error, 'Lỗi cập nhật trạng thái giao dịch:');
    }
};

export const putAdminById = async (req, res) => {
    try {
        const allowed = ['description', 'payment_method', 'payment_ref_id', 'notes', 'package_id', 'metadata'];
        const update = {};
        for (const field of allowed) if (req.body[field] !== undefined) update[field] = req.body[field];
        const transaction = await Transaction.findByIdAndUpdate(req.params.id, update, { new: true, runValidators: true })
            .populate('user', 'HoTen Email TenDangNhap');
        if (!transaction) return res.status(404).json({ message: 'Không tìm thấy giao dịch.' });
        return res.json({ message: 'Cập nhật giao dịch thành công.', data: transaction });
    } catch (error) {
        return sendError(res, error, 'Lỗi cập nhật giao dịch:');
    }
};

export const deleteAdminById = async (req, res) => {
    try {
        const transaction = await Transaction.findByIdAndDelete(req.params.id);
        if (!transaction) return res.status(404).json({ message: 'Không tìm thấy giao dịch.' });
        return res.json({ message: 'Xóa giao dịch thành công.', data: transaction });
    } catch (error) {
        return sendError(res, error, 'Lỗi xóa giao dịch:');
    }
};

export const deleteAdminBulkDelete = async (req, res) => {
    try {
        if (!Array.isArray(req.body.ids) || req.body.ids.length === 0 || req.body.ids.length > 100) {
            return res.status(400).json({ message: 'Danh sách ID phải có từ 1 đến 100 phần tử.' });
        }
        const result = await Transaction.deleteMany({ _id: { $in: req.body.ids } });
        return res.json({ message: `Đã xóa ${result.deletedCount} giao dịch.`, deletedCount: result.deletedCount });
    } catch (error) {
        return sendError(res, error, 'Lỗi xóa nhiều giao dịch:');
    }
};

export const getAdminStatsOverview = async (req, res) => {
    try {
        const match = {};
        if (req.query.startDate || req.query.endDate) {
            match.createdAt = {};
            if (req.query.startDate) match.createdAt.$gte = new Date(req.query.startDate);
            if (req.query.endDate) match.createdAt.$lte = new Date(req.query.endDate);
        }
        const completedMatch = { ...match, status: 'completed' };
        const [totalTransactions, totalRevenue, byStatus, byType, byPaymentMethod, dailyRevenue, topUsers] = await Promise.all([
            Transaction.countDocuments(match),
            Transaction.aggregate([{ $match: completedMatch }, { $group: { _id: null, total: { $sum: '$amount' } } }]),
            Transaction.aggregate([{ $match: match }, { $group: { _id: '$status', count: { $sum: 1 }, total: { $sum: '$amount' } } }, { $sort: { count: -1 } }]),
            Transaction.aggregate([{ $match: match }, { $group: { _id: '$type', count: { $sum: 1 }, total: { $sum: '$amount' } } }, { $sort: { count: -1 } }]),
            Transaction.aggregate([{ $match: match }, { $group: { _id: '$payment_method', count: { $sum: 1 }, total: { $sum: '$amount' } } }, { $sort: { count: -1 } }]),
            Transaction.aggregate([{ $match: completedMatch }, { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } }, revenue: { $sum: '$amount' }, count: { $sum: 1 } } }, { $sort: { _id: -1 } }, { $limit: 30 }, { $sort: { _id: 1 } }]),
            Transaction.aggregate([{ $match: completedMatch }, { $group: { _id: '$user', total: { $sum: '$amount' }, count: { $sum: 1 } } }, { $sort: { total: -1 } }, { $limit: 10 }, { $lookup: { from: 'users', localField: '_id', foreignField: '_id', as: 'user' } }, { $unwind: '$user' }, { $project: { total: 1, count: 1, user: { _id: '$user._id', HoTen: '$user.HoTen', Email: '$user.Email', TenDangNhap: '$user.TenDangNhap' } } }])
        ]);
        const revenue = totalRevenue[0]?.total || 0;
        return res.json({ overview: { totalTransactions, totalRevenue: revenue, averageTransactionValue: totalTransactions ? revenue / totalTransactions : 0 }, byStatus, byType, byPaymentMethod, dailyRevenue, topUsers });
    } catch (error) {
        return sendError(res, error, 'Lỗi thống kê giao dịch:');
    }
};

/**
 * Lịch sử giao dịch của một người dùng.
 *
 * Bản cũ gán `req.query.userId = req.params.userId` rồi gọi lại `getAdminAll`.
 * Express 5 định nghĩa `req.query` là getter parse lại mỗi lần đọc, nên phép
 * gán đó mất trắng và endpoint trả về giao dịch của **mọi** người. Filter vì
 * vậy phải được truyền tường minh; `userId` lấy từ path và đặt sau cùng để
 * `?userId=` trên query không ghi đè được.
 */
export const getAdminUserByUserId = async (req, res) => {
    try {
        const { page, limit, skip } = pagination(req.query);
        const filter = buildTransactionFilter({
            ...req.query,
            userId: req.params.userId,
        });
        return await respondWithTransactionPage(res, { filter, page, limit, skip });
    } catch (error) {
        return sendError(res, error, 'Lỗi lấy lịch sử giao dịch của người dùng:');
    }
};

export const postAdminByIdRefund = async (req, res) => {
    try {
        const transaction = await Transaction.findById(req.params.id);
        if (!transaction) return res.status(404).json({ message: 'Không tìm thấy giao dịch.' });
        if (transaction.status !== 'completed') {
            return res.status(400).json({ message: 'Chỉ có thể hoàn tiền giao dịch đã hoàn thành.' });
        }
        transaction.status = 'refunded';
        transaction.notes = req.body.reason || 'Đã hoàn tiền';
        await transaction.save();
        return res.json({ message: 'Hoàn tiền thành công.', data: transaction });
    } catch (error) {
        return sendError(res, error, 'Lỗi hoàn tiền:');
    }
};

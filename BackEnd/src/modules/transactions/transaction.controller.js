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

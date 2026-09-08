import jwt from 'jsonwebtoken';
import User from '../../model/User.js';
import env from '../config/env.js';

const JWT_SECRET = env.jwtSecret;

//  BYPASS AUTH MODE dùng khi test
const BYPASS_AUTH = env.bypassAuth;

const BYPASS_USER = {
    _id: '6925c1bc5b05cf681d547032',
    email: 'dev@test.com',
    full_name: 'Dev Admin',
    username: 'devadmin',
    role: 'admin',
    VaiTro: 'admin',
    is_banned: false
};

/**
 * Đọc user kèm `tokenVersion`.
 *
 * `tokenVersion` khai báo `select: false` nên phải xin thêm tường minh. Trả về
 * plain object vì không chỗ nào gọi method của document trên `req.user`, và
 * plain object cho phép bỏ hẳn `tokenVersion` trước khi gắn vào request.
 */
const findUserByIdWithVersion = (id) =>
    User.findById(id).select('-MatKhau +tokenVersion').lean();

/** Document tạo trước khi có `tokenVersion` được coi như version 0. */
const versionOf = (value) => value ?? 0;

/**
 * Middleware xác thực user.
 *
 * Nhận `findUserById` qua tham số để test dựng được chuỗi "đăng nhập → đổi mật
 * khẩu → token cũ bị từ chối" mà không cần MongoDB.
 */
export const createAuthenticateUser = ({
    findUserById = findUserByIdWithVersion,
    jwtSecret = JWT_SECRET,
    bypassAuth = BYPASS_AUTH,
} = {}) => async (req, res, next) => {
    //  Tắt auth tạm thời khi test
    if (bypassAuth) {
        req.user = { ...BYPASS_USER };
        console.log('⚠️  AUTH BYPASS MODE (ADMIN) - Development only!');
        return next();
    }

    //  Auth bình thường
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];

        if (!token) {
            return res.status(401).json({
                message: 'Vui lòng đăng nhập để tiếp tục.'
            });
        }

        // Verify token với error handling tốt hơn
        let decoded;
        try {
            decoded = jwt.verify(token, jwtSecret);
        } catch (err) {
            if (err.name === 'TokenExpiredError') {
                return res.status(403).json({
                    message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'
                });
            }
            if (err.name === 'JsonWebTokenError') {
                return res.status(403).json({
                    message: 'Token không hợp lệ.'
                });
            }
            throw err;
        }

        // Tìm user trong MongoDB
        if (decoded.type && decoded.type !== 'access') {
            return res.status(403).json({ message: 'Loại token không hợp lệ.' });
        }

        const user = await findUserById(decoded.id || decoded.userId);

        if (!user) {
            return res.status(401).json({
                message: 'Người dùng không tồn tại hoặc đã bị xóa.'
            });
        }

        // Đổi mật khẩu tăng `tokenVersion` trong database. Không đối chiếu ở đây
        // thì token phát trước lúc đổi vẫn dùng được tới khi hết hạn, tức là đổi
        // mật khẩu không đuổi được người đang giữ token cũ.
        if (versionOf(decoded.tokenVersion) !== versionOf(user.tokenVersion)) {
            return res.status(401).json({
                message: 'Phiên đăng nhập đã kết thúc. Vui lòng đăng nhập lại.'
            });
        }

        // Kiểm tra user có bị khóa không
        if (user.TrangThai !== 'active') {
            return res.status(403).json({
                message: 'Tài khoản của bạn hiện không hoạt động.'
            });
        }

        // Gắn user vào request, bỏ `tokenVersion` để nó không rò ra response nào
        const { tokenVersion, ...safeUser } = user;
        req.user = safeUser;

        next();

    } catch (error) {
        console.error("Auth Error:", error.message);
        return next(error);
    }
};

export const authenticateUser = createAuthenticateUser();

//  Middleware xác thực admin
export const createAuthenticateAdmin = ({
    authenticate = authenticateUser,
    bypassAuth = BYPASS_AUTH,
} = {}) => async (req, res, next) => {
    // 🔥 Tắt auth tạm thời khi dev
    if (bypassAuth) {
        req.user = { ...BYPASS_USER, email: 'admin@test.com' };
        console.log('⚠️  ADMIN AUTH BYPASS MODE - Development only!');
        return next();
    }

    return authenticate(req, res, (error) => {
        if (error) return next(error);
        if (req.user?.VaiTro === 'admin') return next();
        return res.status(403).json({
            message: 'Truy cập bị từ chối. Chức năng này chỉ dành cho Admin.'
        });
    });
};

export const authenticateAdmin = createAuthenticateAdmin();

import jwt from 'jsonwebtoken';
import User from '../../model/User.js';
import env from '../config/env.js';

const JWT_SECRET = env.jwtSecret;

//  BYPASS AUTH MODE dùng khi test
const BYPASS_AUTH = env.bypassAuth;

//  Middleware xác thực user 
export const authenticateUser = async (req, res, next) => {
    //  Tắt auth tạm thời khi test
    if (BYPASS_AUTH) {
        req.user = {
            _id: '6925c1bc5b05cf681d547032',
            email: 'dev@test.com',
            full_name: 'Dev Admin',
            username: 'devadmin',
            role: 'admin',
            VaiTro: 'admin',
            is_banned: false
        };
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
            decoded = jwt.verify(token, JWT_SECRET);
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

        const user = await User.findById(decoded.id || decoded.userId)
            .select('-MatKhau');

        if (!user) {
            return res.status(401).json({ 
                message: 'Người dùng không tồn tại hoặc đã bị xóa.' 
            });
        }

        // Kiểm tra user có bị khóa không
        if (user.TrangThai !== 'active') {
            return res.status(403).json({ 
                message: 'Tài khoản của bạn hiện không hoạt động.' 
            });
        }

        // Gắn user vào request
        req.user = user;
        
        next();

    } catch (error) {
        console.error("Auth Error:", error.message);
        return next(error);
    }
};

//  Middleware xác thực admin 
export const authenticateAdmin = async (req, res, next) => {
    // 🔥 Tắt auth tạm thời khi dev
    if (BYPASS_AUTH) {
        req.user = {
            _id: '6925c1bc5b05cf681d547032',
            email: 'admin@test.com',
            full_name: 'Dev Admin',
            username: 'devadmin',
            role: 'admin',
            VaiTro: 'admin',
            is_banned: false
        };
        console.log('⚠️  ADMIN AUTH BYPASS MODE - Development only!');
        return next();
    }

    return authenticateUser(req, res, (error) => {
        if (error) return next(error);
        if (req.user?.VaiTro === 'admin') return next();
        return res.status(403).json({
            message: 'Truy cập bị từ chối. Chức năng này chỉ dành cho Admin.'
        });
    });
};

export const generateToken = (user) => {
    const payload = {
        id: user._id.toString(),
        email: user.Email,
        role: user.VaiTro || 'user',
        type: 'access'
    };

    return jwt.sign(payload, JWT_SECRET, { 
        expiresIn: '7d' 
    });
};


export const generateRefreshToken = (user) => {
    const payload = {
        id: user._id.toString(),
        type: 'refresh'
    };

    return jwt.sign(payload, JWT_SECRET + '_refresh', { 
        expiresIn: '30d' 
    });
};


export const verifyRefreshToken = (refreshToken) => {
    try {
        return jwt.verify(refreshToken, JWT_SECRET + '_refresh');
    } catch (error) {
        throw new Error('Refresh token không hợp lệ hoặc đã hết hạn.');
    }
};

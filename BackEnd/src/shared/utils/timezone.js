import moment from 'moment-timezone';

// Timezone Việt Nam
const VIETNAM_TIMEZONE = 'Asia/Ho_Chi_Minh';

/**
 * Lấy thời gian hiện tại theo timezone Việt Nam
 * @returns {Date} Date object theo giờ Việt Nam
 */
export const getVietnamTime = () => {
    return moment.tz(VIETNAM_TIMEZONE).toDate();
};

/**
 * Convert UTC time sang Việt Nam time
 * @param {Date} utcDate - UTC Date object
 * @returns {Date} Date object theo giờ Việt Nam
 */
export const toVietnamTime = (utcDate) => {
    if (!utcDate) return null;
    return moment.tz(utcDate, VIETNAM_TIMEZONE).toDate();
};

/**
 * Format date theo timezone Việt Nam
 * @param {Date} date - Date object
 * @param {String} format - Format string (mặc định: 'YYYY-MM-DD HH:mm:ss')
 * @returns {String} Formatted date string
 */
export const formatVietnamTime = (date, format = 'YYYY-MM-DD HH:mm:ss') => {
    if (!date) return null;
    return moment.tz(date, VIETNAM_TIMEZONE).format(format);
};

/**
 * Lấy đầu ngày theo timezone Việt Nam
 * @param {Date} date - Date object (mặc định: hôm nay)
 * @returns {Date} Start of day theo giờ Việt Nam
 */
export const getStartOfDayVietnam = (date = new Date()) => {
    return moment.tz(date, VIETNAM_TIMEZONE).startOf('day').toDate();
};

/**
 * Lấy cuối ngày theo timezone Việt Nam
 * @param {Date} date - Date object (mặc định: hôm nay)
 * @returns {Date} End of day theo giờ Việt Nam
 */
export const getEndOfDayVietnam = (date = new Date()) => {
    return moment.tz(date, VIETNAM_TIMEZONE).endOf('day').toDate();
};

/**
 * Chuyển đổi user object với các field date sang timezone Việt Nam
 * @param {Object} user - User object
 * @returns {Object} User object với dates đã convert
 */
export const convertUserDatesToVietnam = (user) => {
    if (!user) return null;
    
    const userObj = user.toObject ? user.toObject() : { ...user };
    
    // Convert các field date
    if (userObj.NgayTao) {
        userObj.NgayTao = formatVietnamTime(userObj.NgayTao);
    }
    if (userObj.LanDangNhapCuoi) {
        userObj.LanDangNhapCuoi = formatVietnamTime(userObj.LanDangNhapCuoi);
    }
    if (userObj.NgayHocGanNhat) {
        userObj.NgayHocGanNhat = formatVietnamTime(userObj.NgayHocGanNhat);
    }
    if (userObj.NgaySinh) {
        userObj.NgaySinh = formatVietnamTime(userObj.NgaySinh, 'YYYY-MM-DD');
    }
    if (userObj.createdAt) {
        userObj.createdAt = formatVietnamTime(userObj.createdAt);
    }
    if (userObj.updatedAt) {
        userObj.updatedAt = formatVietnamTime(userObj.updatedAt);
    }
    
    return userObj;
};

/**
 * Convert tất cả các field date trong object sang timezone Việt Nam
 * Hỗ trợ cả object đơn và array of objects
 * @param {Object|Array} data - Object hoặc array cần convert
 * @returns {Object|Array} Data với dates đã convert
 */
export const convertDatesToVietnam = (data) => {
    if (!data) return null;
    
    // Nếu là array, convert từng phần tử
    if (Array.isArray(data)) {
        return data.map(item => convertDatesToVietnam(item));
    }
    
    // Convert object
    const obj = data.toObject ? data.toObject() : { ...data };
    
    // Danh sách các field date thường gặp
    const dateFields = [
        'createdAt', 'updatedAt', 
        'NgayTao', 'NgayCapNhat', 'NgayHoc', 'NgayHocGanNhat',
        'LanDangNhapCuoi', 'NgaySinh',
        'last_studied_at', 'completed_at', 'started_at',
        'created_at', 'updated_at'
    ];
    
    dateFields.forEach(field => {
        if (obj[field] instanceof Date || (obj[field] && typeof obj[field] === 'string' && !isNaN(Date.parse(obj[field])))) {
            obj[field] = formatVietnamTime(obj[field]);
        }
    });
    
    return obj;
};

export default {
    getVietnamTime,
    toVietnamTime,
    formatVietnamTime,
    getStartOfDayVietnam,
    getEndOfDayVietnam,
    convertUserDatesToVietnam,
    convertDatesToVietnam,
    VIETNAM_TIMEZONE
};

import { convertDatesToVietnam } from '../utils/timezone.js';

/**
 * Middleware tự động convert tất cả dates trong response sang timezone Việt Nam
 * Áp dụng cho toàn bộ API
 */
export const timezoneMiddleware = (req, res, next) => {
    const originalJson = res.json;
    
    res.json = function(data) {
        // Nếu data có chứa dates, convert sang Vietnam timezone
        if (data) {
            // Xử lý object có nested data
            if (data.data) {
                data.data = convertDatesToVietnam(data.data);
            } else if (Array.isArray(data)) {
                data = convertDatesToVietnam(data);
            } else if (typeof data === 'object' && !data.message) {
                // Chỉ convert nếu không phải là message object đơn thuần
                data = convertDatesToVietnam(data);
            }
        }
        
        return originalJson.call(this, data);
    };
    
    next();
};

export default timezoneMiddleware;

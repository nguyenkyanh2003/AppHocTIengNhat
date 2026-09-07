import mongoose from 'mongoose';
import dotenv from 'dotenv';
import News from '../model/News.js';

dotenv.config();

const clearNews = async () => {
    try {
        const mongoURI = process.env.MONGODB_URI;
        await mongoose.connect(mongoURI, {
            dbName: process.env.DB_NAME || 'AppHocTiengNhat'
        });
        console.log('✅ Kết nối MongoDB thành công');

        await News.deleteMany({});
        console.log('✅ Đã xóa tất cả tin tức cũ');

        await mongoose.disconnect();
        console.log('✅ Ngắt kết nối MongoDB');
    } catch (error) {
        console.error('❌ Lỗi:', error);
    }
};

clearNews();

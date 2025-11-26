import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();
if (!process.env.MONGO_URI) {
    console.error("❌ Lỗi: Thiếu MONGO_URI trong file .env");
    process.exit(1);
}
const connectDB = async () => {
    try {
        const conn = await mongoose.connect(process.env.MONGO_URI, {
            // Các options thường dùng để tránh warning
            serverSelectionTimeoutMS: 5000,
            connectTimeoutMS: 5000,
        });
        console.log(`\n==============================`);
        console.log(`✅ MongoDB Connected Successfully`);
        console.log(`📌 Host: ${conn.connection.host}`);
        console.log(`📦 Database: ${conn.connection.name}`);
        console.log(`==============================\n`);
    } catch (error) {
        console.error("❌ Lỗi kết nối MongoDB:", error.message);

        if (error.message.includes("bad auth")) {
            console.error("❌ Sai username/password trong connection string");
        }
        if (error.message.includes("ENOTFOUND")) {
            console.error("❌ Sai URL hoặc mất mạng");
        }
        if (error.message.includes("timed out")) {
            console.error("❌ Chưa whitelist IP trong MongoDB Atlas (0.0.0.0/0)");
        }

        process.exit(1);
    }
};
mongoose.connection.on("error", (err) => {
    console.error("⚠️ MongoDB Runtime Error:", err.message);
});
mongoose.connection.on("disconnected", () => {
    console.error("⚠️ Mất kết nối MongoDB. Đang thử kết nối lại...");
});
export default connectDB;

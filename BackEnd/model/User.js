import mongoose from "mongoose";

const UserSchema = new mongoose.Schema({
    TenDangNhap: {
        type: String,
        required: true,
        unique: true,
        trim: true
    },
    MatKhau: {
        type: String,
        required: true
    },
    HoTen: {
        type: String,
        required: true
    },
    Email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true,
        trim: true
    },
    TrinhDo: {
        type: String,
        enum: ['N5', 'N4', 'N3', 'N2', 'N1'],
        default: 'N5'
    },
    VaiTro: {
        type: String,
        enum: ['user', 'admin'],
        default: 'user'
    },
    SoDienThoai: String,
    AnhDaiDien: String,
    NgaySinh: Date,
    GioiTinh: {
        type: String,
        enum: ['Nam', 'Nữ', 'Khác']
    },
    DiaChi: String,
    DiemTichLuy: {
        type: Number,
        default: 0
    },
    TongThoiGianHoc: {
        type: Number,
        default: 0
    },
    StreakHienTai: {
        type: Number,
        default: 0
    },
    StreakDaiNhat: {
        type: Number,
        default: 0
    },
    NgayHocGanNhat: Date,
    TrangThai: {
        type: String,
        enum: ['active', 'inactive', 'locked', 'banned'],
        default: 'active'
    },
    NgayTao: {
        type: Date,
        default: Date.now
    },
    LanDangNhapCuoi: Date
}, {
    timestamps: true,  
    collection: 'users'
});



export default mongoose.model('User', UserSchema);
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
    LanDangNhapCuoi: Date,
    tokenVersion: {
        type: Number,
        default: 0,
        select: false
    },
    settings: {
        notificationsEnabled: {
            type: Boolean,
            default: true
        },
        soundEnabled: {
            type: Boolean,
            default: true
        },
        vibrateEnabled: {
            type: Boolean,
            default: true
        },
        language: {
            type: String,
            enum: ['vi', 'en', 'ja'],
            default: 'vi'
        },
        theme: {
            type: String,
            enum: ['light', 'dark', 'auto'],
            default: 'light'
        }
    }
}, {
    timestamps: true,  
    collection: 'users'
});



export default mongoose.model('User', UserSchema);

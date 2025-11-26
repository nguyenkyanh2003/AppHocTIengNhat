import mongoose from 'mongoose';

const GroupChatSchema = new mongoose.Schema({
    group_id: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'StudyGroup', 
        required: true,
        index: true 
    },
    
    // Người gửi tin nhắn
    user_id: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'User', 
        required: true,
        index: true 
    },
    
    // Nội dung tin nhắn
    content: { 
        type: String, 
        required: true,
        trim: true 
    }, 
    
    // Loại tin nhắn 
    type: { 
        type: String, 
        enum: ['TEXT', 'IMAGE', 'FILE', 'SYSTEM'], 
        default: 'TEXT' 
    },
    
    // URL file đính kèm 
    attachment_url: {
        type: String,
        trim: true
    },
    
    // Tên file gốc
    attachment_name: {
        type: String,
        trim: true
    },
    
    // Kích thước file 
    attachment_size: {
        type: Number,
        min: 0
    },
    
    // Tin nhắn trả lời 
    reply_to: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'GroupChat'
    },
    
    // Trạng thái xóa
    is_deleted: {
        type: Boolean,
        default: false,
        index: true
    },
    
    // Chỉnh sửa lần cuối
    is_edited: {
        type: Boolean,
        default: false
    },
    
    // Thời gian chỉnh sửa lần cuối
    edited_at: {
        type: Date
    }
    
}, { 
    timestamps: { 
        createdAt: 'created_at', 
        updatedAt: false 
    } 
});

// Tìm
GroupChatSchema.index({ group_id: 1, created_at: -1 });
GroupChatSchema.index({ group_id: 1, is_deleted: 1, created_at: -1 });
GroupChatSchema.index({ user_id: 1, created_at: -1 });

// Virtual để format thời gian
GroupChatSchema.virtual('formatted_time').get(function() {
    return this.created_at.toLocaleString('vi-VN');
});

// Method để kiểm tra quyền chỉnh sửa/xóa
GroupChatSchema.methods.canModify = function(userId) {
    return this.user_id.toString() === userId.toString();
};

// Chuyển đổi toJSON
GroupChatSchema.set('toJSON', { 
    virtuals: true,
    transform: function(doc, ret) {
        delete ret.__v;
        return ret;
    }
});

export default mongoose.model('GroupChat', GroupChatSchema);
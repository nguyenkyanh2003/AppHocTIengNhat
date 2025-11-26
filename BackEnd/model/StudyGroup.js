import mongoose from 'mongoose';

const MemberSchema = new mongoose.Schema({
    user_id: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'User', 
        required: true 
    },
    role: { 
        type: String, 
        enum: ['member', 'admin'], 
        default: 'member' 
    },
    joined_at: { 
        type: Date, 
        default: Date.now 
    }
}, { _id: false });

const StudyGroupSchema = new mongoose.Schema({
    name: { 
        type: String, 
        required: true, 
        trim: true,
        index: true 
    },
    
    description: { 
        type: String, 
        trim: true 
    },
    
    avatar: { 
        type: String,
        default: 'https://via.placeholder.com/150' 
    },
    
    level: { 
        type: String, 
        enum: ['N5', 'N4', 'N3', 'N2', 'N1', 'ALL'], 
        default: 'ALL',
        index: true 
    },
    
    creator_id: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'User', 
        required: true,
        index: true 
    },
    
    members: {
        type: [MemberSchema],
        default: []
    },
    
    member_count: {
        type: Number,
        default: 0,
        min: 0
    },
    
    is_active: {
        type: Boolean,
        default: true,
        index: true
    },
    
    is_private: {
        type: Boolean,
        default: false
    },
    
    max_members: {
        type: Number,
        default: 50,
        min: 1
    }

}, { 
    timestamps: true 
});

// tìm kiếm nhanh theo thành viên, tên nhóm, mô tả, creator và trạng thái
StudyGroupSchema.index({ 'members.user_id': 1 });
StudyGroupSchema.index({ name: 'text', description: 'text' });
StudyGroupSchema.index({ creator_id: 1, is_active: 1 });

// lấy tổng số thành viên
StudyGroupSchema.virtual('total_members').get(function() {
    return this.members.length;
});

// kiểm tra user có phải thành viên không
StudyGroupSchema.methods.isMember = function(userId) {
    return this.members.some(m => m.user_id.toString() === userId.toString());
};

// kiểm tra user có phải admin không
StudyGroupSchema.methods.isAdmin = function(userId) {
    return this.members.some(
        m => m.user_id.toString() === userId.toString() && m.role === 'admin'
    );
};

// kiểm tra user có phải creator không
StudyGroupSchema.methods.isCreator = function(userId) {
    return this.creator_id.toString() === userId.toString();
};

// thêm thành viên
StudyGroupSchema.methods.addMember = function(userId, role = 'member') {
    if (this.isMember(userId)) {
        throw new Error('Người dùng đã là thành viên của nhóm');
    }
    
    if (this.members.length >= this.max_members) {
        throw new Error('Nhóm đã đạt số lượng thành viên tối đa');
    }
    
    this.members.push({
        user_id: userId,
        role: role,
        joined_at: new Date()
    });
    
    this.member_count = this.members.length;
};

// xóa thành viên
StudyGroupSchema.methods.removeMember = function(userId) {
    const initialLength = this.members.length;
    this.members = this.members.filter(
        m => m.user_id.toString() !== userId.toString()
    );
    
    if (this.members.length === initialLength) {
        throw new Error('Người dùng không phải là thành viên của nhóm');
    }
    
    this.member_count = this.members.length;
};

export default mongoose.model('StudyGroup', StudyGroupSchema);
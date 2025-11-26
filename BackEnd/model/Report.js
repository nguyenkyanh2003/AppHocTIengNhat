import mongoose from 'mongoose';

const ReportSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    
    // Đối tượng bị báo lỗi 
    target_id: { type: mongoose.Schema.Types.ObjectId, required: true },
    
    // Loại đối tượng
    target_type: { 
        type: String, 
        enum: ['Vocabulary', 'Question', 'Grammar', 'Exam'],
        required: true 
    },
    
    // Nội dung báo lỗi 
    content: { type: String, required: true },
    
    // Trạng thái xử lý của Admin
    status: { 
        type: String, 
        enum: ['PENDING', 'APPROVED', 'REJECTED'], 
        default: 'PENDING' 
    },
    
    admin_note: String // Ghi chú của admin sau khi sửa xong

}, { timestamps: true });

export default mongoose.model('Report', ReportSchema);
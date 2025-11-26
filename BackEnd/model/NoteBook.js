import mongoose from 'mongoose';

const NotebookSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
    
    // Danh sách các mục đã lưu
    items: [{
        item_id: { type: mongoose.Schema.Types.ObjectId, required: true },
        item_type: { type: String, enum: ['Từ Vựng', 'Kanji', 'Ngữ Pháp'] },
        saved_at: { type: Date, default: Date.now },
        note: String // Ghi chú riêng của user cho từ này
    }]
    
}, { timestamps: true });

export default mongoose.model('Notebook', NotebookSchema);
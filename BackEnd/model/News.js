import mongoose from 'mongoose';

const NewsSchema = new mongoose.Schema({
    title: { type: String, required: true }, // Tiêu đề bài báo
    description: String, // Mô tả ngắn
    
    // Nội dung HTML của bài báo
    content_html: { type: String, required: true }, 
    
    // Ảnh bìa
    image_url: String,
    
    // Nguồn bài báo
    source: String,
    
    // Phân loại độ khó
    level: { type: String, enum: ['N5', 'N4', 'N3', 'N2', 'N1'] },
    
    // Audio kèm theo
    audio_url: String,

    // Số lượt xem
    views: { type: Number, default: 0 }
}, { timestamps: true });

export default mongoose.model('News', NewsSchema);
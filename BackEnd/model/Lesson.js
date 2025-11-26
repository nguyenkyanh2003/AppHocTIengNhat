import mongoose from 'mongoose';

const LessonSchema = new mongoose.Schema({
    title: { type: String, required: true, trim: true, unique: true },
    level: { type: String, required: true, enum: ['N5', 'N4', 'N3', 'N2', 'N1'], index: true },
    order: { type: Number, default: 1, min: 1 }, 
    description: { type: String, trim: true },
    content_html: String, 
    
    // Các tham chiếu đến từ vựng, ngữ pháp, kanji trong bài học
    vocabularies: { type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Từ Vựng' }], default: [] },
    grammars: { type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Ngữ Pháp' }], default: [] },
    kanjis: { type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Kanji' }], default: [] }

}, { timestamps: true });

// Text index để tìm kiếm nhanh theo title + description
LessonSchema.index({ title: 'text', description: 'text' });

export default mongoose.model('Lesson', LessonSchema);

import mongoose from 'mongoose';

const ExampleSchema = new mongoose.Schema({
    word: { type: String, required: true },
    hiragana: { type: String, required: true },
    meaning: { type: String, required: true }
}, { _id: false }); // tránh tạo _id thừa cho mỗi ví dụ

const KanjiSchema = new mongoose.Schema({
    character: { type: String, required: true, unique: true, trim: true },
    hanviet: { type: String, trim: true },
    onyomi: { type: [String], default: [] },
    kunyomi: { type: [String], default: [] },
    meaning: { type: String, trim: true },
    
    level: { 
        type: String, 
        enum: ['N5', 'N4', 'N3', 'N2', 'N1'], 
        index: true 
    },

    stroke_order_svg: String,
    
    examples: {
        type: [ExampleSchema],
        default: []
    }

}, { timestamps: true });

// Text index để tìm kiếm nhanh theo character và meaning
KanjiSchema.index({ character: 'text', meaning: 'text' });

export default mongoose.model('Kanji', KanjiSchema);

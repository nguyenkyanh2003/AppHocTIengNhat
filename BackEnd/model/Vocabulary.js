import mongoose from 'mongoose';

const VocabularySchema = new mongoose.Schema({
    word: { type: String, required: true, index: true }, // Kanji: 学生
    hiragana: { type: String, required: true },          // Kana: がくせい
    meaning: { type: String, required: true },           // Nghĩa: Học sinh
    level: { type: String, enum: ['N5', 'N4', 'N3', 'N2', 'N1'], index: true },
    // tinh huống sử dụng từ
    usage_context: { type: String }, 
    // Media
    audio_url: String,
    image_url: String,
    lesson: { type: mongoose.Schema.Types.ObjectId, ref: 'Lesson', required: true, index: true },
    // Ví dụ (Quan trọng)
    examples: [{
        sentence: String, // 私は学生です
        meaning: String,  // Tôi là học sinh
        audio_url: String
    }],

    // Link tới Kanji trong từ này
    related_kanjis: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Kanji' }]
});

// Index text để search nhanh
VocabularySchema.index({ word: 'text', meaning: 'text' });

export default mongoose.model('Vocabulary', VocabularySchema);
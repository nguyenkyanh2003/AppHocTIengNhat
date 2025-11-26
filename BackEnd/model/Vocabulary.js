import mongoose from 'mongoose';

const VocabularySchema = new mongoose.Schema({
    word: { type: String, required: true, index: true }, // Kanji: 学生
    hiragana: { type: String, required: true },          // Kana: がくせい
    meaning: { type: String, required: true },           // Nghĩa: Học sinh
    level: { type: String, enum: ['N5', 'N4', 'N3', 'N2', 'N1'], index: true },
    
    // Media
    audio_url: String,
    image_url: String,

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
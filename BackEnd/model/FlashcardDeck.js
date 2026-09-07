import mongoose from 'mongoose';

// Schema cho một thẻ flashcard trong bộ thẻ
const FlashcardCardSchema = new mongoose.Schema({
    front: { type: String, required: true },          // Mặt trước (từ/câu hỏi)
    back: { type: String, required: true },           // Mặt sau (nghĩa/đáp án)
    front_subtext: { type: String },                  // Phụ đề mặt trước (hiragana, phiên âm, v.v.)
    back_subtext: { type: String },                   // Phụ đề mặt sau (ví dụ, gợi ý)
    image_url: { type: String },                      // Hình ảnh minh họa
    audio_url: { type: String },                      // Âm thanh phát âm
    order: { type: Number, default: 0 },              // Thứ tự sắp xếp
    created_at: { type: Date, default: Date.now },
});

// Schema cho bộ thẻ flashcard (giống Quizlet's "Set")
const FlashcardDeckSchema = new mongoose.Schema({
    title: { type: String, required: true },          // Tên bộ thẻ
    description: { type: String },                     // Mô tả bộ thẻ
    user: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'User', 
        required: true,
        index: true 
    },                                                 // Người tạo bộ thẻ
    cards: [FlashcardCardSchema],                     // Danh sách thẻ trong bộ
    is_public: { type: Boolean, default: false },     // Công khai hay riêng tư
    tags: [{ type: String }],                         // Tags để phân loại
    category: { 
        type: String, 
        enum: ['vocabulary', 'kanji', 'grammar', 'custom', 'other'],
        default: 'custom'
    },
    level: { 
        type: String, 
        enum: ['N5', 'N4', 'N3', 'N2', 'N1', 'beginner', 'intermediate', 'advanced', 'other']
    },
    total_cards: { type: Number, default: 0 },        // Tổng số thẻ
    study_count: { type: Number, default: 0 },        // Số lần được học
    favorite_count: { type: Number, default: 0 },     // Số người yêu thích
    created_at: { type: Date, default: Date.now },
    updated_at: { type: Date, default: Date.now },
}, {
    timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' }
});

// Tự động cập nhật total_cards khi có thay đổi
FlashcardDeckSchema.pre('save', function(next) {
    this.total_cards = this.cards.length;
    next();
});

// Index để search và filter nhanh
FlashcardDeckSchema.index({ title: 'text', description: 'text' });
FlashcardDeckSchema.index({ user: 1, created_at: -1 });
FlashcardDeckSchema.index({ is_public: 1, created_at: -1 });
FlashcardDeckSchema.index({ category: 1, level: 1 });

export default mongoose.model('FlashcardDeck', FlashcardDeckSchema);

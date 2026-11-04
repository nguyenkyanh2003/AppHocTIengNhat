import mongoose from 'mongoose';

const SRSProgressSchema = new mongoose.Schema({
    user: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'User', 
        required: true, 
        index: true 
    },

    item_id: { type: mongoose.Schema.Types.ObjectId, required: true },
    item_type: { type: String, enum: ['Vocabulary', 'Kanji'], required: true },

    box: { type: Number, default: 1, min: 1, max: 5 },
    next_review: { type: Date, required: true, index: true },
    streak: { type: Number, default: 0, min: 0 }

}, { timestamps: true });

// Một thẻ là một (user, loại, nội dung): từ vựng và Kanji có lịch ôn riêng.
// DB đang có khoá cũ `(user, item_id)` chuyển bằng `scripts/migrate-srs-card-index.js`.
SRSProgressSchema.index(
    { user: 1, item_type: 1, item_id: 1 },
    { unique: true, name: 'srs_card_key' }
);

export default mongoose.model('SRSProgress', SRSProgressSchema);

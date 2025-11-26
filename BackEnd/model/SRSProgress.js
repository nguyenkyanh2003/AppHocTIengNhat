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

// Compound index để tránh duplicate và query nhanh theo user + item
SRSProgressSchema.index({ user: 1, item_id: 1 }, { unique: true });

export default mongoose.model('SRSProgress', SRSProgressSchema);

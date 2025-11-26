import mongoose from 'mongoose';

// Schema con: chi tiết từng câu trả lời
const UserAnswerSchema = new mongoose.Schema({
    question_id: { 
        type: mongoose.Schema.Types.ObjectId, 
        required: true 
    },

    // Đáp án user chọn (0–3), -1 nếu bỏ qua
    user_choice: { 
        type: Number, 
        default: -1,
        min: -1,
        max: 3
    },

    is_correct: { 
        type: Boolean, 
        required: true 
    }
}, { _id: false });

const HistorySchema = new mongoose.Schema({
    user: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'User', 
        required: true,
        index: true
    },

    exam: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'JLPT', 
        required: true,
        index: true
    },

    score: { type: Number, required: true, min: 0 },
    is_passed: { type: Boolean, required: true },

    taken_at: { type: Date, default: Date.now },
    duration: { type: Number, default: 0, min: 0 },

    section_scores: {
        moji_goi: { type: Number, default: 0, min: 0 },
        bunpou: { type: Number, default: 0, min: 0 },
        dokkai: { type: Number, default: 0, min: 0 },
        choukai: { type: Number, default: 0, min: 0 }
    },

    user_answers: {
        type: [UserAnswerSchema],
        default: []
    }

}, { timestamps: true });

// Compound index để query nhanh user đã làm đề nào chưa
HistorySchema.index({ user: 1, exam: 1 }, { unique: true });

export default mongoose.model('LearningHistory', HistorySchema);

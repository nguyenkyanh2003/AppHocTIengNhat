import mongoose from 'mongoose';

const QuestionBankSchema = new mongoose.Schema({
    level: { 
        type: String, 
        enum: ['N5', 'N4', 'N3', 'N2', 'N1'], 
        required: true, 
        index: true 
    },
    type: { 
        type: String, 
        enum: ['Vocabulary', 'Grammar', 'Kanji'], 
        required: true 
    },
    tags: { type: [String], default: [] },

    content: { type: String, required: true, trim: true },
    choices: {
        type: [String],
        required: true,
        validate: v => v.length === 4
    },
    correct_answer: { type: Number, required: true, min: 0, max: 3 },
    explanation: { type: String, trim: true, default: '' }

}, { timestamps: true });

// Text index để tìm kiếm nhanh theo nội dung câu hỏi
QuestionBankSchema.index({ content: 'text' });

export default mongoose.model('QuestionBank', QuestionBankSchema);

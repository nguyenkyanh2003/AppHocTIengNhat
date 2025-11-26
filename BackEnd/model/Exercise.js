import mongoose from 'mongoose';

const AnswerSchema = new mongoose.Schema({
    content: { type: String, required: true, trim: true },
    is_correct: { type: Boolean, required: true, default: false }
}, { _id: true });

const QuestionSchema = new mongoose.Schema({
    content: { type: String, required: true, trim: true },
    answers: {
        type: [AnswerSchema],
        validate: {
            validator: function(arr) {
                return arr.length >= 2 && arr.length <= 4;
            },
            message: 'Câu hỏi phải có từ 2-4 đáp án'
        }
    },
    explanation: { type: String, trim: true } // Giải thích đáp án
}, { _id: true });

const ExerciseSchema = new mongoose.Schema({
    lesson_id: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'Lesson', 
        required: true,
        index: true 
    },
    
    title: { type: String, required: true, trim: true },
    
    type: { 
        type: String, 
        enum: ['Từ vựng', 'Ngữ pháp', 'Kanji', 'Tổng hợp'],
        default: 'Tổng hợp'
    },
    
    level: { 
        type: String, 
        enum: ['N5', 'N4', 'N3', 'N2', 'N1'],
        required: true,
        index: true 
    },
    
    description: { type: String, trim: true },
    
    questions: [QuestionSchema],
    
    time_limit: { type: Number, default: 0, min: 0 }, // phút, 0 = không giới hạn
    pass_score: { type: Number, default: 60, min: 0, max: 100 },
    
    is_active: { type: Boolean, default: true, index: true },
    
    total_attempts: { type: Number, default: 0, min: 0 }

}, { timestamps: true });

ExerciseSchema.index({ title: 'text' });

export default mongoose.model('Exercise', ExerciseSchema);
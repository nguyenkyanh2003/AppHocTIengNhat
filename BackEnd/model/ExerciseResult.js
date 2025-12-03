import mongoose from 'mongoose';

const UserAnswerSchema = new mongoose.Schema({
    question_id: { type: mongoose.Schema.Types.ObjectId, required: true },
    answer_id: { type: mongoose.Schema.Types.ObjectId, required: true },
    is_correct: { type: Boolean, required: true },
    correct_answer_id: { type: mongoose.Schema.Types.ObjectId }
}, { _id: false });

const ExerciseResultSchema = new mongoose.Schema({
    user_id: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'User', 
        required: true,
        index: true 
    },
    
    exercise_id: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'Exercise', 
        required: true,
        index: true 
    },
    
    score: { type: Number, required: true, min: 0, max: 100 },
    correct_count: { type: Number, required: true, min: 0 },
    total_questions: { type: Number, required: true, min: 1 },
    
    time_spent: { type: Number, default: 0, min: 0 }, // giây
    
    user_answers: [UserAnswerSchema],
    
    is_passed: { type: Boolean, required: true },
    
    completed_at: { type: Date, default: Date.now, index: true }

}, { timestamps: true });

ExerciseResultSchema.index({ user_id: 1, exercise_id: 1 });
ExerciseResultSchema.index({ score: -1 });

export default mongoose.model('ExerciseResult', ExerciseResultSchema);
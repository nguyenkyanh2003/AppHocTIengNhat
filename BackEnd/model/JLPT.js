import mongoose from 'mongoose';
// 1. SCHEMA CON: CÂU HỎI ĐƠN (Question)
const QuestionSchema = new mongoose.Schema({
    mondai: { type: Number, required: true }, 
    question_text: { type: String, required: true },
    image: String,
    audio: String,

    // Mảng 4 đáp án
    choices: {
        type: [String],
        required: true,
        validate: v => v.length === 4 // Đảm bảo có đúng 4 đáp án
    },

    // Index đáp án đúng
    correct_answer: { 
        type: Number, 
        required: true,
        min: 0,
        max: 3
    },

    score: { type: Number, default: 1 },
    explanation: String
}, 
{ _id: false });     // ❗ Không tạo _id thừa cho mỗi câu hỏi
// 2. SCHEMA CON: NHÓM CÂU HỎI (Group Question)
const GroupQuestionSchema = new mongoose.Schema({
    mondai: { type: Number, required: true },

    group_content: String,
    group_image: String,
    group_audio: String,
    transcript: String,

    questions: { 
        type: [QuestionSchema],
        default: [] 
    }
}, 
{ _id: false });     

// 3. SCHEMA CHÍNH: ĐỀ THI JLPT (Exam)
const JLPTSchema = new mongoose.Schema({
    // Thông tin chung 
    title: { type: String, required: true },
    description: String,

    level: { 
        type: String, 
        enum: ['N5', 'N4', 'N3', 'N2', 'N1'], 
        required: true,
        index: true 
    },

    //  Thời gian & Năm tháng 
    year: { type: Number, min: 1990, max: 2100 },
    month: { type: Number, enum: [7, 12] },
    time_limit: { type: Number, default: 105 },

    // Điểm số
    pass_score: { type: Number, default: 90 },
    total_score: { type: Number, default: 180 },

    //  Người tạo
    creator_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

    // Nội dung đề thi 
    sections: {
        moji_goi: { type: [QuestionSchema], default: [] },
        bunpou: { type: [QuestionSchema], default: [] },
        dokkai: { type: [GroupQuestionSchema], default: [] },
        choukai: { type: [GroupQuestionSchema], default: [] }
    },

    // Thống kê
    total_views: { type: Number, default: 0 },
    is_published: { type: Boolean, default: false }

}, 
{ timestamps: true });

export default mongoose.model('JLPT', JLPTSchema);

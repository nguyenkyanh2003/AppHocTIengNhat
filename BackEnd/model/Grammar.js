import mongoose from 'mongoose';

const ExampleSchema = new mongoose.Schema({
    sentence: { type: String, required: true, trim: true },
    meaning: { type: String, required: true, trim: true },
    audio_url: { type: String, trim: true }
}, { _id: false });

const GrammarSchema = new mongoose.Schema({
    title: { 
        type: String, 
        required: true, 
        trim: true,
        index: true 
    },
    
    structure: { 
        type: String, 
        required: true, 
        trim: true 
    },
    
    meaning: { 
        type: String, 
        required: true, 
        trim: true 
    },
    
    usage: { 
        type: String, 
        trim: true,
        default: '' 
    },

    level: { 
        type: String, 
        enum: ['N5', 'N4', 'N3', 'N2', 'N1'], 
        required: true,
        index: true 
    },

    examples: {
        type: [ExampleSchema],
        default: [],
        validate: {
            validator: function(arr) {
                return arr.length <= 10; 
            },
            message: 'Số lượng ví dụ không được vượt quá 10'
        }
    },

    lesson_id: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'Lesson',
        index: true 
    },

    //  Thêm các trường hữu ích
    related_grammar: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Grammar'
    }], // Ngữ pháp liên quan

    notes: { 
        type: String, 
        trim: true 
    }, // Ghi chú đặc biệt

    is_active: { 
        type: Boolean, 
        default: true,
        index: true //  Index cho soft delete
    },

    view_count: { 
        type: Number, 
        default: 0,
        min: 0 
    }, // Số lượt xem

    difficulty: {
        type: Number,
        min: 1,
        max: 5,
        default: 3 // Độ khó 1-5 sao
    }

}, { 
    timestamps: true 
});
// Indexes để tối ưu truy vấn
GrammarSchema.index({ level: 1, is_active: 1 });
GrammarSchema.index({ lesson_id: 1, level: 1 });

// Text index để tìm kiếm
GrammarSchema.index({ 
    title: 'text', 
    structure: 'text', 
    meaning: 'text' 
});

// Virtual field để lấy số lượng ví dụ
GrammarSchema.virtual('example_count').get(function() {
    return this.examples.length;
});

// Method tăng view count
GrammarSchema.methods.incrementViewCount = function() {
    this.view_count += 1;
    return this.save();
};

// Static method tìm ngữ pháp cùng cấp độ
GrammarSchema.statics.findByLevel = function(level, limit = 10) {
    return this.find({ level, is_active: true })
        .sort({ view_count: -1 })
        .limit(limit);
};

export default mongoose.model('Grammar', GrammarSchema);
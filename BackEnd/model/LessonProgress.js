import mongoose from 'mongoose';

const LessonProgressSchema = new mongoose.Schema({
    user: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'User', 
        required: true,
        index: true
    },
    
    lesson: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'Lesson', 
        required: true,
        index: true
    },
    
    // Số lượng đã hoàn thành
    completed_vocabularies: { type: Number, default: 0, min: 0 },
    total_vocabularies: { type: Number, default: 0, min: 0 },
    
    completed_grammars: { type: Number, default: 0, min: 0 },
    total_grammars: { type: Number, default: 0, min: 0 },
    
    completed_kanjis: { type: Number, default: 0, min: 0 },
    total_kanjis: { type: Number, default: 0, min: 0 },
    
    // Danh sách các item đã học
    learned_vocabulary_ids: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Từ Vựng' }],
    learned_grammar_ids: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Ngữ Pháp' }],
    learned_kanji_ids: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Kanji' }],
    
    // Trạng thái
    is_completed: { type: Boolean, default: false },
    completed_at: { type: Date },
    last_studied_at: { type: Date, default: Date.now },
    
}, { timestamps: true });

// Compound index để query nhanh progress của user cho lesson cụ thể
LessonProgressSchema.index({ user: 1, lesson: 1 }, { unique: true });

// Virtual để tính phần trăm hoàn thành
LessonProgressSchema.virtual('overall_progress').get(function() {
    const total = this.total_vocabularies + this.total_grammars + this.total_kanjis;
    if (total === 0) return 0;
    const completed = this.completed_vocabularies + this.completed_grammars + this.completed_kanjis;
    return Math.round((completed / total) * 100);
});

// Method để cập nhật tiến độ khi học một item
LessonProgressSchema.methods.markItemLearned = function(itemType, itemId) {
    const idString = itemId.toString();
    
    switch(itemType) {
        case 'vocabulary':
            if (!this.learned_vocabulary_ids.some(id => id.toString() === idString)) {
                this.learned_vocabulary_ids.push(itemId);
                this.completed_vocabularies = this.learned_vocabulary_ids.length;
            }
            break;
        case 'grammar':
            if (!this.learned_grammar_ids.some(id => id.toString() === idString)) {
                this.learned_grammar_ids.push(itemId);
                this.completed_grammars = this.learned_grammar_ids.length;
            }
            break;
        case 'kanji':
            if (!this.learned_kanji_ids.some(id => id.toString() === idString)) {
                this.learned_kanji_ids.push(itemId);
                this.completed_kanjis = this.learned_kanji_ids.length;
            }
            break;
    }
    
    this.last_studied_at = new Date();
    
    // Check if lesson is completed
    if (this.completed_vocabularies === this.total_vocabularies &&
        this.completed_grammars === this.total_grammars &&
        this.completed_kanjis === this.total_kanjis &&
        !this.is_completed) {
        this.is_completed = true;
        this.completed_at = new Date();
    }
};

// Method để unmark item
LessonProgressSchema.methods.unmarkItemLearned = function(itemType, itemId) {
    const idString = itemId.toString();
    
    switch(itemType) {
        case 'vocabulary':
            this.learned_vocabulary_ids = this.learned_vocabulary_ids.filter(
                id => id.toString() !== idString
            );
            this.completed_vocabularies = this.learned_vocabulary_ids.length;
            break;
        case 'grammar':
            this.learned_grammar_ids = this.learned_grammar_ids.filter(
                id => id.toString() !== idString
            );
            this.completed_grammars = this.learned_grammar_ids.length;
            break;
        case 'kanji':
            this.learned_kanji_ids = this.learned_kanji_ids.filter(
                id => id.toString() !== idString
            );
            this.completed_kanjis = this.learned_kanji_ids.length;
            break;
    }
    
    this.last_studied_at = new Date();
    this.is_completed = false;
    this.completed_at = null;
};

export default mongoose.model('LessonProgress', LessonProgressSchema);

import mongoose from 'mongoose';

const NotebookSchema = new mongoose.Schema({
    user_id: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'User', 
        required: true,
        index: true 
    },
    
    // Ghi chú tự do của user
    title: { 
        type: String, 
        required: true,
        trim: true 
    },
    
    content: { 
        type: String, 
        required: true 
    },
    
    type: { 
        type: String, 
        enum: ['general', 'vocabulary', 'grammar', 'kanji', 'lesson'],
        default: 'general'
    },
    
    tags: [{ 
        type: String, 
        trim: true 
    }],
    
    // Liên kết với item (từ vựng, kanji, ngữ pháp, bài học)
    related_item_id: { 
        type: mongoose.Schema.Types.ObjectId 
    },
    
    related_item_type: { 
        type: String,
        enum: ['vocabulary', 'kanji', 'grammar', 'lesson']
    },
    
    // Giữ lại items cho backward compatibility (nếu cần)
    items: [{
        item_id: { type: mongoose.Schema.Types.ObjectId },
        item_type: { type: String, enum: ['Từ Vựng', 'Kanji', 'Ngữ Pháp'] },
        saved_at: { type: Date, default: Date.now },
        note: String
    }]
    
}, { 
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
});

// Indexes
NotebookSchema.index({ user_id: 1, type: 1 });
NotebookSchema.index({ user_id: 1, createdAt: -1 });
NotebookSchema.index({ tags: 1 });

export default mongoose.model('Notebook', NotebookSchema);
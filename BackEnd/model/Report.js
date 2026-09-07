import mongoose from 'mongoose';

const ReportSchema = new mongoose.Schema({
    user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    type: {
        type: String,
        enum: ['bug', 'suggestion', 'content', 'other'],
        required: true,
        index: true
    },
    related_id: { type: mongoose.Schema.Types.ObjectId },
    related_type: { type: String, trim: true },
    title: { type: String, required: true, trim: true, maxlength: 200 },
    description: { type: String, required: true, trim: true, maxlength: 5000 },
    priority: {
        type: String,
        enum: ['low', 'medium', 'high', 'urgent'],
        default: 'medium',
        index: true
    },
    status: {
        type: String,
        enum: ['pending', 'in_progress', 'resolved', 'rejected'],
        default: 'pending',
        index: true
    },
    admin_response: { type: String, trim: true, maxlength: 5000 },
    resolved_at: Date
}, { timestamps: true });

ReportSchema.index({ user_id: 1, createdAt: -1 });
ReportSchema.index({ status: 1, priority: 1, createdAt: -1 });

export default mongoose.model('Report', ReportSchema);

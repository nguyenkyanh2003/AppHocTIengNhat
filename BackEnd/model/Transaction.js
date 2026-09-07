import mongoose from 'mongoose';

const TransactionSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    type: {
        type: String,
        enum: ['SUBSCRIPTION', 'DEPOSIT', 'SPEND', 'REWARD'],
        required: true
    },
    amount: { type: Number, required: true, min: 0 },
    currency: { type: String, enum: ['VND', 'GOLD', 'GEM'], default: 'VND' },
    description: { type: String, trim: true, maxlength: 500 },
    status: {
        type: String,
        enum: ['pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded'],
        default: 'pending',
        index: true
    },
    payment_method: {
        type: String,
        enum: ['BANK', 'MOMO', 'VNPAY', 'CARD', 'NONE'],
        default: 'NONE'
    },
    payment_ref_id: { type: String, trim: true },
    package_id: { type: String, trim: true },
    notes: { type: String, trim: true, maxlength: 1000 },
    metadata: { type: mongoose.Schema.Types.Mixed }
}, { timestamps: true });

TransactionSchema.index({ user: 1, createdAt: -1 });
TransactionSchema.index({ status: 1, createdAt: -1 });
TransactionSchema.index({ payment_ref_id: 1 }, { unique: true, sparse: true });

export default mongoose.model('Transaction', TransactionSchema);

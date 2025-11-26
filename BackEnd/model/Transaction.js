import mongoose from 'mongoose';
const TransactionSchema = new mongoose.Schema({
    user: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'User', 
        required: true, 
        index: true 
    },

    type: { 
        type: String, 
        enum: ['DEPOSIT', 'SPEND', 'REWARD'], 
        required: true 
    },

    amount: { type: Number, required: true },
    currency: { type: String, enum: ['GOLD', 'GEM'], default: 'GOLD' },

    description: String,

    status: { 
        type: String, 
        enum: ['PENDING', 'SUCCESS', 'FAILED'], 
        default: 'SUCCESS' 
    },

    // Hình thức thanh toán: Bank/MoMo
    payment_method: {
        type: String,
        enum: ['BANK', 'MOMO'],
    },

    // Mã giao dịch từ cổng thanh toán
    payment_ref_id: String 

}, { timestamps: true });

export default mongoose.model('Transaction', TransactionSchema);

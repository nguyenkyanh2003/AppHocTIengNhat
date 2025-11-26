import mongoose from 'mongoose';

const NotificationSchema = new mongoose.Schema({
    title: { type: String, required: true, trim: true },
    message: { type: String, required: true, trim: true },
    
    type: { 
        type: String, 
        enum: ['SYSTEM', 'LESSON', 'EXAM'], 
        required: true, 
        index: true 
    },

    target_level: { 
        type: String, 
        enum: ['N5','N4','N3','N2','N1','ALL'], 
        required: true, 
        index: true 
    },

    data: { type: Object, default: {} }

}, { timestamps: true });

// Text index để tìm kiếm nhanh theo title/message
NotificationSchema.index({ title: 'text', message: 'text' });

export default mongoose.model('Notification', NotificationSchema);

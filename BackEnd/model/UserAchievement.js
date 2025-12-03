import mongoose from 'mongoose';

const UserAchievementSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  achievement: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Achievement',
    required: true
  },
  earned_at: {
    type: Date,
    default: Date.now
  },
  progress: {
    type: Number,
    default: 0
  },
  is_completed: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

// Compound index to prevent duplicate achievements
UserAchievementSchema.index({ user: 1, achievement: 1 }, { unique: true });

export default mongoose.model('UserAchievement', UserAchievementSchema);

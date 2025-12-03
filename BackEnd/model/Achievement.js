import mongoose from 'mongoose';

const AchievementSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    unique: true
  },
  name_vi: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  description_vi: {
    type: String,
    required: true
  },
  icon: {
    type: String,
    required: true
  },
  category: {
    type: String,
    enum: ['vocabulary', 'grammar', 'kanji', 'lesson', 'streak', 'xp', 'practice'],
    required: true
  },
  requirement_type: {
    type: String,
    enum: ['count', 'streak', 'xp', 'completion'],
    required: true
  },
  requirement_value: {
    type: Number,
    required: true
  },
  xp_reward: {
    type: Number,
    default: 100
  },
  rarity: {
    type: String,
    enum: ['common', 'rare', 'epic', 'legendary'],
    default: 'common'
  },
  is_active: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

export default mongoose.model('Achievement', AchievementSchema);

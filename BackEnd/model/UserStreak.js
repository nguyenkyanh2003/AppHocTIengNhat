import mongoose from 'mongoose';

const UserStreakSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  current_streak: {
    type: Number,
    default: 0
  },
  longest_streak: {
    type: Number,
    default: 0
  },
  last_activity_date: { // Đổi từ last_login_date thành last_activity_date
    type: Date,
    default: null
  },
  total_xp: {
    type: Number,
    default: 0
  },
  level: {
    type: Number,
    default: 1
  },
  activity_dates: [{ // Đổi từ login_dates thành activity_dates
    type: Date
  }],
  xp_history: [{
    amount: Number,
    reason: String,
    earned_at: {
      type: Date,
      default: Date.now
    }
  }]
}, {
  timestamps: true
});

// Tính level từ tổng XP (100 XP mỗi level)
UserStreakSchema.virtual('current_level').get(function() {
  return Math.floor(this.total_xp / 100) + 1;
});

// Tính XP cần để lên level tiếp theo
UserStreakSchema.virtual('xp_to_next_level').get(function() {
  const currentLevelXP = (this.current_level - 1) * 100;
  const nextLevelXP = this.current_level * 100;
  return nextLevelXP - this.total_xp;
});

// Phương thức cập nhật streak khi người dùng có hoạt động học tập
UserStreakSchema.methods.updateStreakOnActivity = function() {
  // Sử dụng timezone UTC+7 (Việt Nam)
  const now = new Date();
  const vietnamTime = new Date(now.toLocaleString("en-US", { timeZone: "Asia/Ho_Chi_Minh" }));
  const today = new Date(vietnamTime.getFullYear(), vietnamTime.getMonth(), vietnamTime.getDate());
  
  console.log(`🕒 Streak check - VN Time: ${vietnamTime.toLocaleString('vi-VN')}, Today: ${today.toISOString().split('T')[0]}`);
  
  if (!this.last_activity_date) {
    // Hoạt động đầu tiên
    console.log(`🆕 First activity ever for user`);
    this.current_streak = 1;
    this.longest_streak = 1;
    this.last_activity_date = today;
    this.activity_dates.push(today);
    return { streak: 1, is_new_day: true };
  }
  
  const lastActivity = new Date(this.last_activity_date);
  const lastActivityVN = new Date(lastActivity.getFullYear(), lastActivity.getMonth(), lastActivity.getDate());
  
  const daysDiff = Math.floor((today - lastActivityVN) / (1000 * 60 * 60 * 24));
  
  console.log(`📅 Last activity: ${lastActivityVN.toISOString().split('T')[0]}, Days diff: ${daysDiff}`);
  
  if (daysDiff === 0) {
    // Đã có hoạt động hôm nay rồi, không tăng streak
    return { streak: this.current_streak, is_new_day: false };
  } else if (daysDiff === 1) {
    // Ngày liên tiếp
    this.current_streak += 1;
    if (this.current_streak > this.longest_streak) {
      this.longest_streak = this.current_streak;
    }
    this.last_activity_date = today;
    this.activity_dates.push(today);
    
    return { streak: this.current_streak, is_new_day: true };
  } else {
    // Streak bị đứt
    this.current_streak = 1;
    this.last_activity_date = today;
    this.activity_dates.push(today);
    return { streak: 1, is_new_day: true, streak_broken: true };
  }
};

// Phương thức kiểm tra và cập nhật streak (không cần có activity mới)
// Dùng khi load streak lúc đăng nhập để kiểm tra streak có bị đứt không
UserStreakSchema.methods.checkAndUpdateStreak = function() {
  const now = new Date();
  const vietnamTime = new Date(now.toLocaleString("en-US", { timeZone: "Asia/Ho_Chi_Minh" }));
  const today = new Date(vietnamTime.getFullYear(), vietnamTime.getMonth(), vietnamTime.getDate());
  
  if (!this.last_activity_date) {
    // Chưa có hoạt động nào, không cần update
    return { need_save: false };
  }
  
  const lastActivity = new Date(this.last_activity_date);
  const lastActivityVN = new Date(lastActivity.getFullYear(), lastActivity.getMonth(), lastActivity.getDate());
  const daysDiff = Math.floor((today - lastActivityVN) / (1000 * 60 * 60 * 24));
  
  if (daysDiff === 0) {
    // Hôm nay đã có hoạt động, không cần update
    return { need_save: false };
  } else if (daysDiff === 1) {
    // Ngày hôm qua có hoạt động, streak vẫn còn (chưa làm gì hôm nay)
    return { need_save: false };
  } else if (daysDiff > 1) {
    // Streak bị đứt (không hoạt động quá 1 ngày)
    console.log(`⚠️ Streak broken - Days since last activity: ${daysDiff}`);
    this.current_streak = 0; // Reset về 0, sẽ thành 1 khi có activity tiếp theo
    return { need_save: true, streak_broken: true };
  }
  
  return { need_save: false };
};

// Phương thức thêm XP
UserStreakSchema.methods.addXP = function(amount, reason) {
  this.total_xp += amount;
  this.xp_history.push({
    amount,
    reason,
    earned_at: new Date()
  });
  
  // Cập nhật level
  this.level = this.current_level;
};

UserStreakSchema.set('toJSON', { virtuals: true });
UserStreakSchema.set('toObject', { virtuals: true });

export default mongoose.model('UserStreak', UserStreakSchema);

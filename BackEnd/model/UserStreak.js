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
  // Khoá ngày `YYYY-MM-DD` (múi giờ Việt Nam, xem streak-rules.js) dùng bởi
  // đường ghi streak mới (`streak.repository.createStreakRepository`).
  // Khác với `last_activity_date` (kiểu Date, do method cũ trong file này
  // ghi) — hai trường này song song tồn tại cho tới khi Task 5 gỡ hết các
  // method cũ và caller của chúng.
  last_activity_day: {
    type: String,
    default: null
  },
  // Số băng (freeze) đang có, mỗi băng che một ngày nghỉ khỏi làm đứt chuỗi.
  // Chặn trên bằng MAX_FREEZES trong streak-rules.js — validator ở đây chỉ
  // là lưới an toàn thứ hai phòng khi có chỗ ghi thẳng vào DB.
  freezes_available: {
    type: Number,
    default: 0,
    min: 0,
    max: 2
  },
  total_xp: {
    type: Number,
    default: 0
  },
  // Số lần tóm tắt này được ghi. Đường ghi mới CAS trên chính nó, không phải
  // trên `last_activity_day`.
  //
  // Lý do phải là `revision`: hai hoạt động khác nhau trong **cùng một ngày**
  // (hoàn thành một mục bài học và nộp một bài tập) không làm đổi
  // `last_activity_day`, nên một filter chỉ so ngày sẽ khớp cho cả hai request
  // đồng thời — cả hai cùng "thắng" và bản ghi sau đè mất XP của bản ghi
  // trước. `revision` đổi ở **mọi** lần ghi, nên chỉ đúng một request thắng và
  // request thua biết mình phải đọc lại (spec §3.5).
  revision: {
    type: Number,
    default: 0
  },
  // Số ngày `studied` theo luật mới. Không lấy số bản ghi `StreakDay` thay
  // cho nó: bản ghi `legacy` và `frozen` cũng nằm trong đó nhưng không phải
  // ngày học đã xác minh (spec §3.2).
  total_active_days: {
    type: Number,
    default: 0
  },
  // Số ngày dựng lại từ dữ liệu cũ mà không chứng minh được là có học. Giảm
  // đúng một lần khi một ngày legacy được nâng lên `studied`.
  legacy_day_count: {
    type: Number,
    default: 0
  },
  // Ngày bắt đầu áp dụng luật mới: với user cũ là ngày cutover, với user mới
  // là ngày học đầu tiên. Khoảng trống **trước** mốc này không được diễn giải
  // là nghỉ học — trước đó đơn giản là chưa có ai ghi lại (spec §3.2).
  tracking_started_day: {
    type: String,
    default: null
  },
  // Phiên bản chính sách XP đang áp cho tóm tắt này, đóng dấu cùng lúc với
  // event để hai bên đọc lại được cùng ngữ cảnh.
  policy_version: {
    type: String,
    default: null
  },
  level: {
    type: Number,
    default: 1
  },
  // --- Dữ liệu legacy, chờ migration ở Bước 4 ---
  //
  // Ba mảng dưới đây đã được thay thế: `activity_dates` bởi collection
  // `StreakDay`, `xp_history` và `reward_keys` bởi `ActivityEvent`. Đường ghi
  // mới **không đụng vào chúng**. Chúng vẫn ở đây vì là nguồn duy nhất để
  // dựng lại chuỗi và chặn phát thưởng lại cho người dùng cũ; chỉ được gỡ sau
  // khi migration (spec §4.1 bước 8) kiểm đạt.
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
  }],
  // Khóa của các khoản thưởng đã ghi nhận, ví dụ `lesson-complete:<lessonId>`.
  //
  // Khóa nằm cùng document với `total_xp` để một lệnh ghi có điều kiện vừa
  // kiểm tra "đã thưởng chưa" vừa cộng XP. Nhờ vậy request lặp hoặc chạy đồng
  // thời không thể cộng hai lần, và request thử lại sau lỗi giữa chừng vẫn
  // hoàn tất được. Số khóa bị chặn trên bởi số item trong nội dung bài học.
  reward_keys: {
    type: [String],
    default: []
  }
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

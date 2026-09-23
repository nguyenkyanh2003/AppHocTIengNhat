/**
 * Danh mục huy hiệu — dữ liệu thuần, `seedAchievements.js` lo phần ghi.
 *
 * Bố cục theo cách các app học ngôn ngữ phổ biến làm (Duolingo, Migii, Mazii):
 * mỗi nhóm có một huy hiệu **bước đầu** đạt được ngay buổi học đầu tiên, rồi các
 * bậc tăng dần, độ hiếm tăng theo bậc. Mọi tiêu chí đều là số server tự đếm được
 * (`achievement-rules.js`) — không có huy hiệu nào dựa vào lời khai của client.
 *
 * `name` là khoá upsert: đổi tên một huy hiệu đã có là tạo huy hiệu mới và mất
 * liên kết với người đã đạt nó. Tên tiếng Anh cũ được giữ nguyên vì lý do đó.
 */

const ICONS = Object.freeze({
  streak: '🔥',
  vocabulary: '📚',
  kanji: '🈯',
  grammar: '📝',
  lesson: '📖',
  practice: '🎯',
  xp: '⭐',
});

/** Độ hiếm theo bậc trong nhóm: bậc đầu phổ thông, bậc cuối huyền thoại. */
const rarityFor = (tier, tiers) => {
  if (tier === tiers - 1 && tiers >= 4) return 'legendary';
  if (tier >= Math.ceil(tiers / 2)) return 'epic';
  if (tier >= 1) return 'rare';
  return 'common';
};

const ladder = (category, requirementType, rows) =>
  rows.map(([name, nameVi, value, xpReward, description, descriptionVi], tier) => ({
    name,
    name_vi: nameVi,
    description,
    description_vi: descriptionVi,
    icon: ICONS[category],
    category,
    requirement_type: requirementType,
    requirement_value: value,
    xp_reward: xpReward,
    rarity: rarityFor(tier, rows.length),
  }));

export const ACHIEVEMENTS = Object.freeze([
  // Chuỗi ngày học — bám thang mốc của streak-policy (7/14/30/50/100/365), thêm 3 ngày
  // làm mốc khởi động.
  ...ladder('streak', 'streak', [
    ['Warming Up', 'Khởi Động', 3, 30, 'Study 3 days in a row', 'Học 3 ngày liên tiếp'],
    ['First Step', 'Bước Đầu Tiên', 7, 100, 'Study 7 days in a row', 'Học 7 ngày liên tiếp'],
    ['Two Week Warrior', 'Chiến Binh Hai Tuần', 14, 200, 'Study 14 days in a row', 'Học 14 ngày liên tiếp'],
    ['Monthly Master', 'Bậc Thầy Tháng', 30, 500, 'Study 30 days in a row', 'Học 30 ngày liên tiếp'],
    ['Fifty Days Strong', 'Bền Bỉ 50 Ngày', 50, 800, 'Study 50 days in a row', 'Học 50 ngày liên tiếp'],
    ['Dedication Legend', 'Huyền Thoại Kiên Trì', 100, 2000, 'Study 100 days in a row', 'Học 100 ngày liên tiếp'],
    ['Year of Japanese', 'Một Năm Tiếng Nhật', 365, 5000, 'Study 365 days in a row', 'Học 365 ngày liên tiếp'],
  ]),

  // Từ vựng đã đánh dấu học (mỗi từ vào lịch ôn SRS).
  ...ladder('vocabulary', 'count', [
    ['First Words', 'Những Từ Đầu Tiên', 10, 50, 'Learn 10 vocabulary words', 'Học 10 từ vựng'],
    ['Word Beginner', 'Người Mới Học Từ', 50, 150, 'Learn 50 vocabulary words', 'Học 50 từ vựng'],
    ['Word Collector', 'Người Sưu Tập Từ', 100, 300, 'Learn 100 vocabulary words', 'Học 100 từ vựng'],
    ['N5 Vocabulary', 'Vốn Từ N5', 300, 600, 'Learn 300 vocabulary words', 'Học 300 từ vựng'],
    ['Word Master', 'Bậc Thầy Từ Vựng', 500, 1000, 'Learn 500 vocabulary words', 'Học 500 từ vựng'],
    ['Vocabulary Sage', 'Hiền Nhân Từ Vựng', 1000, 3000, 'Learn 1000 vocabulary words', 'Học 1000 từ vựng'],
  ]),

  // Chữ Hán học trong bài.
  ...ladder('kanji', 'count', [
    ['First Kanji', 'Chữ Hán Đầu Tiên', 10, 50, 'Learn 10 kanji characters', 'Học 10 chữ Kanji'],
    ['Kanji Starter', 'Người Bắt Đầu Kanji', 50, 200, 'Learn 50 kanji characters', 'Học 50 chữ Kanji'],
    ['Kanji Scholar', 'Học Giả Kanji', 200, 600, 'Learn 200 kanji characters', 'Học 200 chữ Kanji'],
    ['Kanji Master', 'Bậc Thầy Kanji', 500, 2000, 'Learn 500 kanji characters', 'Học 500 chữ Kanji'],
  ]),

  // Mẫu ngữ pháp học trong bài.
  ...ladder('grammar', 'count', [
    ['Grammar First Steps', 'Làm Quen Ngữ Pháp', 5, 50, 'Learn 5 grammar points', 'Học 5 mẫu ngữ pháp'],
    ['Grammar Novice', 'Người Mới Học Ngữ Pháp', 20, 150, 'Learn 20 grammar points', 'Học 20 mẫu ngữ pháp'],
    ['Grammar Expert', 'Chuyên Gia Ngữ Pháp', 50, 400, 'Learn 50 grammar points', 'Học 50 mẫu ngữ pháp'],
    ['Grammar Master', 'Bậc Thầy Ngữ Pháp', 100, 1200, 'Learn 100 grammar points', 'Học 100 mẫu ngữ pháp'],
  ]),

  // Bài học hoàn thành.
  ...ladder('lesson', 'count', [
    ['First Lesson', 'Bài Học Đầu Tiên', 1, 30, 'Complete your first lesson', 'Hoàn thành bài học đầu tiên'],
    ['Lesson Beginner', 'Người Mới Học Bài', 5, 100, 'Complete 5 lessons', 'Hoàn thành 5 bài học'],
    ['Lesson Enthusiast', 'Người Đam Mê Bài Học', 20, 400, 'Complete 20 lessons', 'Hoàn thành 20 bài học'],
    ['Lesson Master', 'Bậc Thầy Bài Học', 50, 1500, 'Complete 50 lessons', 'Hoàn thành 50 bài học'],
  ]),

  // Bài tập đã nộp.
  ...ladder('practice', 'count', [
    ['First Practice', 'Lần Luyện Tập Đầu', 1, 30, 'Submit your first exercise', 'Nộp bài tập đầu tiên'],
    ['Practice Newbie', 'Người Mới Luyện Tập', 10, 100, 'Complete 10 practice exercises', 'Hoàn thành 10 bài luyện tập'],
    ['Practice Regular', 'Người Luyện Tập Thường Xuyên', 50, 300, 'Complete 50 practice exercises', 'Hoàn thành 50 bài luyện tập'],
    ['Practice Master', 'Bậc Thầy Luyện Tập', 100, 1000, 'Complete 100 practice exercises', 'Hoàn thành 100 bài luyện tập'],
  ]),

  // Tổng XP.
  ...ladder('xp', 'xp', [
    ['First Points', 'Những Điểm Đầu Tiên', 100, 20, 'Earn 100 XP', 'Kiếm được 100 XP'],
    ['Point Starter', 'Người Mới Kiếm Điểm', 500, 100, 'Earn 500 XP', 'Kiếm được 500 XP'],
    ['Point Collector', 'Người Sưu Tập Điểm', 1000, 200, 'Earn 1000 XP', 'Kiếm được 1000 XP'],
    ['Point Master', 'Bậc Thầy Kiếm Điểm', 5000, 500, 'Earn 5000 XP', 'Kiếm được 5000 XP'],
    ['XP Legend', 'Huyền Thoại XP', 10000, 2000, 'Earn 10000 XP', 'Kiếm được 10000 XP'],
  ]),
]);

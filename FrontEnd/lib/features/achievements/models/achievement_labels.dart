/// Tên nhóm huy hiệu trên tab của người học.
const achievementCategoryLabels = <String, String>{
  'vocabulary': 'Từ vựng',
  'grammar': 'Ngữ pháp',
  'kanji': 'Kanji',
  'lesson': 'Bài học',
  'streak': 'Chuỗi ngày',
  'xp': 'Kinh nghiệm',
  'practice': 'Luyện tập',
};

/// Thứ server đếm cho mỗi nhóm, để admin biết "số cần đạt" là số gì.
const achievementCriterionLabels = <String, String>{
  'vocabulary': 'Số từ vựng đã học',
  'grammar': 'Số bài tập mẫu câu đã đạt',
  'kanji': 'Số chữ Kanji đã học',
  'lesson': 'Số bài học đã hoàn thành',
  'streak': 'Số ngày học liên tiếp',
  'xp': 'Tổng XP',
  'practice': 'Số lần nộp bài tập',
};

const achievementRarityLabels = <String, String>{
  'common': 'Thường',
  'rare': 'Hiếm',
  'epic': 'Sử thi',
  'legendary': 'Huyền thoại',
};

String achievementRarityLabel(String rarity) =>
    achievementRarityLabels[rarity] ?? rarity;

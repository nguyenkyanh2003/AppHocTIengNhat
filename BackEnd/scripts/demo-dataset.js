/**
 * Bộ dữ liệu demo dùng để kiểm thử thủ công mốc 1 (SRS + streak).
 *
 * File này **thuần dữ liệu**: không kết nối MongoDB, không đọc biến môi
 * trường, không in ra gì. Nhờ vậy test có thể `import` để đối chiếu mà không
 * cần DB, và `seed-demo.js` là nơi duy nhất chạm vào database.
 *
 * Bộ demo không có bài học hay bài tập riêng: bài học lấy từ bộ chủ đề trong
 * `situational-lessons.js`, và 15 từ vựng dưới đây đều nằm trong hai bài "Tự
 * giới thiệu" và "Sinh hoạt hằng ngày" của bộ đó. Liên kết từ–bài chỉ có một
 * nơi ghi (`seed-situational-lessons.js`) để hai script không giành nhau một
 * mảng `Lesson.vocabularies`.
 */

export const DEMO_TAG = '[demo]';

/**
 * Hai tài khoản kiểm thử.
 *
 * `password` ở đây là mật khẩu thô để đăng nhập lúc kiểm thử; `seed-demo.js`
 * băm bằng bcrypt trước khi ghi, đúng như luồng đăng ký thật.
 */
export const DEMO_USERS = [
  {
    username: 'demo_hocvien',
    password: 'DemoHocVien123!',
    fullName: 'Học viên Demo',
    email: 'demo.hocvien@example.test',
    level: 'N5',
    role: 'user',
  },
  {
    username: 'demo_admin',
    password: 'DemoAdmin123!',
    fullName: 'Quản trị Demo',
    email: 'demo.admin@example.test',
    level: 'N5',
    role: 'admin',
  },
];

/**
 * Mười lăm từ vựng làm nguyên liệu cho thẻ SRS của tài khoản học viên.
 *
 * Khoá tự nhiên là (`word`, `hiragana`) — đúng unique index của `Vocabulary`.
 * Từ đã tồn tại (ví dụ từ đợt import N5) được dùng lại nguyên vẹn chứ không bị
 * ghi đè nghĩa hay ví dụ.
 */
export const DEMO_VOCABULARIES = [
  // --- tự giới thiệu ---
  {
    word: '私',
    hiragana: 'わたし',
    meaning: 'Tôi',
    level: 'N5',
    usage_context: 'Đại từ nhân xưng ngôi thứ nhất, dùng được ở mọi hoàn cảnh',
    examples: [{ sentence: '私は学生です。', meaning: 'Tôi là sinh viên.' }],
  },
  {
    word: '名前',
    hiragana: 'なまえ',
    meaning: 'Tên',
    level: 'N5',
    usage_context: 'Hỏi và giới thiệu tên',
    examples: [{ sentence: 'お名前は何ですか。', meaning: 'Tên bạn là gì?' }],
  },
  {
    word: '学生',
    hiragana: 'がくせい',
    meaning: 'Học sinh, sinh viên',
    level: 'N5',
    usage_context: 'Nói về nghề nghiệp hoặc thân phận',
    examples: [{ sentence: '私は日本語の学生です。', meaning: 'Tôi là sinh viên tiếng Nhật.' }],
  },
  {
    word: '先生',
    hiragana: 'せんせい',
    meaning: 'Giáo viên',
    level: 'N5',
    usage_context: 'Cũng dùng để gọi bác sĩ, luật sư',
    examples: [{ sentence: '田中さんは先生です。', meaning: 'Anh Tanaka là giáo viên.' }],
  },
  {
    word: '会社員',
    hiragana: 'かいしゃいん',
    meaning: 'Nhân viên công ty',
    level: 'N5',
    usage_context: 'Nghề nghiệp phổ biến khi tự giới thiệu',
    examples: [{ sentence: '父は会社員です。', meaning: 'Bố tôi là nhân viên công ty.' }],
  },
  {
    word: '出身',
    hiragana: 'しゅっしん',
    meaning: 'Quê quán, xuất thân',
    level: 'N5',
    usage_context: 'Nói về nơi sinh ra hoặc nơi tốt nghiệp',
    examples: [{ sentence: 'ベトナムの出身です。', meaning: 'Tôi đến từ Việt Nam.' }],
  },
  {
    word: '友達',
    hiragana: 'ともだち',
    meaning: 'Bạn bè',
    level: 'N5',
    usage_context: 'Danh từ chỉ quan hệ',
    examples: [{ sentence: '友達と話します。', meaning: 'Tôi nói chuyện với bạn.' }],
  },
  {
    word: '日本人',
    hiragana: 'にほんじん',
    meaning: 'Người Nhật',
    level: 'N5',
    usage_context: 'Ghép quốc gia với 人 để chỉ quốc tịch',
    examples: [{ sentence: '彼は日本人ではありません。', meaning: 'Anh ấy không phải người Nhật.' }],
  },

  // --- sinh hoạt hằng ngày ---
  {
    word: '朝',
    hiragana: 'あさ',
    meaning: 'Buổi sáng',
    level: 'N5',
    usage_context: 'Danh từ chỉ thời gian trong ngày',
    examples: [{ sentence: '朝ご飯を食べます。', meaning: 'Tôi ăn bữa sáng.' }],
  },
  {
    word: '毎日',
    hiragana: 'まいにち',
    meaning: 'Hằng ngày',
    level: 'N5',
    usage_context: 'Trạng từ chỉ tần suất, đứng đầu câu',
    examples: [{ sentence: '毎日日本語を勉強します。', meaning: 'Hằng ngày tôi học tiếng Nhật.' }],
  },
  {
    word: '起きる',
    hiragana: 'おきる',
    meaning: 'Thức dậy',
    level: 'N5',
    usage_context: 'Động từ nhóm 2',
    examples: [{ sentence: '毎朝六時に起きます。', meaning: 'Mỗi sáng tôi dậy lúc 6 giờ.' }],
  },
  {
    word: '食べる',
    hiragana: 'たべる',
    meaning: 'Ăn',
    level: 'N5',
    usage_context: 'Động từ nhóm 2',
    examples: [{ sentence: '昼ご飯を食べました。', meaning: 'Tôi đã ăn bữa trưa.' }],
  },
  {
    word: '飲む',
    hiragana: 'のむ',
    meaning: 'Uống',
    level: 'N5',
    usage_context: 'Động từ nhóm 1, dùng cả cho thuốc',
    examples: [{ sentence: '水を飲みます。', meaning: 'Tôi uống nước.' }],
  },
  {
    word: '行く',
    hiragana: 'いく',
    meaning: 'Đi',
    level: 'N5',
    usage_context: 'Động từ nhóm 1, đi với trợ từ に hoặc へ',
    examples: [{ sentence: '学校へ行きます。', meaning: 'Tôi đi đến trường.' }],
  },
  {
    word: '帰る',
    hiragana: 'かえる',
    meaning: 'Trở về, về nhà',
    level: 'N5',
    usage_context: 'Động từ nhóm 1 tuy kết thúc bằng る',
    examples: [{ sentence: '六時に家へ帰ります。', meaning: 'Tôi về nhà lúc 6 giờ.' }],
  },
];

/**
 * Kịch bản tiến độ SRS dựng sẵn cho tài khoản học viên.
 *
 * Mục đích là kiểm thử được ngay mà **không phải chờ sang ngày hôm sau**: một
 * nhóm thẻ đã đến hạn, một nhóm chưa. `dueInDays` âm nghĩa là quá hạn.
 *
 * Mỗi phần tử ứng với một từ trong [DEMO_VOCABULARIES], tra theo `word`.
 */
export const DEMO_SRS_PROGRESS = [
  { word: '私', box: 1, dueInDays: -2, streak: 0 },
  { word: '名前', box: 1, dueInDays: -1, streak: 0 },
  { word: '学生', box: 2, dueInDays: 0, streak: 1 },
  { word: '先生', box: 2, dueInDays: 0, streak: 1 },
  { word: '会社員', box: 3, dueInDays: 0, streak: 2 },
  { word: '出身', box: 3, dueInDays: 3, streak: 2 },
  { word: '友達', box: 4, dueInDays: 7, streak: 3 },
  { word: '日本人', box: 5, dueInDays: 21, streak: 4 },
];

/** Số thẻ đúng ra phải đến hạn khi vừa seed xong. */
export const DEMO_DUE_COUNT = DEMO_SRS_PROGRESS.filter(
  (row) => row.dueInDays <= 0,
).length;

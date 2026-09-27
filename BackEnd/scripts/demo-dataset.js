/**
 * Bộ dữ liệu demo dùng để kiểm thử thủ công mốc 1 (SRS + streak).
 *
 * File này **thuần dữ liệu**: không kết nối MongoDB, không đọc biến môi
 * trường, không in ra gì. Nhờ vậy test có thể `import` để đối chiếu mà không
 * cần DB, và `seed-demo.js` là nơi duy nhất chạm vào database.
 *
 * Bộ demo không có bài học hay bài tập riêng: bài học lấy từ bộ chủ đề trong
 * `situational-lessons.js`, bài tập mẫu dựng từ chính bộ đó trong
 * `sample-exercises.js`, và 15 từ vựng dưới đây đều nằm trong hai bài "Tự
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
    password: '123456',
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

  // --- đi siêu thị ---
  {
    word: '牛乳',
    hiragana: 'ぎゅうにゅう',
    meaning: 'Sữa tươi',
    level: 'N5',
    usage_context: 'Danh từ, hay gặp khi hỏi chỗ bày hàng trong siêu thị',
    examples: [{ sentence: '牛乳を二本買います。', meaning: 'Tôi mua hai chai sữa.' }],
  },
  {
    word: '店員',
    hiragana: 'てんいん',
    meaning: 'Nhân viên cửa hàng',
    level: 'N5',
    usage_context: 'Người bán hàng, thu ngân',
    examples: [{ sentence: '店員に聞きました。', meaning: 'Tôi đã hỏi nhân viên cửa hàng.' }],
  },
  {
    word: '袋',
    hiragana: 'ふくろ',
    meaning: 'Túi đựng',
    level: 'N5',
    usage_context: 'Thu ngân thường hỏi có cần túi không',
    examples: [{ sentence: '袋はいりません。', meaning: 'Tôi không cần túi.' }],
  },
  {
    word: '値段',
    hiragana: 'ねだん',
    meaning: 'Giá cả',
    level: 'N5',
    usage_context: 'Danh từ, đi với 高い / 安い',
    examples: [{ sentence: 'この値段は安いです。', meaning: 'Giá này rẻ.' }],
  },
  {
    word: '野菜',
    hiragana: 'やさい',
    meaning: 'Rau củ',
    level: 'N5',
    usage_context: 'Danh từ chung cho rau và củ',
    examples: [{ sentence: '毎日野菜を食べます。', meaning: 'Hằng ngày tôi ăn rau.' }],
  },
  {
    word: '肉',
    hiragana: 'にく',
    meaning: 'Thịt',
    level: 'N5',
    usage_context: 'Danh từ, ghép thành 豚肉・牛肉・鶏肉',
    examples: [{ sentence: '肉と魚を買いました。', meaning: 'Tôi đã mua thịt và cá.' }],
  },
  {
    word: '卵',
    hiragana: 'たまご',
    meaning: 'Trứng',
    level: 'N5',
    usage_context: 'Danh từ, đếm bằng 個（こ）',
    examples: [{ sentence: '卵を六個ください。', meaning: 'Cho tôi sáu quả trứng.' }],
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

/**
 * Lịch cho bộ thẻ số lượng lớn (`seed-demo.js --bulk=<n>`), để kiểm luồng ôn
 * qua nhiều đợt: đợt mặc định 20 thẻ, nên cần hơn 20 thẻ đến hạn cùng lúc mới
 * thấy được "bỏ qua cả đợt đầu vẫn tới thẻ phía sau".
 *
 * Mọi thẻ đều đã đến hạn (`dueInDays` từ -3 tới 0) và trải đủ năm hộp. Chia
 * theo chỉ số chứ không `Math.random`, để chạy lại cho đúng cùng một bộ.
 * Mỗi thẻ cần một từ khác nhau — unique index `(user, item_id)` không cho hai
 * thẻ cùng một từ — nên runner lấy từ N5 có sẵn trong DB, không lặp từ demo.
 */
export const buildBulkProgress = (count) =>
  Array.from({ length: count }, (_, index) => ({
    box: (index % 5) + 1,
    streak: index % 5,
    dueInDays: -(index % 4),
  }));

/**
 * Lịch sử học 20 ngày của tài khoản học viên demo (`demo-history.js`).
 *
 * Nghỉ đúng một ngày cách đây 14 ngày, nên chuỗi hiện tại là 13 ngày tính tới
 * hôm qua: học một thẻ trong buổi demo là chuỗi lên 14 và mở huy hiệu "Chiến
 * Binh Hai Tuần" ngay trước mắt người xem. Hôm nay luôn để trống.
 */
export const DEMO_LEARNER_HISTORY = Object.freeze({
  days: 20,
  missedOffsets: [14],
  reviewsPerDay: [4, 9],
  accuracy: 0.8,
  exerciseEvery: 3,
});

/**
 * Bốn bạn học giả cho bảng xếp hạng tuần/tháng — mỗi người một nhịp học khác
 * nhau như người dùng thật: chăm chỉ, đều đặn, thất thường, mới bắt đầu.
 * `cards` là số từ N5 được đánh dấu đã học để lượt ôn có thẻ thật đứng sau.
 */
export const DEMO_PEERS = [
  {
    username: 'demo_minhanh',
    fullName: 'Nguyễn Minh Anh',
    email: 'demo.minhanh@example.test',
    level: 'N4',
    cards: 40,
    history: { days: 20, missedOffsets: [], reviewsPerDay: [8, 14], accuracy: 0.88, exerciseEvery: 2 },
  },
  {
    username: 'demo_thulan',
    fullName: 'Lê Thu Lan',
    email: 'demo.thulan@example.test',
    level: 'N5',
    cards: 30,
    history: { days: 20, missedOffsets: [6], reviewsPerDay: [5, 10], accuracy: 0.8, exerciseEvery: 3 },
  },
  {
    username: 'demo_quanghuy',
    fullName: 'Trần Quang Huy',
    email: 'demo.quanghuy@example.test',
    level: 'N5',
    cards: 25,
    history: { days: 20, missedOffsets: [3, 9, 10, 17], reviewsPerDay: [3, 8], accuracy: 0.7, exerciseEvery: 4 },
  },
  {
    username: 'demo_ducminh',
    fullName: 'Phạm Đức Minh',
    email: 'demo.ducminh@example.test',
    level: 'N5',
    cards: 12,
    history: { days: 5, missedOffsets: [], reviewsPerDay: [2, 6], accuracy: 0.65, exerciseEvery: 5 },
  },
].map((peer) => Object.freeze({ ...peer, password: 'Demo123456', role: 'user' }));

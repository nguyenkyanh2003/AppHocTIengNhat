/**
 * Bộ dữ liệu demo dùng để kiểm thử thủ công mốc 1 (SRS + streak).
 *
 * File này **thuần dữ liệu**: không kết nối MongoDB, không đọc biến môi
 * trường, không in ra gì. Nhờ vậy test có thể `import` để đối chiếu mà không
 * cần DB, và `seed-demo.js` là nơi duy nhất chạm vào database.
 *
 * Khoá tự nhiên của từng bản ghi (`username`, `title`, `word`) được dùng làm
 * khoá upsert trong `seed-demo.js`, nên chạy lại nhiều lần không sinh bản sao.
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
 * Hai bài học, cố ý trùng với hai chủ đề hội thoại đầu tiên của mốc 2
 * (tự giới thiệu, sinh hoạt hằng ngày). Nhờ vậy từ mà AI gợi ý trong hội thoại
 * có chỗ để ánh xạ sang `Vocabulary._id` thay vì rơi vào khoảng trống.
 */
export const DEMO_LESSONS = [
  {
    title: 'Bài 1 — Chào hỏi và giới thiệu bản thân',
    level: 'N5',
    order: 1,
    type: 'Hội thoại',
    description:
      'Tự giới thiệu tên, nghề nghiệp và quê quán trong tình huống gặp mặt lần đầu.',
    content_html:
      '<p>Bài học tập trung vào mẫu câu <b>〜です</b> khi nói về bản thân.</p>',
  },
  {
    title: 'Bài 2 — Sinh hoạt hằng ngày',
    level: 'N5',
    order: 2,
    type: 'Hội thoại',
    description:
      'Kể lại một ngày bình thường: thức dậy, ăn uống, đi lại và trở về nhà.',
    content_html:
      '<p>Bài học tập trung vào động từ nhóm 2 và trạng từ chỉ tần suất.</p>',
  },
];

/**
 * Mười lăm từ vựng, chia đều cho hai bài.
 *
 * `lessonTitle` là khoá tham chiếu; `seed-demo.js` đổi nó thành `lesson` ObjectId
 * sau khi bài học đã được upsert.
 */
export const DEMO_VOCABULARIES = [
  // --- Bài 1: tự giới thiệu ---
  {
    word: '私',
    hiragana: 'わたし',
    meaning: 'Tôi',
    level: 'N5',
    usage_context: 'Đại từ nhân xưng ngôi thứ nhất, dùng được ở mọi hoàn cảnh',
    lessonTitle: DEMO_LESSONS[0].title,
    examples: [
      { sentence: '私は学生です。', meaning: 'Tôi là sinh viên.' },
    ],
  },
  {
    word: '名前',
    hiragana: 'なまえ',
    meaning: 'Tên',
    level: 'N5',
    usage_context: 'Hỏi và giới thiệu tên',
    lessonTitle: DEMO_LESSONS[0].title,
    examples: [
      { sentence: 'お名前は何ですか。', meaning: 'Tên bạn là gì?' },
    ],
  },
  {
    word: '学生',
    hiragana: 'がくせい',
    meaning: 'Học sinh, sinh viên',
    level: 'N5',
    usage_context: 'Nói về nghề nghiệp hoặc thân phận',
    lessonTitle: DEMO_LESSONS[0].title,
    examples: [
      { sentence: '私は日本語の学生です。', meaning: 'Tôi là sinh viên tiếng Nhật.' },
    ],
  },
  {
    word: '先生',
    hiragana: 'せんせい',
    meaning: 'Giáo viên',
    level: 'N5',
    usage_context: 'Cũng dùng để gọi bác sĩ, luật sư',
    lessonTitle: DEMO_LESSONS[0].title,
    examples: [
      { sentence: '田中さんは先生です。', meaning: 'Anh Tanaka là giáo viên.' },
    ],
  },
  {
    word: '会社員',
    hiragana: 'かいしゃいん',
    meaning: 'Nhân viên công ty',
    level: 'N5',
    usage_context: 'Nghề nghiệp phổ biến khi tự giới thiệu',
    lessonTitle: DEMO_LESSONS[0].title,
    examples: [
      { sentence: '父は会社員です。', meaning: 'Bố tôi là nhân viên công ty.' },
    ],
  },
  {
    word: '出身',
    hiragana: 'しゅっしん',
    meaning: 'Quê quán, xuất thân',
    level: 'N5',
    usage_context: 'Nói về nơi sinh ra hoặc nơi tốt nghiệp',
    lessonTitle: DEMO_LESSONS[0].title,
    examples: [
      { sentence: 'ベトナムの出身です。', meaning: 'Tôi đến từ Việt Nam.' },
    ],
  },
  {
    word: '友達',
    hiragana: 'ともだち',
    meaning: 'Bạn bè',
    level: 'N5',
    usage_context: 'Danh từ chỉ quan hệ',
    lessonTitle: DEMO_LESSONS[0].title,
    examples: [
      { sentence: '友達と話します。', meaning: 'Tôi nói chuyện với bạn.' },
    ],
  },
  {
    word: '日本人',
    hiragana: 'にほんじん',
    meaning: 'Người Nhật',
    level: 'N5',
    usage_context: 'Ghép quốc gia với 人 để chỉ quốc tịch',
    lessonTitle: DEMO_LESSONS[0].title,
    examples: [
      { sentence: '彼は日本人ではありません。', meaning: 'Anh ấy không phải người Nhật.' },
    ],
  },

  // --- Bài 2: sinh hoạt hằng ngày ---
  {
    word: '朝',
    hiragana: 'あさ',
    meaning: 'Buổi sáng',
    level: 'N5',
    usage_context: 'Danh từ chỉ thời gian trong ngày',
    lessonTitle: DEMO_LESSONS[1].title,
    examples: [
      { sentence: '朝ご飯を食べます。', meaning: 'Tôi ăn bữa sáng.' },
    ],
  },
  {
    word: '毎日',
    hiragana: 'まいにち',
    meaning: 'Hằng ngày',
    level: 'N5',
    usage_context: 'Trạng từ chỉ tần suất, đứng đầu câu',
    lessonTitle: DEMO_LESSONS[1].title,
    examples: [
      { sentence: '毎日日本語を勉強します。', meaning: 'Hằng ngày tôi học tiếng Nhật.' },
    ],
  },
  {
    word: '起きる',
    hiragana: 'おきる',
    meaning: 'Thức dậy',
    level: 'N5',
    usage_context: 'Động từ nhóm 2',
    lessonTitle: DEMO_LESSONS[1].title,
    examples: [
      { sentence: '毎朝六時に起きます。', meaning: 'Mỗi sáng tôi dậy lúc 6 giờ.' },
    ],
  },
  {
    word: '食べる',
    hiragana: 'たべる',
    meaning: 'Ăn',
    level: 'N5',
    usage_context: 'Động từ nhóm 2',
    lessonTitle: DEMO_LESSONS[1].title,
    examples: [
      { sentence: '昼ご飯を食べました。', meaning: 'Tôi đã ăn bữa trưa.' },
    ],
  },
  {
    word: '飲む',
    hiragana: 'のむ',
    meaning: 'Uống',
    level: 'N5',
    usage_context: 'Động từ nhóm 1, dùng cả cho thuốc',
    lessonTitle: DEMO_LESSONS[1].title,
    examples: [
      { sentence: '水を飲みます。', meaning: 'Tôi uống nước.' },
    ],
  },
  {
    word: '行く',
    hiragana: 'いく',
    meaning: 'Đi',
    level: 'N5',
    usage_context: 'Động từ nhóm 1, đi với trợ từ に hoặc へ',
    lessonTitle: DEMO_LESSONS[1].title,
    examples: [
      { sentence: '学校へ行きます。', meaning: 'Tôi đi đến trường.' },
    ],
  },
  {
    word: '帰る',
    hiragana: 'かえる',
    meaning: 'Trở về, về nhà',
    level: 'N5',
    usage_context: 'Động từ nhóm 1 tuy kết thúc bằng る',
    lessonTitle: DEMO_LESSONS[1].title,
    examples: [
      { sentence: '六時に家へ帰ります。', meaning: 'Tôi về nhà lúc 6 giờ.' },
    ],
  },
];

/**
 * Hai bài tập, mỗi bài gắn với một bài học.
 *
 * Câu cuối của bài tập 1 cố ý chỉ có **2 đáp án** để chạm vào biên dưới của
 * validator `answers` (2–4) trong `model/Exercise.js`; các câu còn lại có 4.
 */
export const DEMO_EXERCISES = [
  {
    title: 'Bài tập 1 — Từ vựng giới thiệu bản thân',
    lessonTitle: DEMO_LESSONS[0].title,
    type: 'Từ vựng',
    level: 'N5',
    description: 'Kiểm tra tám từ vựng của bài 1.',
    pass_score: 60,
    time_limit: 0,
    questions: [
      {
        content: '「学生」đọc là gì?',
        explanation: '学 (がく) + 生 (せい) → がくせい.',
        answers: [
          { content: 'がくせい', is_correct: true },
          { content: 'せんせい', is_correct: false },
          { content: 'かいしゃいん', is_correct: false },
          { content: 'ともだち', is_correct: false },
        ],
      },
      {
        content: '「出身」có nghĩa là gì?',
        explanation: 'Hán Việt là XUẤT THÂN, chỉ nơi sinh ra hoặc nơi học ra.',
        answers: [
          { content: 'Quê quán', is_correct: true },
          { content: 'Nghề nghiệp', is_correct: false },
          { content: 'Bạn bè', is_correct: false },
          { content: 'Tên gọi', is_correct: false },
        ],
      },
      {
        content: 'Chọn câu tự giới thiệu đúng ngữ pháp.',
        explanation: 'Mẫu 〜は〜です dùng để nói về bản thân.',
        answers: [
          { content: '私は会社員です。', is_correct: true },
          { content: '私が会社員ます。', is_correct: false },
          { content: '私は会社員ます。', is_correct: false },
          { content: '私を会社員です。', is_correct: false },
        ],
      },
      {
        content: '「日本人」dùng để chỉ quốc tịch, đúng hay sai?',
        explanation: 'Ghép tên nước với 人 tạo thành từ chỉ quốc tịch.',
        answers: [
          { content: 'Đúng', is_correct: true },
          { content: 'Sai', is_correct: false },
        ],
      },
    ],
  },
  {
    title: 'Bài tập 2 — Động từ sinh hoạt hằng ngày',
    lessonTitle: DEMO_LESSONS[1].title,
    type: 'Từ vựng',
    level: 'N5',
    description: 'Kiểm tra bảy từ vựng của bài 2.',
    pass_score: 60,
    time_limit: 0,
    questions: [
      {
        content: '「起きる」có nghĩa là gì?',
        explanation: 'Động từ nhóm 2, thể ます là 起きます.',
        answers: [
          { content: 'Thức dậy', is_correct: true },
          { content: 'Đi ngủ', is_correct: false },
          { content: 'Trở về', is_correct: false },
          { content: 'Uống', is_correct: false },
        ],
      },
      {
        content: 'Từ nào có nghĩa là "hằng ngày"?',
        explanation: '毎 (MỖI) + 日 (NHẬT) → まいにち.',
        answers: [
          { content: '毎日', is_correct: true },
          { content: '朝', is_correct: false },
          { content: '友達', is_correct: false },
          { content: '名前', is_correct: false },
        ],
      },
      {
        content: 'Điền trợ từ: 学校＿行きます。',
        explanation: 'Động từ 行く đi với へ hoặc に để chỉ hướng.',
        answers: [
          { content: 'へ', is_correct: true },
          { content: 'を', is_correct: false },
          { content: 'が', is_correct: false },
          { content: 'で', is_correct: false },
        ],
      },
    ],
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

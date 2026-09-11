import mongoose from 'mongoose';

const VocabularySchema = new mongoose.Schema({
    word: { type: String, required: true, index: true }, // Kanji: 学生
    hiragana: { type: String, required: true },          // Kana: がくせい
    meaning: { type: String, required: true },           // Nghĩa: Học sinh
    level: { type: String, enum: ['N5', 'N4', 'N3', 'N2', 'N1'], index: true },
    // tinh huống sử dụng từ
    usage_context: { type: String }, 
    // Media
    audio_url: String,
    image_url: String,
    // Bài học chứa từ này — **không bắt buộc**.
    //
    // Trước đây `required: true`, nghĩa là không thể nhập một kho từ vựng
    // trước khi chia bài. Nhưng từ vựng là thực thể độc lập: một từ có thể
    // xuất hiện ở nhiều bài, hoặc chưa thuộc bài nào, và tiến độ SRS bám vào
    // *từ* chứ không bám vào bài. Bắt buộc bài học ở đây buộc mọi lần nhập
    // phải bịa ra một bài giữ chỗ, và mỗi lần chia lại bài là một lần tạo bản
    // ghi mới — mất sạch tiến độ học của từ đó.
    lesson: { type: mongoose.Schema.Types.ObjectId, ref: 'Lesson', index: true },
    // Ví dụ (Quan trọng)
    examples: [{
        sentence: String, // 私は学生です
        meaning: String,  // Tôi là học sinh
        audio_url: String
    }],

    // Link tới Kanji trong từ này
    related_kanjis: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Kanji' }]
});

// Index text để search nhanh
VocabularySchema.index({ word: 'text', meaning: 'text' });

// Khoá tự nhiên của một từ: mặt chữ **và** cách đọc.
//
// Chỉ `word` là không đủ — tiếng Nhật có từ đồng hình khác âm khác nghĩa
// (今日 = きょう "hôm nay" và こんにち "thời nay"), gộp chúng làm một là sai
// dữ liệu. Ngược lại, thiếu ràng buộc này thì nhập lại cùng một file sẽ sinh
// bản sao, và đó chính là thứ khiến công cụ nhập cũ phải `deleteMany` toàn
// bộ collection trước khi ghi — cách làm đổi `_id` của mọi từ, kéo theo mất
// tiến độ SRS và mất `LessonProgress`.
//
// Có ràng buộc này thì công cụ nhập upsert được theo khoá tự nhiên: chạy lại
// bao nhiêu lần cũng ra đúng một bản ghi, `_id` không đổi.
VocabularySchema.index({ word: 1, hiragana: 1 }, { unique: true });

export default mongoose.model('Vocabulary', VocabularySchema);
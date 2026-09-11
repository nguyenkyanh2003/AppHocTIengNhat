import mongoose from 'mongoose';

const VocabularySchema = new mongoose.Schema({
    word: { type: String, required: true, index: true }, // Kanji: 学生
    hiragana: { type: String, required: true },          // Kana: がくせい
    meaning: { type: String, required: true },           // Nghĩa: Học sinh
    level: { type: String, enum: ['N5', 'N4', 'N3', 'N2', 'N1'], index: true },
    // Âm Hán-Việt của từ, vd 学生 → "HỌC SINH".
    //
    // `Kanji` đã có trường này cho từng chữ, nhưng âm của một *từ* không phải
    // lúc nào cũng ghép được từ âm của từng chữ, và nguồn dữ liệu thường cho
    // sẵn ở mức từ. Đây là lợi thế riêng của app cho người Việt (mục "Bài học
    // Hán-Việt" trong lộ trình), nên vứt đi lúc nhập là mất thứ khó lấy lại.
    hanviet: { type: String, trim: true },
    // Nhãn bài trong **giáo trình nguồn**, vd "Bài 26".
    //
    // Khác hẳn `lesson` ở dưới: `lesson` trỏ tới một document `Lesson` của
    // app, còn đây chỉ là chuỗi ghi lại từ này nằm ở bài nào trong sách. Giữ
    // nó vì đó là thông tin **thứ tự học** duy nhất có trong dữ liệu nguồn —
    // vứt đi lúc nhập thì sau này muốn chia bài phải tra lại từng từ một.
    source_lesson: { type: String, trim: true },
    // Nhóm động từ theo cách đánh số của Minna no Nihongo: 1 = godan,
    // 2 = ichidan, 3 = bất quy tắc.
    //
    // Tách khỏi `hiragana` chứ không để nguyên chuỗi "おしえます (II)": cột đó
    // là **cách đọc**, thứ sẽ hiển thị trên thẻ ôn và sau này đưa cho giọng
    // đọc. Để nguyên thì máy đọc thành "hai", còn người học thì học thuộc cả
    // dấu ngoặc.
    verb_group: { type: Number, enum: [1, 2, 3] },
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
import mongoose from 'mongoose';

import { SITUATIONS } from '../src/modules/lessons/situation-catalog.js';

/**
 * Một lượt thoại trong hội thoại của bài học tình huống.
 *
 * `reading` là cách đọc cả câu bằng hiragana/katakana, không phải ruby text
 * theo từng kanji — đủ để người học N5 đọc được mà không cần UI furigana.
 */
const DialogueTurnSchema = new mongoose.Schema({
    speaker: { type: String, required: true, trim: true },
    text_ja: { type: String, required: true, trim: true },
    reading: { type: String, required: true, trim: true },
    text_vi: { type: String, required: true, trim: true },
    audio_url: { type: String, default: null },
}, { _id: false });

/**
 * Một dòng lời thoại của video bài học, dùng cho phần "Kịch bản" chạy theo
 * video: mốc thời gian để tô sáng dòng đang nói, ba ngôn ngữ để người học bật
 * tắt từng loại (tiếng Nhật / Roma-ji / tiếng Việt). Tên người nói cũng có đủ
 * ba dạng để đứng cạnh đúng lớp chữ của nó.
 *
 * `key_phrase` đánh dấu câu then chốt của cảnh — phần "Mẫu câu" liệt kê các
 * câu này và phát lại đúng đoạn video của từng câu.
 */
const TranscriptLineSchema = new mongoose.Schema({
    start_seconds: { type: Number, required: true, min: 0 },
    end_seconds: { type: Number, default: null, min: 0 },
    speaker_ja: { type: String, default: null, trim: true },
    speaker_romaji: { type: String, default: null, trim: true },
    speaker_vi: { type: String, default: null, trim: true },
    text_ja: { type: String, required: true, trim: true },
    romaji: { type: String, default: null, trim: true },
    text_vi: { type: String, required: true, trim: true },
    key_phrase: { type: Boolean, default: false },
}, { _id: false });

/** Một từ trong bảng "Từ vựng" của một video: mặt chữ, cách đọc, roma-ji, nghĩa. */
const VideoWordSchema = new mongoose.Schema({
    word: { type: String, required: true, trim: true },
    reading: { type: String, default: null, trim: true },
    romaji: { type: String, default: null, trim: true },
    meaning: { type: String, required: true, trim: true },
}, { _id: false });

export const VIDEO_KINDS = Object.freeze(['scene', 'review']);

/**
 * Video của bài học. `url` là đường dẫn tương đối tới file do backend phục vụ
 * (`/uploads/lesson-videos/...`) hoặc một URL tuyệt đối tới nguồn bên ngoài —
 * app không cần biết khác nhau, chỉ mở `url`.
 *
 * `source` ghi nguồn gốc để màn hình hiển thị và để biết nội dung nào không
 * phải do app tự sản xuất.
 *
 * `duration_seconds` đọc từ chính file khi nhập, để app hiện thời lượng trên
 * khung chờ mà không phải tải video trước.
 *
 * `kind` tách cảnh tình huống (`scene`) khỏi video ôn tập cuối chủ đề
 * (`review`): app đánh số "Cảnh 1, 2, 3" cho cảnh, còn video ôn tập mang tên
 * riêng thay vì thành "Cảnh 4".
 */
const LessonVideoSchema = new mongoose.Schema({
    title: { type: String, required: true, trim: true },
    url: { type: String, required: true, trim: true },
    description: { type: String, default: null, trim: true },
    source: { type: String, default: null, trim: true },
    duration_seconds: { type: Number, default: null, min: 0 },
    kind: { type: String, enum: VIDEO_KINDS, default: 'scene' },
    transcript: { type: [TranscriptLineSchema], default: [] },
    vocabulary: { type: [VideoWordSchema], default: [] },
}, { _id: false });

const LessonSchema = new mongoose.Schema({
    title: { type: String, required: true, trim: true, unique: true },
    level: { type: String, required: true, enum: ['N5', 'N4', 'N3', 'N2', 'N1'], index: true },
    order: { type: Number, default: 1, min: 1 },
    description: { type: String, trim: true },
    content_html: String,
    type: { type: String, trim: true, index: true },
    situation: { type: String, enum: SITUATIONS, default: null, index: true },

    // Bài học tình huống: hội thoại và mục tiêu "làm được gì sau bài này".
    // Bài ngữ pháp cũ để trống hai mảng này và vẫn dùng content_html.
    dialogue: { type: [DialogueTurnSchema], default: [] },

    // Video của bài kèm lời thoại chạy theo video. Bài chưa có video thì mảng
    // rỗng và giao diện bỏ hẳn khối video, không hiện khung trống.
    videos: { type: [LessonVideoSchema], default: [] },
    can_do_goals: { type: [String], default: [] },

    // Các tham chiếu đến từ vựng, ngữ pháp, kanji trong bài học
    vocabularies: { type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Vocabulary' }], default: [] },
    grammars: { type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Grammar' }], default: [] },
    kanjis: { type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Kanji' }], default: [] }

}, { timestamps: true });

// Text index để tìm kiếm nhanh theo title + description
LessonSchema.index({ title: 'text', description: 'text' });

export default mongoose.model('Lesson', LessonSchema);

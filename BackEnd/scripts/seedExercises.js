import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Exercise from '../model/Exercise.js';
import Lesson from '../model/Lesson.js';

dotenv.config();

const sampleExercises = [
    {
        title: 'Bài tập từ vựng N5 - Chào hỏi',
        type: 'Từ vựng',
        level: 'N5',
        description: 'Luyện tập các từ vựng cơ bản về chào hỏi trong tiếng Nhật',
        time_limit: 10,
        pass_score: 70,
        questions: [
            {
                content: 'Từ "おはよう" có nghĩa là gì?',
                answers: [
                    { content: 'Chào buổi sáng', is_correct: true },
                    { content: 'Chào buổi chiều', is_correct: false },
                    { content: 'Chào buổi tối', is_correct: false },
                    { content: 'Tạm biệt', is_correct: false }
                ],
                explanation: 'おはよう (ohayou) nghĩa là "chào buổi sáng"'
            },
            {
                content: 'Cách nói "Cảm ơn" trong tiếng Nhật là gì?',
                answers: [
                    { content: 'すみません', is_correct: false },
                    { content: 'ありがとう', is_correct: true },
                    { content: 'ごめんなさい', is_correct: false },
                    { content: 'さようなら', is_correct: false }
                ],
                explanation: 'ありがとう (arigatou) nghĩa là "cảm ơn"'
            },
            {
                content: '"さようなら" có nghĩa là gì?',
                answers: [
                    { content: 'Xin chào', is_correct: false },
                    { content: 'Cảm ơn', is_correct: false },
                    { content: 'Tạm biệt', is_correct: true },
                    { content: 'Xin lỗi', is_correct: false }
                ],
                explanation: 'さようなら (sayounara) nghĩa là "tạm biệt"'
            }
        ]
    },
    {
        title: 'Bài tập ngữ pháp N4 - Thì quá khứ',
        type: 'Ngữ pháp',
        level: 'N4',
        description: 'Luyện tập cách chia động từ thì quá khứ',
        time_limit: 15,
        pass_score: 75,
        questions: [
            {
                content: 'Thì quá khứ của động từ "食べる" (ăn) là gì?',
                answers: [
                    { content: '食べた', is_correct: true },
                    { content: '食べます', is_correct: false },
                    { content: '食べない', is_correct: false },
                    { content: '食べて', is_correct: false }
                ],
                explanation: '食べた (tabeta) là dạng quá khứ của 食べる'
            },
            {
                content: 'Câu nào đúng để nói "Tôi đã xem phim hôm qua"?',
                answers: [
                    { content: '昨日映画を見る', is_correct: false },
                    { content: '昨日映画を見た', is_correct: true },
                    { content: '昨日映画を見ます', is_correct: false },
                    { content: '昨日映画を見ない', is_correct: false }
                ],
                explanation: '見た (mita) là dạng quá khứ của 見る (xem)'
            }
        ]
    },
    {
        title: 'Bài tập Kanji N3 - Chữ Hán cơ bản',
        type: 'Kanji',
        level: 'N3',
        description: 'Luyện tập đọc và nghĩa của các chữ Hán cơ bản',
        time_limit: 12,
        pass_score: 80,
        questions: [
            {
                content: 'Kanji "山" đọc là gì?',
                answers: [
                    { content: 'やま (yama)', is_correct: true },
                    { content: 'かわ (kawa)', is_correct: false },
                    { content: 'うみ (umi)', is_correct: false },
                    { content: 'そら (sora)', is_correct: false }
                ],
                explanation: '山 (やま) nghĩa là "núi"'
            },
            {
                content: '"日本" đọc là gì?',
                answers: [
                    { content: 'ちゅうごく', is_correct: false },
                    { content: 'にほん', is_correct: true },
                    { content: 'かんこく', is_correct: false },
                    { content: 'あめりか', is_correct: false }
                ],
                explanation: '日本 (にほん) nghĩa là "Nhật Bản"'
            },
            {
                content: 'Kanji "水" có nghĩa là gì?',
                answers: [
                    { content: 'Lửa', is_correct: false },
                    { content: 'Đất', is_correct: false },
                    { content: 'Nước', is_correct: true },
                    { content: 'Gió', is_correct: false }
                ],
                explanation: '水 (みず) nghĩa là "nước"'
            }
        ]
    },
    {
        title: 'Bài tập tổng hợp N5 - Kiểm tra toàn diện',
        type: 'Tổng hợp',
        level: 'N5',
        description: 'Bài tập tổng hợp kiểm tra từ vựng, ngữ pháp và Kanji cấp độ N5',
        time_limit: 20,
        pass_score: 65,
        questions: [
            {
                content: 'Điền từ thích hợp: 私___学生です。',
                answers: [
                    { content: 'は', is_correct: true },
                    { content: 'が', is_correct: false },
                    { content: 'を', is_correct: false },
                    { content: 'に', is_correct: false }
                ],
                explanation: 'は là조사 (trợ từ) chủ đề, đúng nhất trong câu này'
            },
            {
                content: '"これ" có nghĩa là gì?',
                answers: [
                    { content: 'Cái đó (gần người nghe)', is_correct: false },
                    { content: 'Cái này (gần người nói)', is_correct: true },
                    { content: 'Cái kia (xa cả hai)', is_correct: false },
                    { content: 'Cái nào', is_correct: false }
                ],
                explanation: 'これ nghĩa là "cái này", chỉ vật gần người nói'
            }
        ]
    },
    {
        title: 'Bài tập từ vựng N4 - Gia đình',
        type: 'Từ vựng',
        level: 'N4',
        description: 'Học từ vựng liên quan đến thành viên gia đình',
        time_limit: 10,
        pass_score: 70,
        questions: [
            {
                content: 'Từ "お父さん" có nghĩa là gì?',
                answers: [
                    { content: 'Mẹ', is_correct: false },
                    { content: 'Bố', is_correct: true },
                    { content: 'Anh trai', is_correct: false },
                    { content: 'Em gái', is_correct: false }
                ],
                explanation: 'お父さん (otousan) nghĩa là "bố"'
            },
            {
                content: 'Cách gọi "em gái" của mình là gì?',
                answers: [
                    { content: '妹 (いもうと)', is_correct: true },
                    { content: '姉 (あね)', is_correct: false },
                    { content: '弟 (おとうと)', is_correct: false },
                    { content: '兄 (あに)', is_correct: false }
                ],
                explanation: '妹 (imouto) nghĩa là "em gái"'
            }
        ]
    }
];

async function seedExercises() {
    try {
        const mongoURI = process.env.MONGODB_URI;
        if (!mongoURI) {
            throw new Error('MONGODB_URI không được định nghĩa trong file .env');
        }

        await mongoose.connect(mongoURI, {
            dbName: process.env.DB_NAME || 'AppHocTiengNhat'
        });
        console.log('✅ Kết nối MongoDB thành công!');

        // Tìm một lesson để gán cho exercises (hoặc tạo lesson mới nếu chưa có)
        let lesson = await Lesson.findOne();
        
        if (!lesson) {
            console.log('⚠️  Không tìm thấy lesson nào, tạo lesson mẫu...');
            lesson = await Lesson.create({
                title: 'Bài học mẫu',
                level: 'N5',
                description: 'Bài học mẫu để gán cho exercises',
                order: 1
            });
            console.log('✅ Đã tạo lesson mẫu:', lesson.title);
        }

        console.log('📝 Sử dụng lesson:', lesson.title);

        // Xóa các exercises cũ (tùy chọn)
        const deleteCount = await Exercise.countDocuments();
        if (deleteCount > 0) {
            console.log(`⚠️  Tìm thấy ${deleteCount} bài tập cũ. Xóa hết? (đang bỏ qua...)`);
            // await Exercise.deleteMany({}); // Uncomment để xóa
        }

        // Thêm exercises mới
        for (const exerciseData of sampleExercises) {
            const exercise = await Exercise.create({
                ...exerciseData,
                lesson_id: lesson._id
            });
            console.log(`✅ Đã tạo bài tập: ${exercise.title} (${exercise.questions.length} câu hỏi)`);
        }

        console.log('\n🎉 Hoàn thành! Đã tạo', sampleExercises.length, 'bài tập mẫu.');
        
        // Thống kê
        const stats = await Exercise.aggregate([
            { $group: { _id: '$level', count: { $sum: 1 } } },
            { $sort: { _id: 1 } }
        ]);
        console.log('\n📊 Thống kê theo cấp độ:');
        stats.forEach(stat => {
            console.log(`   ${stat._id}: ${stat.count} bài`);
        });

        process.exit(0);
    } catch (error) {
        console.error('❌ Lỗi:', error.message);
        process.exit(1);
    }
}

seedExercises();

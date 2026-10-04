import { exerciseSubmissionService } from './exercise-submission.service.js';
import Exercise from '../../../model/Exercise.js';
import ExerciseResult from '../../../model/ExerciseResult.js';
import mongoose from 'mongoose';


// USER ROUTES

// Lấy danh sách bài tập theo cấp độ
export const listByLevel = async (req, res) => {
    try {
        const { level } = req.params;

        const exercises = await Exercise.find({ 
            level: level,
            is_active: true 
        })
        .select('title type level description time_limit total_attempts createdAt questions')
        .lean();

        // Đếm câu hỏi rồi bỏ hẳn `questions` khỏi DTO. Mảng đó chứa
        // `answers[].is_correct` và `explanation`, tức là đáp án của bài: chi
        // tiết bài tập (`getExercise`) đã cố tình lược hai trường này trước khi
        // người dùng nộp, danh sách phải theo cùng quy tắc.
        const exercisesWithCount = exercises.map(({ questions, ...rest }) => ({
            ...rest,
            question_count: Array.isArray(questions) ? questions.length : 0
        }));

        res.json(exercisesWithCount);
    } catch (error) {
        console.error("Lỗi lấy danh sách bài tập theo cấp độ:", error);
        res.status(500).json({ error: error.message });
    }
};

// Lấy danh sách bài tập theo loại
export const listByType = async (req, res) => {
    try {
        const { type } = req.params;

        const exercises = await Exercise.find({ 
            type: type,
            is_active: true 
        })
        .select('title type level description time_limit total_attempts createdAt questions')
        .lean();

        // Đếm câu hỏi rồi bỏ hẳn `questions` khỏi DTO. Mảng đó chứa
        // `answers[].is_correct` và `explanation`, tức là đáp án của bài: chi
        // tiết bài tập (`getExercise`) đã cố tình lược hai trường này trước khi
        // người dùng nộp, danh sách phải theo cùng quy tắc.
        const exercisesWithCount = exercises.map(({ questions, ...rest }) => ({
            ...rest,
            question_count: Array.isArray(questions) ? questions.length : 0
        }));

        res.json(exercisesWithCount);
    } catch (error) {
        console.error("Lỗi lấy danh sách bài tập theo loại:", error);
        res.status(500).json({ error: error.message });
    }
};

// Lấy danh sách bài tập của 1 bài học
export const listByLesson = async (req, res) => {
    try {
        const { lessonID } = req.params;
        
        if (!mongoose.Types.ObjectId.isValid(lessonID)) {
            return res.status(400).json({ error: "ID bài học không hợp lệ." });
        }

        const exercises = await Exercise.find({ 
            lesson_id: lessonID,
            is_active: true 
        })
        .select('title type level description time_limit total_attempts createdAt questions')
        .lean();

        // Đếm câu hỏi rồi bỏ hẳn `questions` khỏi DTO. Mảng đó chứa
        // `answers[].is_correct` và `explanation`, tức là đáp án của bài: chi
        // tiết bài tập (`getExercise`) đã cố tình lược hai trường này trước khi
        // người dùng nộp, danh sách phải theo cùng quy tắc.
        const exercisesWithCount = exercises.map(({ questions, ...rest }) => ({
            ...rest,
            question_count: Array.isArray(questions) ? questions.length : 0
        }));

        res.json(exercisesWithCount);
    } catch (error) {
        console.error("Lỗi lấy danh sách bài tập:", error);
        res.status(500).json({ error: error.message });
    }
};

// Nộp bài và chấm điểm
//
// Toàn bộ phần chấm, lưu kết quả và ghi hoạt động học nằm trong
// `exercise-submission.service.js`: nó chạy trong một transaction và chống
// nộp trùng bằng `attempt_id`. Controller chỉ còn việc map HTTP.
export const submitExercise = async (req, res) => {
    const { id } = req.valid.params;
    const { attempt_id: attemptId, answers, timeSpent } = req.valid.body;

    const { result, replayed } = await exerciseSubmissionService.submit({
        userId: req.user._id,
        exerciseId: id,
        attemptId,
        answers,
        timeSpent,
    });

    // Gửi lại đúng lượt làm cũ không tạo thêm gì, nên không phải 201.
    res.status(replayed ? 200 : 201).json(result);
};

// Xem lịch sử làm bài của user
export const getMyHistory = async (req, res) => {
    try {
        const userId = req.user._id;

        const results = await ExerciseResult.find({ 
            user_id: userId
        })
        .populate('exercise_id', 'title type level')
        .sort({ completed_at: -1, createdAt: -1 })
        .lean();

        res.json(results);

    } catch (error) {
        console.error("Lỗi xem lịch sử:", error);
        res.status(500).json({ error: error.message });
    }
};

// Xem chi tiết kết quả 1 lần làm bài
export const getMyResult = async (req, res) => {
    try {
        const { resultId } = req.params;
        const userId = req.user._id;

        if (!mongoose.Types.ObjectId.isValid(resultId)) {
            return res.status(400).json({ error: "ID kết quả không hợp lệ." });
        }

        const result = await ExerciseResult.findOne({ 
            _id: resultId,
            user_id: userId 
        })
        .populate({
            path: 'exercise_id',
            select: 'title type level questions'
        })
        .lean();

        if (!result) {
            return res.status(404).json({ error: "Không tìm thấy kết quả." });
        }

        res.json(result);

    } catch (error) {
        console.error("Lỗi xem chi tiết kết quả:", error);
        res.status(500).json({ error: error.message });
    }
};

// Lấy chi tiết bài tập (không có đáp án đúng)
export const getExercise = async (req, res) => {
    try {
        const { id } = req.params;
        
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ error: "ID bài tập không hợp lệ." });
        }

        const exercise = await Exercise.findOne({ 
            _id: id,
            is_active: true 
        })
        .populate('lesson_id', 'title level')
        .lean();

        if (!exercise) {
            return res.status(404).json({ error: "Không tìm thấy bài tập." });
        }

        // Loại bỏ is_correct khỏi answers
        exercise.questions = (exercise.questions || []).map(q => ({
            ...q,
            answers: (q.answers || []).map(a => ({
                _id: a._id,
                content: a.content
            })),
            explanation: undefined // Không trả về giải thích lúc làm bài
        }));

        res.json(exercise);
    } catch (error) {
        console.error("Lỗi lấy chi tiết bài tập:", error);
        res.status(500).json({ error: error.message });
    }
};

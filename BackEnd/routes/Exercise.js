import express from 'express';
import { authenticateAdmin, authenticateUser } from './auth.js';
import multer from 'multer';
import xlsx from 'xlsx';
import Exercise from '../model/Exercise.js';
import ExerciseResult from '../model/ExerciseResult.js';
import Lesson from '../model/Lesson.js';
import mongoose from 'mongoose';

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

// USER ROUTES

// Lấy danh sách bài tập của 1 bài học
router.get("/lesson/:lessonID", authenticateUser, async (req, res) => {
    try {
        const { lessonID } = req.params;
        
        if (!mongoose.Types.ObjectId.isValid(lessonID)) {
            return res.status(400).json({ error: "ID bài học không hợp lệ." });
        }

        const exercises = await Exercise.find({ 
            lesson_id: lessonID,
            is_active: true 
        })
        .select('title type level description time_limit total_attempts createdAt')
        .lean();

        // Thêm số câu hỏi cho mỗi bài tập
        const exercisesWithCount = exercises.map(ex => ({
            ...ex,
            question_count: ex.questions?.length || 0
        }));

        res.json(exercisesWithCount);
    } catch (error) {
        console.error("Lỗi lấy danh sách bài tập:", error);
        res.status(500).json({ error: error.message });
    }
});

// Lấy chi tiết bài tập (không có đáp án đúng)
router.get("/:id", authenticateUser, async (req, res) => {
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
        exercise.questions = exercise.questions.map(q => ({
            ...q,
            answers: q.answers.map(a => ({
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
});

// Nộp bài và chấm điểm
router.post("/submit/:id", authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id || req.user.id;
        const { answers, timeSpent } = req.body; // answers: [{ question_id, answer_id }]

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ error: "ID bài tập không hợp lệ." });
        }

        if (!answers || !Array.isArray(answers) || answers.length === 0) {
            return res.status(400).json({ error: "Định dạng bài nộp không hợp lệ." });
        }

        const exercise = await Exercise.findById(id);
        if (!exercise) {
            return res.status(404).json({ error: "Không tìm thấy bài tập." });
        }

        const totalQuestions = exercise.questions.length;
        if (totalQuestions === 0) {
            return res.status(404).json({ error: "Bài tập này không có câu hỏi." });
        }

        // Chấm điểm
        let correctCount = 0;
        const userAnswers = [];

        for (const userAns of answers) {
            const question = exercise.questions.id(userAns.question_id);
            if (!question) continue;

            const selectedAnswer = question.answers.id(userAns.answer_id);
            if (!selectedAnswer) continue;

            const isCorrect = selectedAnswer.is_correct;
            if (isCorrect) correctCount++;

            userAnswers.push({
                question_id: userAns.question_id,
                answer_id: userAns.answer_id,
                is_correct: isCorrect
            });
        }

        const score = parseFloat(((correctCount / totalQuestions) * 100).toFixed(2));
        const isPassed = score >= exercise.pass_score;

        // Lưu kết quả
        const result = await ExerciseResult.create({
            user_id: userId,
            exercise_id: id,
            score,
            correct_count: correctCount,
            total_questions: totalQuestions,
            time_spent: timeSpent || 0,
            user_answers: userAnswers,
            is_passed: isPassed
        });

        // Tăng số lượt làm bài
        await Exercise.findByIdAndUpdate(id, { $inc: { total_attempts: 1 } });

        res.status(201).json({
            message: "Nộp bài thành công!",
            Diem: result.score,
            KetQuaID: result._id,
            is_passed: isPassed,
            correct_count: correctCount,
            total_questions: totalQuestions
        });

    } catch (error) {
        console.error("Lỗi nộp bài:", error);
        res.status(500).json({ error: error.message });
    }
});

// Xem đáp án (sau khi làm xong)
router.get("/check-answers/:id", authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id || req.user.id;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ error: "ID bài tập không hợp lệ." });
        }

        // Kiểm tra user đã làm bài chưa
        const hasAttempt = await ExerciseResult.exists({ 
            user_id: userId, 
            exercise_id: id 
        });

        if (!hasAttempt) {
            return res.status(403).json({ 
                error: "Bạn phải làm bài trước khi xem đáp án." 
            });
        }

        const exercise = await Exercise.findById(id, 'questions').lean();

        if (!exercise) {
            return res.status(404).json({ error: "Không tìm thấy bài tập." });
        }

        res.json(exercise.questions);

    } catch (error) {
        console.error("Lỗi xem đáp án:", error);
        res.status(500).json({ error: error.message });
    }
});

// Xem lịch sử làm bài
router.get("/my-results/:id", authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id || req.user.id;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ error: "ID bài tập không hợp lệ." });
        }

        const results = await ExerciseResult.find({ 
            user_id: userId,
            exercise_id: id 
        })
        .select('-user_answers')
        .sort({ completed_at: -1 })
        .lean();

        res.json(results);

    } catch (error) {
        console.error("Lỗi xem lịch sử:", error);
        res.status(500).json({ error: error.message });
    }
});

// ADMIN ROUTES 

// Thêm bài tập mới
router.post("/lesson/:lessonID", authenticateAdmin, async (req, res) => {
    try {
        const { lessonID } = req.params;
        const { title, type, level, description, time_limit, pass_score } = req.body;

        if (!mongoose.Types.ObjectId.isValid(lessonID)) {
            return res.status(400).json({ error: "ID bài học không hợp lệ." });
        }

        if (!title || !level) {
            return res.status(400).json({ error: "Vui lòng nhập đầy đủ tiêu đề và cấp độ." });
        }

        const lesson = await Lesson.findById(lessonID);
        if (!lesson) {
            return res.status(404).json({ error: "Không tìm thấy bài học." });
        }

        const newExercise = await Exercise.create({
            lesson_id: lessonID,
            title,
            type: type || 'Tổng hợp',
            level,
            description,
            time_limit: time_limit || 0,
            pass_score: pass_score || 60,
            questions: []
        });

        res.status(201).json(newExercise);

    } catch (error) {
        console.error("Lỗi thêm bài tập:", error);
        res.status(500).json({ error: error.message });
    }
});

// Cập nhật bài tập
router.put("/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ error: "ID bài tập không hợp lệ." });
        }

        const updatedExercise = await Exercise.findByIdAndUpdate(
            id,
            updateData,
            { new: true, runValidators: true }
        );

        if (!updatedExercise) {
            return res.status(404).json({ error: "Không tìm thấy bài tập." });
        }

        res.json(updatedExercise);

    } catch (error) {
        console.error("Lỗi cập nhật bài tập:", error);
        res.status(500).json({ error: error.message });
    }
});

// Xóa bài tập
router.delete("/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ error: "ID bài tập không hợp lệ." });
        }

        const deleted = await Exercise.findByIdAndUpdate(
            id,
            { is_active: false },
            { new: true }
        );

        if (!deleted) {
            return res.status(404).json({ error: "Không tìm thấy bài tập." });
        }

        res.status(204).send();

    } catch (error) {
        console.error("Lỗi xóa bài tập:", error);
        res.status(500).json({ error: error.message });
    }
});

// Thêm câu hỏi trắc nghiệm
router.post("/questions/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const { content, answers, explanation } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ error: "ID bài tập không hợp lệ." });
        }

        if (!content || !answers || !Array.isArray(answers) || answers.length < 2) {
            return res.status(400).json({ 
                error: "Câu hỏi phải có nội dung và ít nhất 2 đáp án." 
            });
        }

        // Kiểm tra có đáp án đúng
        const hasCorrect = answers.some(ans => ans.is_correct === true);
        if (!hasCorrect) {
            return res.status(400).json({ error: "Phải có ít nhất 1 đáp án đúng." });
        }

        const exercise = await Exercise.findById(id);
        if (!exercise) {
            return res.status(404).json({ error: "Không tìm thấy bài tập." });
        }

        exercise.questions.push({
            content,
            answers,
            explanation
        });

        await exercise.save();

        const newQuestion = exercise.questions[exercise.questions.length - 1];
        res.status(201).json(newQuestion);

    } catch (error) {
        console.error("Lỗi thêm câu hỏi:", error);
        res.status(500).json({ error: error.message });
    }
});

// Cập nhật câu hỏi
router.put("/questions/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const { exerciseId, content, answers, explanation } = req.body;

        if (!mongoose.Types.ObjectId.isValid(exerciseId) || !mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ error: "ID không hợp lệ." });
        }

        const exercise = await Exercise.findById(exerciseId);
        if (!exercise) {
            return res.status(404).json({ error: "Không tìm thấy bài tập." });
        }

        const question = exercise.questions.id(id);
        if (!question) {
            return res.status(404).json({ error: "Không tìm thấy câu hỏi." });
        }

        if (content) question.content = content;
        if (answers) {
            const hasCorrect = answers.some(ans => ans.is_correct === true);
            if (!hasCorrect) {
                return res.status(400).json({ error: "Phải có ít nhất 1 đáp án đúng." });
            }
            question.answers = answers;
        }
        if (explanation !== undefined) question.explanation = explanation;

        await exercise.save();

        res.json({ message: "Cập nhật câu hỏi thành công." });

    } catch (error) {
        console.error("Lỗi cập nhật câu hỏi:", error);
        res.status(500).json({ error: error.message });
    }
});

// Xóa câu hỏi
router.delete("/questions/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const { exerciseId } = req.body;

        if (!mongoose.Types.ObjectId.isValid(exerciseId) || !mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ error: "ID không hợp lệ." });
        }

        const exercise = await Exercise.findById(exerciseId);
        if (!exercise) {
            return res.status(404).json({ error: "Không tìm thấy bài tập." });
        }

        const question = exercise.questions.id(id);
        if (!question) {
            return res.status(404).json({ error: "Không tìm thấy câu hỏi." });
        }

        question.remove();
        await exercise.save();

        res.status(204).send();

    } catch (error) {
        console.error("Lỗi xóa câu hỏi:", error);
        res.status(500).json({ error: error.message });
    }
});

// Xem kết quả (Admin)
router.get("/result/:id", authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ error: "ID bài tập không hợp lệ." });
        }

        const results = await ExerciseResult.find({ exercise_id: id })
            .populate('user_id', 'full_name email username')
            .select('-user_answers')
            .sort({ score: -1, completed_at: -1 })
            .lean();

        res.json(results);

    } catch (error) {
        console.error("Lỗi xem kết quả:", error);
        res.status(500).json({ error: error.message });
    }
});

// Upload Excel
router.post("/upload/:id", authenticateAdmin, upload.single('file'), async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: "ID bài tập không hợp lệ." });
        }

        const exercise = await Exercise.findById(id);
        if (!exercise) {
            return res.status(404).json({ message: "Không tìm thấy bài tập." });
        }

        if (!req.file) {
            return res.status(400).json({ message: "Vui lòng upload file Excel." });
        }

        if (!req.file.originalname.endsWith(".xlsx") && !req.file.mimetype.includes("sheet")) {
            return res.status(400).json({ 
                message: "File không hợp lệ. Vui lòng upload file Excel (.xlsx)." 
            });
        }

        const workbook = xlsx.read(req.file.buffer, { type: 'buffer' });
        const worksheet = workbook.Sheets[workbook.SheetNames[0]];
        const data = xlsx.utils.sheet_to_json(worksheet);

        if (!data || data.length === 0) {
            return res.status(400).json({ message: "File Excel không có dữ liệu." });
        }

        let countSuccess = 0;
        let errors = [];

        for (let i = 0; i < data.length; i++) {
            const row = data[i];
            const rowIndex = i + 2;

            if (!row.NoiDung || !row.DapAnA || !row.DapAnB || !row.DapAnDung) {
                errors.push({ 
                    row: rowIndex, 
                    issue: "Thiếu trường: NoiDung, DapAnA, DapAnB, DapAnDung" 
                });
                continue;
            }

            const correctChar = row.DapAnDung.toString().trim().toUpperCase();
            if (!["A", "B", "C", "D"].includes(correctChar)) {
                errors.push({ row: rowIndex, issue: "DapAnDung phải là A/B/C/D" });
                continue;
            }

            try {
                const answers = [
                    { content: row.DapAnA, is_correct: correctChar === 'A' },
                    { content: row.DapAnB, is_correct: correctChar === 'B' }
                ];

                if (row.DapAnC) {
                    answers.push({ content: row.DapAnC, is_correct: correctChar === 'C' });
                }
                if (row.DapAnD) {
                    answers.push({ content: row.DapAnD, is_correct: correctChar === 'D' });
                }

                exercise.questions.push({
                    content: row.NoiDung,
                    answers,
                    explanation: row.GiaiThich || ''
                });

                countSuccess++;
            } catch (err) {
                errors.push({ 
                    row: rowIndex, 
                    issue: "Lỗi: " + err.message 
                });
            }
        }

        await exercise.save();

        res.status(201).json({
            message: `${countSuccess} câu hỏi đã được thêm thành công.`,
            errors
        });

    } catch (error) {
        console.error("Lỗi upload Excel:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
});

export default router;
import { jlptSubmissionService } from './jlpt-submission.service.js';
import { submissionOf } from './jlpt.schema.js';
import mongoose from 'mongoose';
import JLPT from '../../../model/JLPT.js';
import LearningHistory from '../../../model/LearningHistory.js';

// Utility: shuffle array in-place
const shuffleArray = (arr) => {
    for (let i = arr.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [arr[i], arr[j]] = [arr[j], arr[i]];
    }
    return arr;
};

// Utility: collect practice questions by type
const collectPracticeQuestions = async ({ level, type, limit }) => {
    const match = { is_published: true, is_active: true };
    if (level) match.level = level;

    const exams = await JLPT.find(match)
        .select(`level title sections.${type}`)
        .lean();

    const pool = [];

    const pushSingle = (q, exam) => {
        pool.push({
            ...q,
            exam_id: exam._id,
            exam_title: exam.title,
            level: exam.level,
            section: type
        });
    };

    exams.forEach(exam => {
        const section = exam.sections?.[type];
        if (!section || !Array.isArray(section)) return;

        if (type === 'moji_goi' || type === 'bunpou') {
            section.forEach(q => pushSingle(q, exam));
        } else {
            // dokkai, choukai: flatten group questions with context
            section.forEach(group => {
                (group.questions || []).forEach(q => {
                    pushSingle({
                        ...q,
                        group_content: group.group_content,
                        group_image: group.group_image,
                        group_audio: group.group_audio,
                        transcript: group.transcript,
                    }, exam);
                });
            });
        }
    });

    shuffleArray(pool);
    return pool.slice(0, limit);
};

// API Lấy danh sách bộ đề
export const listExams = async (req, res) => {
    try {
        const userId = req.user._id;
        const { level, year, month, page = 1, limit = 10 } = req.query;
        const skip = (parseInt(page) - 1) * parseInt(limit);
        const filter = { is_published: true, is_active: true };
        if (level) filter.level = level;
        if (year) filter.year = parseInt(year);
        if (month) filter.month = parseInt(month);

        const [listDe, total] = await Promise.all([
            JLPT.find(filter)
                .sort({ year: -1, month: -1, createdAt: -1 })
                .limit(parseInt(limit))
                .skip(skip)
                .lean(),
            JLPT.countDocuments(filter)
        ]);

        const examIds = listDe.map(e => e._id);
        const histories = await LearningHistory.find({
            user: userId,
            exam: { $in: examIds }
        })
        .select('exam score is_passed taken_at createdAt')
        .sort({ taken_at: -1 })
        .lean();

        const historyMap = new Map();
        histories.forEach(h => {
            // Some records may store exam under `exam` instead of `exam_id`
            const examRef = h.exam || h.exam_id || h.examId;
            if (!examRef) return;
            const examIdStr = examRef.toString();
            if (!historyMap.has(examIdStr)) {
                historyMap.set(examIdStr, h);
            }
        });

        const result = listDe.map(de => {
            let totalQuestions = 0;
            totalQuestions += de.sections?.moji_goi?.length || 0;
            totalQuestions += de.sections?.bunpou?.length || 0;
            de.sections?.dokkai?.forEach(g => { totalQuestions += g.questions?.length || 0; });
            de.sections?.choukai?.forEach(g => { totalQuestions += g.questions?.length || 0; });

            const history = historyMap.get(de._id.toString());
            return {
                id: de._id,
                title: de.title,
                description: de.description,
                level: de.level,
                year: de.year,
                month: de.month,
                time_limit: de.time_limit,
                pass_score: de.pass_score,
                total_score: de.total_score,
                total_questions: totalQuestions,
                total_views: de.total_views,
                created_at: de.createdAt,
                TrangThaiLamBai: history ? 'Đã làm' : 'Chưa làm',
                KetQuaGannhat: history ? {
                    score: history.score,
                    is_passed: history.is_passed,
                    completed_at: history.taken_at || history.createdAt
                } : null
            };
        });

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / parseInt(limit)),
            currentPage: parseInt(page),
            data: result
        });
    } catch (error) {
        console.error('Lỗi khi lấy danh sách đề thi:', error);
        res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
};

// API Luyện nhanh theo kỹ năng
export const getPracticeQuestions = async (req, res) => {
    try {
        const { level, type = 'moji_goi', limit = 10 } = req.query;
        const allowed = ['moji_goi', 'bunpou', 'dokkai', 'choukai'];
        if (!allowed.includes(type)) {
            return res.status(400).json({ message: 'Loại luyện tập không hợp lệ.' });
        }
        const lim = Math.min(parseInt(limit) || 10, 50);
        const questions = await collectPracticeQuestions({ level, type, limit: lim });
        if (!questions.length) {
            return res.status(404).json({ message: 'Chưa có câu hỏi phù hợp.' });
        }
        res.json({ total: questions.length, data: questions });
    } catch (error) {
        console.error('Lỗi lấy câu hỏi luyện nhanh:', error);
        res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
};

// API Lấy đáp án sau khi đã nộp
export const getSolutions = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'ID đề thi không hợp lệ.' });
        }
        const history = await LearningHistory.findOne({ user: userId, exam: id }).lean();
        if (!history) {
            return res.status(403).json({ message: 'Bạn cần nộp bài trước khi xem đáp án.' });
        }
        const deThi = await JLPT.findOne({ _id: id, is_published: true, is_active: true }).lean();
        if (!deThi) {
            return res.status(404).json({ message: 'Không tìm thấy đề thi' });
        }
        res.json({
            exam: {
                id: deThi._id,
                title: deThi.title,
                level: deThi.level,
                year: deThi.year,
                month: deThi.month,
            },
            sections: deThi.sections
        });
    } catch (error) {
        console.error('Lỗi lấy đáp án:', error);
        res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
};

// API Lấy đề thi theo ID (ẩn đáp án)
export const getExam = async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'ID đề thi không hợp lệ.' });
        }
        const deThi = await JLPT.findOne({ _id: id, is_published: true, is_active: true })
            .populate('creator_id', 'HoTen Email')
            .lean();
        if (!deThi) {
            return res.status(404).json({ message: 'Không tìm thấy đề thi' });
        }
        const cleanSections = {
            moji_goi: deThi.sections.moji_goi?.map(q => {
                const { correct_answer, explanation, ...rest } = q;
                return rest;
            }) || [],
            bunpou: deThi.sections.bunpou?.map(q => {
                const { correct_answer, explanation, ...rest } = q;
                return rest;
            }) || [],
            dokkai: deThi.sections.dokkai?.map(group => ({
                ...group,
                questions: group.questions.map(q => {
                    const { correct_answer, explanation, ...rest } = q;
                    return rest;
                })
            })) || [],
            choukai: deThi.sections.choukai?.map(group => ({
                ...group,
                questions: group.questions.map(q => {
                    const { correct_answer, explanation, ...rest } = q;
                    return rest;
                })
            })) || []
        };

        await JLPT.findByIdAndUpdate(id, { $inc: { total_views: 1 } });

        res.json({
            id: deThi._id,
            title: deThi.title,
            description: deThi.description,
            level: deThi.level,
            year: deThi.year,
            month: deThi.month,
            time_limit: deThi.time_limit,
            pass_score: deThi.pass_score,
            total_score: deThi.total_score,
            created_at: deThi.createdAt,
            sections: cleanSections
        });
    } catch (error) {
        console.error('Lỗi khi lấy đề thi theo ID:', error);
        res.status(500).json({ error: error.message });
    }
};

// API: Nộp bài & chấm điểm (POST /:id/submit)
//
// Chấm, lưu kết quả và ghi hoạt động học nằm trong
// `jlpt-submission.service.js`: chạy trong một transaction, chống nộp trùng
// bằng `attempt_id`. Controller chỉ map HTTP.
export const submitExamHandler = async (req, res) => {
    const { id } = req.valid.params;
    const { answers, timeSpent } = submissionOf(req.valid.body);

    const { result } = await jlptSubmissionService.submit({
        userId: req.user._id,
        examId: id,
        attemptId: req.valid.body.attempt_id,
        answers,
        timeSpent,
    });

    res.json(result);
};

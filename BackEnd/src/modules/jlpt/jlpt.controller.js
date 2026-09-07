import multer from 'multer';
import xlsx from 'xlsx';
import mongoose from 'mongoose';
import JLPT from '../../../model/JLPT.js';
import LearningHistory from '../../../model/LearningHistory.js';
import Grammar from '../../../model/Grammar.js';
import UserStreak from '../../../model/UserStreak.js';
import { scoreExamAnswers } from './jlpt-scoring.service.js';

export const upload = multer({ storage: multer.memoryStorage() });

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

// API: Nộp bài & chấm điểm (hỗ trợ cả /submit/:id và /:id/submit)
export const submitExamHandler = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;
        const body = req.body || {};
        const rawAnswers = body.userAnswers || body.answers || body.user_answers || [];
        const thoiGianLamBai = body.thoiGianLamBai || body.ThoiGianLamBai || body.time_spent;
        const started_at = body.started_at;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'ID đề thi không hợp lệ.' });
        }
        if (!Array.isArray(rawAnswers) || rawAnswers.length === 0) {
            return res.status(400).json({ message: 'Dữ liệu bài làm không hợp lệ.' });
        }

        const deThi = await JLPT.findById(id);
        if (!deThi || !deThi.is_published || !deThi.is_active) {
            return res.status(404).json({ message: 'Đề thi không tồn tại.' });
        }

        const scoredExam = scoreExamAnswers({
            sections: deThi.sections,
            rawAnswers
        });
        const diemTuVung = scoredExam.sectionScores.moji_goi;
        const diemNguPhap = scoredExam.sectionScores.bunpou;
        const diemDocHieu = scoredExam.sectionScores.dokkai;
        const diemNgheHieu = scoredExam.sectionScores.choukai;
        const tongDiemDatDuoc = scoredExam.totalScore;
        const chiTietKetQuaList = scoredExam.answerDetails.map((detail) => {
            let questionId = detail.questionId;
            try {
                if (!questionId) {
                    questionId = new mongoose.Types.ObjectId();
                } else if (typeof questionId === 'string' && mongoose.Types.ObjectId.isValid(questionId)) {
                    questionId = new mongoose.Types.ObjectId(questionId);
                } else if (!(questionId instanceof mongoose.Types.ObjectId)) {
                    questionId = new mongoose.Types.ObjectId();
                }
            } catch (error) {
                questionId = new mongoose.Types.ObjectId();
            }

            return {
                question_id: questionId,
                user_choice: detail.userChoice,
                is_correct: detail.isCorrect,
                section: detail.section,
                question_index: detail.questionIndex,
                group_index: detail.groupIndex
            };
        });

        const isPassed = tongDiemDatDuoc >= deThi.pass_score;
        const tongThoiGian = thoiGianLamBai || (deThi.time_limit * 60);

        const history = await LearningHistory.findOneAndUpdate(
            { user: userId, exam: id },
            {
                $set: {
                    score: tongDiemDatDuoc,
                    is_passed: isPassed,
                    duration: tongThoiGian,
                    section_scores: {
                        moji_goi: diemTuVung,
                        bunpou: diemNguPhap,
                        dokkai: diemDocHieu,
                        choukai: diemNgheHieu
                    },
                    user_answers: chiTietKetQuaList,
                    taken_at: new Date()
                }
            },
            { upsert: true, new: true, setDefaultsOnInsert: true }
        );

        await UserStreak.findOneAndUpdate(
            { user: userId },
            {
                $setOnInsert: { current_streak: 0, xp: 0 },
                $max: { longest_streak: 0 }
            },
            { upsert: true }
        );

        res.json({
            KetQuaCuoiCung: isPassed ? 'Đỗ' : 'Trượt',
            DiemTuVung: diemTuVung,
            DiemNguPhap: diemNguPhap,
            DiemDocHieu: diemDocHieu,
            DiemNgheHieu: diemNgheHieu,
            TongDiemDatDuoc: tongDiemDatDuoc,
            TongThoiGian: tongThoiGian
        });
    } catch (error) {
        console.error('Lỗi nộp bài JLPT:', error);
        res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
};




// API: Tạo vỏ đề thi JLPT
export const createExam = async (req, res) => {
    try {
        const { 
            title, description, level, year, month, 
            time_limit, pass_score, total_score 
        } = req.body;

        if (!title || !level) {
            return res.status(400).json({ 
                message: "Vui lòng nhập tiêu đề và cấp độ." 
            });
        }

        const newDeThi = await JLPT.create({
            title: title || req.body.TenBoDe,
            description: description || req.body.MoTa,
            level: level || req.body.CapDo,
            year: year || req.body.NamThi,
            month: month,
            time_limit: time_limit || req.body.ThoiGian || 105,
            pass_score: pass_score || req.body.DiemChuan || 90,
            total_score: total_score || req.body.TongDiem || 180,
            creator_id: req.user._id,
            sections: {
                moji_goi: [],
                bunpou: [],
                dokkai: [],
                choukai: []
            }
        });

        res.status(201).json({
            message: "Tạo đề thi thành công.",
            data: newDeThi
        });

    } catch (error) {
        console.error("Lỗi khi tạo bộ đề thi JLPT:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Cập nhật trạng thái xuất bản
export const setPublishStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { TrangThai, is_published } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        const status = is_published !== undefined ? is_published : TrangThai;

        const deThi = await JLPT.findByIdAndUpdate(
            id,
            { is_published: !!status },
            { new: true }
        );

        if (!deThi) {
            return res.status(404).json({ message: "Đề thi không tồn tại" });
        }

        res.json({ 
            message: `Cập nhật trạng thái đề thi thành công. Trạng thái: ${status ? 'Công khai' : 'Ẩn'}` 
        });

    } catch (error) {
        console.error("Lỗi khi cập nhật trạng thái đề thi JLPT:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Cập nhật thông tin đề thi
export const updateExam = async (req, res) => {
    try {
        const { id } = req.params;
        const { 
            title, description, level, year, month,
            time_limit, pass_score, total_score,
            TenBoDe, MoTa, CapDo, NamThi, ThoiGian, DiemChuan, TongDiem
        } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        const updateData = {};
        if (title || TenBoDe) updateData.title = title || TenBoDe;
        if (description || MoTa) updateData.description = description || MoTa;
        if (level || CapDo) updateData.level = level || CapDo;
        if (year || NamThi) updateData.year = year || NamThi;
        if (month) updateData.month = month;
        if (time_limit || ThoiGian) updateData.time_limit = time_limit || ThoiGian;
        if (pass_score || DiemChuan) updateData.pass_score = pass_score || DiemChuan;
        if (total_score || TongDiem) updateData.total_score = total_score || TongDiem;

        const deThi = await JLPT.findByIdAndUpdate(
            id,
            updateData,
            { new: true, runValidators: true }
        );

        if (!deThi) {
            return res.status(404).json({ message: "Đề thi không tồn tại" });
        }

        res.json({ 
            message: "Cập nhật thông tin đề thi thành công",
            data: deThi 
        });

    } catch (error) {
        console.error("Lỗi khi cập nhật thông tin đề thi JLPT:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Cập nhật nhóm đọc hiểu
export const updateReadingGroup = async (req, res) => {
    try {
        const { groupId } = req.params;
        const { NoiDungBaiDoc, MondaiSo, group_content, mondai } = req.body;

        if (!mongoose.Types.ObjectId.isValid(groupId)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        const content = group_content || NoiDungBaiDoc;
        const mondaiNum = mondai || MondaiSo;

        const result = await JLPT.updateOne(
            { 'sections.dokkai._id': groupId },
            {
                $set: {
                    'sections.dokkai.$.group_content': content,
                    'sections.dokkai.$.mondai': mondaiNum
                }
            }
        );

        if (result.matchedCount === 0) {
            return res.status(404).json({ message: "Bài đọc không tồn tại" });
        }

        res.json({ message: "Cập nhật bài đọc thành công" });

    } catch (error) {
        console.error("Lỗi khi cập nhật bài đọc JLPT:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Cập nhật nhóm nghe hiểu
export const updateListeningGroup = async (req, res) => {
    try {
        const { groupId } = req.params;
        const { LinkAudio, ScriptAudio, MondaiSo, group_audio, transcript, mondai } = req.body;

        if (!mongoose.Types.ObjectId.isValid(groupId)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        const audio = group_audio || LinkAudio;
        const script = transcript || ScriptAudio;
        const mondaiNum = mondai || MondaiSo;

        const result = await JLPT.updateOne(
            { 'sections.choukai._id': groupId },
            {
                $set: {
                    'sections.choukai.$.group_audio': audio,
                    'sections.choukai.$.transcript': script,
                    'sections.choukai.$.mondai': mondaiNum
                }
            }
        );

        if (result.matchedCount === 0) {
            return res.status(404).json({ message: "Bài nghe không tồn tại" });
        }

        res.json({ message: "Cập nhật bài nghe thành công" });

    } catch (error) {
        console.error("Lỗi khi cập nhật bài nghe JLPT:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Cập nhật câu hỏi
export const updateQuestion = async (req, res) => {
    try {
        const { questionId } = req.params;
        const { 
            LoaiCauHoi, NoiDung, HinhAnh, GiaiThich, 
            DapAnA, DapAnB, DapAnC, DapAnD, DapAnDung,
            question_text, image, explanation, 
            choices, correct_answer
        } = req.body;

        if (!mongoose.Types.ObjectId.isValid(questionId)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        const loai = LoaiCauHoi;
        const updateData = {
            question_text: question_text || NoiDung,
            image: image || HinhAnh,
            explanation: explanation || GiaiThich,
            choices: choices || [DapAnA, DapAnB, DapAnC, DapAnD],
            correct_answer: correct_answer !== undefined ? correct_answer : 
                            (DapAnDung ? ['A', 'B', 'C', 'D'].indexOf(DapAnDung.toUpperCase()) : undefined)
        };

        let result;

        if (['TuVung', 'Kanji', 'moji_goi'].includes(loai)) {
            result = await JLPT.updateOne(
                { 'sections.moji_goi._id': questionId },
                { $set: Object.fromEntries(
                    Object.entries(updateData).map(([k, v]) => [`sections.moji_goi.$.${k}`, v])
                )}
            );
        } else if (['NguPhap', 'bunpou'].includes(loai)) {
            result = await JLPT.updateOne(
                { 'sections.bunpou._id': questionId },
                { $set: Object.fromEntries(
                    Object.entries(updateData).map(([k, v]) => [`sections.bunpou.$.${k}`, v])
                )}
            );
        } else if (['DocHieu', 'dokkai'].includes(loai)) {
            result = await JLPT.updateOne(
                { 'sections.dokkai.questions._id': questionId },
                { $set: Object.fromEntries(
                    Object.entries(updateData).map(([k, v]) => [`sections.dokkai.$[].questions.$[q].${k}`, v])
                )},
                { arrayFilters: [{ 'q._id': questionId }] }
            );
        } else if (['NgheHieu', 'choukai'].includes(loai)) {
            result = await JLPT.updateOne(
                { 'sections.choukai.questions._id': questionId },
                { $set: Object.fromEntries(
                    Object.entries(updateData).map(([k, v]) => [`sections.choukai.$[].questions.$[q].${k}`, v])
                )},
                { arrayFilters: [{ 'q._id': questionId }] }
            );
        } else {
            return res.status(400).json({ message: "Loại câu hỏi không hợp lệ." });
        }

        if (!result || result.matchedCount === 0) {
            return res.status(404).json({ message: "Câu hỏi không tồn tại." });
        }

        res.json({ message: "Cập nhật câu hỏi thành công" });

    } catch (error) {
        console.error("Lỗi khi cập nhật câu hỏi JLPT:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Xóa đề thi (soft delete)
export const deleteExam = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        const deThi = await JLPT.findByIdAndUpdate(
            id,
            { is_active: false },
            { new: true }
        );

        if (!deThi) {
            return res.status(404).json({ message: "Đề thi không tồn tại" });
        }

        res.status(204).send();

    } catch (error) {
        console.error("Lỗi khi xóa đề thi JLPT:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Xóa câu hỏi
export const deleteQuestion = async (req, res) => {
    try {
        const { questionId, type } = req.params;

        if (!mongoose.Types.ObjectId.isValid(questionId)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        let result;
        const typeMap = {
            'TuVung': 'moji_goi',
            'Kanji': 'moji_goi',
            'NguPhap': 'bunpou',
            'DocHieu': 'dokkai',
            'NgheHieu': 'choukai',
            'KienThuc': ['moji_goi', 'bunpou'],
            'Nhom': ['dokkai', 'choukai']
        };

        const sections = Array.isArray(typeMap[type]) ? typeMap[type] : [typeMap[type] || type];

        for (const section of sections) {
            if (['moji_goi', 'bunpou'].includes(section)) {
                result = await JLPT.updateOne(
                    { [`sections.${section}._id`]: questionId },
                    { $pull: { [`sections.${section}`]: { _id: questionId } } }
                );
            } else {
                result = await JLPT.updateOne(
                    { [`sections.${section}.questions._id`]: questionId },
                    { $pull: { [`sections.${section}.$[].questions`]: { _id: questionId } } }
                );
            }

            if (result.modifiedCount > 0) break;
        }

        if (!result || result.modifiedCount === 0) {
            return res.status(404).json({ message: "Không tìm thấy câu hỏi để xóa." });
        }

        res.json({ message: "Xóa câu hỏi thành công." });

    } catch (error) {
        console.error("Lỗi khi xóa câu hỏi JLPT:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Import từ Excel
export const importQuestions = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        if (!req.file) {
            return res.status(400).json({ message: 'Vui lòng tải lên tệp Excel.' });
        }

        const workbook = xlsx.read(req.file.buffer, { type: 'buffer' });
        const worksheet = workbook.Sheets[workbook.SheetNames[0]];
        const data = xlsx.utils.sheet_to_json(worksheet);

        if (data.length === 0) {
            return res.status(400).json({ message: 'Tệp Excel không có dữ liệu.' });
        }

        const deThi = await JLPT.findById(id);
        if (!deThi) {
            return res.status(404).json({ message: "Đề thi không tồn tại." });
        }

        for (let i = 0; i < data.length; i++) {
            const row = data[i];
            const rowNum = i + 2;

            if (!row.NoiDungCauHoi) {
                return res.status(400).json({ 
                    message: `Dòng ${rowNum}: Thiếu nội dung câu hỏi` 
                });
            }
            if (!row.LoaiCauHoi) {
                return res.status(400).json({ 
                    message: `Dòng ${rowNum}: Thiếu loại câu hỏi` 
                });
            }
            if (!row.DapAnDung || !['A', 'B', 'C', 'D'].includes(row.DapAnDung.toString().toUpperCase())) {
                return res.status(400).json({ 
                    message: `Dòng ${rowNum}: Đáp án đúng phải là A, B, C hoặc D` 
                });
            }
        }

        // Group theo nội dung (cho dokkai/choukai)
        const groupMap = new Map();
        let successCount = 0;

        for (const row of data) {
            const loaiCauHoi = row.LoaiCauHoi.trim();
            const correctAnswer = ['A', 'B', 'C', 'D'].indexOf(row.DapAnDung.toString().toUpperCase());

            const questionData = {
                mondai: row.MondaiSo || 1,
                question_text: row.NoiDungCauHoi,
                image: row.HinhAnh || undefined,
                audio: row.LinkAudio || undefined,
                choices: [row.DapAnA, row.DapAnB, row.DapAnC, row.DapAnD],
                correct_answer: correctAnswer,
                score: parseFloat(row.Diem) || 1,
                explanation: row.GiaiThich || undefined,
                grammar_id: row.NguPhapID || undefined
            };

            // Xử lý theo loại
            if (['TuVung', 'Kanji'].includes(loaiCauHoi)) {
                deThi.sections.moji_goi.push(questionData);
                successCount++;
            } 
            else if (loaiCauHoi === 'NguPhap') {
                deThi.sections.bunpou.push(questionData);
                successCount++;
            }
            else if (loaiCauHoi === 'DocHieu') {
                const contentKey = row.NoiDungBaiHoc || `dokkai_${row.MondaiSo}`;
                
                if (!groupMap.has(contentKey)) {
                    const newGroup = {
                        mondai: row.MondaiSo || 1,
                        group_content: row.NoiDungBaiHoc || '',
                        group_image: row.HinhAnhBaiDoc || undefined,
                        questions: []
                    };
                    deThi.sections.dokkai.push(newGroup);
                    groupMap.set(contentKey, deThi.sections.dokkai[deThi.sections.dokkai.length - 1]);
                }
                
                const group = groupMap.get(contentKey);
                group.questions.push({
                    mondai: row.MondaiSo || 1,
                    question_text: row.NoiDungCauHoi,
                    choices: [row.DapAnA, row.DapAnB, row.DapAnC, row.DapAnD],
                    correct_answer: correctAnswer,
                    score: parseFloat(row.Diem) || 1,
                    explanation: row.GiaiThich || undefined
                });
                successCount++;
            }
            else if (loaiCauHoi === 'NgheHieu') {
                const audioKey = row.LinkAudio || `choukai_${row.MondaiSo}`;
                
                if (!groupMap.has(audioKey)) {
                    const newGroup = {
                        mondai: row.MondaiSo || 1,
                        group_audio: row.LinkAudio || '',
                        transcript: row.Script || undefined,
                        questions: []
                    };
                    deThi.sections.choukai.push(newGroup);
                    groupMap.set(audioKey, deThi.sections.choukai[deThi.sections.choukai.length - 1]);
                }
                
                const group = groupMap.get(audioKey);
                group.questions.push({
                    mondai: row.MondaiSo || 1,
                    question_text: row.NoiDungCauHoi,
                    choices: [row.DapAnA, row.DapAnB, row.DapAnC, row.DapAnD],
                    correct_answer: correctAnswer,
                    score: parseFloat(row.Diem) || 1,
                    explanation: row.GiaiThich || undefined
                });
                successCount++;
            }
        }

        await deThi.save();

        res.status(201).json({
            message: `Upload thành công! Đã thêm ${successCount} câu hỏi.`,
            data: {
                moji_goi_count: deThi.sections.moji_goi.length,
                bunpou_count: deThi.sections.bunpou.length,
                dokkai_groups: deThi.sections.dokkai.length,
                choukai_groups: deThi.sections.choukai.length
            }
        });

    } catch (error) {
        console.error("Lỗi khi import câu hỏi JLPT:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Xem đáp án sau khi làm xong
export const getAnswers = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        // Kiểm tra user đã làm bài chưa
        const hasAttempt = await LearningHistory.exists({ 
            user_id: userId, 
            exam_id: id 
        });

        if (!hasAttempt) {
            return res.status(403).json({ 
                message: "Bạn phải làm bài trước khi xem đáp án." 
            });
        }

        const deThi = await JLPT.findById(id)
            .select('title level sections')
            .lean();

        if (!deThi || !deThi.is_published) {
            return res.status(404).json({ message: "Đề thi không tồn tại." });
        }

        res.json({
            title: deThi.title,
            level: deThi.level,
            sections: deThi.sections
        });

    } catch (error) {
        console.error("Lỗi xem đáp án:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Lịch sử làm bài của user
export const getMyHistory = async (req, res) => {
    try {
        const userId = req.user._id;
        const { page = 1, limit = 10, exam_id, level } = req.query;
        
        const skip = (parseInt(page) - 1) * parseInt(limit);
        const filter = { user_id: userId };
        
        if (exam_id && mongoose.Types.ObjectId.isValid(exam_id)) {
            filter.exam_id = exam_id;
        }

        const [histories, total] = await Promise.all([
            LearningHistory.find(filter)
                .populate({
                    path: 'exam_id',
                    select: 'title level year month pass_score total_score',
                    match: level ? { level } : {}
                })
                .select('-user_answers')
                .sort({ completed_at: -1 })
                .limit(parseInt(limit))
                .skip(skip)
                .lean(),
            LearningHistory.countDocuments(filter)
        ]);

        // Filter out null exam_id (nếu exam bị xóa)
        const validHistories = histories.filter(h => h.exam_id);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / parseInt(limit)),
            currentPage: parseInt(page),
            data: validHistories
        });

    } catch (error) {
        console.error("Lỗi xem lịch sử:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Chi tiết 1 lần làm bài
export const getHistoryDetail = async (req, res) => {
    try {
        const { historyId } = req.params;
        const userId = req.user._id;

        if (!mongoose.Types.ObjectId.isValid(historyId)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        const history = await LearningHistory.findOne({
            _id: historyId,
            user_id: userId
        })
        .populate({
            path: 'exam_id',
            select: 'title level sections year month'
        })
        .lean();

        if (!history) {
            return res.status(404).json({ message: "Không tìm thấy kết quả." });
        }

        res.json(history);

    } catch (error) {
        console.error("Lỗi xem chi tiết lịch sử:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Thêm câu hỏi đơn (Moji Goi)
export const addMojiGoiQuestion = async (req, res) => {
    try {
        const { id } = req.params;
        const { mondai, question_text, image, audio, choices, correct_answer, score, explanation } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        if (!question_text || !choices || choices.length !== 4 || correct_answer === undefined) {
            return res.status(400).json({ 
                message: "Vui lòng nhập đầy đủ thông tin: nội dung, 4 đáp án, đáp án đúng." 
            });
        }

        const deThi = await JLPT.findById(id);
        if (!deThi) {
            return res.status(404).json({ message: "Đề thi không tồn tại." });
        }

        deThi.sections.moji_goi.push({
            mondai: mondai || 1,
            question_text,
            image,
            audio,
            choices,
            correct_answer,
            score: score || 1,
            explanation
        });

        await deThi.save();

        res.status(201).json({
            message: "Thêm câu hỏi từ vựng thành công.",
            data: deThi.sections.moji_goi[deThi.sections.moji_goi.length - 1]
        });

    } catch (error) {
        console.error("Lỗi thêm câu hỏi:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Thêm câu hỏi ngữ pháp (Bunpou)
export const addBunpouQuestion = async (req, res) => {
    try {
        const { id } = req.params;
        const { mondai, question_text, image, choices, correct_answer, score, explanation, grammar_id } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        if (!question_text || !choices || choices.length !== 4 || correct_answer === undefined) {
            return res.status(400).json({ 
                message: "Vui lòng nhập đầy đủ thông tin." 
            });
        }

        const deThi = await JLPT.findById(id);
        if (!deThi) {
            return res.status(404).json({ message: "Đề thi không tồn tại." });
        }

        deThi.sections.bunpou.push({
            mondai: mondai || 1,
            question_text,
            image,
            choices,
            correct_answer,
            score: score || 1,
            explanation,
            grammar_id
        });

        await deThi.save();

        res.status(201).json({
            message: "Thêm câu hỏi ngữ pháp thành công.",
            data: deThi.sections.bunpou[deThi.sections.bunpou.length - 1]
        });

    } catch (error) {
        console.error("Lỗi thêm câu hỏi:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Thêm nhóm đọc hiểu (Dokkai)
export const addDokkaiGroup = async (req, res) => {
    try {
        const { id } = req.params;
        const { mondai, group_content, group_image, questions } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        if (!group_content || !questions || !Array.isArray(questions) || questions.length === 0) {
            return res.status(400).json({ 
                message: "Vui lòng nhập nội dung đọc và câu hỏi." 
            });
        }

        const deThi = await JLPT.findById(id);
        if (!deThi) {
            return res.status(404).json({ message: "Đề thi không tồn tại." });
        }

        deThi.sections.dokkai.push({
            mondai: mondai || 1,
            group_content,
            group_image,
            questions
        });

        await deThi.save();

        res.status(201).json({
            message: "Thêm nhóm đọc hiểu thành công.",
            data: deThi.sections.dokkai[deThi.sections.dokkai.length - 1]
        });

    } catch (error) {
        console.error("Lỗi thêm nhóm đọc:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Thêm nhóm nghe hiểu (Choukai)
export const addChoukaiGroup = async (req, res) => {
    try {
        const { id } = req.params;
        const { mondai, group_audio, transcript, questions } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        if (!group_audio || !questions || !Array.isArray(questions) || questions.length === 0) {
            return res.status(400).json({ 
                message: "Vui lòng nhập audio và câu hỏi." 
            });
        }

        const deThi = await JLPT.findById(id);
        if (!deThi) {
            return res.status(404).json({ message: "Đề thi không tồn tại." });
        }

        deThi.sections.choukai.push({
            mondai: mondai || 1,
            group_audio,
            transcript,
            questions
        });

        await deThi.save();

        res.status(201).json({
            message: "Thêm nhóm nghe hiểu thành công.",
            data: deThi.sections.choukai[deThi.sections.choukai.length - 1]
        });

    } catch (error) {
        console.error("Lỗi thêm nhóm nghe:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Xóa nhóm đọc/nghe
export const deleteQuestionGroup = async (req, res) => {
    try {
        const { groupId, type } = req.params; // type: dokkai hoặc choukai

        if (!mongoose.Types.ObjectId.isValid(groupId)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        if (!['dokkai', 'choukai'].includes(type)) {
            return res.status(400).json({ message: "Type phải là dokkai hoặc choukai." });
        }

        const result = await JLPT.updateOne(
            { [`sections.${type}._id`]: groupId },
            { $pull: { [`sections.${type}`]: { _id: groupId } } }
        );

        if (result.modifiedCount === 0) {
            return res.status(404).json({ message: "Không tìm thấy nhóm để xóa." });
        }

        res.json({ message: "Xóa nhóm thành công." });

    } catch (error) {
        console.error("Lỗi xóa nhóm:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Thống kê đề thi (Admin)
export const getExamStats = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        const deThi = await JLPT.findById(id)
            .select('title level total_views total_attempts')
            .lean();

        if (!deThi) {
            return res.status(404).json({ message: "Đề thi không tồn tại." });
        }

        const results = await LearningHistory.find({ exam_id: id })
            .select('score is_passed section_scores completed_at')
            .lean();

        const stats = {
            exam_info: {
                title: deThi.title,
                level: deThi.level,
                total_views: deThi.total_views,
                total_attempts: deThi.total_attempts
            },
            user_stats: {
                total_users: results.length,
                pass_count: results.filter(r => r.is_passed).length,
                fail_count: results.filter(r => !r.is_passed).length,
                pass_rate: results.length > 0 
                    ? ((results.filter(r => r.is_passed).length / results.length) * 100).toFixed(2) + '%'
                    : '0%'
            },
            score_stats: {
                average_score: results.length > 0 
                    ? (results.reduce((sum, r) => sum + r.score, 0) / results.length).toFixed(2)
                    : 0,
                highest_score: results.length > 0 
                    ? Math.max(...results.map(r => r.score))
                    : 0,
                lowest_score: results.length > 0 
                    ? Math.min(...results.map(r => r.score))
                    : 0
            },
            section_averages: {
                moji_goi: results.length > 0 
                    ? (results.reduce((sum, r) => sum + (r.section_scores?.moji_goi || 0), 0) / results.length).toFixed(2)
                    : 0,
                bunpou: results.length > 0 
                    ? (results.reduce((sum, r) => sum + (r.section_scores?.bunpou || 0), 0) / results.length).toFixed(2)
                    : 0,
                dokkai: results.length > 0 
                    ? (results.reduce((sum, r) => sum + (r.section_scores?.dokkai || 0), 0) / results.length).toFixed(2)
                    : 0,
                choukai: results.length > 0 
                    ? (results.reduce((sum, r) => sum + (r.section_scores?.choukai || 0), 0) / results.length).toFixed(2)
                    : 0
            },
            recent_attempts: results
                .sort((a, b) => new Date(b.completed_at) - new Date(a.completed_at))
                .slice(0, 10)
                .map(r => ({
                    score: r.score,
                    is_passed: r.is_passed,
                    completed_at: r.completed_at
                }))
        };

        res.json(stats);

    } catch (error) {
        console.error("Lỗi xem thống kê:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Danh sách kết quả của 1 đề (Admin)
export const getExamResults = async (req, res) => {
    try {
        const { id } = req.params;
        const { page = 1, limit = 20, sort = 'score' } = req.query;
        
        const skip = (parseInt(page) - 1) * parseInt(limit);

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: "ID không hợp lệ." });
        }

        const sortOptions = {
            'score': { score: -1 },
            'date': { completed_at: -1 },
            'duration': { duration: 1 }
        };

        const [results, total] = await Promise.all([
            LearningHistory.find({ exam_id: id })
                .populate('user_id', 'HoTen Email TenDangNhap AnhDaiDien')
                .select('-user_answers')
                .sort(sortOptions[sort] || { score: -1 })
                .limit(parseInt(limit))
                .skip(skip)
                .lean(),
            LearningHistory.countDocuments({ exam_id: id })
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / parseInt(limit)),
            currentPage: parseInt(page),
            data: results
        });

    } catch (error) {
        console.error("Lỗi xem kết quả:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// API: Lấy tất cả đề thi (Admin - không filter published)
export const listAdminExams = async (req, res) => {
    try {
        const { page = 1, limit = 10, level, year, search } = req.query;
        
        const skip = (parseInt(page) - 1) * parseInt(limit);
        const filter = { is_active: true };
        
        if (level) filter.level = level;
        if (year) filter.year = parseInt(year);
        if (search) {
            filter.$or = [
                { title: { $regex: search, $options: 'i' } },
                { description: { $regex: search, $options: 'i' } }
            ];
        }

        const [exams, total] = await Promise.all([
            JLPT.find(filter)
                .populate('creator_id', 'HoTen Email')
                .select('-sections')
                .sort({ createdAt: -1 })
                .limit(parseInt(limit))
                .skip(skip)
                .lean(),
            JLPT.countDocuments(filter)
        ]);

        // Lấy số lượng attempts cho mỗi đề
        const examIds = exams.map(e => e._id);
        const attemptCounts = await LearningHistory.aggregate([
            { $match: { exam_id: { $in: examIds } } },
            { $group: { _id: '$exam_id', count: { $sum: 1 } } }
        ]);

        const attemptMap = new Map(
            attemptCounts.map(a => [a._id.toString(), a.count])
        );

        const result = exams.map(exam => ({
            ...exam,
            attempt_count: attemptMap.get(exam._id.toString()) || 0
        }));

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / parseInt(limit)),
            currentPage: parseInt(page),
            data: result
        });

    } catch (error) {
        console.error("Lỗi lấy danh sách admin:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};


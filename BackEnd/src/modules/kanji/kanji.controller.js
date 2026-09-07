import multer from "multer";
import xlsx from "xlsx";
import Kanji from "../../../model/Kanji.js";
import Lesson from "../../../model/Lesson.js";
import UserStreak from "../../../model/UserStreak.js";
import mongoose from "mongoose";

const storage = multer.memoryStorage();
const spreadsheetFileFilter = (_req, file, callback) => {
    const validExtension = /\.(xlsx?|xls)$/i.test(file.originalname);
    const validMime = [
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/octet-stream'
    ].includes(file.mimetype);
    callback(validExtension && validMime ? null : new Error('Chỉ chấp nhận tệp Excel .xls hoặc .xlsx.'), validExtension && validMime);
};
export const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 },
    fileFilter: spreadsheetFileFilter
});

const toStringArray = (value) => {
    if (Array.isArray(value)) return value.map(String).map(item => item.trim()).filter(Boolean);
    if (typeof value !== 'string') return [];
    return value.split(/[,;、]/).map(item => item.trim()).filter(Boolean);
};

export const normalizeKanjiInput = (body) => ({
    lessonId: body.lessonId ?? body.lesson ?? body.BaiHocID,
    character: body.character ?? body.KyTuKanji,
    hanviet: body.hanviet ?? body.HanViet,
    onyomi: toStringArray(body.onyomi ?? body.AmOn),
    kunyomi: toStringArray(body.kunyomi ?? body.AmKun),
    meaning: body.meaning ?? body.Nghia,
    strokeOrderImage: body.strokeOrderImage ?? body.HinhAnhNetViet,
    level: body.level ?? body.CapDo,
    examples: body.examples
});

const compact = (value) => Object.fromEntries(
    Object.entries(value).filter(([, field]) => field !== undefined)
);

// Lấy danh sách Kanji 
export const getRoot = async (req, res) => {
    try {
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 20;
        const level = req.query.level ?? req.query.capDo;

        const filter = {};
        if (level) {
            filter.level = level;
        }

        const skip = (page - 1) * limit;
        
        const [data, count] = await Promise.all([
            Kanji.find(filter)
                .sort({ createdAt: 1 })
                .skip(skip)
                .limit(limit)
                .lean(),
            Kanji.countDocuments(filter)
        ]);

        res.json({
            totalItems: count,
            totalPages: Math.ceil(count / limit),
            currentPage: page,
            data: data,
        });
    } catch (error) {
        console.error("Lỗi khi lấy danh sách Kanji:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// Tìm kiếm chi tiết 1 Kanji 
export const getSearch = async (req, res) => {
    try {
        const { keyword, capDo } = req.query; 
        if (!keyword || keyword.trim() === "") {
            return res.status(400).json({ message: "Vui lòng nhập từ khóa tìm kiếm." });
        }
        
        const searchRegex = new RegExp(keyword.trim(), 'i');
        const filter = {
            $or: [
                { character: searchRegex },
                { onyomi: searchRegex },
                { kunyomi: searchRegex },
                { meaning: searchRegex }
            ],
        };
        
        if (capDo) {
            filter.level = capDo;
        }

        const result = await Kanji.find(filter)
            .sort({ createdAt: 1 })
            .limit(50)
            .lean();

        if (result.length === 0) {
            return res.status(404).json({ message: "Không tìm thấy Kanji phù hợp." });
        }
        res.json(result);
    } catch (error) {
        console.error("Lỗi khi tìm Kanji:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Lấy kanji theo cấp độ (N5, N4, N3, N2, N1)
export const getLevelByLevel = async (req, res) => {
    try {
        const { level } = req.params;
        
        if (!['N5', 'N4', 'N3', 'N2', 'N1'].includes(level)) {
            return res.status(400).json({ message: "Cấp độ không hợp lệ." });
        }

        const data = await Kanji.find({ level })
            .sort({ createdAt: 1 })
            .lean();

        res.json({ data, total: data.length });
    } catch (error) {
        console.error("Lỗi khi lấy Kanji theo level:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

export const getLessonByLessonId = async (req, res) => {
    try {
        const data = await Kanji.find({ lessonId: req.params.lessonId })
            .sort({ createdAt: 1 })
            .lean();
        return res.json({ data, total: data.length });
    } catch (error) {
        console.error('Lỗi khi lấy Kanji theo bài học:', error);
        return res.status(500).json({ message: 'Lỗi máy chủ.' });
    }
};

// Lấy chi tiết 1 kanji theo ID
export const getById = async (req, res) => {
    try {
        const { id } = req.params;

        const kanji = await Kanji.findById(id).lean();

        if (!kanji) {
            return res.status(404).json({ message: "Không tìm thấy Kanji." });
        }

        res.json({ data: kanji });
    } catch (error) {
        console.error("Lỗi khi lấy chi tiết Kanji:", error);
        res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
    }
};

// Đánh dấu đã học kanji (CHỈ DÙNG TRONG LESSON - KHÔNG CỘNG XP Ở ĐÂY)
// XP chỉ được cộng qua LessonProgress khi học trong bài học
export const postLearnById = async (req, res) => {
    try {
        const { id } = req.params;
        const { lessonId } = req.body; // Bắt buộc phải có lessonId
        const userId = req.user._id;
        
        if (!lessonId) {
            return res.status(400).json({ 
                message: "Vui lòng học kanji trong bài học để được cộng điểm." 
            });
        }
        
        // Kiểm tra kanji có tồn tại không
        const kanji = await Kanji.findById(id);
        if (!kanji) {
            return res.status(404).json({ message: "Không tìm thấy kanji." });
        }
        
        // Chuyển hướng về LessonProgress API
        return res.json({ 
            message: "Vui lòng sử dụng API /lesson-progress/lesson/:lessonId/update để cập nhật tiến độ học",
            redirect: `/lesson-progress/lesson/${lessonId}/update`
        });
        
    } catch (error) {
        console.error("Lỗi đánh dấu học kanji:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Thêm Kanji mới
export const postRoot = async (req, res) => {
    try {
        const input = compact(normalizeKanjiInput(req.body));

        if (!input.character || !input.lessonId || !input.meaning || !input.level) {
            return res.status(400).json({ message: "Ký tự, bài học, nghĩa và cấp độ là bắt buộc." });
        }
        if (!mongoose.Types.ObjectId.isValid(input.lessonId)) {
            return res.status(400).json({ message: "ID bài học không hợp lệ." });
        }
        if (!['N5', 'N4', 'N3', 'N2', 'N1'].includes(input.level)) {
            return res.status(400).json({ message: "Cấp độ không hợp lệ." });
        }
        const baiHoc = await Lesson.findById(input.lessonId);
        if (!baiHoc) {
            return res.status(404).json({ message: `Không tìm thấy bài học ${input.lessonId}.` });
        }

        const newKanji = await Kanji.create(input);

        res.status(201).json({
            message: "Thêm Kanji thành công.",
            data: newKanji,
        });
    } catch (error) {
        console.error("Lỗi khi thêm Kanji:", error);
        res.status(500).json({ message: "Lỗi máy chủ!", error: error.message });
    }
};

// Thêm file excel kanji
export const postUpload = async (req, res) => {
    const session = await Kanji.startSession();
    session.startTransaction();
    
    try {
        if (!req.file) {
            return res.status(400).json({ message: "Vui lòng tải lên file Excel." });
        }
        const workbook = xlsx.read(req.file.buffer, { type: 'buffer' });
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];

        const data = xlsx.utils.sheet_to_json(worksheet);
        if (data.length === 0) {
            await session.abortTransaction();
            session.endSession();
            return res.status(400).json({ message: "File Excel không có dữ liệu." });
        }

        const kanjiList = [];
        const errors = [];
        for (const [index, row] of data.entries()) {
            if (!row.BaiHocID || !row.KyTuKanji || !row.AmOn || !row.AmKun || !row.Nghia || !row.CapDo) {
                errors.push(`Dòng ${index + 2}: Thiếu thông tin bắt buộc (BaiHocID, KyTuKanji, AmOn, AmKun, Nghia, CapDo).`);
                continue;
            }
            if (!['N5', 'N4', 'N3', 'N2', 'N1'].includes(row.CapDo)) {
                errors.push(`Dòng ${index + 2}: Cấp độ (${row.CapDo}) không hợp lệ.`);
                continue;
            }

            kanjiList.push({
                lessonId: row.BaiHocID,
                character: row.KyTuKanji,
                onyomi: row.AmOn || "",
                kunyomi: row.AmKun || "",
                meaning: row.Nghia,
                strokeOrderImage: row.HinhAnhNetViet || null,
                level: row.CapDo,
            });
        }

        if (errors.length > 0) {
            await session.abortTransaction();
            session.endSession();
            return res.status(400).json({ message: "Lỗi dữ liệu trong file Excel.", errors });
        }

        await Kanji.insertMany(kanjiList, { session });
        await session.commitTransaction();
        session.endSession();
        
        res.status(201).json({ message: "Tải lên Kanji từ file Excel thành công.", totalInserted: kanjiList.length });
    } catch (error) {
        console.error("Lỗi khi tải lên tệp Excel:", error);
        await session.abortTransaction();
        session.endSession();
        res.status(500).json({ message: "Lỗi máy chủ!", error: error.message });
    }
};

// Cập nhật Kanji
export const putById = async (req, res) => {
    try {
        const { id } = req.params;
        const input = compact(normalizeKanjiInput(req.body));

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: "ID Kanji không hợp lệ." });
        }
        if (input.lessonId) {
            if (!mongoose.Types.ObjectId.isValid(input.lessonId)) {
                return res.status(400).json({ message: "ID bài học không hợp lệ." });
            }
            const baiHoc = await Lesson.findById(input.lessonId);
            if (!baiHoc) {
                return res.status(404).json({ message: `Không tìm thấy bài học ${input.lessonId}.` });
            }
        }
        
        if (input.level && !['N5', 'N4', 'N3', 'N2', 'N1'].includes(input.level)) {
            return res.status(400).json({ message: "Cấp độ không hợp lệ." });
        }

        const updatedKanji = await Kanji.findByIdAndUpdate(
            id,
            input,
            { new: true, runValidators: true }
        );

        if (!updatedKanji) {
            return res.status(404).json({ message: "Không tìm thấy Kanji để cập nhật." });
        }

        res.json({ message: "Cập nhật Kanji thành công.", data: updatedKanji });
    } catch (error) {
        console.error("Lỗi cập nhật Kanji:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Xóa Kanji
export const deleteById = async (req, res) => {
    try {
        const { id } = req.params;
        
        const SRSProgress = (await import("../../../model/SRSProgress.js")).default;
        const hasRelatedData = await SRSProgress.findOne({ 
            itemId: id, 
            itemType: 'kanji' 
        });

        if (hasRelatedData) {
            return res.status(400).json({
                message: "Không thể xóa Kanji này vì có dữ liệu luyện viết liên quan. Hãy xóa dữ liệu liên quan trước trong bảng luyện viết.",
            });
        }

        const deletedKanji = await Kanji.findByIdAndDelete(id);

        if (!deletedKanji) {
            return res.status(404).json({ message: "Không tìm thấy Kanji để xóa." });
        }

        res.json({ message: "Xóa Kanji thành công." });
    } catch (error) {
        console.error("Lỗi khi xóa Kanji:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};


import Vocabulary from "../../../model/Vocabulary.js";
import Lesson from "../../../model/Lesson.js";
import UserStreak from "../../../model/UserStreak.js";
import multer from "multer";
import Excel from "exceljs";
import { createRequire } from "module"; // Dùng cho pdf-parse nếu cần

const storage = multer.memoryStorage();
export const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, callback) => {
    const validExtension = /\.(xlsx?|xls)$/i.test(file.originalname);
    const validMime = [
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/octet-stream'
    ].includes(file.mimetype);
    callback(validExtension && validMime ? null : new Error('Chỉ chấp nhận tệp Excel .xls hoặc .xlsx.'), validExtension && validMime);
  }
});

// 1. Lấy danh sách toàn bộ từ vựng (phân trang, filter)
export const getRoot = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const { level, studyStatus, sortBy } = req.query;
    const userId = req.user._id;

    const query = {};
    if (level) query.level = level;

    const skip = (page - 1) * limit;

    // Determine sort order
    let sortOption = { createdAt: -1 }; // default: newest
    if (sortBy === 'alphabet') {
      sortOption = { word: 1 };
    } else if (sortBy === 'difficulty') {
      // Sort by level (N5 easiest, N1 hardest)
      sortOption = { level: -1 };
    }

    // Get vocabularies
    let vocabularies = await Vocabulary.find(query)
      .populate('lesson', 'title level')
      .sort(sortOption)
      .skip(skip)
      .limit(limit)
      .lean();

    // Filter by study status if requested
    if (studyStatus === 'learned' || studyStatus === 'unlearned') {
      const SRSProgress = (await import('../../../model/SRSProgress.js')).default;
      
      const vocabIds = vocabularies.map(v => v._id);
      const learnedItems = await SRSProgress.find({
        user: userId,
        item_type: 'Vocabulary',
        item_id: { $in: vocabIds }
      }).select('item_id').lean();

      const learnedIds = new Set(learnedItems.map(item => item.item_id.toString()));

      if (studyStatus === 'learned') {
        vocabularies = vocabularies.filter(v => learnedIds.has(v._id.toString()));
      } else {
        vocabularies = vocabularies.filter(v => !learnedIds.has(v._id.toString()));
      }
    }

    const total = await Vocabulary.countDocuments(query);

    res.json({
      totalItems: total,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      data: vocabularies
    });
  } catch (error) {
    console.error("Lỗi lấy danh sách từ vựng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// 2. Tìm từ vựng theo từ khóa
export const getSearch = async (req, res) => {
  try {
    const { keyword, level } = req.query;
    if (!keyword || keyword.trim() === "") {
      return res.status(400).json({ message: "Vui lòng nhập từ khóa tìm kiếm." });
    }

    const searchRegex = new RegExp(keyword.trim(), 'i');
    const query = {
      $or: [
        { word: searchRegex },
        { hiragana: searchRegex },
        { meaning: searchRegex }
      ]
    };
    
    if (level) query.level = level;

    const results = await Vocabulary.find(query)
      .populate('lesson', 'title')
      .sort({ createdAt: -1 })
      .lean();

    if (results.length === 0) {
      return res.status(404).json({ message: "Không tìm thấy từ vựng phù hợp." });
    }

    res.json({
      total: results.length,
      data: results
    });
  } catch (error) {
    console.error("Lỗi tìm kiếm từ vựng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// 3. Lấy chi tiết một từ vựng theo ID
export const getById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const vocabulary = await Vocabulary.findById(id)
      .populate('lesson', 'title level')
      .populate('related_kanjis')
      .lean();

    if (!vocabulary) {
      return res.status(404).json({ message: "Không tìm thấy từ vựng." });
    }

    // Check if user has learned this vocabulary
    const SRSProgress = (await import('../../../model/SRSProgress.js')).default;
    const progress = await SRSProgress.findOne({
      user: userId,
      item_id: id,
      item_type: 'Vocabulary'
    }).lean();

    // Add isLearned flag
    vocabulary.isLearned = !!progress;
    if (progress) {
      vocabulary.learnedAt = progress.createdAt;
      vocabulary.reviewBox = progress.box;
    }

    res.json(vocabulary);
  } catch (error) {
    console.error("Lỗi lấy chi tiết từ vựng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// 4. Lấy danh sách từ vựng theo bài học
export const getLessonByLessonId = async (req, res) => {
  try {
    const { lessonId } = req.params; 
    // Sửa 'lesson'
    const vocabByLesson = await Vocabulary.find({ lesson: lessonId })
      .populate('lesson', 'title level') 
      .sort({ createdAt: -1 }) 
      .lean();

    res.json({
      total: vocabByLesson.length,
      data: vocabByLesson
    });
  } catch (error) {
    console.error("Lỗi lấy từ vựng theo bài học:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// 5. Lấy danh sách từ vựng theo cấp độ
export const getLevelByLevelEnum = async (req, res) => {
  try {
    const { levelEnum } = req.params; 
    const vocabularies = await Vocabulary.find({ level: levelEnum })
      .populate('lesson', 'title level') 
      .sort({ createdAt: -1 })
      .lean();

    if (!vocabularies.length) {
        return res.status(404).json({ message: "Không tìm thấy từ vựng nào." });
    }

    res.json({
      message: `Tìm thấy ${vocabularies.length} từ vựng cấp độ ${levelEnum}`,
      total: vocabularies.length,
      data: vocabularies
    });
  } catch (error) {
    console.error("Lỗi lấy từ vựng theo cấp độ:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// 6. Lấy danh sách tình huống học
export const getSituations = async (req, res) => {
  try {
    const situations = await Vocabulary.distinct('usage_context', {
      usage_context: { $ne: null, $ne: "" } 
    });

    res.json({
      message: "Lấy danh sách tình huống thành công",
      total: situations.length,
      data: situations.sort()
    });
  } catch (error) {
    console.error("Lỗi lấy danh sách tình huống:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// 7. Tìm từ vựng theo tình huống
export const getSituationSearch = async (req, res) => {
  try {
    const { q } = req.query;  
    
    if (!q || q.trim() === "") {
      return res.status(400).json({ message: "Vui lòng nhập tên tình huống muốn tìm." });
    }

    const searchRegex = new RegExp(q.trim(), 'i'); 

    const results = await Vocabulary.find({ usage_context: searchRegex }) 
      .populate('lesson', 'title level') 
      .sort({ createdAt: -1 })
      .lean();

    if (results.length === 0) {
      return res.status(404).json({ message: `Không tìm thấy từ vựng nào thuộc tình huống '${q}'.` });
    }

    res.json({
      message: `Tìm thấy ${results.length} từ vựng thuộc tình huống chứa từ '${q}'`,
      total: results.length,
      data: results
    });
  } catch (error) {
    console.error("Lỗi tìm từ vựng theo tình huống:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// 8. Lấy từ vựng ngẫu nhiên để luyện tập
export const getRandomPractice = async (req, res) => {
  try {
    const { limit = 10, level } = req.query;
    const query = {};
    
    if (level) query.level = level; // Sửa CapDo -> level

    const vocabularies = await Vocabulary.aggregate([
      { $match: query },
      { $sample: { size: parseInt(limit, 10) } }
    ]);

    res.json({
      total: vocabularies.length,
      data: vocabularies
    });
  } catch (error) {
    console.error("Lỗi lấy từ vựng ngẫu nhiên:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// Đánh dấu đã học từ vựng (CHỈ DÙNG TRONG LESSON - KHÔNG CỘNG XP Ở ĐÂY)
// XP chỉ được cộng qua LessonProgress khi học trong bài học
export const postLearnById = async (req, res) => {
    try {
        const { id } = req.params;
        const { lessonId } = req.body; // Bắt buộc phải có lessonId
        const userId = req.user._id;
        
        if (!lessonId) {
            return res.status(400).json({ 
                message: "Vui lòng học từ vựng trong bài học để được cộng điểm." 
            });
        }
        
        // Kiểm tra từ vựng có tồn tại không
        const vocabulary = await Vocabulary.findById(id);
        if (!vocabulary) {
            return res.status(404).json({ message: "Không tìm thấy từ vựng." });
        }
        
        // Chuyển hướng về LessonProgress API
        return res.json({ 
            message: "Vui lòng sử dụng API /lesson-progress/lesson/:lessonId/update để cập nhật tiến độ học",
            redirect: `/lesson-progress/lesson/${lessonId}/update`
        });
        
    } catch (error) {
        console.error("Lỗi đánh dấu học từ vựng:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// --- ADMIN ROUTES ---

// 8. Thêm từ vựng mới
export const postRoot = async (req, res) => {
  try {
    const { lesson, word, hiragana, meaning, level, usage_context, examples, related_kanjis } = req.body;
    
    if (!lesson || !word || !hiragana || !meaning || !level) {
      return res.status(400).json({ 
        message: "Vui lòng nhập đầy đủ thông tin bắt buộc (lesson, word, hiragana, meaning, level)." 
      });
    }
    
    const existingLesson = await Lesson.findById(lesson);
    if (!existingLesson) {
      return res.status(404).json({ message: `Không tìm thấy bài học có ID: ${lesson}` });
    }

    const newVocab = await Vocabulary.create({
      lesson,
      word,
      hiragana,
      meaning,
      level,
      usage_context,
      examples: examples || [],
      related_kanjis: related_kanjis || []
    });

    const populatedVocab = await Vocabulary.findById(newVocab._id)
      .populate('lesson', 'title level')
      .lean();

    res.status(201).json({
      message: "Thêm từ vựng thành công",
      data: populatedVocab
    });

  } catch (error) {
    console.error("Lỗi thêm từ vựng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// 9. Cập nhật từ vựng 
export const putById = async (req, res) => {
  try {
    const { id } = req.params;
    const { lesson, word, hiragana, meaning, level, examples, related_kanjis, usage_context } = req.body;
    
    if (lesson) {
      const baiHoc = await Lesson.findById(lesson);
      if (!baiHoc) {
        return res.status(404).json({ message: `Không tìm thấy bài học ${lesson}.` });
      }
    }

    const updateData = {};
    if (lesson) updateData.lesson = lesson;
    if (word) updateData.word = word;
    if (hiragana) updateData.hiragana = hiragana;
    if (meaning) updateData.meaning = meaning;
    if (level) updateData.level = level;
    if (examples) updateData.examples = examples;
    if (related_kanjis) updateData.related_kanjis = related_kanjis;
    if (usage_context) updateData.usage_context = usage_context;

    const updatedVocab = await Vocabulary.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    ).populate('lesson', 'title level');

    if (!updatedVocab) {
      return res.status(404).json({ message: "Không tìm thấy từ vựng để cập nhật." });
    }

    res.json({ 
      message: "Cập nhật từ vựng thành công", 
      data: updatedVocab 
    });
  } catch (error) {
    console.error("Lỗi cập nhật từ vựng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// 10. Xóa từ vựng
export const deleteById = async (req, res) => {
  try {
    const { id } = req.params;
    const deletedVocab = await Vocabulary.findByIdAndDelete(id);

    if (!deletedVocab) {
      return res.status(404).json({ message: "Không tìm thấy từ vựng để xóa." });
    }

    res.json({ 
      message: "Xóa từ vựng thành công",
      data: deletedVocab
    });
  } catch (error) {
    console.error("Lỗi xóa từ vựng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// 11. Xóa nhiều từ vựng 
export const deleteRoot = async (req, res) => {
  try {
    const { ids } = req.body;
    
    if (!Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({ message: "Danh sách ID không hợp lệ." });
    }

    const result = await Vocabulary.deleteMany({ _id: { $in: ids } });

    res.json({ 
      message: `Đã xóa ${result.deletedCount} từ vựng.`,
      deletedCount: result.deletedCount
    });
  } catch (error) {
    console.error("Lỗi xóa nhiều từ vựng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// 12. Upload file Excel (Đã mapping Header Việt -> DB Anh)
export const postUpload = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "Vui lòng upload file Excel." });
    }

    const { lesson, level } = req.body; 
    if (!lesson || !level) {
      return res.status(400).json({ message: "Vui lòng cung cấp Bài học (lesson) và cấp độ (level)." });
    }

    const baiHoc = await Lesson.findById(lesson);
    if (!baiHoc) {
      return res.status(404).json({ message: `Không tìm thấy bài học ${lesson}.` });
    }

    const vocabArray = [];
    const workbook = new Excel.Workbook();
    await workbook.xlsx.load(req.file.buffer);
    const worksheet = workbook.getWorksheet(1);

    if (!worksheet) {
      return res.status(400).json({ message: "Không tìm thấy sheet nào trong file." });
    }

    let headers = [];
    worksheet.eachRow({ includeEmpty: false }, (row, rowNumber) => {
      if (rowNumber === 1) {
        headers = row.values.map(h => h ? h.toString().trim() : h);
        return;
      }

      const rowData = {};
      row.values.forEach((value, index) => {
        if (headers[index]) {
          rowData[headers[index]] = value;
        }
      });

      if (rowData["TuVung"] && rowData["Hiragana"] && rowData["NghiaTV"]) {
        vocabArray.push({
          lesson,
          level,
          word: rowData["TuVung"],
          hiragana: rowData["Hiragana"],
          meaning: rowData["NghiaTV"],
          examples: [], 
          usage_context: rowData["TinhHuong"] || null
        });
      }
    });

    if (vocabArray.length === 0) {
      return res.status(400).json({ 
        message: "File Excel rỗng hoặc thiếu cột bắt buộc (TuVung, Hiragana, NghiaTV)." 
      });
    }

    const newVocabs = await Vocabulary.insertMany(vocabArray);
    
    res.status(201).json({
      message: `Thêm thành công ${newVocabs.length} từ vựng.`,
      count: newVocabs.length,
      data: newVocabs
    });
  } catch (error) {
    console.error("Lỗi upload file:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// 13. Thống kê từ vựng 
export const getAdminStats = async (req, res) => {
  try {
    const [
      totalVocabularies,
      byLevel,
      bySituation,
      byLesson,
      recentVocabularies
    ] = await Promise.all([
      Vocabulary.countDocuments(),
      Vocabulary.aggregate([
        { $group: { _id: "$level", count: { $sum: 1 } } }, 
        { $sort: { _id: 1 } }
      ]),
      Vocabulary.aggregate([
        { $match: { usage_context: { $ne: null, $ne: "" } } }, 
        { $group: { _id: "$usage_context", count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 10 }
      ]),
      Vocabulary.aggregate([
        { $group: { _id: "$lesson", count: { $sum: 1 } } }, 
        { $sort: { count: -1 } },
        { $limit: 10 },
        {
          $lookup: {
            from: 'lessons', 
            localField: '_id',
            foreignField: '_id',
            as: 'lessonInfo'
          }
        },
        { $unwind: '$lessonInfo' }
      ]),
      Vocabulary.find()
        .populate('lesson', 'title level')
        .sort({ createdAt: -1 })
        .limit(10)
        .lean()
    ]);

    res.json({
      totalVocabularies,
      byLevel,
      bySituation,
      byLesson,
      recentVocabularies
    });
  } catch (error) {
    console.error("Lỗi lấy thống kê từ vựng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// 14. Export Excel (Mapping DB Anh -> Header Việt cho User dễ đọc)
export const getAdminExport = async (req, res) => {
  try {
    const { level, lesson } = req.query;
    const query = {};
    
    if (level) query.level = level;
    if (lesson) query.lesson = lesson;

    const vocabularies = await Vocabulary.find(query)
      .populate('lesson', 'title')
      .lean();

    const workbook = new Excel.Workbook();
    const worksheet = workbook.addWorksheet('Tu Vung');

    // Header Excel (Tiếng Việt cho dễ hiểu)
    worksheet.columns = [
      { header: 'TuVung', key: 'word', width: 20 },
      { header: 'Hiragana', key: 'hiragana', width: 20 },
      { header: 'NghiaTV', key: 'meaning', width: 30 },
      { header: 'CapDo', key: 'level', width: 10 },
      { header: 'TinhHuong', key: 'usage_context', width: 20 },
      { header: 'BaiHoc', key: 'lessonName', width: 30 }
    ];

    // Map dữ liệu
    vocabularies.forEach(vocab => {
      worksheet.addRow({
        word: vocab.word,
        hiragana: vocab.hiragana,
        meaning: vocab.meaning,
        level: vocab.level,
        usage_context: vocab.usage_context || '',
        lessonName: vocab.lesson?.title || ''
      });
    });

    // Style
    worksheet.getRow(1).font = { bold: true };
    
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    );
    res.setHeader(
      'Content-Disposition',
      `attachment; filename=vocabulary_export_${Date.now()}.xlsx`
    );

    await workbook.xlsx.write(res);
    res.end();
  } catch (error) {
    console.error("Lỗi export từ vựng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// Mark vocabulary as learned (add to SRS)
export const postByIdMarkLearned = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    // Check if vocabulary exists
    const vocabulary = await Vocabulary.findById(id);
    if (!vocabulary) {
      return res.status(404).json({ message: "Không tìm thấy từ vựng." });
    }

    // Import SRSProgress model
    const SRSProgress = (await import('../../../model/SRSProgress.js')).default;

    // Check if already learned
    const existingProgress = await SRSProgress.findOne({
      user: userId,
      item_id: id,
      item_type: 'Vocabulary'
    });

    if (existingProgress) {
      return res.json({ 
        message: "Từ vựng đã được đánh dấu là đã học.",
        progress: existingProgress 
      });
    }

    // Create new SRS progress entry
    const newProgress = await SRSProgress.create({
      user: userId,
      item_id: id,
      item_type: 'Vocabulary',
      box: 1,
      next_review: new Date(Date.now() + 24 * 60 * 60 * 1000), // Review after 1 day
      streak: 0
    });

    res.json({
      message: "Đã đánh dấu từ vựng là đã học.",
      progress: newProgress
    });
  } catch (error) {
    console.error("Lỗi mark vocabulary as learned:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};

// Unmark vocabulary as learned (remove from SRS)
export const deleteByIdMarkLearned = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const SRSProgress = (await import('../../../model/SRSProgress.js')).default;

    const result = await SRSProgress.deleteOne({
      user: userId,
      item_id: id,
      item_type: 'Vocabulary'
    });

    if (result.deletedCount === 0) {
      return res.status(404).json({ message: "Không tìm thấy progress để xóa." });
    }

    res.json({ message: "Đã xóa đánh dấu đã học." });
  } catch (error) {
    console.error("Lỗi unmark vocabulary:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
};


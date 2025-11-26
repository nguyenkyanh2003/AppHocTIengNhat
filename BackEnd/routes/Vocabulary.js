import express from "express";
import Vocabulary from "../model/Vocabulary.js";
import Lesson from "../model/Lesson.js";
import multer from "multer";
import Excel from "exceljs";
import { authenticateUser, authenticateAdmin } from "./auth.js";

const router = express.Router();
const storage = multer.memoryStorage();
const upload = multer({ storage });

// Lấy danh sách toàn bộ từ vựng (có phân trang, filter)
router.get("/", authenticateUser, async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const { CapDo, BaiHocID } = req.query;

    const query = {};
    if (CapDo) query.CapDo = CapDo;
    if (BaiHocID) query.BaiHocID = BaiHocID;

    const skip = (page - 1) * limit;

    const [vocabularies, total] = await Promise.all([
      Vocabulary.find(query)
        .populate('BaiHocID', 'TenBaiHoc CapDo')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Vocabulary.countDocuments(query)
    ]);

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
});

// Lấy chi tiết từ vựng
router.get("/:id", authenticateUser, async (req, res) => {
  try {
    const { id } = req.params;
    
    const vocabulary = await Vocabulary.findById(id)
      .populate('BaiHocID', 'TenBaiHoc CapDo LoaiBaiHoc')
      .lean();

    if (!vocabulary) {
      return res.status(404).json({ message: "Không tìm thấy từ vựng." });
    }

    res.json({ data: vocabulary });
  } catch (error) {
    console.error("Lỗi lấy chi tiết từ vựng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// Tìm từ vựng theo từ khóa
router.get("/search", authenticateUser, async (req, res) => {
  try {
    const { keyword, CapDo } = req.query;
    if (!keyword || keyword.trim() === "") {
      return res.status(400).json({ message: "Vui lòng nhập từ khóa tìm kiếm." });
    }

    const searchRegex = new RegExp(keyword.trim(), 'i');
    const query = {
      $or: [
        { TuVung: searchRegex },
        { Hiragana: searchRegex },
        { NghiaTV: searchRegex },
        { KanjiLienQuan: searchRegex }
      ]
    };
    
    if (CapDo) query.CapDo = CapDo;

    const results = await Vocabulary.find(query)
      .populate('BaiHocID', 'TenBaiHoc CapDo')
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
});

// Lấy danh sách từ vựng theo bài học
router.get("/lesson/:baiHocID", authenticateUser, async (req, res) => {
  try {
    const { baiHocID } = req.params;
    
    const vocabByLesson = await Vocabulary.find({ BaiHocID: baiHocID })
      .populate('BaiHocID', 'TenBaiHoc CapDo')
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
});

// Lấy danh sách từ vựng theo cấp độ
router.get("/level/:capDo", authenticateUser, async (req, res) => {
  try {
    const { capDo } = req.params;
    
    const vocabularies = await Vocabulary.find({ CapDo: capDo })
      .populate('BaiHocID', 'TenBaiHoc')
      .sort({ createdAt: -1 })
      .lean();

    res.json({
      total: vocabularies.length,
      data: vocabularies
    });
  } catch (error) {
    console.error("Lỗi lấy từ vựng theo cấp độ:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// Lấy danh sách tình huống học
router.get("/situations", authenticateUser, async (req, res) => {
  try {
    const situations = await Vocabulary.distinct('TinhHuong', {
      TinhHuong: { $ne: null, $ne: "" }
    });

    res.json({
      total: situations.length,
      data: situations.sort()
    });
  } catch (error) {
    console.error("Lỗi lấy danh sách tình huống:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// Tìm từ vựng theo tình huống
router.get("/situation/search", authenticateUser, async (req, res) => {
  try {
    const { q } = req.query;
    if (!q || q.trim() === "") {
      return res.status(400).json({ message: "Vui lòng chọn tình huống muốn học." });
    }

    const searchRegex = new RegExp(q.trim(), 'i');
    const results = await Vocabulary.find({ TinhHuong: searchRegex })
      .populate('BaiHocID', 'TenBaiHoc CapDo')
      .sort({ createdAt: -1 })
      .lean();

    if (results.length === 0) {
      return res.status(404).json({ message: "Không tìm thấy từ vựng cho tình huống." });
    }

    res.json({
      total: results.length,
      data: results
    });
  } catch (error) {
    console.error("Lỗi tìm từ vựng theo tình huống:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// Lấy từ vựng ngẫu nhiên để luyện tập
router.get("/random/practice", authenticateUser, async (req, res) => {
  try {
    const { limit = 10, CapDo } = req.query;
    const query = {};
    
    if (CapDo) query.CapDo = CapDo;

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
});

// ADMIN ROUTES

// Thêm từ vựng mới
router.post("/", authenticateAdmin, async (req, res) => {
  try {
    const { BaiHocID, TuVung, Hiragana, NghiaTV, CapDo, ViDu, KanjiLienQuan, TachNghia, TinhHuong } = req.body;
    
    // Validation cơ bản
    if (!BaiHocID || !TuVung || !Hiragana || !NghiaTV || !CapDo) {
      return res.status(400).json({ 
        message: "Vui lòng nhập đầy đủ thông tin bắt buộc (BaiHocID, TuVung, Hiragana, NghiaTV, CapDo)." 
      });
    }
    
    // Kiểm tra bài học tồn tại
    const baiHoc = await Lesson.findById(BaiHocID);
    if (!baiHoc) {
      return res.status(404).json({ message: `Không tìm thấy bài học ${BaiHocID}.` });
    }

    const newVocab = await Vocabulary.create({
      BaiHocID,
      TuVung,
      Hiragana,
      NghiaTV,
      CapDo,
      ViDu,
      KanjiLienQuan, 
      TachNghia, 
      TinhHuong
    });

    const populatedVocab = await Vocabulary.findById(newVocab._id)
      .populate('BaiHocID', 'TenBaiHoc CapDo')
      .lean();

    res.status(201).json({
      message: "Thêm từ vựng thành công",
      data: populatedVocab
    });
  } catch (error) {
    console.error("Lỗi thêm từ vựng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// Cập nhật từ vựng
router.put("/:id", authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { BaiHocID, TuVung, Hiragana, NghiaTV, CapDo, ViDu, KanjiLienQuan, TachNghia, TinhHuong } = req.body;
    
    // Kiểm tra bài học tồn tại nếu có thay đổi
    if (BaiHocID) {
      const baiHoc = await Lesson.findById(BaiHocID);
      if (!baiHoc) {
        return res.status(404).json({ message: `Không tìm thấy bài học ${BaiHocID}.` });
      }
    }

    const updateData = {};
    if (BaiHocID) updateData.BaiHocID = BaiHocID;
    if (TuVung) updateData.TuVung = TuVung;
    if (Hiragana) updateData.Hiragana = Hiragana;
    if (NghiaTV) updateData.NghiaTV = NghiaTV;
    if (CapDo) updateData.CapDo = CapDo;
    if (ViDu !== undefined) updateData.ViDu = ViDu;
    if (KanjiLienQuan !== undefined) updateData.KanjiLienQuan = KanjiLienQuan;
    if (TachNghia !== undefined) updateData.TachNghia = TachNghia;
    if (TinhHuong !== undefined) updateData.TinhHuong = TinhHuong;

    const updatedVocab = await Vocabulary.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    ).populate('BaiHocID', 'TenBaiHoc CapDo');

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
});

// Xóa từ vựng
router.delete("/:id", authenticateAdmin, async (req, res) => {
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
});

// Xóa nhiều từ vựng
router.delete("/", authenticateAdmin, async (req, res) => {
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
});

// Upload file Excel để import từ vựng
router.post("/upload", authenticateAdmin, upload.single("fileExcel"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "Vui lòng upload file Excel." });
    }

    const { BaiHocID, CapDo } = req.body;
    if (!BaiHocID || !CapDo) {
      return res.status(400).json({ message: "Vui lòng cung cấp Bài học và cấp độ." });
    }

    // Kiểm tra bài học tồn tại
    const baiHoc = await Lesson.findById(BaiHocID);
    if (!baiHoc) {
      return res.status(404).json({ message: `Không tìm thấy bài học ${BaiHocID}.` });
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
          BaiHocID,
          CapDo,
          TuVung: rowData["TuVung"],
          Hiragana: rowData["Hiragana"],
          NghiaTV: rowData["NghiaTV"],
          ViDu: rowData["ViDu"] || null,
          KanjiLienQuan: rowData["KanjiLienQuan"] || null,
          TachNghia: rowData["TachNghia"] || null,
          TinhHuong: rowData["TinhHuong"] || null
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
});

// Lấy tất cả từ vựng (admin - có phân trang)
router.get("/admin/all", authenticateAdmin, async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const { search, CapDo, BaiHocID } = req.query;

    const query = {};
    
    if (search) {
      const searchRegex = new RegExp(search, 'i');
      query.$or = [
        { TuVung: searchRegex },
        { Hiragana: searchRegex },
        { NghiaTV: searchRegex }
      ];
    }
    
    if (CapDo) query.CapDo = CapDo;
    if (BaiHocID) query.BaiHocID = BaiHocID;

    const skip = (page - 1) * limit;

    const [vocabularies, total] = await Promise.all([
      Vocabulary.find(query)
        .populate('BaiHocID', 'TenBaiHoc CapDo')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Vocabulary.countDocuments(query)
    ]);

    res.json({
      totalItems: total,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      data: vocabularies
    });
  } catch (error) {
    console.error("Lỗi lấy danh sách từ vựng (admin):", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

// Thống kê từ vựng (admin)
router.get("/admin/stats", authenticateAdmin, async (req, res) => {
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
        { $group: { _id: "$CapDo", count: { $sum: 1 } } },
        { $sort: { _id: 1 } }
      ]),
      Vocabulary.aggregate([
        { $match: { TinhHuong: { $ne: null, $ne: "" } } },
        { $group: { _id: "$TinhHuong", count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 10 }
      ]),
      Vocabulary.aggregate([
        { $group: { _id: "$BaiHocID", count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 10 },
        {
          $lookup: {
            from: 'lessons',
            localField: '_id',
            foreignField: '_id',
            as: 'lesson'
          }
        },
        { $unwind: '$lesson' }
      ]),
      Vocabulary.find()
        .populate('BaiHocID', 'TenBaiHoc CapDo')
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
});

// Export từ vựng ra Excel (admin)
router.get("/admin/export", authenticateAdmin, async (req, res) => {
  try {
    const { CapDo, BaiHocID } = req.query;
    const query = {};
    
    if (CapDo) query.CapDo = CapDo;
    if (BaiHocID) query.BaiHocID = BaiHocID;

    const vocabularies = await Vocabulary.find(query)
      .populate('BaiHocID', 'TenBaiHoc')
      .lean();

    const workbook = new Excel.Workbook();
    const worksheet = workbook.addWorksheet('Tu Vung');

    // Thêm header
    worksheet.columns = [
      { header: 'TuVung', key: 'TuVung', width: 20 },
      { header: 'Hiragana', key: 'Hiragana', width: 20 },
      { header: 'NghiaTV', key: 'NghiaTV', width: 30 },
      { header: 'CapDo', key: 'CapDo', width: 10 },
      { header: 'ViDu', key: 'ViDu', width: 40 },
      { header: 'KanjiLienQuan', key: 'KanjiLienQuan', width: 20 },
      { header: 'TachNghia', key: 'TachNghia', width: 30 },
      { header: 'TinhHuong', key: 'TinhHuong', width: 20 },
      { header: 'BaiHoc', key: 'BaiHoc', width: 30 }
    ];

    // Thêm dữ liệu
    vocabularies.forEach(vocab => {
      worksheet.addRow({
        TuVung: vocab.TuVung,
        Hiragana: vocab.Hiragana,
        NghiaTV: vocab.NghiaTV,
        CapDo: vocab.CapDo,
        ViDu: vocab.ViDu || '',
        KanjiLienQuan: vocab.KanjiLienQuan || '',
        TachNghia: vocab.TachNghia || '',
        TinhHuong: vocab.TinhHuong || '',
        BaiHoc: vocab.BaiHocID?.TenBaiHoc || ''
      });
    });

    // Style header
    worksheet.getRow(1).font = { bold: true };
    worksheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFD3D3D3' }
    };

    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    );
    res.setHeader(
      'Content-Disposition',
      `attachment; filename=vocabulary_${Date.now()}.xlsx`
    );

    await workbook.xlsx.write(res);
    res.end();
  } catch (error) {
    console.error("Lỗi export từ vựng:", error);
    res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
  }
});

export default router;
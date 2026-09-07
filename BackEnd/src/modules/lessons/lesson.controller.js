import Grammar from '../../../model/Grammar.js';
import Kanji from '../../../model/Kanji.js';
import Lesson from '../../../model/Lesson.js';
import Vocabulary from '../../../model/Vocabulary.js';

const LEVELS = ['N5', 'N4', 'N3', 'N2', 'N1'];

const escapeRegex = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const pagination = (query, defaultLimit = 10) => {
  const page = Math.max(Number.parseInt(query.page || '1', 10), 1);
  const limit = Math.min(
    Math.max(Number.parseInt(query.limit || `${defaultLimit}`, 10), 1),
    100,
  );
  return { page, limit, skip: (page - 1) * limit };
};

const lessonInput = (body) => ({
  title: body.title ?? body.TenBaiHoc,
  level: body.level ?? body.CapDo,
  order: body.order,
  description: body.description ?? body.LoaiBaiHoc,
  content_html: body.content_html ?? body.NoiDung,
  type: body.type,
});

const compact = (object) => Object.fromEntries(
  Object.entries(object).filter(([, value]) => value !== undefined),
);

const sendError = (res, error, label) => {
  console.error(label, error);
  if (error?.name === 'ValidationError' || error?.name === 'CastError') {
    return res.status(400).json({ message: 'Dữ liệu bài học không hợp lệ.' });
  }
  if (error?.code === 11000) {
    return res.status(409).json({ message: 'Tên bài học đã tồn tại.' });
  }
  return res.status(500).json({ message: 'Lỗi máy chủ.' });
};

export const getRoot = async (req, res) => {
  try {
    const { page, limit, skip } = pagination(req.query);
    const level = req.query.level || req.query.capDo;
    const type = req.query.type || req.query.loaiBaiHoc;
    const query = {};
    if (level) query.level = level;
    if (type) query.type = { $regex: escapeRegex(type), $options: 'i' };
    if (req.query.search) {
      const pattern = { $regex: escapeRegex(req.query.search), $options: 'i' };
      query.$or = [{ title: pattern }, { description: pattern }];
    }

    const [lessons, total] = await Promise.all([
      Lesson.find(query).sort({ level: -1, order: 1 }).skip(skip).limit(limit).lean(),
      Lesson.countDocuments(query),
    ]);
    return res.json({
      totalItems: total,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      data: lessons,
    });
  } catch (error) {
    return sendError(res, error, 'Lỗi khi lấy danh sách bài học:');
  }
};

export const getById = async (req, res) => {
  try {
    const lesson = await Lesson.findById(req.params.id)
      .populate('vocabularies')
      .populate('grammars')
      .populate('kanjis')
      .lean();
    if (!lesson) {
      return res.status(404).json({ message: 'Bài học không tồn tại.' });
    }

    const [vocabularies, grammars, kanjis] = await Promise.all([
      lesson.vocabularies?.length
        ? lesson.vocabularies
        : Vocabulary.find({ lesson: lesson._id }).lean(),
      lesson.grammars?.length
        ? lesson.grammars
        : Grammar.find({ lesson_id: lesson._id, is_active: true }).lean(),
      lesson.kanjis?.length
        ? lesson.kanjis
        : Kanji.find({ lessonId: lesson._id }).lean(),
    ]);
    return res.json({
      ...lesson,
      vocabularies,
      grammars,
      kanjis,
      tuvungs: vocabularies,
      nguphaps: grammars,
    });
  } catch (error) {
    return sendError(res, error, 'Lỗi khi lấy chi tiết bài học:');
  }
};

export const getLevelByCapDo = async (req, res) => {
  try {
    if (!LEVELS.includes(req.params.capDo)) {
      return res.status(400).json({ message: 'Cấp độ không hợp lệ.' });
    }
    const lessons = await Lesson.find({ level: req.params.capDo })
      .sort({ order: 1 })
      .lean();
    return res.json({ total: lessons.length, data: lessons });
  } catch (error) {
    return sendError(res, error, 'Lỗi khi lấy bài học theo cấp độ:');
  }
};

export const getTypeByLoaiBaiHoc = async (req, res) => {
  try {
    const lessons = await Lesson.find({
      type: { $regex: escapeRegex(req.params.loaiBaiHoc), $options: 'i' },
    })
      .sort({ level: -1, order: 1 })
      .lean();
    return res.json({ total: lessons.length, data: lessons });
  } catch (error) {
    return sendError(res, error, 'Lỗi khi lấy bài học theo loại:');
  }
};

export const getStatsOverview = async (_req, res) => {
  try {
    const [totalLessons, byLevel, byType] = await Promise.all([
      Lesson.countDocuments(),
      Lesson.aggregate([
        { $group: { _id: '$level', count: { $sum: 1 } } },
        { $sort: { _id: 1 } },
      ]),
      Lesson.aggregate([
        { $match: { type: { $nin: [null, ''] } } },
        { $group: { _id: '$type', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
      ]),
    ]);
    return res.json({ totalLessons, byLevel, byType });
  } catch (error) {
    return sendError(res, error, 'Lỗi khi lấy thống kê bài học:');
  }
};

export const postRoot = async (req, res) => {
  try {
    const input = compact(lessonInput(req.body));
    if (!input.title || !input.level) {
      return res.status(400).json({ message: 'Tên và cấp độ bài học là bắt buộc.' });
    }
    if (!LEVELS.includes(input.level)) {
      return res.status(400).json({ message: 'Cấp độ không hợp lệ.' });
    }
    const lesson = await Lesson.create(input);
    return res.status(201).json({ message: 'Thêm bài học thành công.', data: lesson });
  } catch (error) {
    return sendError(res, error, 'Lỗi khi tạo bài học:');
  }
};

export const postBulk = async (req, res) => {
  try {
    if (!Array.isArray(req.body.lessons) || req.body.lessons.length === 0 || req.body.lessons.length > 100) {
      return res.status(400).json({ message: 'Danh sách phải có từ 1 đến 100 bài học.' });
    }
    const lessons = req.body.lessons.map((item) => compact(lessonInput(item)));
    if (lessons.some((item) => !item.title || !LEVELS.includes(item.level))) {
      return res.status(400).json({ message: 'Mỗi bài học cần tên và cấp độ hợp lệ.' });
    }
    const createdLessons = await Lesson.insertMany(lessons);
    return res.status(201).json({
      message: `Thêm thành công ${createdLessons.length} bài học.`,
      data: createdLessons,
    });
  } catch (error) {
    return sendError(res, error, 'Lỗi khi tạo nhiều bài học:');
  }
};

const updateLesson = async (req, res) => {
  try {
    const input = compact(lessonInput(req.body));
    if (input.level && !LEVELS.includes(input.level)) {
      return res.status(400).json({ message: 'Cấp độ không hợp lệ.' });
    }
    const lesson = await Lesson.findByIdAndUpdate(req.params.id, input, {
      new: true,
      runValidators: true,
    });
    if (!lesson) {
      return res.status(404).json({ message: 'Bài học không tồn tại.' });
    }
    return res.json({ message: 'Cập nhật bài học thành công.', data: lesson });
  } catch (error) {
    return sendError(res, error, 'Lỗi cập nhật bài học:');
  }
};

export const putById = updateLesson;
export const patchById = updateLesson;

const relatedCounts = async (lessonIds) => {
  const [vocabulary, kanji, grammar] = await Promise.all([
    Vocabulary.countDocuments({ lesson: { $in: lessonIds } }),
    Kanji.countDocuments({ lessonId: { $in: lessonIds } }),
    Grammar.countDocuments({ lesson_id: { $in: lessonIds } }),
  ]);
  return { vocabulary, kanji, grammar };
};

export const deleteById = async (req, res) => {
  try {
    const relatedData = await relatedCounts([req.params.id]);
    if (Object.values(relatedData).some((count) => count > 0)) {
      return res.status(409).json({
        message: 'Không thể xóa bài học đang có nội dung liên quan.',
        relatedData,
      });
    }
    const lesson = await Lesson.findByIdAndDelete(req.params.id);
    if (!lesson) {
      return res.status(404).json({ message: 'Bài học không tồn tại.' });
    }
    return res.json({ message: 'Xóa bài học thành công.', data: lesson });
  } catch (error) {
    return sendError(res, error, 'Lỗi xóa bài học:');
  }
};

export const deleteRoot = async (req, res) => {
  try {
    if (!Array.isArray(req.body.ids) || req.body.ids.length === 0 || req.body.ids.length > 100) {
      return res.status(400).json({ message: 'Danh sách ID phải có từ 1 đến 100 phần tử.' });
    }
    const relatedData = await relatedCounts(req.body.ids);
    if (Object.values(relatedData).some((count) => count > 0)) {
      return res.status(409).json({
        message: 'Không thể xóa các bài học đang có nội dung liên quan.',
        relatedData,
      });
    }
    const result = await Lesson.deleteMany({ _id: { $in: req.body.ids } });
    return res.json({
      message: `Xóa thành công ${result.deletedCount} bài học.`,
      deletedCount: result.deletedCount,
    });
  } catch (error) {
    return sendError(res, error, 'Lỗi xóa nhiều bài học:');
  }
};

export const postByIdDuplicate = async (req, res) => {
  try {
    const original = await Lesson.findById(req.params.id).lean();
    if (!original) {
      return res.status(404).json({ message: 'Bài học không tồn tại.' });
    }
    delete original._id;
    delete original.createdAt;
    delete original.updatedAt;
    original.title = `${original.title} (Bản sao ${Date.now()})`;
    const lesson = await Lesson.create(original);
    return res.status(201).json({ message: 'Sao chép bài học thành công.', data: lesson });
  } catch (error) {
    return sendError(res, error, 'Lỗi sao chép bài học:');
  }
};

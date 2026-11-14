import Kanji from '../../../model/Kanji.js';
import Lesson from '../../../model/Lesson.js';

/** Thứ tự nhập kho (cũng là thứ tự giáo trình); `_id` đi kèm để trang không lặp hay sót chữ. */
const OLDEST_FIRST = { createdAt: 1, _id: 1 };

/** Mọi truy vấn Mongoose của Kanji. */
export const createKanjiRepository = ({ Kanji: kanjiModel = Kanji, Lesson: lessonModel = Lesson } = {}) => ({
  findPage({ filter, skip, limit }) {
    return kanjiModel.find(filter).sort(OLDEST_FIRST).skip(skip).limit(limit).lean();
  },

  count(filter) {
    return kanjiModel.countDocuments(filter);
  },

  search({ filter, limit }) {
    return kanjiModel.find(filter).sort(OLDEST_FIRST).limit(limit).lean();
  },

  findById(id) {
    return kanjiModel.findById(id).lean();
  },

  /** Chữ trong [characters] đã có trong kho (unique index `character`). */
  async findCharacters(characters) {
    const rows = await kanjiModel.find({ character: { $in: characters } }).select('character').lean();
    return rows.map((row) => row.character);
  },

  /** ID trong [ids] ứng với bài học có thật, dạng chuỗi. */
  async existingLessonIds(ids) {
    const found = await lessonModel.find({ _id: { $in: ids } }).distinct('_id');
    return found.map(String);
  },

  async create(doc) {
    return (await kanjiModel.create(doc)).toObject();
  },

  insertMany(docs, { session } = {}) {
    return kanjiModel.insertMany(docs, { session });
  },

  updateById({ id, set }) {
    return kanjiModel.findByIdAndUpdate(id, { $set: set }, { new: true, runValidators: true }).lean();
  },

  /** Bài học đang liệt kê chữ này trong mảng `kanjis`. */
  findLessonsUsing(id) {
    return lessonModel.find({ kanjis: id }).select('title').lean();
  },

  deleteById(id) {
    return kanjiModel.findByIdAndDelete(id).lean();
  },
});

export const kanjiRepository = createKanjiRepository();

export default kanjiRepository;

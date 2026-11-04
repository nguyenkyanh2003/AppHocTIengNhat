import Kanji from '../../../model/Kanji.js';
import Lesson from '../../../model/Lesson.js';

/**
 * Truy vấn Mongoose của các route Kanji đã theo khuôn (chi tiết, thêm/gỡ ôn
 * tập, xoá). Các route Kanji còn lại vẫn nằm ở controller cũ cho tới đợt
 * refactor của module.
 */
export const createKanjiRepository = ({ Kanji: kanjiModel = Kanji, Lesson: lessonModel = Lesson } = {}) => ({
  findById(id) {
    return kanjiModel.findById(id).lean();
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

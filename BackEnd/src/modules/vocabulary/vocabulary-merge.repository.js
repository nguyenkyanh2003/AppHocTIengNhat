import Lesson from '../../../model/Lesson.js';
import LessonProgress from '../../../model/LessonProgress.js';
import NoteBook from '../../../model/NoteBook.js';
import SRSProgress from '../../../model/SRSProgress.js';
import Vocabulary from '../../../model/Vocabulary.js';

/**
 * Gộp một từ vựng trùng vào bản giữ lại (dòng `merge` của `vocabulary-fixes`).
 *
 * Một từ được trỏ tới bằng `_id` ở năm nơi: danh sách từ của bài học, tiến độ
 * bài học, thẻ ôn SRS, sổ tay (hai kiểu trường) và trường `lesson` trên chính
 * từ đó. Gộp là chuyển hết các chỗ đó sang bản giữ lại rồi mới xoá bản sao —
 * xoá trước thì bài học mất từ, người học mất thẻ ôn.
 *
 * `merge` phải chạy trong transaction (`session`): bước nào hỏng thì mọi bước
 * trước được huỷ, không để lại nửa chừng.
 */
export const createVocabularyMergeRepository = ({
  Vocabulary: vocabularyModel,
  Lesson: lessonModel,
  LessonProgress: lessonProgressModel,
  SRSProgress: srsModel,
  NoteBook: noteBookModel,
}) => ({
  /**
   * Chỗ cùng lúc trỏ tới **cả hai** bản: gộp ở đó sẽ sinh một từ hai lần trong
   * bài, hoặc hai thẻ ôn cho cùng một từ (vi phạm unique index của SRS). Script
   * dừng và để người quyết thay vì tự chọn bỏ dữ liệu nào.
   */
  async findOverlaps({ fromId, intoId }) {
    const lessons = await lessonModel.countDocuments({ vocabularies: { $all: [fromId, intoId] } });
    const progresses = await lessonProgressModel.countDocuments({
      learned_vocabulary_ids: { $all: [fromId, intoId] },
    });
    const learners = await srsModel.distinct('user', { item_type: 'Vocabulary', item_id: fromId });
    const cards = learners.length === 0
      ? 0
      : await srsModel.countDocuments({ item_type: 'Vocabulary', item_id: intoId, user: { $in: learners } });
    return { lessons, progresses, cards };
  },

  /**
   * Chuyển mọi chỗ trỏ tới `fromId` sang `intoId` rồi xoá bản sao theo `filter`
   * (kèm nghĩa đã soát). Thay **tại chỗ** trong mảng nên thứ tự từ trong bài
   * không đổi. Trả số bản ghi đã chuyển ở từng nơi.
   */
  async merge({ fromId, intoId, lesson, filter, session }) {
    const inPlace = { arrayFilters: [{ item: fromId }], session };
    const count = async (result) => (await result).modifiedCount;

    const moved = {
      lessons: await count(lessonModel.updateMany(
        { vocabularies: fromId },
        { $set: { 'vocabularies.$[item]': intoId } },
        inPlace,
      )),
      progresses: await count(lessonProgressModel.updateMany(
        { learned_vocabulary_ids: fromId },
        { $set: { 'learned_vocabulary_ids.$[item]': intoId } },
        inPlace,
      )),
      cards: await count(srsModel.updateMany(
        { item_type: 'Vocabulary', item_id: fromId },
        { $set: { item_id: intoId } },
        { session },
      )),
      notes: await count(noteBookModel.updateMany(
        { related_item_id: fromId },
        { $set: { related_item_id: intoId } },
        { session },
      )) + await count(noteBookModel.updateMany(
        { 'items.item_id': fromId },
        { $set: { 'items.$[entry].item_id': intoId } },
        { arrayFilters: [{ 'entry.item_id': fromId }], session },
      )),
    };

    // Chỉ điền khi bản giữ lại chưa thuộc bài nào: đổi bài đang có sẽ cướp từ khỏi bài đó.
    if (lesson) {
      await vocabularyModel.updateOne({ _id: intoId, lesson: null }, { $set: { lesson } }, { session });
    }

    const { deletedCount } = await vocabularyModel.deleteOne(filter, { session });
    if (deletedCount !== 1) {
      // Ném để transaction huỷ các bước chuyển ở trên.
      throw new Error(`Bản sao ${filter.word} (${filter.hiragana}) đã đổi khác lúc soát — không gộp.`);
    }
    return moved;
  },
});

export const vocabularyMergeRepository = createVocabularyMergeRepository({
  Vocabulary,
  Lesson,
  LessonProgress,
  SRSProgress,
  NoteBook,
});

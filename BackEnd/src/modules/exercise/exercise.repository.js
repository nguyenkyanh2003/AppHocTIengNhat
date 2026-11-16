import Exercise from '../../../model/Exercise.js';
import ExerciseResult from '../../../model/ExerciseResult.js';

/** `questions` lấy về chỉ để đếm; service bỏ nó trước khi trả ra ngoài. */
const LIST_FIELDS = 'title type level description time_limit total_attempts createdAt questions';
const SUMMARY_FIELDS = 'title type level';
const OLDEST_FIRST = { createdAt: 1, _id: 1 };
const NEWEST_RESULT_FIRST = { completed_at: -1, _id: -1 };

/** Truy vấn Mongoose để xem bài tập và kết quả. Phần nộp bài nằm ở `exercise-submission.repository.js`. */
export const createExerciseRepository = ({ Exercise: exerciseModel = Exercise, ExerciseResult: resultModel = ExerciseResult } = {}) => ({
  findActive(filter) {
    return exerciseModel.find({ ...filter, is_active: true }).select(LIST_FIELDS).sort(OLDEST_FIRST).lean();
  },

  findActiveById(id) {
    return exerciseModel.findOne({ _id: id, is_active: true }).populate('lesson_id', 'title level').lean();
  },

  findHistoryPage({ userId, skip, limit }) {
    return resultModel
      .find({ user_id: userId })
      .populate('exercise_id', SUMMARY_FIELDS)
      .sort(NEWEST_RESULT_FIRST)
      .skip(skip)
      .limit(limit)
      .lean();
  },

  countHistory(userId) {
    return resultModel.countDocuments({ user_id: userId });
  },

  /** Kết quả của chính người dùng, kèm đề đầy đủ (đáp án, lời giải) để xem lại. */
  findResult({ id, userId }) {
    return resultModel
      .findOne({ _id: id, user_id: userId })
      .populate('exercise_id', `${SUMMARY_FIELDS} questions`)
      .lean();
  },
});

export const exerciseRepository = createExerciseRepository();

import { ApiError } from '../../shared/http/api-error.js';
import { toSkip } from '../../shared/http/pagination.js';
import { withoutUndefined } from '../../shared/utils/object.js';
import { jlptRepository } from './jlpt.repository.js';

/** Hai phần câu lẻ và hai phần câu theo nhóm (đoạn đọc, bài nghe). */
const SINGLE_SECTIONS = ['moji_goi', 'bunpou'];
const GROUP_SECTIONS = ['dokkai', 'choukai'];

const examNotFound = () => ApiError.notFound('Không tìm thấy đề thi.');

/** Fisher–Yates trên một bản sao. */
const shuffleCopy = (items) => {
  const copy = [...items];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
};

const countQuestions = (sections = {}) =>
  SINGLE_SECTIONS.reduce((sum, type) => sum + (sections[type]?.length ?? 0), 0) +
  GROUP_SECTIONS.reduce(
    (sum, type) => sum + (sections[type] ?? []).reduce((count, group) => count + (group.questions?.length ?? 0), 0),
    0,
  );

/** Câu hỏi khi đang thi: bỏ đáp án đúng và lời giải. */
const withoutAnswer = ({ correct_answer: _answer, explanation: _explanation, ...question }) => question;

const hideAnswers = (sections = {}) => ({
  ...Object.fromEntries(SINGLE_SECTIONS.map((type) => [type, (sections[type] ?? []).map(withoutAnswer)])),
  ...Object.fromEntries(
    GROUP_SECTIONS.map((type) => [
      type,
      (sections[type] ?? []).map((group) => ({ ...group, questions: (group.questions ?? []).map(withoutAnswer) })),
    ]),
  ),
});

const toListItem = ({ sections, ...exam }, latest) => ({
  ...exam,
  total_questions: countQuestions(sections),
  last_result: latest
    ? { score: latest.score, is_passed: latest.is_passed, completed_at: latest.taken_at ?? latest.createdAt }
    : null,
});

/** Câu luyện nhanh: câu trong nhóm mang theo đoạn văn/âm thanh của nhóm. */
const practiceQuestionsOf = (exam, type) => {
  const source = { exam_id: exam._id, exam_title: exam.title, level: exam.level, section: type };
  const section = exam.sections?.[type] ?? [];
  if (SINGLE_SECTIONS.includes(type)) return section.map((question) => ({ ...question, ...source }));
  return section.flatMap((group) =>
    (group.questions ?? []).map((question) => ({
      ...question,
      group_content: group.group_content,
      group_image: group.group_image,
      group_audio: group.group_audio,
      transcript: group.transcript,
      ...source,
    })),
  );
};

/**
 * Đề JLPT phía người học: danh sách, đề để thi (ẩn đáp án), đáp án sau khi
 * nộp và luyện nhanh. Nộp và chấm đề ở `jlpt-submission.service.js`.
 */
export const createJlptService = ({ repository = jlptRepository, shuffle = shuffleCopy } = {}) => ({
  async list({ userId, page, limit, level, year, month }) {
    const filter = withoutUndefined({ level, year, month });
    const [exams, total] = await Promise.all([
      repository.findPublishedPage({ filter, skip: toSkip({ page, limit }), limit }),
      repository.countPublished(filter),
    ]);
    const results = await repository.findLatestResults({ userId, examIds: exams.map((exam) => exam._id) });
    const latestOf = new Map(results.map((result) => [String(result.exam), result]));
    return { items: exams.map((exam) => toListItem(exam, latestOf.get(String(exam._id)))), total, page, limit };
  },

  async detail(id) {
    const exam = await repository.findPublishedAndCountView(id);
    if (!exam) throw examNotFound();
    return { ...exam, sections: hideAnswers(exam.sections) };
  },

  async solutions({ userId, examId }) {
    if (!(await repository.hasResult({ userId, examId }))) {
      throw ApiError.forbidden('Bạn cần nộp bài trước khi xem đáp án.');
    }
    const exam = await repository.findPublished(examId);
    if (!exam) throw examNotFound();
    return exam;
  },

  async practice({ type, level, limit }) {
    const exams = await repository.findPracticeSections({ type, level });
    return shuffle(exams.flatMap((exam) => practiceQuestionsOf(exam, type))).slice(0, limit);
  },
});

export const jlptService = createJlptService();

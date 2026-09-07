const findAnswerById = (answers, answerId) => {
  if (typeof answers.id === 'function') {
    return answers.id(answerId);
  }

  return answers.find((answer) => String(answer._id) === String(answerId));
};

export const normalizeExerciseAnswers = (answers) => {
  const answerMap = new Map();

  for (const answer of answers) {
    if (!answer || !answer.question_id || !answer.answer_id) continue;
    const questionId = String(answer.question_id);
    if (!answerMap.has(questionId)) {
      answerMap.set(questionId, String(answer.answer_id));
    }
  }

  return answerMap;
};

export const scoreExerciseAnswers = ({ questions, answers, passScore = 60 }) => {
  const answerMap = normalizeExerciseAnswers(answers);
  const totalQuestions = questions.length;
  let correctCount = 0;
  const userAnswers = [];

  for (const question of questions) {
    const questionId = String(question._id);
    if (!answerMap.has(questionId)) continue;

    const selectedAnswer = findAnswerById(question.answers, answerMap.get(questionId));
    if (!selectedAnswer) continue;

    const isCorrect = !!selectedAnswer.is_correct;
    if (isCorrect) correctCount += 1;

    const correctAnswer = question.answers.find((answer) => answer.is_correct);
    const correctAnswerId = correctAnswer ? String(correctAnswer._id) : null;

    userAnswers.push({
      question_id: question._id,
      answer_id: selectedAnswer._id,
      is_correct: isCorrect,
      correct_answer_id: correctAnswerId,
    });
  }

  const score = parseFloat(((correctCount / totalQuestions) * 100).toFixed(2));

  return {
    score,
    correctCount,
    totalQuestions,
    userAnswers,
    isPassed: score >= passScore,
  };
};


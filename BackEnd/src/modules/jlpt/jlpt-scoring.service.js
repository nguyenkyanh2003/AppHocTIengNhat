const addSingleQuestion = (answerMap, question, type, keys) => {
  const answerData = {
    answer: question.correct_answer,
    type,
    score: question.score || 1,
    questionId: question._id || keys[0],
  };

  keys.forEach((key) => answerMap.set(key, answerData));
};

export const buildCorrectAnswerMap = (sections) => {
  const answerMap = new Map();

  sections.moji_goi?.forEach((question, index) => {
    addSingleQuestion(answerMap, question, 'moji_goi', [
      `moji_goi_${index}`,
      `moji-${index}`,
    ]);
  });

  sections.bunpou?.forEach((question, index) => {
    addSingleQuestion(answerMap, question, 'bunpou', [
      `bunpou_${index}`,
      `bunpou-${index}`,
    ]);
  });

  sections.dokkai?.forEach((group, groupIndex) => {
    group.questions?.forEach((question, questionIndex) => {
      addSingleQuestion(answerMap, question, 'dokkai', [
        `dokkai_${groupIndex}_${questionIndex}`,
        `dokkai-${groupIndex}-${questionIndex}`,
      ]);
    });
  });

  sections.choukai?.forEach((group, groupIndex) => {
    group.questions?.forEach((question, questionIndex) => {
      addSingleQuestion(answerMap, question, 'choukai', [
        `choukai_${groupIndex}_${questionIndex}`,
        `choukai-${groupIndex}-${questionIndex}`,
      ]);
    });
  });

  return answerMap;
};

export const normalizeSubmittedAnswers = (rawAnswers) => rawAnswers
  .map((answer) => ({
    key: answer.key || answer.question_key || answer.questionKey,
    choice: answer.choice ?? answer.selected ?? answer.answer ?? answer.option,
    section: answer.section,
    index: answer.index,
    groupIndex: answer.groupIndex,
  }))
  .filter((answer) => answer.key !== undefined && answer.choice !== undefined);

export const scoreExamAnswers = ({ sections, rawAnswers }) => {
  const correctAnswerMap = buildCorrectAnswerMap(sections);
  const normalizedAnswers = normalizeSubmittedAnswers(rawAnswers);
  const sectionScores = {
    moji_goi: 0,
    bunpou: 0,
    dokkai: 0,
    choukai: 0,
  };
  let correctCount = 0;
  const answerDetails = [];

  for (const answer of normalizedAnswers) {
    const key = answer.key
      || `${answer.section}_${answer.index}${answer.groupIndex !== undefined ? `_${answer.groupIndex}` : ''}`;
    const correctData = correctAnswerMap.get(key);
    if (!correctData) continue;

    const isCorrect = Number(correctData.answer) === Number(answer.choice);
    if (isCorrect) {
      correctCount += 1;
      sectionScores[correctData.type] += correctData.score;
    }

    answerDetails.push({
      questionId: correctData.questionId,
      userChoice: answer.choice ?? -1,
      isCorrect,
      section: correctData.type,
      questionIndex: answer.index,
      groupIndex: answer.groupIndex,
    });
  }

  return {
    correctCount,
    sectionScores,
    totalScore: Object.values(sectionScores).reduce((sum, score) => sum + score, 0),
    answerDetails,
  };
};


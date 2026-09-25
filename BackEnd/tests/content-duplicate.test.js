import assert from 'node:assert/strict';
import test from 'node:test';

import Exercise from '../model/Exercise.js';
import Grammar from '../model/Grammar.js';
import JLPT from '../model/JLPT.js';
import Lesson from '../model/Lesson.js';
import * as exerciseController from '../src/modules/exercise/exercise.controller.js';
import { createOrReviveGrammar } from '../src/modules/grammar/grammar-natural-key.js';
import * as grammarController from '../src/modules/grammar/grammar.controller.js';
import * as jlptController from '../src/modules/jlpt/jlpt.controller.js';
import { isDuplicateKeyError } from '../src/shared/db/duplicate-key.js';

const ID = '507f1f77bcf86cd799439011';

const duplicateKey = () => Object.assign(new Error('E11000 duplicate key error'), { code: 11000 });

/**
 * Thay tạm một static của model rồi trả lại sau test. Controller của ba module
 * này còn dùng model trực tiếp, nên đây là cách duy nhất để thử nhánh lỗi mà
 * không cần MongoDB.
 */
const stub = (t, model, name, impl) => {
  const hadOwn = Object.hasOwn(model, name);
  const original = model[name];
  model[name] = impl;
  t.after(() => {
    if (hadOwn) model[name] = original;
    else delete model[name];
  });
};

/** `res` tối thiểu, ghi lại status và body. */
const fakeRes = () => {
  const res = { statusCode: 200, body: undefined };
  res.status = (code) => {
    res.statusCode = code;
    return res;
  };
  res.json = (body) => {
    res.body = body;
    return res;
  };
  return res;
};

const quiet = (t) => {
  const original = console.error;
  console.error = () => {};
  t.after(() => {
    console.error = original;
  });
};

// --- nhận diện lỗi trùng -----------------------------------------------------

test('isDuplicateKeyError nhận E11000 ở cả lỗi gốc lẫn lỗi được bọc', () => {
  assert.equal(isDuplicateKeyError(duplicateKey()), true);
  assert.equal(isDuplicateKeyError(new Error('bọc', { cause: duplicateKey() })), true);
  assert.equal(isDuplicateKeyError(new Error('mất kết nối')), false);
  assert.equal(isDuplicateKeyError(undefined), false);
});

// --- khôi phục ngữ pháp đã xoá mềm -------------------------------------------

test('tạo lại đúng ngữ pháp đã xoá mềm thì khôi phục bản đó với nội dung mới', async () => {
  const calls = [];
  const model = {
    findOneAndUpdate: async (filter, update, options) => {
      calls.push({ filter, update, options });
      return { _id: 'g1', ...update.$set };
    },
    create: async () => assert.fail('không được tạo bản mới khi còn bản để khôi phục'),
  };

  const { grammar, revived } = await createOrReviveGrammar({
    model,
    data: { title: '  です / だ ', level: 'N5', structure: 'N + です', notes: undefined },
  });

  assert.equal(revived, true);
  assert.equal(grammar._id, 'g1');
  const [{ filter, update, options }] = calls;
  // Lọc theo tiêu đề đã trim: schema trim khi lưu, nên bản trong DB không có khoảng trắng.
  assert.deepEqual(filter, { level: 'N5', title: 'です / だ', is_active: false });
  assert.deepEqual(update.$set, { title: 'です / だ', level: 'N5', structure: 'N + です', is_active: true });
  assert.equal('notes' in update.$set, false, 'trường không gửi không được ghi thành undefined');
  assert.equal(options.runValidators, true);
});

test('không có bản để khôi phục thì tạo mới', async () => {
  const created = [];
  const model = {
    findOneAndUpdate: async () => null,
    create: async (doc) => {
      created.push(doc);
      return { _id: 'g2', ...doc };
    },
  };

  const { grammar, revived } = await createOrReviveGrammar({
    model,
    data: { title: 'は', level: 'N5', lesson_id: undefined },
  });

  assert.equal(revived, false);
  assert.equal(grammar._id, 'g2');
  assert.deepEqual(created, [{ title: 'は', level: 'N5' }]);
});

// --- API admin trả 409 thay vì 500 -------------------------------------------

const grammarBody = { title: 'です / だ', structure: 'N + です', meaning: 'là', level: 'N5' };

test('thêm ngữ pháp trùng bản đang hoạt động trả 409 kèm tên và cấp độ', async (t) => {
  stub(t, Grammar, 'findOneAndUpdate', async () => null);
  stub(t, Grammar, 'create', async () => {
    throw duplicateKey();
  });
  const res = fakeRes();

  await grammarController.postRoot({ body: grammarBody }, res);

  assert.equal(res.statusCode, 409);
  assert.equal(res.body.code, 'DUPLICATE_GRAMMAR');
  assert.match(res.body.message, /です \/ だ/);
  assert.match(res.body.message, /N5/);
});

test('thêm ngữ pháp đã xoá mềm trả 201 và báo đã khôi phục', async (t) => {
  stub(t, Grammar, 'findOneAndUpdate', async () => ({ _id: ID, ...grammarBody, is_active: true }));
  stub(t, Grammar, 'create', async () => assert.fail('không được tạo bản mới'));
  const res = fakeRes();

  await grammarController.postRoot({ body: grammarBody }, res);

  assert.equal(res.statusCode, 201);
  assert.match(res.body.message, /khôi phục/);
  assert.equal(res.body.data._id, ID);
});

test('đổi tên ngữ pháp trùng ngữ pháp khác trả 409', async (t) => {
  stub(t, Grammar, 'findByIdAndUpdate', async () => {
    throw duplicateKey();
  });
  const res = fakeRes();

  await grammarController.putById({ params: { id: ID }, body: { title: 'は' } }, res);

  assert.equal(res.statusCode, 409);
  assert.equal(res.body.code, 'DUPLICATE_GRAMMAR');
});

test('lỗi khác của ngữ pháp vẫn là 500', async (t) => {
  quiet(t);
  stub(t, Grammar, 'findOneAndUpdate', async () => null);
  stub(t, Grammar, 'create', async () => {
    throw new Error('mất kết nối');
  });
  const res = fakeRes();

  await grammarController.postRoot({ body: grammarBody }, res);

  assert.equal(res.statusCode, 500);
});

test('thêm bài tập trùng tên trong cùng bài học trả 409', async (t) => {
  stub(t, Lesson, 'findById', async () => ({ _id: ID }));
  stub(t, Exercise, 'create', async () => {
    throw duplicateKey();
  });
  const res = fakeRes();

  await exerciseController.createExercise(
    { params: { lessonID: ID }, body: { title: 'Ôn tập', level: 'N5' } },
    res,
  );

  assert.equal(res.statusCode, 409);
  assert.equal(res.body.code, 'DUPLICATE_EXERCISE');
});

test('đổi tên bài tập trùng bài khác trả 409', async (t) => {
  stub(t, Exercise, 'findByIdAndUpdate', async () => {
    throw duplicateKey();
  });
  const res = fakeRes();

  await exerciseController.updateExercise({ params: { id: ID }, body: { title: 'Ôn tập' } }, res);

  assert.equal(res.statusCode, 409);
  assert.equal(res.body.code, 'DUPLICATE_EXERCISE');
});

test('tạo và đổi tên đề JLPT trùng tên trả 409', async (t) => {
  stub(t, JLPT, 'create', async () => {
    throw duplicateKey();
  });
  stub(t, JLPT, 'findByIdAndUpdate', async () => {
    throw duplicateKey();
  });

  const created = fakeRes();
  await jlptController.createExam(
    { body: { title: 'Đề mẫu', level: 'N4' }, user: { _id: ID } },
    created,
  );
  assert.equal(created.statusCode, 409);
  assert.equal(created.body.code, 'DUPLICATE_EXAM');

  const updated = fakeRes();
  await jlptController.updateExam({ params: { id: ID }, body: { title: 'Đề mẫu' } }, updated);
  assert.equal(updated.statusCode, 409);
  assert.equal(updated.body.code, 'DUPLICATE_EXAM');
});

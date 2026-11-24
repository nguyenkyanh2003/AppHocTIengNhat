/**
 * Kiểm thử thực tế qua HTTP: server đang chạy + MongoDB thật trong `.env`.
 *
 *   npm run dev                  # cửa sổ khác
 *   node scripts/smoke-api.js
 *
 * Tạo ba tài khoản tạm `zz_smoke_*` (người học A, B và một admin), đi qua các luồng chính
 * bằng đúng request app gửi, kiểm mã HTTP và hình dạng response contract (`conventions.md`),
 * rồi xoá mọi thứ các tài khoản tạm đã tạo, trả lại các bộ đếm lượt xem đã tăng và so số
 * bản ghi từng collection với lúc bắt đầu. Lần chạy hỏng giữa chừng để lại gì thì lần sau
 * dọn trước khi chạy. Không chạy với NODE_ENV=production.
 */
import { randomUUID } from 'node:crypto';
import { readdirSync, rmSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

import mongoose from 'mongoose';

import env from '../src/config/env.js';
import Achievement from '../model/Achievement.js';
import ActivityEvent from '../model/ActivityEvent.js';
import Exercise from '../model/Exercise.js';
import Grammar from '../model/Grammar.js';
import JLPT from '../model/JLPT.js';
import News from '../model/News.js';
import SRSProgress from '../model/SRSProgress.js';
import StudyGroup from '../model/StudyGroup.js';
import User from '../model/User.js';

const API = process.env.SMOKE_API_URL ?? `http://localhost:${env.port}/api`;
const PREFIX = 'zz_smoke_';
const PASSWORD = 'mat-khau-smoke-1';

/** Trường trỏ tới người dùng trong các model (`ref: 'User'`). */
const USER_FIELDS = ['user', 'user_id', 'recipient', 'sender', 'creator_id'];

// ------------------------------------------------------------------- báo kết quả

const failures = [];
let passed = 0;

const check = (label, condition, detail = '') => {
  if (condition) passed += 1;
  else failures.push(`${label}${detail ? ` — ${detail}` : ''}`);
  console.log(`${condition ? '✅' : '❌'} ${label}${!condition && detail ? ` — ${detail}` : ''}`);
};

const section = (title) => console.log(`\n## ${title}`);

// ------------------------------------------------------------------------- HTTP

const request = async (method, path, { token, body } = {}) => {
  const response = await fetch(`${API}${path}`, {
    method,
    headers: {
      ...(token && { Authorization: `Bearer ${token}` }),
      ...(body !== undefined && { 'Content-Type': 'application/json' }),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = { raw: text.slice(0, 120) };
  }
  return { status: response.status, body: json };
};

/** Gửi một tệp bằng multipart, như app gửi ảnh đại diện hay tệp Excel. */
const upload = async (method, path, { token, field, fileName, type, bytes }) => {
  const form = new FormData();
  form.append(field, new Blob([bytes], { type }), fileName);
  const response = await fetch(`${API}${path}`, { method, headers: { Authorization: `Bearer ${token}` }, body: form });
  return { status: response.status, body: await response.json().catch(() => null) };
};

/** Phiên của một tài khoản: mọi request mang access token của nó. */
const as = (token) => ({
  get: (path) => request('GET', path, { token }),
  post: (path, body = {}) => request('POST', path, { token, body }),
  put: (path, body = {}) => request('PUT', path, { token, body }),
  patch: (path, body = {}) => request('PATCH', path, { token, body }),
  delete: (path) => request('DELETE', path, { token }),
});

const isObject = (value) => value !== null && typeof value === 'object' && !Array.isArray(value);
const isCount = (value) => Number.isInteger(value) && value >= 0;

/** Các hình dạng response hợp lệ theo `conventions.md`. */
const SHAPES = {
  object: (body) => isObject(body?.data),
  nullable: (body) => isObject(body) && 'data' in body && (body.data === null || isObject(body.data)),
  list: (body) => Array.isArray(body?.data) && isCount(body.total),
  paged: (body) =>
    Array.isArray(body?.data) && ['page', 'limit', 'total', 'totalPages'].every((key) => isCount(body[key])),
  cursor: (body) => Array.isArray(body?.data) && 'next_cursor' in body,
  batch: (body) => Array.isArray(body?.data) && isCount(body.limit),
  deleted: (body) => body?.data?.deleted === true,
  error: (body) => typeof body?.message === 'string' && !('data' in body),
};

const describe = ({ status, body }) => `HTTP ${status} ${JSON.stringify(body)?.slice(0, 160)}`;

/** Kiểm mã HTTP và hình dạng; trả `data` của response. */
const expect = async (label, pending, { status = 200, shape = 'object' } = {}) => {
  const response = await pending;
  check(label, response.status === status && SHAPES[shape](response.body), describe(response));
  return response.body?.data;
};

/** Lỗi phải là đúng mã kèm `{ message }`, không bao giờ là 500. */
const expectError = (label, pending, status) => expect(label, pending, { status, shape: 'error' });

// --------------------------------------------------------- dữ liệu tạm và dọn dẹp

/** Bộ đếm lượt xem/lượt làm bị tăng trong lần chạy, để trả lại khi dọn. */
const counters = [];
const countView = (model, id, field) => counters.push({ model, id, field });

const collectionOf = (model) => mongoose.connection.db.collection(model.collection.name);

/** Thứ tạo trong lần chạy mà không tìm lại được theo tên: tài khoản admin đã xoá, nội dung admin thêm. */
const created = { users: [], grammar: [], achievements: [] };

const collectionCounts = async () => {
  const counts = {};
  for (const { name } of await mongoose.connection.db.listCollections().toArray()) {
    counts[name] = await mongoose.connection.db.collection(name).countDocuments();
  }
  return counts;
};

/** Xoá mọi tài khoản `zz_smoke_*` (cả của lần chạy trước) và mọi thứ trỏ về chúng. */
const purgeSmokeData = async () => {
  const db = mongoose.connection.db;
  const users = await collectionOf(User).find({ TenDangNhap: { $regex: `^${PREFIX}` } }).toArray();
  const ids = [...users.map((user) => user._id), ...created.users.map((id) => new mongoose.Types.ObjectId(id))];
  if (ids.length > 0) {
    const owned = { $or: USER_FIELDS.map((field) => ({ [field]: { $in: ids } })) };
    for (const { name } of await db.listCollections().toArray()) {
      if (name !== User.collection.name) await db.collection(name).deleteMany(owned);
    }
    // Nhóm của người khác mà tài khoản tạm từng vào.
    await collectionOf(StudyGroup).updateMany(
      { 'members.user_id': { $in: ids } },
      { $pull: { members: { user_id: { $in: ids } } } },
    );
    await collectionOf(User).deleteMany({ _id: { $in: ids } });
  }
  await Grammar.deleteMany({ $or: [{ _id: { $in: created.grammar } }, { title: { $regex: `^${PREFIX}` } }] });
  await Achievement.deleteMany({ $or: [{ _id: { $in: created.achievements } }, { name: { $regex: `^${PREFIX}` } }] });
  return ids.length;
};

/** Tệp trong `uploads/` (đường dẫn tương đối), để xoá đúng những tệp lần chạy này tạo. */
const UPLOADS = fileURLToPath(new URL('../uploads/', import.meta.url));
const uploadedFiles = () =>
  readdirSync(UPLOADS, { recursive: true }).filter((path) => statSync(join(UPLOADS, path)).isFile());

const removeNewUploads = (before) => {
  for (const path of uploadedFiles().filter((file) => !before.includes(file))) rmSync(join(UPLOADS, path));
};

const restoreCounters = async () => {
  for (const { model, id, field } of counters) {
    await collectionOf(model).updateOne({ _id: new mongoose.Types.ObjectId(id) }, { $inc: { [field]: -1 } });
  }
};

/** Thẻ ôn đến hạn từ một giờ trước; trả mốc hạn đúng như client sẽ đọc. */
const makeDue = async (userId, itemId, itemType) => {
  const due = new Date(Date.now() - 60 * 60 * 1000);
  await SRSProgress.updateOne({ user: userId, item_id: itemId, item_type: itemType }, { $set: { next_review: due } });
  return due.toISOString();
};

// ------------------------------------------------------------------------ luồng

const stamp = Date.now().toString(36);
const account = (role) => ({
  username: `${PREFIX}${role}_${stamp}`,
  hoTen: `Smoke ${role.toUpperCase()}`,
  email: `${PREFIX}${role}_${stamp}@example.invalid`,
  password: PASSWORD,
});

const login = async (username, password = PASSWORD) => request('POST', '/users/login', { body: { username, password } });

async function authFlow() {
  section('Tài khoản và phiên đăng nhập');
  const people = {};
  for (const role of ['a', 'b', 'admin']) {
    const user = await expect(`đăng ký ${role}`, request('POST', '/users/register', { body: account(role) }), { status: 201 });
    check(`đăng ký ${role}: không trả mật khẩu`, user && !('MatKhau' in user));
    people[role] = { id: user?._id, username: account(role).username };
    if (user?._id) created.users.push(user._id);
  }
  await User.updateOne({ _id: people.admin.id }, { $set: { VaiTro: 'admin' } });

  for (const person of Object.values(people)) {
    const session = await expect(`đăng nhập ${person.username}`, login(person.username));
    Object.assign(person, { token: session?.token, refreshToken: session?.refreshToken, api: as(session?.token) });
  }
  await expectError('sai mật khẩu → 401', login(people.a.username, 'sai-mat-khau'), 401);
  await expectError('không có token → 401', request('GET', '/lesson'), 401);

  const refreshed = await expect('đổi refresh token lấy cặp mới', request('POST', '/users/refresh-token', { body: { refreshToken: people.a.refreshToken } }));
  if (refreshed?.token) Object.assign(people.a, { token: refreshed.token, refreshToken: refreshed.refreshToken, api: as(refreshed.token) });

  const { a, b } = people;
  await expect('xem hồ sơ của mình', a.api.get(`/users/profile/${a.id}`));
  await expectError('xem hồ sơ người khác → 403', a.api.get(`/users/profile/${b.id}`), 403);
  const profile = await expect('sửa họ tên', a.api.put(`/users/profile/${a.id}`, { hoTen: 'Smoke A đã sửa' }));
  check('họ tên mới được lưu', profile?.HoTen === 'Smoke A đã sửa', JSON.stringify(profile)?.slice(0, 80));
  return people;
}

async function contentFlow({ a }) {
  section('Đọc nội dung');
  const lessons = await expect('bài học: trang đầu', a.api.get('/lesson?page=1&limit=5&level=N5'), { shape: 'paged' });
  const lesson = lessons?.[0];
  await expect('bài học: chủ đề', a.api.get('/lesson/situations?level=N5'), { shape: 'list' });
  const detail = await expect('bài học: chi tiết', a.api.get(`/lesson/${lesson?._id}`));

  const words = await expect('từ vựng: trang đầu', a.api.get('/vocabulary?page=1&limit=5&level=N5'), { shape: 'paged' });
  const sets = await expect('từ vựng: bộ theo cấp', a.api.get('/vocabulary/sets?level=N5'), { shape: 'list' });
  await expect('từ vựng: chi tiết bộ', a.api.get(`/vocabulary/sets/${encodeURIComponent(sets?.[0]?.id)}`));
  await expect('từ vựng: tìm', a.api.get(`/vocabulary/search?keyword=${encodeURIComponent('学')}`), { shape: 'list' });
  await expect('từ vựng: chi tiết', a.api.get(`/vocabulary/${words?.[0]?._id}`));
  await expect('từ vựng: theo bài', a.api.get(`/vocabulary/lesson/${lesson?._id}`), { shape: 'list' });

  const kanji = await expect('kanji: trang đầu', a.api.get('/kanji?page=1&limit=5'), { shape: 'paged' });
  await expect('kanji: chi tiết', a.api.get(`/kanji/${kanji?.[0]?._id}`));
  await expect('kanji: tìm', a.api.get(`/kanji/search?keyword=${encodeURIComponent('学')}`), { shape: 'list' });

  const grammar = await expect('ngữ pháp: trang đầu', a.api.get('/grammar?page=1&limit=5&level=N5'), { shape: 'paged' });
  await expect('ngữ pháp: chi tiết', a.api.get(`/grammar/${grammar?.[0]?._id}`));
  countView(Grammar, grammar?.[0]?._id, 'view_count');

  const news = await expect('tin tức: trang đầu', a.api.get('/news?page=1&limit=5'), { shape: 'paged' });
  if (news?.[0]) {
    await expect('tin tức: chi tiết', a.api.get(`/news/${news[0]._id}`));
    countView(News, news[0]._id, 'views');
    await expect('tin tức: liên quan', a.api.get(`/news/${news[0]._id}/related`), { shape: 'list' });
  }

  section('Tìm kiếm');
  const hits = await expect('tìm "学" có kết quả', a.api.get(`/search?q=${encodeURIComponent('学')}`), { shape: 'list' });
  check('kết quả tìm có loại', hits?.length > 0 && hits.every((hit) => typeof hit.type === 'string'), JSON.stringify(hits?.[0])?.slice(0, 80));
  const none = await expect('tìm từ không có → 200 + mảng rỗng', a.api.get('/search?q=zzqqxxkhongco'), { shape: 'list' });
  check('không có kết quả là mảng rỗng', Array.isArray(none) && none.length === 0);

  return { lesson: detail?.lesson ?? detail, word: words?.[0], kanji: kanji?.[0] };
}

async function learningLoop({ a }, { lesson, word, kanji }) {
  section('Vòng lặp học: SRS');
  const xpBefore = (await a.api.get('/streak/my-streak')).body?.data?.total_xp ?? 0;
  await expect('đánh dấu đã học một từ', a.api.post(`/vocabulary/${word._id}/mark-learned`));
  await expect('đánh dấu đã học một chữ Kanji', a.api.post(`/kanji/${kanji._id}/mark-learned`));
  const dueWord = await makeDue(a.id, word._id, 'Vocabulary');
  await makeDue(a.id, kanji._id, 'Kanji');

  const count = await expect('đếm thẻ đến hạn', a.api.get('/srs/due/count'));
  check('đến hạn có cả từ và Kanji', count?.total >= 2, JSON.stringify(count));
  const kanjiCards = await expect('thẻ Kanji đến hạn', a.api.get('/srs/due?item_type=Kanji'), { shape: 'batch' });
  check('thẻ Kanji mang đúng item_type', kanjiCards?.some((card) => card.item_type === 'Kanji'), JSON.stringify(kanjiCards?.[0])?.slice(0, 120));

  const answer = { item_id: word._id, item_type: 'Vocabulary', is_correct: true, expected_next_review: dueWord };
  const reviewed = await expect('ôn đúng một thẻ', a.api.post('/srs/review', answer));
  check('ôn đúng: lên hộp 2', reviewed?.box === 2, JSON.stringify(reviewed)?.slice(0, 120));
  await expectError('gửi lại cùng lượt ôn → 409, không xử lý lần hai', a.api.post('/srs/review', answer), 409);
  await expect('thống kê hộp', a.api.get('/srs/stats'));
  await expect('gỡ chữ Kanji khỏi lịch ôn', a.api.delete(`/kanji/${kanji._id}/mark-learned`), { shape: 'deleted' });

  section('Vòng lặp học: bài học');
  const lessonPath = `/lesson-progress/lesson/${lesson._id}`;
  await expect('chưa học bài → data null', a.api.get(lessonPath), { shape: 'nullable' });
  await expect('bắt đầu bài', a.api.post(`${lessonPath}/start`));
  const vocabularyId = lesson.vocabularies?.[0]?._id ?? lesson.vocabularies?.[0];
  if (vocabularyId) {
    await expect('đánh dấu một từ trong bài', a.api.post(`${lessonPath}/update`, { item_type: 'vocabulary', item_id: String(vocabularyId), completed: true }));
  }
  await expect('hoàn thành bài', a.api.post(`${lessonPath}/complete`));
  const progress = await expect('/progress đọc từ LessonProgress', a.api.get('/progress'), { shape: 'list' });
  check('bài vừa học có trong /progress', progress?.some((row) => String(row.lesson?._id ?? row.lesson) === String(lesson._id)));
  await expect('tiến độ các bài', a.api.get('/lesson-progress/lessons'), { shape: 'list' });

  section('Vòng lặp học: bài tập');
  const exercises = await expect('bài tập N5', a.api.get('/exercise/level/N5'), { shape: 'list' });
  const exercise = await expect('đề bài tập', a.api.get(`/exercise/${exercises?.[0]?._id}`));
  check('đề không lộ đáp án đúng', !JSON.stringify(exercise ?? {}).includes('is_correct'));
  const submission = {
    attempt_id: randomUUID(),
    answers: (exercise?.questions ?? []).map((question) => ({ question_id: question._id, answer_id: question.answers?.[0]?._id })),
    timeSpent: 30,
  };
  const result = await expect('nộp bài → 201', a.api.post(`/exercise/submit/${exercise?._id}`, submission), { status: 201 });
  countView(Exercise, exercise?._id, 'total_attempts');
  const replay = await expect('gửi lại cùng lượt → 200, cùng kết quả', a.api.post(`/exercise/submit/${exercise?._id}`, submission));
  check('gửi lại không tạo kết quả mới', replay?._id === result?._id);

  // Luật XP: mỗi bài tối đa 10 (chưa đạt 5, làm đạt nhận nốt), làm lại khi đủ được 0.
  const reward = result?.xp;
  const tier = result?.passed ? 10 : 5;
  check('kết quả kèm XP lượt làm', reward?.awarded === tier && reward?.remaining === 10 - tier, JSON.stringify(reward));
  check('gửi lại trả đúng XP lần đầu', JSON.stringify(replay?.xp) === JSON.stringify(reward));
  const redo = await expect(
    'làm lại bằng lượt mới → 201',
    a.api.post(`/exercise/submit/${exercise?._id}`, { ...submission, attempt_id: randomUUID() }),
    { status: 201 },
  );
  countView(Exercise, exercise?._id, 'total_attempts');
  check('làm lại cùng kết quả không cộng thêm XP', redo?.xp?.awarded === 0 && redo?.xp?.remaining === 10 - tier, JSON.stringify(redo?.xp));

  // Hai lượt mới nộp cùng lúc vào một bài chưa làm: transaction phải xếp chúng
  // nối tiếp, chỉ một lượt nhận XP.
  const other = exercises?.[1] ? await expect('đề bài tập thứ hai', a.api.get(`/exercise/${exercises[1]._id}`)) : null;
  if (other) {
    const answers = other.questions.map((question) => ({ question_id: question._id, answer_id: question.answers?.[0]?._id }));
    const race = await Promise.all(
      [1, 2].map(() => a.api.post(`/exercise/submit/${other._id}`, { attempt_id: randomUUID(), answers, timeSpent: 20 })),
    );
    race.forEach(() => countView(Exercise, other._id, 'total_attempts'));
    check('hai lượt nộp song song đều được chấm', race.every((response) => response.status === 201), race.map((r) => r.status).join(', '));
    const [left, right] = race.map((response) => response.body?.data);
    const awarded = [left?.xp?.awarded, right?.xp?.awarded];
    check('hai lượt song song chỉ nhận XP một lần', awarded[0] + awarded[1] === (left?.passed ? 10 : 5), awarded.join(' + '));
  }
  const paid = new Map();
  for (const event of await ActivityEvent.find({ user: a.id, type: 'exercise.submit' }).lean()) {
    paid.set(event.source_id, (paid.get(event.source_id) ?? 0) + event.xp_delta);
  }
  check('nhật ký: không bài nào cho quá 10 XP', paid.size > 0 && [...paid.values()].every((xp) => xp <= 10), JSON.stringify([...paid.values()]));
  await expect('lịch sử bài tập', a.api.get('/exercise/history?page=1&limit=10'), { shape: 'paged' });
  await expect('xem lại kết quả', a.api.get(`/exercise/result/${result?._id}`));

  section('Vòng lặp học: JLPT');
  const exams = await expect('đề JLPT', a.api.get('/jlpt?page=1&limit=5'), { shape: 'paged' });
  const exam = await expect('chi tiết đề', a.api.get(`/jlpt/${exams?.[0]?._id}`));
  countView(JLPT, exams?.[0]?._id, 'total_views');
  await expectError('xem đáp án trước khi nộp → 403', a.api.get(`/jlpt/${exam?._id}/solutions`), 403);
  const firstKey = exam?.sections?.moji_goi?.length ? 'moji_goi_0' : 'bunpou_0';
  const jlptAttempt = { attempt_id: randomUUID(), answers: [{ question_key: firstKey, selected: 0 }], time_spent: 60 };
  // Mỗi đề giữ một kết quả gần nhất (upsert), không tạo tài nguyên mới nên là 200.
  const jlptResult = await expect('nộp đề JLPT', a.api.post(`/jlpt/${exam?._id}/submit`, jlptAttempt));
  check('kết quả có điểm từng phần', isObject(jlptResult?.section_scores), JSON.stringify(jlptResult)?.slice(0, 120));
  check('nộp đề lần đầu: 20 XP', jlptResult?.xp?.awarded === 20 && jlptResult?.xp?.remaining === 0, JSON.stringify(jlptResult?.xp));
  const retake = await expect('thi lại đề bằng lượt mới', a.api.post(`/jlpt/${exam?._id}/submit`, { ...jlptAttempt, attempt_id: randomUUID() }));
  check('thi lại không cộng thêm XP', retake?.xp?.awarded === 0, JSON.stringify(retake?.xp));
  await expect('đáp án sau khi nộp', a.api.get(`/jlpt/${exam?._id}/solutions`));
  const listed = await expect('danh sách đề có kết quả gần nhất', a.api.get('/jlpt?page=1&limit=5'), { shape: 'paged' });
  check('đề vừa thi có last_result', listed?.find((row) => row._id === exam?._id)?.last_result != null);
  await expect('luyện nhanh', a.api.get('/jlpt/practice?type=moji_goi&limit=5'), { shape: 'list' });

  section('Chuỗi ngày, XP, thành tích, tiến độ');
  const streak = await expect('chuỗi ngày', a.api.get('/streak/my-streak'));
  check('XP tăng sau khi học (gửi lại không cộng thêm)', streak?.total_xp > xpBefore, `${xpBefore} → ${streak?.total_xp}`);
  await expect('lịch sử XP', a.api.get('/streak/xp-history'), { shape: 'list' });
  await expect('lịch sử XP theo trang', a.api.get('/streak/xp-history?mode=page&limit=5'), { shape: 'cursor' });
  await expect('lịch học', a.api.get('/streak/days'), { shape: 'cursor' });
  await expect('bảng xếp hạng', a.api.get('/streak/leaderboard?period=week&limit=10'));
  await expect('cài đặt mục tiêu', a.api.get('/streak/settings'));
  await expect('lưu mục tiêu XP', a.api.put('/streak/settings', { daily_goal_xp: 30 }));
  await expect('huy hiệu của tôi', a.api.get('/achievement/my-achievements'));
  await expect('mọi huy hiệu', a.api.get('/achievement/all'), { shape: 'list' });
  await expect('thống kê huy hiệu', a.api.get('/achievement/stats'));
  await expect('huy hiệu theo nhóm', a.api.get('/achievement/category/vocabulary'));
  await expect('tổng quan tiến độ', a.api.get('/progress/dashboard/stats'));
  await expect('dòng thời gian', a.api.get('/progress/dashboard/timeline?period=week'), { shape: 'list' });
  await expect('bản đồ nhiệt', a.api.get('/progress/dashboard/heatmap'), { shape: 'list' });
  await expect('phân bổ', a.api.get('/progress/dashboard/breakdown'));
  await expect('học lại bài từ đầu', a.api.post(`${lessonPath}/reset`));
  await expect('bỏ đánh dấu từ', a.api.delete(`/vocabulary/${word._id}/mark-learned`), { shape: 'deleted' });
  return { exerciseResult: result, exam };
}

async function personalFlow({ a, b }, { exerciseResult, exam }) {
  section('Dữ liệu cá nhân và quyền sở hữu');
  const note = await expect('tạo ghi chú', a.api.post('/notebook', { title: 'Ghi chú smoke', content: 'Nội dung' }), { status: 201 });
  await expect('sửa ghi chú', a.api.put(`/notebook/${note?._id}`, { title: 'Ghi chú smoke đã sửa' }));
  await expect('danh sách ghi chú', a.api.get('/notebook?page=1&limit=10'), { shape: 'paged' });
  await expectError('B đọc ghi chú của A → 404', b.api.get(`/notebook/${note?._id}`), 404);
  await expectError('B xoá ghi chú của A → 404', b.api.delete(`/notebook/${note?._id}`), 404);
  await expect('xoá ghi chú', a.api.delete(`/notebook/${note?._id}`), { shape: 'deleted' });

  const deck = await expect('tạo bộ thẻ', a.api.post('/flashcard/decks', { title: 'Bộ smoke' }), { status: 201 });
  const withCard = await expect('thêm thẻ', a.api.post(`/flashcard/decks/${deck?._id}/cards`, { front: '学生', back: 'học sinh' }), { status: 201 });
  const cardId = withCard?.cards?.[0]?._id;
  await expect('sửa thẻ', a.api.put(`/flashcard/decks/${deck?._id}/cards/${cardId}`, { back: 'sinh viên' }));
  await expect('ghi lượt học', a.api.post(`/flashcard/decks/${deck?._id}/study`));
  await expect('bộ thẻ của tôi', a.api.get('/flashcard/decks?page=1&limit=10'), { shape: 'paged' });
  await expectError('B mở bộ thẻ riêng của A → 404', b.api.get(`/flashcard/decks/${deck?._id}`), 404);
  await expect('xoá thẻ', a.api.delete(`/flashcard/decks/${deck?._id}/cards/${cardId}`));
  await expect('xoá bộ thẻ', a.api.delete(`/flashcard/decks/${deck?._id}`), { shape: 'deleted' });

  await expectError('B xem kết quả bài tập của A → 404', b.api.get(`/exercise/result/${exerciseResult?._id}`), 404);
  await expectError('B xem đáp án đề A đã thi → 403', b.api.get(`/jlpt/${exam?._id}/solutions`), 403);

  const goal = await expect('tạo mục tiêu', a.api.post('/goal', { type: 'vocabulary', target: 5 }), { status: 201 });
  const goals = await expect('danh sách mục tiêu', a.api.get('/goal'), { shape: 'list' });
  check('mục tiêu kèm số đếm để gợi ý', isObject((await a.api.get('/goal')).body?.counts), JSON.stringify(goals)?.slice(0, 80));
  await expect('sửa mục tiêu', a.api.patch(`/goal/${goal?.id}`, { title: 'Mục tiêu smoke' }));
  await expectError('B xoá mục tiêu của A → 404', b.api.delete(`/goal/${goal?.id}`), 404);
  await expect('xoá mục tiêu', a.api.delete(`/goal/${goal?.id}`), { shape: 'deleted' });

  await expect('đọc cài đặt', a.api.get('/settings'));
  await expect('lưu cài đặt', a.api.post('/settings', { notificationsEnabled: true, soundEnabled: false, vibrateEnabled: true, language: 'vi', theme: 'dark' }));

  section('Nhóm học');
  const group = await expect('tạo nhóm', a.api.post('/group', { name: `Nhóm smoke ${stamp}` }), { status: 201 });
  await expect('B vào nhóm', b.api.post(`/group/join/${group?._id}`));
  await expect('chi tiết nhóm', b.api.get(`/group/${group?._id}`));
  await expect('thống kê nhóm', b.api.get(`/group/${group?._id}/stats`));
  await expect('nhóm của tôi', b.api.get('/group/me'), { shape: 'list' });
  await expect('mọi nhóm', b.api.get('/group?page=1&limit=10'), { shape: 'paged' });
  await expectError('B xoá nhóm của A → 403', b.api.delete(`/group/${group?._id}`), 403);
  await expect('B rời nhóm', b.api.post(`/group/leave/${group?._id}`));
  await expect('A xoá nhóm', a.api.delete(`/group/${group?._id}`), { shape: 'deleted' });
}

/** PNG 1×1 hợp lệ. */
const TINY_PNG = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', 'base64');
const XLSX = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

async function filesAndRecoveryFlow({ a, b, admin }) {
  section('Quên mật khẩu');
  // Chỉ thử email không có tài khoản: không gửi thư thật cho ai.
  await expectError('email sai định dạng → 400', request('POST', '/users/forgot-password', { body: { email: 'khong-phai-email' } }), 400);
  const forgot = await request('POST', '/users/forgot-password', { body: { email: `${PREFIX}khong_co_${stamp}@example.invalid` } });
  check('email không có tài khoản → 200 thông báo chung (503 nếu máy chưa cấu hình email)',
    (forgot.status === 200 && forgot.body?.data?.requested === true) || forgot.body?.code === 'EMAIL_NOT_CONFIGURED', describe(forgot));

  section('Tải tệp');
  const avatar = { token: a.token, field: 'avatar', fileName: 'smoke.png', type: 'image/png', bytes: TINY_PNG };
  const withAvatar = await expect('đổi ảnh đại diện', upload('PUT', `/users/profile/${a.id}/avatar`, avatar));
  const path = withAvatar?.AnhDaiDien ?? '';
  const served = await fetch(new URL(path, API));
  check('ảnh vừa tải được phục vụ lại', path.startsWith('/uploads/avatars/') && served.status === 200
    && served.headers.get('content-type') === 'image/png', `${path} → HTTP ${served.status}`);
  const filesNow = uploadedFiles().length;
  await expectError('B đổi ảnh đại diện của A → 403', upload('PUT', `/users/profile/${a.id}/avatar`, { ...avatar, token: b.token }), 403);
  await expectError('ảnh đại diện là tệp chữ → 400', upload('PUT', `/users/profile/${a.id}/avatar`, { ...avatar, fileName: 'smoke.txt', type: 'text/plain' }), 400);
  await expectError('tệp HTML đổi tên thành .png → 400', upload('PUT', `/users/profile/${a.id}/avatar`, { ...avatar, bytes: Buffer.from('<html><script>alert(1)</script></html>') }), 400);
  check('request bị từ chối không để lại tệp nào', uploadedFiles().length === filesNow, `${filesNow} → ${uploadedFiles().length} tệp`);
  const replaced = await expect('đổi ảnh đại diện lần hai', upload('PUT', `/users/profile/${a.id}/avatar`, avatar));
  check('ảnh cũ bị xoá khi có ảnh mới', (await fetch(new URL(path, API))).status === 404 && replaced?.AnhDaiDien !== path
    && uploadedFiles().length === filesNow, `ảnh cũ ${path}`);

  const sheet = { token: admin.token, field: 'fileExcel', type: XLSX, bytes: Buffer.from('PK') };
  const legacy = await upload('POST', '/kanji/upload', { ...sheet, fileName: 'kanji.xls', type: 'application/vnd.ms-excel' });
  check('nhập Kanji từ .xls → 400 hướng dẫn lưu lại .xlsx', legacy.status === 400 && /\.xlsx/.test(legacy.body?.message), describe(legacy));
  await expectError('nhập Kanji từ tệp .xlsx hỏng → 400', upload('POST', '/kanji/upload', { ...sheet, fileName: 'kanji.xlsx' }), 400);
}

async function adminFlow({ a, b, admin }) {
  section('Quản trị');
  await expectError('người học gọi API quản trị → 403', a.api.get('/users/admin/users'), 403);

  const users = await expect('tìm tài khoản', admin.api.get(`/users/admin/users?search=${PREFIX}&limit=20`), { shape: 'paged' });
  check('tìm thấy ba tài khoản tạm', users?.length >= 3, `${users?.length}`);
  const learnerA = users?.find((user) => user._id === a.id);
  check('XP và chuỗi ngày lấy từ streak thật (A đã học nên XP > 0)', learnerA?.total_xp > 0 && isCount(learnerA?.current_streak),
    JSON.stringify({ total_xp: learnerA?.total_xp, current_streak: learnerA?.current_streak }));
  check('không trả các trường thống kê cũ của User', users?.every((user) => !('DiemTichLuy' in user) && !('StreakHienTai' in user)));
  const stats = await expect('thống kê tài khoản', admin.api.get('/users/admin/stats'));
  check('thống kê có số theo trạng thái', Array.isArray(stats?.byStatus) && stats.byStatus.some((row) => row._id === 'active'));

  await expect('khoá B', admin.api.put(`/users/admin/users/${b.id}`, { trangThai: 'banned' }));
  const banned = await login(b.username);
  check('B bị khoá không đăng nhập được', banned.status === 403 || banned.status === 401, describe(banned));
  await expect('mở khoá B', admin.api.put(`/users/admin/users/${b.id}`, { trangThai: 'active' }));
  await expect('nâng B lên quản trị', admin.api.put(`/users/admin/users/${b.id}`, { vaiTro: 'admin' }));
  await expect('hạ B xuống người học', admin.api.put(`/users/admin/users/${b.id}`, { vaiTro: 'user' }));
  await expectError('admin không tự xoá mình → 400', admin.api.delete(`/users/admin/users/${admin.id}`), 400);

  await expect('gửi thông báo cho A', admin.api.post('/notifications', { recipient_id: a.id, title: 'Smoke', message: 'Thông báo thử' }), { status: 201 });
  const unread = await expect('A đếm chưa đọc', a.api.get('/notifications/count/unread'));
  check('A có thông báo chưa đọc', unread?.unread_count >= 1, JSON.stringify(unread));
  const inbox = await expect('A xem thông báo', a.api.get('/notifications?page=1&limit=20'), { shape: 'paged' });
  const notice = inbox?.find((item) => item.title === 'Smoke');
  await expect('A đọc thông báo', a.api.put(`/notifications/read/${notice?.id}`));
  await expect('A đọc tất cả', a.api.put('/notifications/read-all'));
  await expectError('B xoá thông báo của A → 404', b.api.delete(`/notifications/${notice?.id}`), 404);
  await expect('A xoá thông báo', a.api.delete(`/notifications/${notice?.id}`), { shape: 'deleted' });

  const report = await expect('A gửi báo cáo', a.api.post('/report/create', { type: 'bug', title: 'Smoke report', description: 'Thử' }), { status: 201 });
  await expect('báo cáo của A', a.api.get('/report/my-reports?page=1&limit=10'), { shape: 'paged' });
  await expect('admin xem báo cáo', admin.api.get('/report/admin/all?status=pending'), { shape: 'paged' });
  await expect('admin phản hồi', admin.api.put(`/report/admin/${report?._id}/status`, { status: 'in_progress', admin_response: 'Đã nhận' }));
  const resolved = await expect('admin đổi trạng thái, giữ phản hồi', admin.api.put(`/report/admin/${report?._id}/status`, { status: 'resolved' }));
  check('phản hồi cũ còn nguyên', resolved?.admin_response === 'Đã nhận', JSON.stringify(resolved)?.slice(0, 120));
  await expect('thống kê báo cáo', admin.api.get('/report/admin/stats'));
  await expect('admin xoá báo cáo', admin.api.delete(`/report/admin/${report?._id}`), { shape: 'deleted' });

  const transaction = await expect('A gửi yêu cầu nâng cấp', a.api.post('/transactions/create', { type: 'SUBSCRIPTION', amount: 99000, package_id: 'premium_month' }), { status: 201 });
  const pending = await expect('admin xem giao dịch chờ', admin.api.get('/transactions/admin/all?status=pending'), { shape: 'paged' });
  check('giao dịch của A có người mua đã populate', isObject(pending?.find((row) => row._id === transaction?._id)?.user));
  await expect('admin duyệt giao dịch', admin.api.put(`/transactions/admin/${transaction?._id}/status`, { status: 'completed' }));

  const badges = await expect('admin xem huy hiệu', admin.api.get('/achievement/admin/all'), { shape: 'list' });
  check('huy hiệu kèm số người đã mở', badges?.every((badge) => isCount(badge.unlocked)));
  const badge = await expect('admin tạo huy hiệu (ẩn)', admin.api.post('/achievement/admin', {
    name: `${PREFIX}badge_${stamp}`, name_vi: 'Smoke', description: 'smoke', description_vi: 'smoke', icon: '🧪',
    category: 'vocabulary', requirement_type: 'count', requirement_value: 99999, is_active: false,
  }), { status: 201 });
  created.achievements.push(badge?._id);
  await expect('admin sửa huy hiệu', admin.api.put(`/achievement/admin/${badge?._id}`, { xp_reward: 5 }));
  await expect('admin xoá huy hiệu', admin.api.delete(`/achievement/admin/${badge?._id}`), { shape: 'deleted' });

  const grammar = await expect('admin thêm ngữ pháp', admin.api.post('/grammar', {
    title: `${PREFIX}grammar_${stamp}`, structure: 'N + です', meaning: 'là', level: 'N5',
  }), { status: 201 });
  created.grammar.push(grammar?._id);
  await expect('admin sửa ngữ pháp', admin.api.put(`/grammar/${grammar?._id}`, { meaning: 'là (sửa)' }));
  await expect('admin xoá ngữ pháp', admin.api.delete(`/grammar/${grammar?._id}`), { shape: 'deleted' });
  await expectError('người học thêm ngữ pháp → 403', a.api.post('/grammar', { title: 'x', structure: 'x', meaning: 'x', level: 'N5' }), 403);

  await expect('phân tích 30 ngày', admin.api.get('/progress/admin/analytics?period=30d'));
  await expect('thống kê bài học', admin.api.get('/lesson/stats/overview'));
  await expect('admin xoá tài khoản B', admin.api.delete(`/users/admin/users/${b.id}`), { shape: 'deleted' });
}

async function removedRoutesFlow({ a }) {
  section('Route đã gỡ trả 404');
  for (const path of ['/exercise/type/vocabulary', '/lesson/level/N5', '/lesson-progress/stats', '/users/me']) {
    await expectError(`GET ${path}`, a.api.get(path), 404);
  }
  await expectError('DELETE /users/admin/users (xoá hàng loạt)', a.api.delete('/users/admin/users'), 404);
}

async function logoutFlow({ a }) {
  section('Đăng xuất');
  await expect('đăng xuất', request('POST', '/users/logout', { token: a.token, body: { refreshToken: a.refreshToken } }));
  await expectError('access token của phiên đã đăng xuất → 401', a.api.get('/lesson'), 401);
}

// ------------------------------------------------------------------------ chạy

const main = async () => {
  if (env.nodeEnv === 'production') throw new Error('Không chạy smoke test trên production.');
  await mongoose.connect(env.mongoUri, { dbName: env.databaseName });
  console.log(`Smoke test ${API} trên database '${mongoose.connection.name}'`);

  const leftover = await purgeSmokeData();
  if (leftover > 0) console.log(`Đã dọn ${leftover} tài khoản tạm của lần chạy trước.`);
  const baseline = await collectionCounts();
  const filesBefore = uploadedFiles();

  try {
    const people = await authFlow();
    const content = await contentFlow(people);
    const learned = await learningLoop(people, content);
    await personalFlow(people, learned);
    await filesAndRecoveryFlow(people);
    await adminFlow(people);
    await removedRoutesFlow(people);
    await logoutFlow(people);
  } catch (error) {
    check('chạy hết các luồng không ném lỗi', false, error.stack);
  } finally {
    section('Dọn dữ liệu tạm');
    await purgeSmokeData();
    await restoreCounters();
    // Tải ảnh của người khác bị chặn sau khi multer đã ghi tệp, nên dọn theo thư mục chứ không theo database.
    removeNewUploads(filesBefore);
    check('không còn tệp tải lên của lần chạy', uploadedFiles().length === filesBefore.length);
    const after = await collectionCounts();
    const drift = Object.keys({ ...baseline, ...after }).filter((name) => (baseline[name] ?? 0) !== (after[name] ?? 0));
    check('số bản ghi mọi collection khớp lúc bắt đầu', drift.length === 0,
      drift.map((name) => `${name}: ${baseline[name] ?? 0} → ${after[name] ?? 0}`).join(', '));
    await mongoose.disconnect();
  }

  console.log(`\n${passed} đạt, ${failures.length} hỏng`);
  if (failures.length > 0) {
    console.log(failures.map((failure) => `  - ${failure}`).join('\n'));
    process.exitCode = 1;
  }
};

await main();

import assert from 'node:assert/strict';
import fs from 'node:fs';
import test from 'node:test';

import {
  parseTimecode,
  reviewLessonVideos,
} from '../src/modules/lessons/lesson-video.review.js';
import { SITUATIONAL_LESSONS } from '../scripts/situational-lessons.js';

const line = (over = {}) => ({
  start: '00:04:00',
  end: '00:07:00',
  speaker_ja: 'オウ',
  speaker_vi: 'Ou',
  text_ja: 'おはようございます。',
  romaji: 'Ohayoo gozaimasu.',
  text_vi: 'Chào buổi sáng.',
  ...over,
});

const data = (over = {}) => ({
  lesson: { title: 'Tình huống: Tự giới thiệu' },
  videos: [{ title: 'Chào buổi sáng', url: '/uploads/a.mp4', transcript: [line()] }],
  ...over,
});

// --- mốc thời gian ---------------------------------------------------------

test('đọc được mm:ss, mm:ss:ff và hh:mm:ss:ff', () => {
  assert.equal(parseTimecode('01:30'), 90);
  assert.equal(parseTimecode('00:04:00'), 4);
  assert.equal(parseTimecode('02:37:15'), 157.5);
  assert.equal(parseTimecode('01:00:00:00'), 3600);
  assert.equal(parseTimecode(12.5), 12.5);
});

test('mốc thời gian sai trả về null chứ không đoán', () => {
  assert.equal(parseTimecode('mấy giờ'), null);
  assert.equal(parseTimecode('00:0a'), null);
  assert.equal(parseTimecode('7'), null);
  assert.equal(parseTimecode(null), null);
});

// --- kiểm dữ liệu ----------------------------------------------------------

test('file hợp lệ được chuẩn hoá sang giây', () => {
  const { videos, errors } = reviewLessonVideos(data());

  assert.deepEqual(errors, []);
  assert.equal(videos.length, 1);
  assert.deepEqual(videos[0].transcript[0], {
    start_seconds: 4,
    end_seconds: 7,
    speaker_ja: 'オウ',
    speaker_romaji: null,
    speaker_vi: 'Ou',
    text_ja: 'おはようございます。',
    romaji: 'Ohayoo gozaimasu.',
    text_vi: 'Chào buổi sáng.',
    key_phrase: false,
  });
  assert.deepEqual(videos[0].vocabulary, []);
});

test('thiếu tiêu đề hoặc đường dẫn thì video bị loại và báo lỗi', () => {
  const { videos, errors } = reviewLessonVideos(
    data({ videos: [{ title: 'Không có file', transcript: [] }] }),
  );

  assert.equal(videos.length, 0);
  assert.match(errors.join(' '), /url/);
});

test('lời thoại thiếu bản dịch hoặc sai mốc thời gian được báo đúng số dòng', () => {
  const { errors } = reviewLessonVideos(
    data({
      videos: [{
        title: 'V',
        url: '/uploads/a.mp4',
        transcript: [line(), line({ text_vi: '' }), line({ start: 'xx' })],
      }],
    }),
  );

  assert.match(errors.join(' '), /Lời thoại 2/);
  assert.match(errors.join(' '), /Lời thoại 3/);
});

test('kết thúc trước lúc bắt đầu, hoặc thứ tự lùi về trước, đều bị chặn', () => {
  const backwards = reviewLessonVideos(
    data({
      videos: [{
        title: 'V',
        url: '/uploads/a.mp4',
        transcript: [
          line({ start: '00:20', end: '00:25' }),
          line({ start: '00:05', end: '00:09' }),
        ],
      }],
    }),
  );
  assert.match(backwards.errors.join(' '), /lùi về trước/);

  const inverted = reviewLessonVideos(
    data({ videos: [{ title: 'V', url: '/uploads/a.mp4', transcript: [line({ start: '00:20', end: '00:10' })] }] }),
  );
  assert.match(inverted.errors.join(' '), /nhỏ hơn/);
});

test('file không có danh sách video bị từ chối cả file', () => {
  assert.match(reviewLessonVideos({ lesson: {} }).errors.join(' '), /videos/);
  assert.match(reviewLessonVideos(null).errors.join(' '), /object JSON/);
});

test('video mặc định là cảnh tình huống; `kind` lạ bị chặn', () => {
  const ok = reviewLessonVideos(
    data({ videos: [{ title: 'Cảnh 1', url: '/a.mp4' }, { title: 'Ôn tập', url: '/b.mp4', kind: 'review' }] }),
  );
  assert.deepEqual(ok.errors, []);
  assert.deepEqual(ok.videos.map((video) => video.kind), ['scene', 'review']);

  const bad = reviewLessonVideos(data({ videos: [{ title: 'V', url: '/a.mp4', kind: 'trailer' }] }));
  assert.match(bad.errors.join(' '), /`kind` phải là scene hoặc review/);
});

test('từ vựng của video được chuẩn hoá; từ thiếu mặt chữ hay nghĩa bị báo', () => {
  const ok = reviewLessonVideos(
    data({ videos: [{ title: 'V', url: '/a.mp4', vocabulary: [{ word: ' 道 ', reading: 'みち', meaning: 'con đường' }] }] }),
  );
  assert.deepEqual(ok.errors, []);
  assert.deepEqual(ok.videos[0].vocabulary, [{ word: '道', reading: 'みち', romaji: null, meaning: 'con đường' }]);

  const bad = reviewLessonVideos(data({ videos: [{ title: 'V', url: '/a.mp4', vocabulary: [{ word: '道' }, { meaning: 'x' }] }] }));
  assert.match(bad.errors.join(' '), /Từ 1: thiếu `meaning`/);
  assert.match(bad.errors.join(' '), /Từ 2: thiếu `word`/);
});

test('hai cảnh trỏ cùng một file bị chặn', () => {
  const { errors } = reviewLessonVideos(
    data({
      videos: [
        { title: 'Cảnh 1', url: '/uploads/a.mp4' },
        { title: 'Cảnh 2', url: '/uploads/a.mp4' },
      ],
    }),
  );
  assert.match(errors.join(' '), /Video 2: trùng `url` với video 1/);
});

// --- file dữ liệu thật -----------------------------------------------------

const DATA_DIR = new URL('../data/lesson-videos/', import.meta.url);
const dataFiles = fs.readdirSync(DATA_DIR).filter((name) => name.endsWith('.json'));

test('mọi file trong data/lesson-videos hợp lệ và trỏ tới một bài trong bộ chủ đề', () => {
  const titles = new Set(SITUATIONAL_LESSONS.map((lesson) => lesson.title));
  const urls = new Set();

  for (const name of dataFiles) {
    const content = JSON.parse(fs.readFileSync(new URL(name, DATA_DIR), 'utf8'));
    const { videos, errors } = reviewLessonVideos(content);

    assert.deepEqual(errors, [], name);
    assert.ok(titles.has(content.lesson?.title), `${name}: không có bài "${content.lesson?.title}"`);
    for (const video of videos) {
      assert.ok(!urls.has(video.url), `${name}: ${video.url} đã dùng ở file khác`);
      urls.add(video.url);
    }
  }
});

test('bài chào hỏi giữ đủ bốn cảnh kèm lời thoại', () => {
  const content = JSON.parse(fs.readFileSync(new URL('n5-01-greeting.json', DATA_DIR), 'utf8'));
  const { videos } = reviewLessonVideos(content);

  assert.equal(videos.length, 4);
  assert.ok(videos.every((video) => video.transcript.length > 0));
});

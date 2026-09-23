import assert from 'node:assert/strict';
import fs from 'node:fs';
import test from 'node:test';

import {
  parseTimecode,
  reviewLessonVideos,
} from '../src/modules/lessons/lesson-video.review.js';

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
  lesson: { level: 'N5', order: 1 },
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
    speaker_vi: 'Ou',
    text_ja: 'おはようございます。',
    romaji: 'Ohayoo gozaimasu.',
    text_vi: 'Chào buổi sáng.',
  });
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

// --- file dữ liệu thật -----------------------------------------------------

test('data/lesson-videos/n5-01-greeting.json hợp lệ toàn bộ', () => {
  const file = new URL('../data/lesson-videos/n5-01-greeting.json', import.meta.url);
  const { videos, errors } = reviewLessonVideos(JSON.parse(fs.readFileSync(file, 'utf8')));

  assert.deepEqual(errors, []);
  assert.equal(videos.length, 4);
  assert.ok(videos.every((video) => video.transcript.length > 0));
});

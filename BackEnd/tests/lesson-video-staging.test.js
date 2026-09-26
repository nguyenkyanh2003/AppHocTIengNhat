import assert from 'node:assert/strict';
import test from 'node:test';

import {
  mergeManifest,
  parseRawVideoName,
  planLessonFolder,
  transcriptSkeleton,
  VIDEO_SOURCE,
} from '../scripts/lesson-video-staging.js';
import { parseTranscriptText } from '../scripts/transcript-text.js';

// Tên file lấy đúng như trong data/Video_baihoc.
test('đọc được cảnh và video ôn tập với mọi kiểu dấu đang có', () => {
  assert.deepEqual(parseRawVideoName('10－1．Em muốn mở tài khoản..mp4'), {
    lesson: 10, scene: 1, title: 'Em muốn mở tài khoản',
  });
  assert.equal(parseRawVideoName('5－3．Cỡ không vừa một chút….mp4').title, 'Cỡ không vừa một chút…');
  assert.deepEqual(parseRawVideoName('1-1．Chào buổi sáng.mp4'), { lesson: 1, scene: 1, title: 'Chào buổi sáng' });
  assert.deepEqual(parseRawVideoName('9－2. ở đâu ạ.mp4'), { lesson: 9, scene: 2, title: 'ở đâu ạ' });
  assert.deepEqual(parseRawVideoName('8－2．Tôi muốn đi .mp4'), { lesson: 8, scene: 2, title: 'Tôi muốn đi' });

  assert.deepEqual(parseRawVideoName('10. Ôn tập.mp4'), { lesson: 10, scene: null, title: 'Ôn tập' });
  assert.deepEqual(parseRawVideoName('5.Ôn tập.mp4'), { lesson: 5, scene: null, title: 'Ôn tập' });
  assert.equal(parseRawVideoName('2. On tap.mp4').lesson, 2);
  assert.deepEqual(parseRawVideoName('1 tổng hợp lý thuyết chào hỏi.mp4'), {
    lesson: 1, scene: null, title: 'Tổng hợp lý thuyết chào hỏi',
  });
  assert.equal(parseRawVideoName('ghi chú.txt'), null);
});

const files = (...entries) => entries.map(([name, hash]) => ({ name, hash }));

test('bốn video khác nhau: ba cảnh theo thứ tự rồi tới video ôn tập', () => {
  const { videos, errors } = planLessonFolder({
    lesson: 10,
    files: files(
      ['10. Ôn tập.mp4', 'd'],
      ['10－2．Em muốn làm thẻ tín dụng..mp4', 'b'],
      ['10－1．Em muốn mở tài khoản..mp4', 'a'],
      ['10－3．Quý khách muốn tích lũy khoảng bao nhiêu tiền hàng tháng.mp4', 'c'],
    ),
  });

  assert.deepEqual(errors, []);
  assert.deepEqual(videos.map((video) => video.target), ['scene-1.mp4', 'scene-2.mp4', 'scene-3.mp4', 'summary.mp4']);
  assert.deepEqual(videos.map((video) => video.kind), ['scene', 'scene', 'scene', 'review']);
  assert.equal(videos[1].title, 'Em muốn làm thẻ tín dụng');
  assert.equal(videos[3].title, 'Ôn tập', 'video ôn tập luôn mang một tên, dù tên file là "On tap" hay "Tổng hợp…"');
});

test('bốn file giống hệt nhau thì từ chối cả thư mục — đúng tình trạng bài 2–12 hiện tại', () => {
  const { videos, errors } = planLessonFolder({
    lesson: 9,
    files: files(
      ['9. Ôn tập.mp4', 'x'],
      ['9－1．Hãy đi thẳng đường này.mp4', 'x'],
      ['9－2. ở đâu ạ.mp4', 'x'],
      ['9－3．Tôi đang ở gần.mp4', 'x'],
    ),
  });

  assert.deepEqual(videos, []);
  assert.match(errors.join(' '), /4 file giống hệt nhau/);
});

test('file đánh số bài khác với thư mục bị chặn — đúng tình trạng thư mục bài 4', () => {
  const { videos, errors } = planLessonFolder({
    lesson: 4,
    files: files(['3－1．Quầy hàng đó ở đâu ạ.mp4', 'a'], ['4－2．Cảnh khác.mp4', 'b']),
  });

  assert.deepEqual(videos, []);
  assert.match(errors.join(' '), /ghi bài 3 nhưng nằm trong thư mục bài 4/);
});

test('hai file cùng số cảnh, hai video ôn tập, hoặc tên sai mẫu đều được báo', () => {
  const { errors } = planLessonFolder({
    lesson: 5,
    files: files(
      ['5－1．A.mp4', 'a'],
      ['5－1．B.mp4', 'b'],
      ['5. Ôn tập.mp4', 'c'],
      ['5 Tổng hợp.mp4', 'd'],
      ['video.mp4', 'e'],
    ),
  });

  assert.match(errors.join(' '), /cùng là cảnh 1/);
  assert.match(errors.join(' '), /hai video ôn tập/);
  assert.match(errors.join(' '), /"video.mp4": tên không theo mẫu/);
});

test('khung lời thoại sinh ra đủ tiêu đề cảnh và đọc lại được bằng chính bộ đọc lời thoại', () => {
  const skeleton = transcriptSkeleton({
    lesson: 10,
    title: 'Tình huống: Rút tiền và gửi tiết kiệm',
    videos: [
      { target: 'scene-1.mp4', title: 'Em muốn mở tài khoản.' },
      { target: 'summary.mp4', title: 'Ôn tập' },
    ],
  });

  const { scenes, errors } = parseTranscriptText(skeleton);
  assert.deepEqual(errors, [], 'khung mới sinh không được có lỗi định dạng');
  assert.deepEqual([...scenes.keys()], ['scene-1.mp4', 'summary.mp4']);
  assert.deepEqual(
    [...scenes.values()],
    [{ lines: [], vocabulary: [] }, { lines: [], vocabulary: [] }],
    'khung chưa có câu thoại hay từ vựng nào',
  );
  assert.match(skeleton, /apply-transcript\.js --lesson 10/);
  assert.match(skeleton, /# Em muốn mở tài khoản\./);
});

test('cập nhật file mô tả giữ lời thoại đã nhập, thêm cảnh mới với lời thoại rỗng', () => {
  const transcript = [{ start: '00:04', text_ja: 'おはようございます。', text_vi: 'Chào buổi sáng.' }];
  const manifest = {
    lesson: { title: 'Tình huống: Hỏi đường' },
    videos: [
      { title: 'Tên đã sửa tay', url: '/uploads/lesson-videos/n5-09-directions/scene-1.mp4', source: VIDEO_SOURCE, transcript },
      { title: 'Hỏi đường', url: '/uploads/lesson-videos/n5-09-directions/video-1.mp4', transcript: [] },
    ],
  };

  const merged = mergeManifest({
    manifest,
    dir: 'n5-09-directions',
    videos: [
      { target: 'scene-1.mp4', title: 'Hãy đi thẳng đường này', kind: 'scene' },
      { target: 'summary.mp4', title: 'Ôn tập', kind: 'review' },
    ],
  });

  assert.deepEqual(merged.lesson, manifest.lesson);
  assert.deepEqual(merged.videos[0], { ...manifest.videos[0], kind: 'scene' }, 'giữ tên và lời thoại đã sửa tay');
  assert.deepEqual(merged.videos[1], {
    title: 'Ôn tập',
    url: '/uploads/lesson-videos/n5-09-directions/summary.mp4',
    kind: 'review',
    source: VIDEO_SOURCE,
    transcript: [],
  });
  assert.equal(merged.videos.length, 2, 'video-1.mp4 không còn trong thư mục gốc thì bị bỏ');
});

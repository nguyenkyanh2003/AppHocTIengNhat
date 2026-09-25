import assert from 'node:assert/strict';
import test from 'node:test';

import { reviewLessonVideos } from '../src/modules/lessons/lesson-video.review.js';
import { applyTranscripts, parseTranscriptText } from '../scripts/transcript-text.js';

const TEXT = `# Lời thoại bài 9 — gõ trong lúc xem video
## scene-1.mp4
00:04-00:07 | 通行人 / Người đi đường | この道をまっすぐ行ってください。 | Kono michi o massugu itte kudasai. | Bạn cứ đi thẳng đường này.
00:08       |                        | はい、まっすぐですね。           |                                   | Vâng, đi thẳng ạ.

## scene-2.mp4
00:02 | オウ / Ou | すみません。 | Sumimasen. | Xin lỗi.
`;

test('đọc được file lời thoại: tách cảnh, mốc thời gian, người nói, ba lớp chữ', () => {
  const { scenes, errors } = parseTranscriptText(TEXT);

  assert.deepEqual(errors, []);
  assert.deepEqual([...scenes.keys()], ['scene-1.mp4', 'scene-2.mp4']);
  assert.deepEqual(scenes.get('scene-1.mp4')[0], {
    start: '00:04',
    end: '00:07',
    speaker_ja: '通行人',
    speaker_vi: 'Người đi đường',
    text_ja: 'この道をまっすぐ行ってください。',
    romaji: 'Kono michi o massugu itte kudasai.',
    text_vi: 'Bạn cứ đi thẳng đường này.',
  });
});

test('ô để trống là không có: câu không mốc kết thúc, không người nói, không roma-ji', () => {
  const { scenes } = parseTranscriptText(TEXT);
  const line = scenes.get('scene-1.mp4')[1];

  assert.equal('end' in line, false);
  assert.equal(line.speaker_ja, null);
  assert.equal(line.speaker_vi, null);
  assert.equal(line.romaji, null);
  assert.equal(line.text_vi, 'Vâng, đi thẳng ạ.');
});

test('mọi lỗi gõ đều chỉ đúng số dòng', () => {
  const { errors } = parseTranscriptText(
    [
      '00:01 | | Câu lạc chỗ. | | Chưa có tên cảnh.', // dòng 1
      '## scene-1.mp4', // 2
      '00:02 | | あ。 | | Thiếu ô.', // 3 — chỉ 5 ô, hợp lệ
      '00:03 | | い。 | Thiếu nghĩa tiếng Việt |', // 4
      'xx:yy | | う。 | | Mốc sai.', // 5
      '00:20-00:10 | | え。 | | Kết thúc trước bắt đầu.', // 6
      '00:04 | | | | Thiếu tiếng Nhật.', // 7
      '00:05 | Thiếu ô cuối', // 8
      '## scene-1.mp4', // 9
    ].join('\n'),
  );

  assert.match(errors[0], /^Dòng 1: câu thoại nằm trước dòng "## /);
  assert.match(errors[1], /^Dòng 4: thiếu nghĩa tiếng Việt/);
  assert.match(errors[2], /^Dòng 5: mốc thời gian "xx:yy"/);
  assert.match(errors[3], /^Dòng 6: mốc kết thúc "00:10" trước mốc bắt đầu/);
  assert.match(errors[4], /^Dòng 7: thiếu câu tiếng Nhật/);
  assert.match(errors[5], /^Dòng 8: cần đúng 5 ô/);
  assert.match(errors[6], /^Dòng 9: "scene-1.mp4" đã có phần lời thoại ở trên/);
  assert.equal(errors.length, 7);
});

const manifest = () => ({
  lesson: { title: 'Tình huống: Hỏi đường' },
  videos: [
    { title: 'Cảnh 1', url: '/uploads/lesson-videos/n5-09-directions/scene-1.mp4', transcript: [] },
    { title: 'Cảnh 2', url: '/uploads/lesson-videos/n5-09-directions/scene-2.mp4', transcript: [] },
    { title: 'Ôn tập', url: '/uploads/lesson-videos/n5-09-directions/summary.mp4', transcript: [] },
  ],
});

test('ghi lời thoại vào đúng cảnh, cảnh chưa gõ giữ nguyên', () => {
  const { scenes } = parseTranscriptText(TEXT);
  const { manifest: updated, applied, errors } = applyTranscripts({ manifest: manifest(), scenes });

  assert.deepEqual(errors, []);
  assert.deepEqual(applied, [
    { name: 'scene-1.mp4', count: 2 },
    { name: 'scene-2.mp4', count: 1 },
  ]);
  assert.equal(updated.videos[0].transcript.length, 2);
  assert.equal(updated.videos[1].transcript.length, 1);
  assert.deepEqual(updated.videos[2].transcript, [], 'cảnh chưa gõ lời thoại không bị đụng tới');
  assert.equal(updated.videos[0].title, 'Cảnh 1', 'chỉ thay lời thoại, không thay tên cảnh');
});

test('tiêu đề cảnh chưa gõ dòng nào không xoá lời thoại đã có', () => {
  const before = manifest();
  before.videos[0].transcript = [{ start: '00:01', text_ja: 'あ。', text_vi: 'A.' }];

  const { scenes } = parseTranscriptText('## scene-1.mp4\n# đang gõ dở\n');
  const { manifest: updated, applied, empty, errors } = applyTranscripts({ manifest: before, scenes });

  assert.deepEqual(errors, []);
  assert.deepEqual(applied, []);
  assert.deepEqual(empty, ['scene-1.mp4']);
  assert.deepEqual(updated.videos[0].transcript, before.videos[0].transcript);
});

test('gõ nhầm tên cảnh bị báo chứ không lặng lẽ bỏ qua', () => {
  const { scenes } = parseTranscriptText('## scene-9.mp4\n00:01 | | あ。 | | A.');
  const { applied, errors } = applyTranscripts({ manifest: manifest(), scenes });

  assert.deepEqual(applied, []);
  assert.match(errors.join(' '), /không có cảnh "scene-9.mp4"/);
  assert.match(errors.join(' '), /scene-1\.mp4, scene-2\.mp4, summary\.mp4/);
});

test('kết quả đi qua được bộ kiểm lúc nhập DB', () => {
  const { scenes } = parseTranscriptText(TEXT);
  const { manifest: updated } = applyTranscripts({ manifest: manifest(), scenes });
  const { videos, errors } = reviewLessonVideos(updated);

  assert.deepEqual(errors, []);
  assert.deepEqual(videos[0].transcript[0], {
    start_seconds: 4,
    end_seconds: 7,
    speaker_ja: '通行人',
    speaker_vi: 'Người đi đường',
    text_ja: 'この道をまっすぐ行ってください。',
    romaji: 'Kono michi o massugu itte kudasai.',
    text_vi: 'Bạn cứ đi thẳng đường này.',
  });
});

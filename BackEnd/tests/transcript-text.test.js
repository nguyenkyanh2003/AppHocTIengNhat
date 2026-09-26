import assert from 'node:assert/strict';
import test from 'node:test';

import { reviewLessonVideos } from '../src/modules/lessons/lesson-video.review.js';
import { applyTranscripts, parseTranscriptText } from '../scripts/transcript-text.js';

// Câu mẫu tự soạn cho test, không lấy từ video nào.
const TEXT = `# Lời thoại bài 9 — gõ trong lúc xem video
## scene-1.mp4
00:04-00:07 | 通行人 / Tsuukoonin / Người đi đường | この道をまっすぐ行ってください。 | Kono michi o massugu itte kudasai. | Bạn cứ đi thẳng đường này.
*00:08      | 客 / Khách                            | 駅はどこですか。                 | Eki wa doko desu ka.               | Nhà ga ở đâu ạ?
00:11       |                                       | はい。                           |                                    | Vâng.
### từ vựng
道 | みち | michi | con đường
駅 | えき | eki | nhà ga

## scene-2.mp4
00:02 | オウ / Ou | すみません。 | Sumimasen. | Xin lỗi.
`;

test('đọc được file lời thoại: tách cảnh, mốc thời gian, người nói ba dạng, ba lớp chữ', () => {
  const { scenes, errors } = parseTranscriptText(TEXT);

  assert.deepEqual(errors, []);
  assert.deepEqual([...scenes.keys()], ['scene-1.mp4', 'scene-2.mp4']);
  assert.deepEqual(scenes.get('scene-1.mp4').lines[0], {
    start: '00:04',
    end: '00:07',
    speaker_ja: '通行人',
    speaker_romaji: 'Tsuukoonin',
    speaker_vi: 'Người đi đường',
    text_ja: 'この道をまっすぐ行ってください。',
    romaji: 'Kono michi o massugu itte kudasai.',
    text_vi: 'Bạn cứ đi thẳng đường này.',
    key_phrase: false,
  });
});

test('người nói hai dạng là tiếng Nhật / tiếng Việt; ô trống là không có', () => {
  const { scenes } = parseTranscriptText(TEXT);
  const [, second, third] = scenes.get('scene-1.mp4').lines;

  assert.equal(second.speaker_ja, '客');
  assert.equal(second.speaker_romaji, null);
  assert.equal(second.speaker_vi, 'Khách');
  assert.equal('end' in third, false);
  assert.equal(third.speaker_ja, null);
  assert.equal(third.romaji, null);
});

test('dấu * trước mốc thời gian đánh dấu câu then chốt', () => {
  const { scenes } = parseTranscriptText(TEXT);
  assert.deepEqual(scenes.get('scene-1.mp4').lines.map((line) => line.key_phrase), [false, true, false]);
  assert.equal(scenes.get('scene-1.mp4').lines[1].start, '00:08');
});

test('sau "### từ vựng" mỗi dòng là một từ, thuộc đúng cảnh đang mở', () => {
  const { scenes } = parseTranscriptText(TEXT);
  assert.deepEqual(scenes.get('scene-1.mp4').vocabulary, [
    { word: '道', reading: 'みち', romaji: 'michi', meaning: 'con đường' },
    { word: '駅', reading: 'えき', romaji: 'eki', meaning: 'nhà ga' },
  ]);
  assert.deepEqual(scenes.get('scene-2.mp4').vocabulary, [], 'cảnh mới mở thì quay lại đọc câu thoại');
  assert.equal(scenes.get('scene-2.mp4').lines.length, 1);
});

test('mọi lỗi gõ đều chỉ đúng số dòng', () => {
  const { errors } = parseTranscriptText(
    [
      '00:01 | | Câu lạc chỗ. | | Chưa có tên cảnh.', // dòng 1
      '## scene-1.mp4', // 2
      '00:02 | | あ。 | | Đủ năm ô.', // 3 — hợp lệ
      '00:03 | | い。 | Thiếu nghĩa tiếng Việt |', // 4
      'xx:yy | | う。 | | Mốc sai.', // 5
      '00:20-00:10 | | え。 | | Kết thúc trước bắt đầu.', // 6
      '00:04 | | | | Thiếu tiếng Nhật.', // 7
      '00:05 | Thiếu ô cuối', // 8
      '### từ vựng', // 9
      '道 | みち | michi', // 10 — thiếu ô
      ' | | | nghĩa', // 11 — thiếu mặt chữ
      '## scene-1.mp4', // 12
    ].join('\n'),
  );

  assert.match(errors[0], /^Dòng 1: câu thoại nằm trước dòng "## /);
  assert.match(errors[1], /^Dòng 4: thiếu nghĩa tiếng Việt/);
  assert.match(errors[2], /^Dòng 5: mốc thời gian "xx:yy"/);
  assert.match(errors[3], /^Dòng 6: mốc kết thúc "00:10" trước mốc bắt đầu/);
  assert.match(errors[4], /^Dòng 7: thiếu câu tiếng Nhật/);
  assert.match(errors[5], /^Dòng 8: cần đúng 5 ô/);
  assert.match(errors[6], /^Dòng 10: từ vựng cần 4 ô/);
  assert.match(errors[7], /^Dòng 11: từ vựng thiếu mặt chữ/);
  assert.match(errors[8], /^Dòng 12: "scene-1.mp4" đã có phần lời thoại ở trên/);
  assert.equal(errors.length, 9);
});

const manifest = () => ({
  lesson: { title: 'Tình huống: Hỏi đường' },
  videos: [
    { title: 'Cảnh 1', url: '/uploads/lesson-videos/n5-09-directions/scene-1.mp4', transcript: [] },
    { title: 'Cảnh 2', url: '/uploads/lesson-videos/n5-09-directions/scene-2.mp4', transcript: [] },
    { title: 'Ôn tập', url: '/uploads/lesson-videos/n5-09-directions/summary.mp4', transcript: [] },
  ],
});

test('ghi lời thoại và từ vựng vào đúng cảnh, cảnh chưa gõ giữ nguyên', () => {
  const { scenes } = parseTranscriptText(TEXT);
  const { manifest: updated, applied, errors } = applyTranscripts({ manifest: manifest(), scenes });

  assert.deepEqual(errors, []);
  assert.deepEqual(applied, [
    { name: 'scene-1.mp4', count: 3, words: 2 },
    { name: 'scene-2.mp4', count: 1, words: 0 },
  ]);
  assert.equal(updated.videos[0].transcript.length, 3);
  assert.equal(updated.videos[0].vocabulary.length, 2);
  assert.equal('vocabulary' in updated.videos[1], false, 'cảnh chưa có bảng từ không bị ghi mảng rỗng');
  assert.deepEqual(updated.videos[2].transcript, [], 'cảnh chưa gõ lời thoại không bị đụng tới');
  assert.equal(updated.videos[0].title, 'Cảnh 1', 'chỉ thay nội dung, không thay tên cảnh');
});

test('tiêu đề cảnh chưa gõ gì không xoá nội dung đã có', () => {
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

test('kết quả đi qua được bộ kiểm lúc nhập DB, giữ đủ người nói, câu then chốt và từ vựng', () => {
  const { scenes } = parseTranscriptText(TEXT);
  const { manifest: updated } = applyTranscripts({ manifest: manifest(), scenes });
  const { videos, errors } = reviewLessonVideos(updated);

  assert.deepEqual(errors, []);
  assert.deepEqual(videos[0].transcript[1], {
    start_seconds: 8,
    end_seconds: null,
    speaker_ja: '客',
    speaker_romaji: null,
    speaker_vi: 'Khách',
    text_ja: '駅はどこですか。',
    romaji: 'Eki wa doko desu ka.',
    text_vi: 'Nhà ga ở đâu ạ?',
    key_phrase: true,
  });
  assert.deepEqual(videos[0].vocabulary[0], { word: '道', reading: 'みち', romaji: 'michi', meaning: 'con đường' });
});

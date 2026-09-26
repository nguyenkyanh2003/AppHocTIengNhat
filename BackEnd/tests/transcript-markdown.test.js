import assert from 'node:assert/strict';
import test from 'node:test';

import { parseTranscriptMarkdown, spreadTimecodes } from '../scripts/transcript-markdown.js';

// Tài liệu mẫu tự soạn, cùng khuôn với tài liệu lời thoại thật.
const MARKDOWN = `# Lời thoại mẫu

## Bài 9 – Hỏi đường

### 9. Ôn tập · Ôn lại bài 9

| Thời gian | Người nói | Lời thoại |
|:---:|:---:|---|
| **00:00** | *Chủ đề* | **えきは どこですか** |
| | | eki wa doko desu ka |
| | | Nhà ga ở đâu ạ? |

### 9-1 · Hỏi nhà ga

| Thời gian | Người nói | Lời thoại |
|:---:|:---:|---|
| **00:03** | 客 | すみません。 |
| | Kyaku | Sumimasen. |
| | Khách | Xin lỗi. |
| **00:03** | 客 | 駅はどこですか。 |
| | Kyaku | Eki wa doko desu ka. |
| | Khách | Nhà ga ở đâu ạ? |
`;

test('đọc được bài, video và câu thoại ba lớp; tên người nói cũng ba dạng', () => {
  const { lessons, errors } = parseTranscriptMarkdown(MARKDOWN);

  assert.deepEqual(errors, []);
  assert.deepEqual([...lessons.keys()], [9]);
  assert.deepEqual([...lessons.get(9).keys()], ['summary.mp4', 'scene-1.mp4']);
  assert.deepEqual(lessons.get(9).get('scene-1.mp4')[1], {
    start: '00:03',
    speaker: { ja: '客', romaji: 'Kyaku', vi: 'Khách' },
    textJa: '駅はどこですか。',
    romaji: 'Eki wa doko desu ka.',
    textVi: 'Nhà ga ở đâu ạ?',
  });
});

test('thẻ chủ đề (người nói in nghiêng) là nhãn, chỉ đứng ở lớp tiếng Việt, bỏ chữ đậm', () => {
  const [card] = parseTranscriptMarkdown(MARKDOWN).lessons.get(9).get('summary.mp4');
  assert.deepEqual(card.speaker, { ja: null, romaji: null, vi: 'Chủ đề' });
  assert.equal(card.textJa, 'えきは どこですか');
});

test('hai câu cùng giây thì câu sau lùi nửa giây để câu trước vẫn được tô sáng', () => {
  const lines = parseTranscriptMarkdown(MARKDOWN).lessons.get(9).get('scene-1.mp4');
  assert.deepEqual(spreadTimecodes(lines), ['00:03', '00:03:15']);
});

test('câu thiếu hàng hay video lạc bài đều bị báo đúng dòng', () => {
  const { errors } = parseTranscriptMarkdown(
    [
      '## Bài 9 – Hỏi đường',
      '### 8-1 · Lạc bài', // dòng 2
      '### 9-1 · Thiếu hàng',
      '| **00:01** | 客 | あ。 |', // dòng 4
      '| | Kyaku | A. |',
      '| **00:02** | 客 | い。 |',
      '| | Kyaku | I. |',
      '| | Khách | I. |',
    ].join('\n'),
  );

  assert.match(errors[0], /^Dòng 2: video "### 8-1/);
  assert.match(errors[1], /^Dòng 4: câu lúc 00:01 có 2 hàng/);
  assert.equal(errors.length, 2);
});

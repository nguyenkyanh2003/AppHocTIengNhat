import { normalizeJapanese, normalizeVietnamese, reviewRows } from './vocabulary-import.review.js';
import { tagKey } from './vocabulary-tags.review.js';

/**
 * Sửa kho từ vựng theo một file đã soát tay (`data/vocabulary-fixes.json`).
 *
 * Các dòng công cụ nhập từ chối (ô có nhiều dạng viết, cách đọc lẫn chữ Hán,
 * gạch đầu dòng bị đọc thành chữ 一, nghĩa mới của một từ đã có...) không tự
 * sửa được: mỗi dòng cần một quyết định của người. File sửa ghi lại đúng quyết
 * định đó, kèm `source` trỏ về dòng gốc, và module này kiểm file rồi tính việc
 * cần ghi — hàm thuần, không đụng DB, giống `vocabulary-import.review.js`.
 *
 * Sáu loại sửa:
 * - `add`: thêm một từ chưa có. Chuẩn hoá bằng **đúng** luật của công cụ nhập,
 *   để khoá `(word, hiragana)` khớp với các từ đã nhập trước đó.
 * - `set-meaning`: thay nghĩa của một từ đã có, chỉ khi nghĩa trong DB đúng là
 *   nghĩa cũ đã soát (`from`) — ai đó sửa tay sau lúc soát thì không ghi đè.
 * - `rename`: sửa khoá của một từ đã có **tại chỗ**, giữ `_id` để tiến độ ôn
 *   tập và liên kết bài học bám theo.
 * - `remove`: xoá một bản sao không ai trỏ tới, chỉ khi bản giữ lại (`keep`)
 *   còn trong DB — không bao giờ xoá bản ghi cuối cùng của một từ. Script kiểm
 *   thêm rằng không có thẻ ôn, bài học hay sổ tay nào trỏ tới bản bị xoá.
 * - `merge`: như `remove` nhưng bản sao **đang được dùng** (bài học, tiến độ,
 *   thẻ ôn, sổ tay): chuyển mọi chỗ trỏ tới nó sang bản giữ lại (`into`) rồi mới
 *   xoá. Phần chạm DB nằm ở `vocabulary-merge.repository.js`.
 * - `skip`: dòng gốc không cần ghi gì (từ đã có); vẫn ghi lại lý do, và kiểm
 *   rằng từ được viện dẫn thật sự có trong DB.
 */

export const FIX_ACTIONS = Object.freeze(['add', 'set-meaning', 'rename', 'remove', 'merge', 'skip']);

const describe = ({ word, hiragana }) => `${word} (${hiragana})`;

const normalizeKey = (value) => ({
  word: normalizeJapanese(value?.word),
  hiragana: normalizeJapanese(value?.hiragana),
});

const requireKey = (key, label, messages) => {
  if (!key.word || !key.hiragana) messages.push(`Thiếu từ hoặc cách đọc ở ${label}.`);
};

/** Dòng thêm đi qua `reviewRows` của công cụ nhập, nên cùng luật chuẩn hoá và kiểm kana. */
const reviewAdd = (fix, messages) => {
  const { accepted, errors } = reviewRows([{
    TuVung: fix.word,
    Hiragana: fix.hiragana,
    NghiaTV: fix.meaning,
    HanViet: fix.hanviet,
    CapDo: fix.level,
    BaiHoc: fix.source_lesson,
  }]);
  errors.forEach((error) => messages.push(error.message));
  const row = accepted[0];
  if (!row) return null;
  if (!row.level) {
    messages.push('Thiếu cấp độ.');
    return null;
  }

  const added = {
    source: fix.source,
    action: 'add',
    word: row.word,
    hiragana: row.hiragana,
    meaning: row.meaning,
    level: row.level,
  };
  if (row.hanviet) added.hanviet = row.hanviet;
  if (row.lessonTitle) added.source_lesson = row.lessonTitle;
  if (row.verb_group) added.verb_group = row.verb_group;
  return added;
};

const reviewSetMeaning = (fix, messages) => {
  const key = normalizeKey(fix);
  requireKey(key, 'từ cần sửa nghĩa', messages);
  const from = normalizeVietnamese(fix.from);
  const to = normalizeVietnamese(fix.to);
  if (!from) messages.push('Thiếu nghĩa cũ (`from`) để đối chiếu.');
  if (!to) messages.push('Thiếu nghĩa mới (`to`).');
  if (from && from === to) messages.push('Nghĩa mới giống hệt nghĩa cũ.');
  return { source: fix.source, action: 'set-meaning', ...key, from, to };
};

const reviewRename = (fix, messages) => {
  const from = normalizeKey(fix.from);
  const to = normalizeKey(fix.to);
  requireKey(from, '`from`', messages);
  requireKey(to, '`to`', messages);
  if (from.word && tagKey(from) === tagKey(to)) messages.push('Khoá mới giống hệt khoá cũ.');
  return { source: fix.source, action: 'rename', from, to };
};

/**
 * Dòng bỏ một bản sao (`remove`, `merge`): khoá bản sao, nghĩa hiện tại để đối
 * chiếu trước khi xoá, khoá bản giữ lại ở trường `targetField` và lý do.
 */
const reviewDuplicate = (targetField) => (fix, messages) => {
  const key = normalizeKey(fix);
  const target = normalizeKey(fix[targetField]);
  requireKey(key, 'bản sao', messages);
  requireKey(target, `\`${targetField}\` (bản giữ lại)`, messages);
  if (key.word && tagKey(key) === tagKey(target)) messages.push('Bản giữ lại không được là chính bản sao.');
  const meaning = normalizeVietnamese(fix.meaning);
  if (!meaning) messages.push('Thiếu nghĩa hiện tại (`meaning`) để đối chiếu trước khi xoá.');
  const reason = normalizeVietnamese(fix.reason);
  if (!reason) messages.push('Bỏ bản sao phải ghi lý do.');
  return { source: fix.source, action: fix.action, ...key, meaning, [targetField]: target, reason };
};

const reviewSkip = (fix, messages) => {
  const key = normalizeKey(fix);
  requireKey(key, 'từ đã có', messages);
  const reason = normalizeVietnamese(fix.reason);
  if (!reason) messages.push('Bỏ qua phải ghi lý do.');
  return { source: fix.source, action: 'skip', ...key, reason };
};

const REVIEWERS = Object.freeze({
  add: reviewAdd,
  'set-meaning': reviewSetMeaning,
  rename: reviewRename,
  remove: reviewDuplicate('keep'),
  merge: reviewDuplicate('into'),
  skip: reviewSkip,
});

/**
 * Khoá mà một dòng sửa **tạo ra hoặc đụng tới**, để bắt hai dòng giẫm lên
 * nhau. Kế hoạch được tính trên ảnh chụp DB trước khi ghi, nên hai dòng cùng
 * khoá sẽ cho kết quả phụ thuộc thứ tự — chặn ngay từ file.
 */
const keysOf = (fix) => {
  if (fix.action === 'rename') return [fix.from, fix.to];
  return [fix];
};

/**
 * Hai dòng được cùng chạm một khoá khi không dòng nào làm từ đó đổi khoá, biến
 * mất hay mới xuất hiện: `skip` chỉ khẳng định từ đang có, nên đi cùng `skip`
 * khác (nhiều dòng gốc trùng một từ) hay `set-meaning` (nghĩa đổi, từ vẫn đó).
 */
const canShareKey = (first, second) => {
  const actions = [first.action, second.action];
  return actions.includes('skip') && actions.every((action) => action === 'skip' || action === 'set-meaning');
};

/**
 * Kiểm cả file, trả `{ accepted, errors }`. **Không ném**: báo đủ mọi dòng sai
 * kèm `source`, để người sửa file biết sửa dòng nào.
 */
export const reviewFixes = (fixes) => {
  if (!Array.isArray(fixes)) {
    return { accepted: [], errors: [{ index: -1, source: null, messages: ['File sửa phải là một mảng JSON.'] }] };
  }

  const accepted = [];
  const errors = [];
  const claimed = new Map();

  fixes.forEach((fix, index) => {
    const messages = [];
    const source = typeof fix?.source === 'string' ? fix.source.trim() : '';
    if (!source) messages.push('Thiếu `source` (dòng gốc hoặc lý do sửa).');

    const review = REVIEWERS[fix?.action];
    if (!review) {
      messages.push(`Loại sửa không hợp lệ: ${fix?.action}. Chỉ nhận ${FIX_ACTIONS.join(', ')}.`);
    }
    const normalized = review ? review({ ...fix, source }, messages) : null;

    if (normalized && messages.length === 0) {
      for (const key of keysOf(normalized)) {
        const owner = (claimed.get(tagKey(key)) ?? []).find((other) => !canShareKey(other, normalized));
        if (owner) messages.push(`Trùng khoá ${describe(key)} với dòng ${owner.source}.`);
      }
    }

    if (messages.length > 0) {
      errors.push({ index, source: source || null, messages });
      return;
    }
    keysOf(normalized).forEach((key) => {
      claimed.set(tagKey(key), [...(claimed.get(tagKey(key)) ?? []), normalized]);
    });
    accepted.push(normalized);
  });

  return { accepted, errors };
};

const planAdd = (fix, existing) => {
  const current = existing.get(tagKey(fix));
  if (current) {
    const same = current.meaning === fix.meaning && current.level === fix.level;
    return same
      ? { status: 'done' }
      : { status: 'conflict', detail: `Đã có ${describe(fix)} (${current.level}: ${current.meaning}).` };
  }
  const { source, action, ...document } = fix;
  return { status: 'apply', operation: { insertOne: { document } } };
};

const planSetMeaning = (fix, existing) => {
  const current = existing.get(tagKey(fix));
  if (!current) return { status: 'missing', detail: `Không có ${describe(fix)}.` };
  if (current.meaning === fix.to) return { status: 'done' };
  if (current.meaning !== fix.from) {
    return { status: 'conflict', detail: `Nghĩa hiện tại "${current.meaning}" khác nghĩa cũ đã soát "${fix.from}".` };
  }
  return {
    status: 'apply',
    operation: {
      updateOne: {
        filter: { _id: current._id, meaning: fix.from },
        update: { $set: { meaning: fix.to } },
      },
    },
  };
};

const planRename = (fix, existing) => {
  const current = existing.get(tagKey(fix.from));
  const target = existing.get(tagKey(fix.to));
  if (!current && target) return { status: 'done' };
  if (!current) return { status: 'missing', detail: `Không có ${describe(fix.from)}.` };
  if (target) return { status: 'conflict', detail: `${describe(fix.to)} đã là một từ khác.` };
  return {
    status: 'apply',
    operation: {
      updateOne: {
        filter: { _id: current._id, word: fix.from.word, hiragana: fix.from.hiragana },
        update: { $set: { word: fix.to.word, hiragana: fix.to.hiragana } },
      },
    },
  };
};

/** Trường trỏ tới bản giữ lại của từng loại bỏ bản sao. */
const TARGET_FIELD = Object.freeze({ remove: 'keep', merge: 'into' });

/**
 * Bỏ một bản sao (`remove`, `merge`). Bản giữ lại phải còn — không bao giờ xoá
 * bản ghi cuối cùng của một từ; bản sao đã mất thì coi như đã xong; nghĩa khác
 * lúc soát thì để người xem lại. Điều kiện xoá kèm nghĩa cũ, như `set-meaning`.
 */
const planDuplicate = (fix, existing) => {
  const targetKey = fix[TARGET_FIELD[fix.action]];
  const target = existing.get(tagKey(targetKey));
  if (!target) {
    return { status: 'missing', detail: `Bản giữ lại ${describe(targetKey)} không có — không xoá bản ghi cuối cùng của từ.` };
  }
  const current = existing.get(tagKey(fix));
  if (!current) return { status: 'done' };
  if (current.meaning !== fix.meaning) {
    return { status: 'conflict', detail: `Nghĩa hiện tại "${current.meaning}" khác lúc soát "${fix.meaning}".` };
  }

  const filter = { _id: current._id, word: fix.word, hiragana: fix.hiragana, meaning: fix.meaning };
  const operation = fix.action === 'merge'
    ? { merge: { fromId: current._id, intoId: target._id, lesson: current.lesson ?? null, filter } }
    : { deleteOne: { filter } };
  return { status: 'apply', operation };
};

const planSkip = (fix, existing) =>
  existing.has(tagKey(fix))
    ? { status: 'skip' }
    : { status: 'missing', detail: `Dòng bỏ qua viện dẫn ${describe(fix)} nhưng DB không có.` };

const PLANNERS = Object.freeze({
  add: planAdd,
  'set-meaning': planSetMeaning,
  rename: planRename,
  remove: planDuplicate,
  merge: planDuplicate,
  skip: planSkip,
});

/**
 * Tính việc cần ghi cho các dòng **đã qua `reviewFixes`**.
 *
 * @param existing Map khoá `tagKey` → bản ghi hiện có (`_id`, `word`,
 *   `hiragana`, `meaning`, `level`, `lesson`).
 * @returns `operations` — lệnh `bulkWrite` của Vocabulary, riêng gộp là
 *   `{ merge }` vì đụng nhiều collection — và `outcomes`, trạng thái từng dòng:
 *   `apply` (sẽ ghi), `done` (DB đã đúng, chạy lại không ghi gì), `skip`,
 *   `conflict` hay `missing` (DB khác lúc soát: người phải xem lại).
 */
export const planFixes = (fixes, existing) => {
  const operations = [];
  const outcomes = fixes.map((fix) => {
    const { operation, ...outcome } = PLANNERS[fix.action](fix, existing);
    if (operation) operations.push(operation);
    return { fix, ...outcome };
  });
  return { operations, outcomes };
};

/** Mọi khoá cần đọc từ DB để lập kế hoạch cho các dòng sửa (gồm cả bản giữ lại của dòng bỏ bản sao). */
export const keysToLoad = (fixes) =>
  fixes
    .flatMap((fix) => (TARGET_FIELD[fix.action] ? [fix, fix[TARGET_FIELD[fix.action]]] : keysOf(fix)))
    .map(({ word, hiragana }) => ({ word, hiragana }));

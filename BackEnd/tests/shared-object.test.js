import assert from 'node:assert/strict';
import test from 'node:test';

import { withoutUndefined } from '../src/shared/utils/object.js';

test('bỏ khoá mang `undefined`, giữ `null`, `0`, chuỗi rỗng và `false`', () => {
  assert.deepEqual(
    withoutUndefined({ status: undefined, type: 'bug', note: null, count: 0, search: '', active: false }),
    { type: 'bug', note: null, count: 0, search: '', active: false },
  );
});

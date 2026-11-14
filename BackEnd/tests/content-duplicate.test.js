import assert from 'node:assert/strict';
import test from 'node:test';

import { isDuplicateKeyError } from '../src/shared/db/duplicate-key.js';

const duplicateKey = () => Object.assign(new Error('E11000 duplicate key error'), { code: 11000 });

// --- nhận diện lỗi trùng -----------------------------------------------------

test('isDuplicateKeyError nhận E11000 ở cả lỗi gốc lẫn lỗi được bọc', () => {
  assert.equal(isDuplicateKeyError(duplicateKey()), true);
  assert.equal(isDuplicateKeyError(new Error('bọc', { cause: duplicateKey() })), true);
  assert.equal(isDuplicateKeyError(new Error('mất kết nối')), false);
  assert.equal(isDuplicateKeyError(undefined), false);
});

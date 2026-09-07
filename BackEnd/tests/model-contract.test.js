import assert from 'node:assert/strict';
import test from 'node:test';

import Report from '../model/Report.js';
import Transaction from '../model/Transaction.js';

test('transaction model matches the controller API contract', () => {
  assert.equal(Transaction.schema.path('user').options.required, true);
  assert.equal(Transaction.schema.path('amount').options.required, true);
  assert.deepEqual(Transaction.schema.path('status').enumValues, [
    'pending',
    'processing',
    'completed',
    'failed',
    'cancelled',
    'refunded',
  ]);
  assert.ok(Transaction.schema.path('payment_method'));
  assert.ok(Transaction.schema.path('package_id'));
});

test('report model matches user and admin workflows', () => {
  assert.equal(Report.schema.path('user_id').options.required, true);
  assert.equal(Report.schema.path('title').options.required, true);
  assert.equal(Report.schema.path('description').options.required, true);
  assert.deepEqual(Report.schema.path('status').enumValues, [
    'pending',
    'in_progress',
    'resolved',
    'rejected',
  ]);
  assert.ok(Report.schema.path('admin_response'));
  assert.ok(Report.schema.path('resolved_at'));
});

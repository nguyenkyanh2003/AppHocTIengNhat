import assert from 'node:assert/strict';
import test from 'node:test';
import { createUnitOfWork } from '../src/shared/db/unit-of-work.js';

const fake = () => {
  const events = [];
  const session = {
    startTransaction: () => events.push('begin'),
    commitTransaction: async () => events.push('commit'),
    abortTransaction: async () => events.push('abort'),
    endSession: async () => events.push('end'),
  };
  return { events, session, startSession: async () => session };
};
const labeled = (label) => Object.assign(new Error(label), { errorLabels: [label] });
test('transaction passes session, commits value, and always closes', async () => {
  const connection = fake();
  const value = await createUnitOfWork({ connection }).run(async ({ session }) => {
    assert.equal(session, connection.session);
    return 42;
  });
  assert.equal(value, 42);
  assert.deepEqual(connection.events, ['begin', 'commit', 'end']);
});
test('business errors abort without retry', async () => {
  const connection = fake();
  await assert.rejects(createUnitOfWork({ connection }).run(async () => { throw new Error('business'); }), /business/);
  assert.deepEqual(connection.events, ['begin', 'abort', 'end']);
});
test('transient callback retries are actually bounded', async () => {
  const connection = fake();
  let attempts = 0;
  await assert.rejects(createUnitOfWork({ connection, maxRetries: 3 }).run(async () => {
    attempts += 1;
    throw labeled('TransientTransactionError');
  }));
  assert.equal(attempts, 3);
  assert.equal(connection.events.at(-1), 'end');
});
test('unknown commit outcome retries commit only, never the business callback', async () => {
  const connection = fake();
  let commits = 0;
  let calls = 0;
  connection.session.commitTransaction = async () => {
    commits += 1;
    if (commits < 3) throw labeled('UnknownTransactionCommitResult');
  };
  await createUnitOfWork({ connection }).run(async () => { calls += 1; });
  assert.equal(calls, 1);
  assert.equal(commits, 3);
});
test('transient failure at commit replays the whole transaction, not just the commit', async () => {
  // Nhãn transient ném ra từ chính `commitTransaction` vẫn là lỗi transient:
  // khuôn retry của MongoDB đòi chạy lại **cả** transaction, vì phía server
  // transaction đó chưa hề xảy ra. Bản trước gọi commit ngoài khối catch của
  // `fn`, nên lỗi này thoát thẳng ra ngoài và request hỏng oan.
  const connection = fake();
  let commits = 0;
  let calls = 0;
  connection.session.commitTransaction = async () => {
    commits += 1;
    if (commits < 2) throw labeled('TransientTransactionError');
  };
  await createUnitOfWork({ connection }).run(async () => { calls += 1; });
  assert.equal(calls, 2);
  assert.equal(commits, 2);
});
test('a transaction replayed after a transient commit failure is aborted first', async () => {
  // Không abort trước khi startTransaction lần hai thì driver ném
  // "transaction already in progress" — lỗi thật sẽ bị che bởi lỗi này.
  const connection = fake();
  let commits = 0;
  connection.session.commitTransaction = async () => {
    connection.events.push('commit');
    commits += 1;
    if (commits < 2) throw labeled('TransientTransactionError');
  };
  await createUnitOfWork({ connection }).run(async () => {});
  assert.deepEqual(connection.events, ['begin', 'commit', 'abort', 'begin', 'commit', 'end']);
});
test('transient commit retries are bounded like callback retries', async () => {
  const connection = fake();
  let calls = 0;
  connection.session.commitTransaction = async () => { throw labeled('TransientTransactionError'); };
  await assert.rejects(createUnitOfWork({ connection, maxRetries: 3 }).run(async () => { calls += 1; }));
  assert.equal(calls, 3);
  assert.equal(connection.events.at(-1), 'end');
});
test('a failing abort does not replace the error that caused it', async () => {
  const connection = fake();
  connection.session.abortTransaction = async () => { throw new Error('connection lost'); };
  await assert.rejects(
    createUnitOfWork({ connection }).run(async () => { throw new Error('business'); }),
    /business/,
  );
});

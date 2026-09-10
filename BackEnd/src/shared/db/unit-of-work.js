import mongoose from 'mongoose';

/**
 * Gom nhiều lệnh ghi (vd. lịch ôn tập + hoạt động học) vào một transaction
 * MongoDB duy nhất, để service không phải tự quản vòng đời session.
 *
 * Driver MongoDB có hai kiểu lỗi transaction cần retry, và **không được lẫn
 * lộn** vì cách xử lý ngược nhau:
 *
 * - `TransientTransactionError`: cả transaction có thể thử lại an toàn từ
 *   đầu (vd. write conflict) — bản thân transaction chưa hề "xảy ra" ở phía
 *   server, nên chạy lại `fn` không tạo tác dụng phụ kép.
 * - `UnknownTransactionCommitResult`: chỉ riêng lệnh `commitTransaction` bị
 *   mất kết quả (vd. timeout/network drop ngay lúc commit) — transaction có
 *   thể đã áp dụng ở server hoặc chưa, driver không biết. Retry ở đây nghĩa
 *   là gọi lại `commitTransaction`, MongoDB tự đảm bảo an toàn khi commit
 *   trùng. Nếu chạy lại `fn` thay vì chỉ commit, một transaction đã thành
 *   công âm thầm bị nhân đôi tác dụng phụ (vd. ghi hai lần lịch ôn).
 */
const TRANSIENT_LABEL = 'TransientTransactionError';
const UNKNOWN_COMMIT_LABEL = 'UnknownTransactionCommitResult';

const hasLabel = (error, label) =>
  Array.isArray(error?.errorLabels) && error.errorLabels.includes(label);

/**
 * Commit với retry bị giới hạn, chỉ dành riêng cho `UnknownTransactionCommitResult`.
 * Không gọi lại `startTransaction`/`fn` — xem giải thích ở đầu file.
 */
const commitWithRetry = async (session, maxRetries) => {
  for (let attempt = 1; ; attempt += 1) {
    try {
      await session.commitTransaction();
      return;
    } catch (error) {
      if (!hasLabel(error, UNKNOWN_COMMIT_LABEL) || attempt >= maxRetries) throw error;
    }
  }
};

/**
 * Tạo một unit of work gắn với một mongoose connection cụ thể.
 *
 * `maxRetries` áp dụng độc lập cho hai vòng lặp: số lần chạy lại toàn bộ
 * transaction khi gặp `TransientTransactionError`, và số lần gọi lại
 * `commitTransaction` khi gặp `UnknownTransactionCommitResult`. Cả hai đều
 * phải có chặn trên — MongoDB không tự đảm bảo write conflict sẽ hết sau
 * hữu hạn lần, để vòng lặp không chặn có thể treo request mãi mãi.
 */
export const createUnitOfWork = ({ connection, maxRetries = 3 }) => ({
  async run(fn) {
    const session = await connection.startSession();
    try {
      for (let attempt = 1; ; attempt += 1) {
        session.startTransaction();
        let result;
        try {
          result = await fn({ session });
        } catch (error) {
          // fn ném lỗi: transaction chưa commit gì, an toàn để abort rồi thử
          // lại từ đầu — nhưng chỉ khi lỗi được MongoDB gắn nhãn transient và
          // vẫn còn lượt thử. Lỗi nghiệp vụ (không nhãn) luôn abort ngay,
          // không retry, để không lặp lại tác dụng phụ đã xảy ra trước lỗi.
          await session.abortTransaction();
          if (hasLabel(error, TRANSIENT_LABEL) && attempt < maxRetries) continue;
          throw error;
        }

        // fn chạy xong không lỗi: chỉ còn rủi ro ở chính lệnh commit, xử lý
        // bằng vòng retry riêng thay vì lặp lại khối for này.
        await commitWithRetry(session, maxRetries);
        return result;
      }
    } finally {
      // Đóng session dù thành công, lỗi hay hết lượt retry — driver giữ tài
      // nguyên phía server cho session còn mở, bỏ sót sẽ rò rỉ dần.
      await session.endSession();
    }
  },
});

/** Bản dựng sẵn dùng connection Mongoose mặc định của app. */
export const unitOfWork = createUnitOfWork({ connection: mongoose.connection });

export default unitOfWork;

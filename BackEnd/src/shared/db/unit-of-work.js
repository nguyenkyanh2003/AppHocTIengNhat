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
 * Abort mà không để lỗi của chính lệnh abort che mất lỗi gốc.
 *
 * Khi tới đây thì đã có một lỗi đáng báo cáo (lỗi nghiệp vụ, hoặc lỗi
 * transient ở commit). Nếu `abortTransaction` cũng hỏng — thường vì kết nối
 * đã đứt, đúng cái đã làm lệnh trước hỏng — thì ném lỗi abort ra ngoài sẽ
 * thay thế nguyên nhân thật bằng một triệu chứng phái sinh. Server tự dọn
 * transaction bỏ dở khi session hết hạn, nên nuốt lỗi ở đây không rò rỉ gì.
 */
const abortQuietly = async (session) => {
  try {
    await session.abortTransaction();
  } catch {
    // Cố ý bỏ qua: xem giải thích ở trên.
  }
};

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
 * transaction khi gặp `TransientTransactionError` (dù lỗi đó phát sinh trong
 * `fn` hay ở chính lệnh commit), và số lần gọi lại `commitTransaction` khi
 * gặp `UnknownTransactionCommitResult`. Cả hai đều phải có chặn trên — MongoDB không tự đảm bảo write conflict sẽ hết sau
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
          await abortQuietly(session);
          if (hasLabel(error, TRANSIENT_LABEL) && attempt < maxRetries) continue;
          throw error;
        }

        try {
          await commitWithRetry(session, maxRetries);
        } catch (error) {
          // `commitWithRetry` chỉ nuốt nhãn `UnknownTransactionCommitResult`;
          // mọi thứ khác rơi xuống đây. Nhãn transient phát sinh **ở chính
          // lệnh commit** (write conflict phát hiện lúc commit, bầu cử lại
          // primary) vẫn là lỗi transient theo đúng nghĩa: transaction chưa
          // được áp dụng ở server, nên phải chạy lại **cả** transaction —
          // chạy lại mỗi commit thì không có gì để commit nữa.
          //
          // Đây là chỗ bản trước sai: `commitWithRetry` nằm ngoài mọi khối
          // catch, nên lỗi transient ở commit thoát thẳng ra ngoài và request
          // hỏng dù lẽ ra chỉ cần thử lại. Bộ test cũ không bắt được vì chỉ
          // phủ nhánh `UnknownTransactionCommitResult`.
          await abortQuietly(session);
          if (hasLabel(error, TRANSIENT_LABEL) && attempt < maxRetries) continue;
          throw error;
        }

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

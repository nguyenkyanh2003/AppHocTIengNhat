import { ApiError } from '../../shared/http/api-error.js';

/**
 * Chính sách XP và mốc huy hiệu — nguồn **duy nhất** quyết định một hoạt động
 * đáng bao nhiêu XP và có tính là ngày học hay không.
 *
 * Tách khỏi `streak.service.js` vì đây là thứ thay đổi theo quyết định sản
 * phẩm (đổi số XP, thêm loại hoạt động) chứ không theo cơ chế ghi dữ liệu, và
 * vì mọi event ghi ra đều phải đóng dấu phiên bản chính sách đã dùng — muốn
 * đóng dấu được thì chính sách phải là một thứ có danh tính, không phải mấy
 * hằng số rải trong service.
 *
 * Lỗi cũ mà file này tồn tại để chặn: mỗi module tự chọn số XP, và
 * `POST /streak/add-xp` nhận thẳng `amount` từ client không trần. Ở đây không
 * có tham số nào của caller đi thẳng vào con số trả về — trừ hai ngoại lệ
 * được khai báo tường minh và kiểm chặt bên dưới (`exercise.submit` đọc cờ
 * chấm của server, `streak.milestone` đọc cấu hình Achievement của server).
 */

/**
 * Đóng dấu vào mọi `ActivityEvent` và vào tóm tắt `UserStreak`.
 *
 * Cần cho migration và cho việc đọc lại lịch sử: một event 5 XP ghi hôm nay
 * và một event 5 XP ghi sau lần đổi bảng giá không có ý nghĩa như nhau, và
 * không có cách nào phân biệt nếu không lưu phiên bản tại thời điểm ghi.
 */
export const POLICY_VERSION = 'streak-policy@2026-09-11';

/** Thang mốc streak duy nhất, dùng cho cả huy hiệu lẫn thông báo. */
export const STREAK_MILESTONES = Object.freeze([7, 14, 30, 50, 100, 365]);

/** Loại event dành cho phần thưởng mốc — không phải một hoạt động học. */
export const MILESTONE_REWARD_TYPE = 'streak.milestone';

/**
 * Trần XP cho một phần thưởng cấu hình được.
 *
 * Không phải luật nghiệp vụ mà là lưới an toàn: giá trị đi vào đây đến từ
 * bảng `Achievement` do admin nhập, và một lần gõ thừa số 0 ở đó không được
 * phép biến thành hàng triệu XP ghi vĩnh viễn vào lịch sử.
 */
const MAX_CONFIGURED_REWARD_XP = 100_000;

/**
 * Bảng XP, chép nguyên từ spec §3.4.
 *
 * `xp` là số cố định; `grade` (nếu có) là cặp giá trị chọn theo **kết quả
 * server đã chấm**. `study: false` cho hành động không phải học — chúng vẫn
 * có mặt trong bảng thay vì bị bỏ trống, để `xpFor('login')` trả 0 một cách
 * có chủ đích thay vì ném "loại không hợp lệ" và buộc caller phải nhớ danh
 * sách loại trừ ở chỗ khác.
 */
const TABLE = Object.freeze({
  'srs.review': { xp: 2, study: true },
  'lesson.progress': { xp: 2, study: true },
  'lesson.complete': { xp: 20, study: true },
  'jlpt.submit': { xp: 20, study: true },
  'exercise.submit': { grade: { passed: 10, failed: 5 }, study: true },

  // Spec §3.4 dòng cuối: 0 XP và không tạo event học. Bỏ thưởng mở bài 3 XP
  // và login 10 XP từ cutover — hai khoản này là lý do chính khiến chuỗi cũ
  // nối được chỉ bằng việc đăng nhập.
  login: { xp: 0, study: false },
  'lesson.open': { xp: 0, study: false },
  'vocabulary.mark': { xp: 0, study: false },
  'srs.reset': { xp: 0, study: false },
  'srs.delete': { xp: 0, study: false },
  'srs.skip': { xp: 0, study: false },

  // Event thưởng: không tính ngày học, không tăng XP mục tiêu ngày, và tuyệt
  // đối không gọi ngược lại `recordActivity` (spec §3.4).
  [MILESTONE_REWARD_TYPE]: { configured: true, study: false },
});

/**
 * Danh sách loại hoạt động hợp lệ, đóng — thêm loại mới phải sửa `TABLE`.
 *
 * Là mảng đóng băng chứ không phải `Set`: `Object.freeze` trên một `Set`
 * không chặn được `add()` (phương thức đó ghi vào slot nội bộ, không phải
 * vào thuộc tính), nên một "tập hợp đóng băng" chỉ là cảm giác an toàn giả.
 */
export const ACTIVITY_TYPES = Object.freeze(Object.keys(TABLE));

/** Loại này có nằm trong bảng chính sách không (không ném lỗi). */
export const isActivityType = (type) => Object.hasOwn(TABLE, type);

const ruleFor = (type) => {
  const rule = TABLE[type];
  if (!rule) {
    throw ApiError.badRequest('Loại hoạt động không hợp lệ.', {
      code: 'UNKNOWN_ACTIVITY_TYPE',
      details: { type },
    });
  }
  return rule;
};

const configuredRewardXp = (outcome) => {
  const value = outcome?.configuredXp;
  // Không cấu hình thưởng cho mốc này: vẫn ghi event (để không cấp lại lần
  // sau) nhưng không cộng XP.
  if (value === undefined || value === null) return 0;

  const isSane =
    typeof value === 'number' &&
    Number.isSafeInteger(value) &&
    value >= 0 &&
    value <= MAX_CONFIGURED_REWARD_XP;
  if (!isSane) {
    throw ApiError.badRequest('Cấu hình XP thưởng không hợp lệ.', {
      code: 'INVALID_REWARD_CONFIG',
    });
  }
  return value;
};

/**
 * XP của một hoạt động, tính từ **kết quả server đã chấm**.
 *
 * `outcome` chỉ được đọc ở đúng hai loại khai báo tường minh trong bảng; với
 * mọi loại khác nó bị bỏ qua hoàn toàn, nên một caller lỡ chuyển tiếp
 * `req.body` vào đây cũng không đổi được con số.
 *
 * `exercise.submit` không có `outcome` được tính là **chưa đạt** (5 XP) chứ
 * không phải đạt: thiếu kết quả chấm nghĩa là chưa chấm xong, và mặc định
 * rộng rãi ở đây là cách một bug im lặng biến thành XP phát thừa.
 */
export const xpFor = (type, outcome) => {
  const rule = ruleFor(type);
  if (rule.configured) return configuredRewardXp(outcome);
  if (rule.grade) return outcome?.passed === true ? rule.grade.passed : rule.grade.failed;
  return rule.xp;
};

/**
 * Hoạt động này có làm hôm nay thành một ngày học không.
 *
 * Tách khỏi `xpFor` vì hai câu hỏi khác nhau: một event 0 XP vẫn có thể là
 * ngày học (nếu sau này có loại như vậy), và một event có XP vẫn có thể
 * không phải ngày học (event thưởng mốc).
 */
export const countsAsStudy = (type) => ruleFor(type).study;

/**
 * Những mốc mà **chính lần ghi này** vừa vượt qua: `previous < m <= next`.
 *
 * Dùng khoảng mở-đóng thay vì so bằng (`m === next`) để một lần ghi nhảy
 * nhiều ngày — dữ liệu về trễ, hoặc migration dựng lại chuỗi — không đánh rơi
 * mốc ở giữa. Và dùng `previous` thay vì chỉ nhìn `next` để chuỗi đứt rồi học
 * lại không phát thưởng lần hai cho mốc đã qua.
 */
export const milestonesCrossed = (previousStreak, nextStreak) =>
  STREAK_MILESTONES.filter(
    (milestone) => milestone > previousStreak && milestone <= nextStreak,
  );

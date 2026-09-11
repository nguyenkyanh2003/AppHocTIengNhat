/**
 * Luật ngày và luật băng (freeze) của streak, viết dưới dạng hàm thuần.
 *
 * Không chạm DB và không đọc đồng hồ hệ thống (ngày "hôm nay" luôn được truyền
 * vào dưới dạng khoá `YYYY-MM-DD`), nên test chạy được mọi tình huống nghỉ dài
 * mà không phải chờ thời gian thật. Lỗi streak cũ nằm ở phép đổi múi giờ và
 * phép so ngày — gom hết về đây để hai thứ đó chỉ cần đúng một chỗ.
 */
export const STREAK_TIMEZONE = 'Asia/Ho_Chi_Minh';

/** Một băng bảo vệ đúng một ngày nghỉ; kho băng không bao giờ vượt quá số này. */
export const MAX_FREEZES = 2;

/**
 * Một `Intl.DateTimeFormat` cho mỗi múi giờ, dựng một lần rồi dùng lại.
 *
 * Dựng formatter là phần đắt nhất của `dayKey` (phải nạp dữ liệu ICU của múi
 * giờ), mà `dayKey` được gọi ở mọi lần ghi hoạt động. Số múi giờ dùng thật
 * trong app là hằng số (giờ Việt Nam, cộng `UTC` cho phép cộng ngày nội bộ),
 * nên cache không phình.
 *
 * `calendar: 'gregory'` và `numberingSystem: 'latn'` là bắt buộc chứ không
 * phải cho chắc: locale mặc định của máy chạy có thể là lịch phi-Gregory
 * (`ja-JP-u-ca-japanese` cho ra năm Lệnh Hoà 8) hoặc hệ số phi-Latin
 * (`ar-EG-u-nu-arab` cho ra `٢٠٢٦`), và khoá ngày lưu vào DB thì không được
 * đổi theo máy nào đang chạy.
 */
const dayFormatters = new Map();

const formatterFor = (timeZone) => {
  const cached = dayFormatters.get(timeZone);
  if (cached) return cached;

  const formatter = new Intl.DateTimeFormat('en-US', {
    timeZone,
    calendar: 'gregory',
    numberingSystem: 'latn',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
  dayFormatters.set(timeZone, formatter);
  return formatter;
};

/**
 * Khoá ngày dạng `YYYY-MM-DD` theo múi giờ chỉ định.
 *
 * Đọc `formatToParts()` rồi tự ghép, thay vì tin vào hình dạng chuỗi mà
 * `format()` trả về. Cách cũ (`format('en-CA')`) chạy đúng chỉ vì bản ICU
 * hiện tại tình cờ trả `YYYY-MM-DD` cho locale đó — thứ tự trường và dấu
 * phân cách là dữ liệu CLDR, có thể đổi giữa các bản Node mà không báo lỗi,
 * và khi đổi thì `dayKey` trả khoá sai **im lặng**. `parts` thì có hợp đồng
 * thật: mỗi phần tự khai `type` của nó.
 *
 * `formatter` mở ra ở tham số thứ ba để test bơm được một ICU giả; mã chạy
 * thật không bao giờ truyền tham số này.
 */
export const dayKey = (date, timeZone = STREAK_TIMEZONE, formatter = formatterFor(timeZone)) => {
  let year;
  let month;
  let day;

  for (const part of formatter.formatToParts(date)) {
    if (part.type === 'year') year = part.value;
    else if (part.type === 'month') month = part.value;
    else if (part.type === 'day') day = part.value;
  }

  // Thiếu phần nào nghĩa là formatter không được cấu hình để trả ngày đầy đủ.
  // Ném thay vì ghép ra `undefined-09-10`: khoá ngày hỏng mà vẫn ghi được vào
  // DB sẽ làm hỏng mọi phép so ngày về sau, và lỗi sẽ hiện ra ở chỗ khác.
  if (year === undefined || month === undefined || day === undefined) {
    throw new RangeError('Formatter không trả đủ year/month/day để dựng khoá ngày.');
  }

  return `${year.padStart(4, '0')}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
};

/**
 * Quy đổi khoá `YYYY-MM-DD` sang mốc UTC (ms), đồng thời xác thực đây là một
 * ngày có thật trên lịch.
 *
 * `Date.UTC` tự "tràn" ngày không tồn tại sang tháng sau (vd 30/2 → 2/3) thay
 * vì báo lỗi, nên phải tự dựng lại ngày từ mốc UTC rồi so khớp — lệch là ném
 * `RangeError` ngay, không để âm thầm tính sai số ngày nghỉ.
 */
const parseDayKey = (key) => {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(key);
  if (!match) {
    throw new RangeError(`Khoá ngày không đúng định dạng YYYY-MM-DD: ${key}`);
  }

  const [, yearStr, monthStr, dayStr] = match;
  const year = Number(yearStr);
  const month = Number(monthStr);
  const day = Number(dayStr);
  const utcMs = Date.UTC(year, month - 1, day);
  const roundTrip = new Date(utcMs);

  const isRealDate =
    roundTrip.getUTCFullYear() === year &&
    roundTrip.getUTCMonth() === month - 1 &&
    roundTrip.getUTCDate() === day;
  if (!isRealDate) {
    throw new RangeError(`Ngày không tồn tại trên lịch: ${key}`);
  }

  return utcMs;
};

/** Số ngày lịch giữa hai khoá ngày (âm nếu `toKey` đứng trước `fromKey`). */
export const daysBetween = (fromKey, toKey) => {
  const from = parseDayKey(fromKey);
  const to = parseDayKey(toKey);
  return Math.round((to - from) / 86_400_000);
};

/** Cộng thêm N ngày lịch vào một khoá ngày, trả về khoá ngày mới. */
const addDays = (key, amount) => {
  const [, yearStr, monthStr, dayStr] = /^(\d{4})-(\d{2})-(\d{2})$/.exec(key);
  const next = new Date(Date.UTC(Number(yearStr), Number(monthStr) - 1, Number(dayStr) + amount));
  // Đổi lại qua dayKey với múi giờ UTC để chắc chắn cùng định dạng, không lệ
  // thuộc múi giờ mặc định của môi trường chạy.
  return dayKey(next, 'UTC');
};

/**
 * Áp một lần hoạt động học lên trạng thái streak.
 *
 * Băng chỉ bị tiêu ở đây — tức là chỉ khi người học thật sự học, không phải
 * lúc chỉ mở app. Xem [projectStreak] cho đường đọc không tiêu băng.
 */
export const applyActivity = (state, todayKey) => {
  const {
    currentStreak = 0,
    longestStreak = 0,
    lastActivityDay = null,
    freezesAvailable = 0,
  } = state;

  // Học lần đầu: chưa có ngày mốc nào để so, chuỗi bắt đầu từ 1.
  if (!lastActivityDay) {
    return {
      currentStreak: 1,
      longestStreak: Math.max(longestStreak, 1),
      lastActivityDay: todayKey,
      freezesUsed: 0,
      frozenDays: [],
      isNewDay: true,
      broken: false,
    };
  }

  const gap = daysBetween(lastActivityDay, todayKey);

  // Học lại trong đúng ngày đã ghi nhận, hoặc dữ liệu trễ báo về một ngày đã
  // qua — không có ngày mới nào để tính, giữ nguyên trạng thái.
  if (gap <= 0) {
    return {
      currentStreak,
      longestStreak,
      lastActivityDay,
      freezesUsed: 0,
      frozenDays: [],
      isNewDay: false,
      broken: false,
    };
  }

  const missed = gap - 1; // Số ngày trống giữa lần học trước và hôm nay.
  // Băng che được tối đa bằng số băng đang có, dù cuối cùng có đủ cứu chuỗi
  // hay không — đây là những ngày sẽ được đánh dấu đã tiêu băng.
  const frozenDays = Array.from({ length: Math.min(missed, freezesAvailable) }, (_, index) =>
    addDays(lastActivityDay, index + 1),
  );

  if (missed > freezesAvailable) {
    // Không đủ băng che hết khoảng trống: dùng hết số băng đang có nhưng vẫn
    // không cứu được, chuỗi đứt và bắt đầu lại từ 1. Kỷ lục dài nhất không
    // đổi vì đó là chuyện đã xảy ra, không bị xoá bởi lần đứt chuỗi này.
    return {
      currentStreak: 1,
      longestStreak,
      lastActivityDay: todayKey,
      freezesUsed: freezesAvailable,
      frozenDays,
      isNewDay: true,
      broken: true,
    };
  }

  // Đủ băng che khoảng trống (kể cả khi không cần băng nào, missed === 0):
  // chuỗi tiếp tục, có thể lập kỷ lục mới.
  const next = currentStreak + 1;
  return {
    currentStreak: next,
    longestStreak: Math.max(longestStreak, next),
    lastActivityDay: todayKey,
    freezesUsed: missed,
    frozenDays,
    isNewDay: true,
    broken: false,
  };
};

/**
 * Trạng thái streak để **hiển thị**, không ghi gì và không tiêu băng.
 *
 * Đường đọc phải dùng hàm này thay vì `applyActivity`: nếu dùng nhầm
 * `applyActivity` thì chỉ mở ứng dụng sau một kỳ nghỉ là băng đã bị trừ, dù
 * người học chưa ôn thẻ nào trong ngày hôm đó.
 */
export const projectStreak = (state, todayKey) => {
  const { currentStreak = 0, lastActivityDay = null, freezesAvailable = 0 } = state;
  if (!lastActivityDay) return { currentStreak: 0, broken: false };

  const gap = daysBetween(lastActivityDay, todayKey);
  const missed = Math.max(0, gap - 1);
  if (missed === 0) return { currentStreak, broken: false };

  const covered = missed <= freezesAvailable;
  return {
    currentStreak: covered ? currentStreak : 0,
    broken: !covered,
  };
};

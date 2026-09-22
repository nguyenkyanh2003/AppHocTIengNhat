/**
 * Cách chia bộ từ vựng để học, thay cho một danh sách dài theo cấp độ.
 *
 * - N5, N4: chia theo **chủ đề** — từ cơ bản gắn với đời sống, gom theo chủ đề
 *   thì dễ hiểu và dễ nhớ (kiểu LingoDeer, Duolingo).
 * - N3, N2, N1: chia theo **từ loại** và **ba mức độ khó** — cách của
 *   Mimikara Oboeru. Ở cấp cao nhiều từ trừu tượng, ép vào chủ đề rất gượng.
 *
 * Không chia theo số bài giáo trình: người không học giáo trình đó sẽ không
 * hiểu "Bài 26" là gì, và app phải đứng độc lập được.
 *
 * Nhãn tiếng Việt nằm ở đây để backend trả kèm; thêm chủ đề mới chỉ là thêm
 * một dòng, không cần migration vì các field trên `Vocabulary` là optional.
 */

// Thứ tự trong object là thứ tự hiển thị.
export const TOPICS = Object.freeze({
  greet: 'Chào hỏi & giao tiếp',
  people: 'Con người & gia đình',
  body: 'Cơ thể & sức khoẻ',
  food: 'Ăn uống',
  home: 'Nhà cửa & đồ dùng',
  clothes: 'Quần áo & phụ kiện',
  school: 'Trường học & học tập',
  work: 'Công việc',
  shop: 'Mua sắm & tiền bạc',
  travel: 'Giao thông & địa điểm',
  time: 'Thời gian & lịch',
  number: 'Số đếm & đơn vị',
  nature: 'Thời tiết & thiên nhiên',
  hobby: 'Sở thích & giải trí',
  comm: 'Liên lạc & thông tin',
  country: 'Quốc gia & ngôn ngữ',
  society: 'Xã hội & sự kiện',
  action: 'Hoạt động hằng ngày',
  quality: 'Tính chất & trạng thái',
  feeling: 'Cảm xúc & suy nghĩ',
  function: 'Từ chỉ định & từ nối',
  // Tên riêng trong giáo trình nguồn (桜大学, 博多, ...) — không phải từ vựng
  // để học; giữ nhãn riêng để giao diện ẩn đi thay vì xoá dữ liệu.
  proper: 'Tên riêng',
});

export const WORD_TYPES = Object.freeze({
  n: 'Danh từ',
  v: 'Động từ',
  ai: 'Tính từ đuôi い',
  ana: 'Tính từ đuôi な',
  adv: 'Phó từ',
  conj: 'Liên từ',
  pron: 'Đại từ & từ chỉ định',
  particle: 'Trợ từ',
  counter: 'Trợ số từ',
  affix: 'Tiền tố & hậu tố',
  expr: 'Cụm từ & câu giao tiếp',
});

export const DIFFICULTIES = Object.freeze({
  1: 'Cơ bản',
  2: 'Trung bình',
  3: 'Nâng cao',
});

/** Cấp độ chia theo chủ đề; các cấp còn lại chia theo từ loại + độ khó. */
export const TOPIC_LEVELS = Object.freeze(['N5', 'N4']);

export const TOPIC_CODES = Object.freeze(Object.keys(TOPICS));
export const WORD_TYPE_CODES = Object.freeze(Object.keys(WORD_TYPES));
export const DIFFICULTY_VALUES = Object.freeze(Object.keys(DIFFICULTIES).map(Number));

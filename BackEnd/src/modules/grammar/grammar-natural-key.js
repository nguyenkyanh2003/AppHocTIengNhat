import Grammar from '../../../model/Grammar.js';

/**
 * Tạo ngữ pháp mới; nếu đúng khoá tự nhiên `(level, title)` đang có một bản
 * **đã xoá mềm** thì khôi phục bản đó với nội dung mới.
 *
 * Xoá ngữ pháp chỉ đặt `is_active = false`, nên bản ghi vẫn giữ khoá. Không có
 * nhánh khôi phục thì admin xoá một ngữ pháp rồi thêm lại đúng tên đó sẽ bị
 * chặn mãi, trong khi màn quản trị không có chỗ nào hiện lại bản đã xoá. Khôi
 * phục giữ nguyên `_id`, nên tiến độ học đang trỏ vào ngữ pháp này nối lại
 * đúng chỗ.
 *
 * Trùng với một bản **đang hoạt động** thì để unique index ném E11000 — caller
 * đổi nó thành 409.
 */
export const createOrReviveGrammar = async ({ data, model = Grammar }) => {
  const title = typeof data.title === 'string' ? data.title.trim() : data.title;
  // Bỏ trường không gửi: `$set` một giá trị `undefined` là ghi đè nội dung cũ
  // bằng khoảng trống.
  const fields = Object.fromEntries(
    Object.entries({ ...data, title }).filter(([, value]) => value !== undefined),
  );

  const revived = await model.findOneAndUpdate(
    { level: fields.level, title, is_active: false },
    { $set: { ...fields, is_active: true } },
    { new: true, runValidators: true },
  );
  if (revived) return { grammar: revived, revived: true };

  return { grammar: await model.create(fields), revived: false };
};

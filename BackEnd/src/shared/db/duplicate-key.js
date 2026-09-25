/**
 * Lỗi trùng khoá của MongoDB (E11000).
 *
 * Mongoose có lúc bọc lỗi driver trong `cause` (bulk write, transaction), nên
 * xét cả hai tầng. Nhận ra đúng lỗi này để trả 409 kèm lời giải thích, thay vì
 * để nó rơi xuống nhánh 500 "Lỗi máy chủ" kèm chuỗi lỗi thô của driver.
 */
export const isDuplicateKeyError = (error) =>
  error?.code === 11000 || error?.cause?.code === 11000;

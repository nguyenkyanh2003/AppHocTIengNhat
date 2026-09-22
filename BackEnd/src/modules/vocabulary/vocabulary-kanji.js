/**
 * Tách chữ Hán của một từ để màn chi tiết phân tích từng chữ.
 *
 * Nguồn dữ liệu theo thứ tự ưu tiên:
 * 1. Document `Kanji` của chữ đó (có âm Hán-Việt **và** nghĩa riêng).
 * 2. Âm Hán-Việt của cả từ, tách theo khoảng trắng: `学生` + "HỌC SINH" →
 *    学 = HỌC, 生 = SINH. Chỉ ghép khi số âm bằng số chữ Hán — "ĐOẠN/ĐOÁN
 *    TUYỆT" cho hai chữ thì ghép được, còn lệch số thì bỏ, vì ghép sai tệ hơn
 *    không ghép.
 *
 * Phần lớn từ chỉ có nguồn 2 (collection `Kanji` mới có vài chục chữ), nên
 * `meaning` thường là `null` — giao diện phải chịu được điều đó.
 */

// CJK Unified Ideographs + Extension A, cùng dấu lặp 々.
const KANJI = /[㐀-䶿一-鿿々]/u;

export const kanjiCharacters = (word) =>
  [...new Set([...(word ?? '')].filter((char) => KANJI.test(char) && char !== '々'))];

const splitHanviet = (hanviet) =>
  (hanviet ?? '').trim().split(/\s+/).filter(Boolean);

/**
 * @param {{ word: string, hanviet?: string }} vocabulary
 * @param {Array<{ _id, character, hanviet?, meaning? }>} kanjiDocs
 */
export const buildKanjiBreakdown = (vocabulary, kanjiDocs = []) => {
  const characters = [...(vocabulary.word ?? '')].filter(
    (char) => KANJI.test(char) && char !== '々',
  );
  if (characters.length === 0) return [];

  const byCharacter = new Map(kanjiDocs.map((doc) => [doc.character, doc]));
  const tokens = splitHanviet(vocabulary.hanviet);
  const aligned = tokens.length === characters.length;

  return characters.map((character, index) => {
    const doc = byCharacter.get(character);
    return {
      character,
      hanviet: doc?.hanviet || (aligned ? tokens[index] : null),
      meaning: doc?.meaning || null,
      kanjiId: doc?._id ?? null,
    };
  });
};

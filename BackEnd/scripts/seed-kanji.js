/**
 * Nạp 20 Kanji mẫu có âm Hán-Việt — upsert theo `character` (unique index),
 * không xoá gì. Xem `content-upsert.js` về lý do và cách xử lý xung đột.
 *
 * Không gán `lessonId`: bản cũ gán bài theo vòng `index % số bài`, tức gắn chữ
 * vào một bài ngẫu nhiên không liên quan. Liên kết bài học đi qua trang quản
 * trị hoặc `sync-lesson-relations.js`, và upsert không đụng liên kết đã có.
 *
 *   node scripts/seed-kanji.js --dry-run
 *   node scripts/seed-kanji.js [--overwrite]
 */
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Kanji from '../model/Kanji.js';
import { applyPlan, parseFlags, planUpserts, printPlan } from './content-upsert.js';

dotenv.config({ quiet: true });

// Dữ liệu mẫu 20 Kanji cơ bản
const kanjiData = [
  // N5 - 10 kanji
  {
    character: '学',
    hanviet: 'Học',
    onyomi: ['ガク', 'がく'],
    kunyomi: ['まな(ぶ)'],
    meaning: 'Học, học tập',
    level: 'N5',
    examples: [
      { word: '学生', hiragana: 'がくせい', meaning: 'Học sinh' },
      { word: '学校', hiragana: 'がっこう', meaning: 'Trường học' },
      { word: '大学', hiragana: 'だいがく', meaning: 'Đại học' },
    ]
  },
  {
    character: '日',
    hanviet: 'Nhật',
    onyomi: ['ニチ', 'ジツ'],
    kunyomi: ['ひ', 'か'],
    meaning: 'Mặt trời, ngày',
    level: 'N5',
    examples: [
      { word: '日本', hiragana: 'にほん', meaning: 'Nhật Bản' },
      { word: '毎日', hiragana: 'まいにち', meaning: 'Mỗi ngày' },
      { word: '今日', hiragana: 'きょう', meaning: 'Hôm nay' },
    ]
  },
  {
    character: '人',
    hanviet: 'Nhân',
    onyomi: ['ジン', 'ニン'],
    kunyomi: ['ひと'],
    meaning: 'Người',
    level: 'N5',
    examples: [
      { word: '日本人', hiragana: 'にほんじん', meaning: 'Người Nhật' },
      { word: '外国人', hiragana: 'がいこくじん', meaning: 'Người nước ngoài' },
      { word: '友人', hiragana: 'ゆうじん', meaning: 'Bạn bè' },
    ]
  },
  {
    character: '本',
    hanviet: 'Bản',
    onyomi: ['ホン'],
    kunyomi: ['もと'],
    meaning: 'Sách, gốc',
    level: 'N5',
    examples: [
      { word: '本', hiragana: 'ほん', meaning: 'Sách' },
      { word: '日本', hiragana: 'にほん', meaning: 'Nhật Bản' },
      { word: '本当', hiragana: 'ほんとう', meaning: 'Thật sự' },
    ]
  },
  {
    character: '山',
    hanviet: 'Sơn',
    onyomi: ['サン'],
    kunyomi: ['やま'],
    meaning: 'Núi',
    level: 'N5',
    examples: [
      { word: '山', hiragana: 'やま', meaning: 'Núi' },
      { word: '富士山', hiragana: 'ふじさん', meaning: 'Núi Phú Sĩ' },
      { word: '登山', hiragana: 'とざん', meaning: 'Leo núi' },
    ]
  },
  {
    character: '川',
    hanviet: 'Xuyên',
    onyomi: ['セン'],
    kunyomi: ['かわ'],
    meaning: 'Sông',
    level: 'N5',
    examples: [
      { word: '川', hiragana: 'かわ', meaning: 'Sông' },
      { word: '河川', hiragana: 'かせん', meaning: 'Sông ngòi' },
    ]
  },
  {
    character: '水',
    hanviet: 'Thủy',
    onyomi: ['スイ'],
    kunyomi: ['みず'],
    meaning: 'Nước',
    level: 'N5',
    examples: [
      { word: '水', hiragana: 'みず', meaning: 'Nước' },
      { word: '水曜日', hiragana: 'すいようび', meaning: 'Thứ tư' },
      { word: '飲み水', hiragana: 'のみみず', meaning: 'Nước uống' },
    ]
  },
  {
    character: '火',
    hanviet: 'Hỏa',
    onyomi: ['カ'],
    kunyomi: ['ひ'],
    meaning: 'Lửa',
    level: 'N5',
    examples: [
      { word: '火', hiragana: 'ひ', meaning: 'Lửa' },
      { word: '火曜日', hiragana: 'かようび', meaning: 'Thứ ba' },
      { word: '花火', hiragana: 'はなび', meaning: 'Pháo hoa' },
    ]
  },
  {
    character: '木',
    hanviet: 'Mộc',
    onyomi: ['モク', 'ボク'],
    kunyomi: ['き'],
    meaning: 'Cây, gỗ',
    level: 'N5',
    examples: [
      { word: '木', hiragana: 'き', meaning: 'Cây' },
      { word: '木曜日', hiragana: 'もくようび', meaning: 'Thứ năm' },
      { word: '大木', hiragana: 'たいぼく', meaning: 'Cây lớn' },
    ]
  },
  {
    character: '金',
    hanviet: 'Kim',
    onyomi: ['キン', 'コン'],
    kunyomi: ['かね'],
    meaning: 'Vàng, tiền',
    level: 'N5',
    examples: [
      { word: '金', hiragana: 'かね', meaning: 'Tiền' },
      { word: '金曜日', hiragana: 'きんようび', meaning: 'Thứ sáu' },
      { word: '料金', hiragana: 'りょうきん', meaning: 'Phí, giá' },
    ]
  },
  
  // N4 - 5 kanji
  {
    character: '食',
    hanviet: 'Thực',
    onyomi: ['ショク', 'ジキ'],
    kunyomi: ['た(べる)', 'く(う)'],
    meaning: 'Ăn, thức ăn',
    level: 'N4',
    examples: [
      { word: '食べる', hiragana: 'たべる', meaning: 'Ăn' },
      { word: '食事', hiragana: 'しょくじ', meaning: 'Bữa ăn' },
      { word: '夕食', hiragana: 'ゆうしょく', meaning: 'Bữa tối' },
    ]
  },
  {
    character: '飲',
    hanviet: 'Ẩm',
    onyomi: ['イン'],
    kunyomi: ['の(む)'],
    meaning: 'Uống',
    level: 'N4',
    examples: [
      { word: '飲む', hiragana: 'のむ', meaning: 'Uống' },
      { word: '飲み物', hiragana: 'のみもの', meaning: 'Đồ uống' },
      { word: '飲食', hiragana: 'いんしょく', meaning: 'Ăn uống' },
    ]
  },
  {
    character: '住',
    hanviet: 'Trụ',
    onyomi: ['ジュウ'],
    kunyomi: ['す(む)'],
    meaning: 'Sống, ở',
    level: 'N4',
    examples: [
      { word: '住む', hiragana: 'すむ', meaning: 'Sống' },
      { word: '住所', hiragana: 'じゅうしょ', meaning: 'Địa chỉ' },
      { word: '移住', hiragana: 'いじゅう', meaning: 'Di cư' },
    ]
  },
  {
    character: '働',
    hanviet: 'Động',
    onyomi: ['ドウ'],
    kunyomi: ['はたら(く)'],
    meaning: 'Làm việc',
    level: 'N4',
    examples: [
      { word: '働く', hiragana: 'はたらく', meaning: 'Làm việc' },
      { word: '労働', hiragana: 'ろうどう', meaning: 'Lao động' },
    ]
  },
  {
    character: '勉',
    hanviet: 'Miễn',
    onyomi: ['ベン'],
    kunyomi: [],
    meaning: 'Cố gắng, siêng năng',
    level: 'N4',
    examples: [
      { word: '勉強', hiragana: 'べんきょう', meaning: 'Học tập' },
      { word: '勤勉', hiragana: 'きんべん', meaning: 'Cần cù' },
    ]
  },

  // N3 - 3 kanji
  {
    character: '経',
    hanviet: 'Kinh',
    onyomi: ['ケイ', 'キョウ'],
    kunyomi: ['へ(る)'],
    meaning: 'Trải qua, kinh tế',
    level: 'N3',
    examples: [
      { word: '経験', hiragana: 'けいけん', meaning: 'Kinh nghiệm' },
      { word: '経済', hiragana: 'けいざい', meaning: 'Kinh tế' },
      { word: '経過', hiragana: 'けいか', meaning: 'Kinh qua' },
    ]
  },
  {
    character: '験',
    hanviet: 'Nghiệm',
    onyomi: ['ケン', 'ゲン'],
    kunyomi: [],
    meaning: 'Kiểm tra, thử nghiệm',
    level: 'N3',
    examples: [
      { word: '経験', hiragana: 'けいけん', meaning: 'Kinh nghiệm' },
      { word: '試験', hiragana: 'しけん', meaning: 'Kỳ thi' },
      { word: '実験', hiragana: 'じっけん', meaning: 'Thí nghiệm' },
    ]
  },
  {
    character: '情',
    hanviet: 'Tình',
    onyomi: ['ジョウ', 'セイ'],
    kunyomi: ['なさ(け)'],
    meaning: 'Tình cảm',
    level: 'N3',
    examples: [
      { word: '情報', hiragana: 'じょうほう', meaning: 'Thông tin' },
      { word: '感情', hiragana: 'かんじょう', meaning: 'Cảm xúc' },
      { word: '同情', hiragana: 'どうじょう', meaning: 'Đồng cảm' },
    ]
  },

  // N2 - 2 kanji
  {
    character: '環',
    hanviet: 'Hoàn',
    onyomi: ['カン'],
    kunyomi: [],
    meaning: 'Vòng, môi trường',
    level: 'N2',
    examples: [
      { word: '環境', hiragana: 'かんきょう', meaning: 'Môi trường' },
      { word: '循環', hiragana: 'じゅんかん', meaning: 'Tuần hoàn' },
    ]
  },
  {
    character: '境',
    hanviet: 'Cảnh',
    onyomi: ['キョウ', 'ケイ'],
    kunyomi: ['さかい'],
    meaning: 'Biên giới, cảnh',
    level: 'N2',
    examples: [
      { word: '環境', hiragana: 'かんきょう', meaning: 'Môi trường' },
      { word: '国境', hiragana: 'こっきょう', meaning: 'Biên giới' },
      { word: '境界', hiragana: 'きょうかい', meaning: 'Ranh giới' },
    ]
  },
];

const run = async () => {
  const flags = parseFlags();
  await mongoose.connect(process.env.MONGODB_URI, { dbName: process.env.DB_NAME || 'AppHocTiengNhat' });
  console.log(`✅ Đã kết nối MongoDB${flags.dryRun ? ' (--dry-run, không ghi)' : ''}`);

  try {
    const existing = await Kanji.find({ character: { $in: kanjiData.map((kanji) => kanji.character) } }).lean();
    const plan = planUpserts({ rows: kanjiData, existing, keyOf: (kanji) => kanji.character });
    if (!flags.dryRun) await applyPlan({ model: Kanji, plan, overwrite: flags.overwrite });
    printPlan('Kanji', plan, flags);
  } finally {
    await mongoose.connection.close();
  }
};

run().catch((error) => {
  console.error('❌ Lỗi:', error.message);
  process.exit(1);
});

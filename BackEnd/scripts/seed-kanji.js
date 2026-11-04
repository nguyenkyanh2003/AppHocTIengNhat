
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Kanji from '../model/Kanji.js';
import { applyPlan, parseFlags, planUpserts, printPlan } from './content-upsert.js';

dotenv.config({ quiet: true });

// Dữ liệu mẫu 40 Kanji cơ bản. 20 chữ cuối mảng được chọn để mỗi bài N5 có bước
// Chữ Hán; chạy `link-lesson-kanji.js` sau khi seed để gắn chữ vào bài.
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

  // Bước Chữ Hán của các bài N5 — 20 kanji. Mỗi chữ lấy từ chính từ vựng của bài
  // (ví dụ đầu tiên là từ trong bài), theo thứ tự bài.
  {
    character: '店',
    hanviet: 'Điếm',
    onyomi: ['テン'],
    kunyomi: ['みせ'],
    meaning: 'Cửa hàng, tiệm',
    level: 'N5',
    examples: [
      { word: '店員', hiragana: 'てんいん', meaning: 'Nhân viên cửa hàng' },
      { word: '店', hiragana: 'みせ', meaning: 'Cửa hàng' },
      { word: '喫茶店', hiragana: 'きっさてん', meaning: 'Quán cà phê' },
    ]
  },
  {
    character: '肉',
    hanviet: 'Nhục',
    onyomi: ['ニク'],
    kunyomi: [],
    meaning: 'Thịt',
    level: 'N4',
    examples: [
      { word: '肉', hiragana: 'にく', meaning: 'Thịt' },
      { word: '牛肉', hiragana: 'ぎゅうにく', meaning: 'Thịt bò' },
      { word: '豚肉', hiragana: 'ぶたにく', meaning: 'Thịt lợn' },
    ]
  },
  {
    character: '安',
    hanviet: 'An',
    onyomi: ['アン'],
    kunyomi: ['やす(い)'],
    meaning: 'Rẻ; yên ổn',
    level: 'N5',
    examples: [
      { word: '安い', hiragana: 'やすい', meaning: 'Rẻ' },
      { word: '安心', hiragana: 'あんしん', meaning: 'Yên tâm' },
      { word: '安全', hiragana: 'あんぜん', meaning: 'An toàn' },
    ]
  },
  {
    character: '高',
    hanviet: 'Cao',
    onyomi: ['コウ'],
    kunyomi: ['たか(い)'],
    meaning: 'Cao; đắt',
    level: 'N5',
    examples: [
      { word: '高い', hiragana: 'たかい', meaning: 'Đắt, cao' },
      { word: '高校', hiragana: 'こうこう', meaning: 'Trường cấp ba' },
      { word: '最高', hiragana: 'さいこう', meaning: 'Tuyệt nhất' },
    ]
  },
  {
    character: '動',
    hanviet: 'Động',
    onyomi: ['ドウ'],
    kunyomi: ['うご(く)'],
    meaning: 'Chuyển động, hoạt động',
    level: 'N4',
    examples: [
      { word: '運動靴', hiragana: 'うんどうぐつ', meaning: 'Giày thể thao' },
      { word: '動く', hiragana: 'うごく', meaning: 'Chuyển động, chạy (máy)' },
      { word: '自動', hiragana: 'じどう', meaning: 'Tự động' },
    ]
  },
  {
    character: '気',
    hanviet: 'Khí',
    onyomi: ['キ', 'ケ'],
    kunyomi: [],
    meaning: 'Khí, tinh thần, tâm trạng',
    level: 'N5',
    examples: [
      { word: '人気', hiragana: 'にんき', meaning: 'Được yêu thích' },
      { word: '天気', hiragana: 'てんき', meaning: 'Thời tiết' },
      { word: '元気', hiragana: 'げんき', meaning: 'Khỏe mạnh' },
    ]
  },
  {
    character: '白',
    hanviet: 'Bạch',
    onyomi: ['ハク'],
    kunyomi: ['しろ', 'しろ(い)'],
    meaning: 'Màu trắng',
    level: 'N5',
    examples: [
      { word: '白', hiragana: 'しろ', meaning: 'Màu trắng' },
      { word: '白い', hiragana: 'しろい', meaning: 'Trắng' },
      { word: '面白い', hiragana: 'おもしろい', meaning: 'Thú vị' },
    ]
  },
  {
    character: '大',
    hanviet: 'Đại',
    onyomi: ['ダイ', 'タイ'],
    kunyomi: ['おお(きい)'],
    meaning: 'To, lớn',
    level: 'N5',
    examples: [
      { word: '大きい', hiragana: 'おおきい', meaning: 'To, lớn' },
      { word: '大学', hiragana: 'だいがく', meaning: 'Đại học' },
      { word: '大人', hiragana: 'おとな', meaning: 'Người lớn' },
    ]
  },
  {
    character: '小',
    hanviet: 'Tiểu',
    onyomi: ['ショウ'],
    kunyomi: ['ちい(さい)', 'こ'],
    meaning: 'Nhỏ, bé',
    level: 'N5',
    examples: [
      { word: '小さい', hiragana: 'ちいさい', meaning: 'Nhỏ, bé' },
      { word: '小学校', hiragana: 'しょうがっこう', meaning: 'Trường tiểu học' },
      { word: '小銭', hiragana: 'こぜに', meaning: 'Tiền lẻ' },
    ]
  },
  {
    character: '手',
    hanviet: 'Thủ',
    onyomi: ['シュ'],
    kunyomi: ['て'],
    meaning: 'Tay',
    level: 'N5',
    examples: [
      { word: '切手', hiragana: 'きって', meaning: 'Tem' },
      { word: '手紙', hiragana: 'てがみ', meaning: 'Thư' },
      { word: '上手', hiragana: 'じょうず', meaning: 'Giỏi' },
    ]
  },
  {
    character: '電',
    hanviet: 'Điện',
    onyomi: ['デン'],
    kunyomi: [],
    meaning: 'Điện',
    level: 'N5',
    examples: [
      { word: '電車', hiragana: 'でんしゃ', meaning: 'Tàu điện' },
      { word: '電話', hiragana: 'でんわ', meaning: 'Điện thoại' },
      { word: '電気', hiragana: 'でんき', meaning: 'Điện, đèn điện' },
    ]
  },
  {
    character: '車',
    hanviet: 'Xa',
    onyomi: ['シャ'],
    kunyomi: ['くるま'],
    meaning: 'Xe',
    level: 'N5',
    examples: [
      { word: '電車', hiragana: 'でんしゃ', meaning: 'Tàu điện' },
      { word: '車', hiragana: 'くるま', meaning: 'Xe ô tô' },
      { word: '自転車', hiragana: 'じてんしゃ', meaning: 'Xe đạp' },
    ]
  },
  {
    character: '駅',
    hanviet: 'Dịch',
    onyomi: ['エキ'],
    kunyomi: [],
    meaning: 'Nhà ga',
    level: 'N5',
    examples: [
      { word: '駅', hiragana: 'えき', meaning: 'Nhà ga' },
      { word: '駅員', hiragana: 'えきいん', meaning: 'Nhân viên nhà ga' },
      { word: '東京駅', hiragana: 'とうきょうえき', meaning: 'Ga Tokyo' },
    ]
  },
  {
    character: '右',
    hanviet: 'Hữu',
    onyomi: ['ウ', 'ユウ'],
    kunyomi: ['みぎ'],
    meaning: 'Bên phải',
    level: 'N5',
    examples: [
      { word: '右', hiragana: 'みぎ', meaning: 'Bên phải' },
      { word: '右側', hiragana: 'みぎがわ', meaning: 'Phía bên phải' },
      { word: '左右', hiragana: 'さゆう', meaning: 'Trái phải' },
    ]
  },
  {
    character: '左',
    hanviet: 'Tả',
    onyomi: ['サ'],
    kunyomi: ['ひだり'],
    meaning: 'Bên trái',
    level: 'N5',
    examples: [
      { word: '左', hiragana: 'ひだり', meaning: 'Bên trái' },
      { word: '左側', hiragana: 'ひだりがわ', meaning: 'Phía bên trái' },
      { word: '左手', hiragana: 'ひだりて', meaning: 'Tay trái' },
    ]
  },
  {
    character: '月',
    hanviet: 'Nguyệt',
    onyomi: ['ゲツ', 'ガツ'],
    kunyomi: ['つき'],
    meaning: 'Mặt trăng, tháng',
    level: 'N5',
    examples: [
      { word: '毎月', hiragana: 'まいつき', meaning: 'Hàng tháng' },
      { word: '今月', hiragana: 'こんげつ', meaning: 'Tháng này' },
      { word: '月曜日', hiragana: 'げつようび', meaning: 'Thứ hai' },
    ]
  },
  {
    character: '分',
    hanviet: 'Phân',
    onyomi: ['ブン', 'フン', 'ブ'],
    kunyomi: ['わ(ける)', 'わ(かる)'],
    meaning: 'Chia; phút; hiểu',
    level: 'N5',
    examples: [
      { word: '分ける', hiragana: 'わける', meaning: 'Chia, phân loại' },
      { word: '分かる', hiragana: 'わかる', meaning: 'Hiểu' },
      { word: '五分', hiragana: 'ごふん', meaning: 'Năm phút' },
    ]
  },
  {
    character: '市',
    hanviet: 'Thị',
    onyomi: ['シ'],
    kunyomi: ['いち'],
    meaning: 'Thành phố; chợ',
    level: 'N4',
    examples: [
      { word: '市役所', hiragana: 'しやくしょ', meaning: 'Văn phòng hành chính thành phố' },
      { word: '市内', hiragana: 'しない', meaning: 'Trong thành phố' },
      { word: '市場', hiragana: 'いちば', meaning: 'Chợ' },
    ]
  },
  {
    character: '使',
    hanviet: 'Sử',
    onyomi: ['シ'],
    kunyomi: ['つか(う)'],
    meaning: 'Dùng, sử dụng',
    level: 'N4',
    examples: [
      { word: '使う', hiragana: 'つかう', meaning: 'Dùng, sử dụng' },
      { word: '使用中', hiragana: 'しようちゅう', meaning: 'Đang sử dụng' },
      { word: '大使館', hiragana: 'たいしかん', meaning: 'Đại sứ quán' },
    ]
  },
  {
    character: '入',
    hanviet: 'Nhập',
    onyomi: ['ニュウ'],
    kunyomi: ['い(れる)', 'はい(る)'],
    meaning: 'Vào, cho vào',
    level: 'N5',
    examples: [
      { word: '入れる', hiragana: 'いれる', meaning: 'Cho vào' },
      { word: '入る', hiragana: 'はいる', meaning: 'Đi vào' },
      { word: '入口', hiragana: 'いりぐち', meaning: 'Lối vào' },
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

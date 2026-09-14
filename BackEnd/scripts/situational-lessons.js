/**
 * Nội dung ba bài học theo tình huống, tổ chức giống cách Tsunagaru
 * (tsunagarujp.mext.go.jp) trình bày: mỗi bài là một cảnh đời sống, có mục tiêu
 * "làm được gì", một đoạn hội thoại của cảnh đó, và bảng từ vựng đi kèm.
 *
 * ⚠️ Nội dung tiếng Nhật ở đây do Claude soạn theo mẫu câu N5 phổ biến và
 * CHƯA được người biết tiếng Nhật rà soát. Phải rà lại trước khi dùng trong
 * bản bảo vệ hoặc demo chính thức.
 *
 * Dữ liệu thuần, không chạm DB — `seed-situational-lessons.js` lo phần ghi.
 */

export const SITUATIONAL_LESSONS = [
  {
    title: 'Tình huống: Đi siêu thị',
    level: 'N5',
    order: 1,
    situation: 'supermarket',
    type: 'Tình huống',
    description: 'Hỏi giá, hỏi vị trí hàng hoá và thanh toán ở siêu thị.',
    can_do_goals: [
      'Hỏi được giá của một món hàng',
      'Hỏi được món hàng nằm ở đâu trong siêu thị',
      'Trả lời được khi nhân viên hỏi có cần túi không',
    ],
    dialogue: [
      {
        speaker: 'Khách',
        text_ja: 'すみません、牛乳はどこですか。',
        reading: 'すみません、ぎゅうにゅうはどこですか。',
        text_vi: 'Xin lỗi, sữa tươi ở đâu ạ?',
      },
      {
        speaker: 'Nhân viên',
        text_ja: 'あちらの右のたなです。',
        reading: 'あちらのみぎのたなです。',
        text_vi: 'Ở kệ bên phải đằng kia ạ.',
      },
      {
        speaker: 'Khách',
        text_ja: 'ありがとうございます。これはいくらですか。',
        reading: 'ありがとうございます。これはいくらですか。',
        text_vi: 'Cảm ơn chị. Cái này bao nhiêu tiền ạ?',
      },
      {
        speaker: 'Nhân viên',
        text_ja: '２００円です。',
        reading: 'にひゃくえんです。',
        text_vi: '200 yên ạ.',
      },
      {
        speaker: 'Nhân viên',
        text_ja: 'ふくろはいりますか。',
        reading: 'ふくろはいりますか。',
        text_vi: 'Anh/chị có cần túi không ạ?',
      },
      {
        speaker: 'Khách',
        text_ja: 'いいえ、けっこうです。',
        reading: 'いいえ、けっこうです。',
        text_vi: 'Không, không cần đâu ạ.',
      },
      {
        speaker: 'Nhân viên',
        text_ja: 'ありがとうございました。',
        reading: 'ありがとうございました。',
        text_vi: 'Xin cảm ơn quý khách.',
      },
    ],
    vocabularies: [
      { word: '牛乳', hiragana: 'ぎゅうにゅう', meaning: 'sữa tươi' },
      { word: '店員', hiragana: 'てんいん', meaning: 'nhân viên cửa hàng' },
      { word: '棚', hiragana: 'たな', meaning: 'kệ hàng' },
      { word: '袋', hiragana: 'ふくろ', meaning: 'túi đựng' },
      { word: '値段', hiragana: 'ねだん', meaning: 'giá cả' },
      { word: '会計', hiragana: 'かいけい', meaning: 'thanh toán, tính tiền' },
      { word: '野菜', hiragana: 'やさい', meaning: 'rau củ' },
      { word: '肉', hiragana: 'にく', meaning: 'thịt' },
      { word: '卵', hiragana: 'たまご', meaning: 'trứng' },
    ],
  },
  {
    title: 'Tình huống: Đi tàu',
    level: 'N5',
    order: 2,
    situation: 'train',
    type: 'Tình huống',
    description: 'Mua vé, hỏi đường ra ga và hỏi tàu đi đúng tuyến.',
    can_do_goals: [
      'Hỏi được tàu nào đi đến nơi mình muốn',
      'Hỏi được giá vé và mua vé',
      'Hỏi được tàu khởi hành ở sân ga số mấy',
    ],
    dialogue: [
      {
        speaker: 'Khách',
        text_ja: 'すみません、東京駅までいくらですか。',
        reading: 'すみません、とうきょうえきまでいくらですか。',
        text_vi: 'Xin lỗi, đến ga Tokyo hết bao nhiêu tiền ạ?',
      },
      {
        speaker: 'Nhân viên',
        text_ja: '４５０円です。',
        reading: 'よんひゃくごじゅうえんです。',
        text_vi: '450 yên ạ.',
      },
      {
        speaker: 'Khách',
        text_ja: 'きっぷを１まいください。',
        reading: 'きっぷをいちまいください。',
        text_vi: 'Cho tôi một vé ạ.',
      },
      {
        speaker: 'Khách',
        text_ja: 'この電車は東京駅に行きますか。',
        reading: 'このでんしゃはとうきょうえきにいきますか。',
        text_vi: 'Tàu này có đi ga Tokyo không ạ?',
      },
      {
        speaker: 'Nhân viên',
        text_ja: 'はい、行きます。３ばんせんです。',
        reading: 'はい、いきます。さんばんせんです。',
        text_vi: 'Có ạ. Sân ga số 3 ạ.',
      },
      {
        speaker: 'Khách',
        text_ja: 'わかりました。ありがとうございます。',
        reading: 'わかりました。ありがとうございます。',
        text_vi: 'Tôi hiểu rồi. Cảm ơn anh/chị.',
      },
    ],
    vocabularies: [
      { word: '電車', hiragana: 'でんしゃ', meaning: 'tàu điện' },
      { word: '駅', hiragana: 'えき', meaning: 'nhà ga' },
      { word: '切符', hiragana: 'きっぷ', meaning: 'vé' },
      { word: '改札', hiragana: 'かいさつ', meaning: 'cửa soát vé' },
      { word: '乗り換え', hiragana: 'のりかえ', meaning: 'chuyển tàu' },
      { word: '片道', hiragana: 'かたみち', meaning: 'một chiều' },
      { word: '往復', hiragana: 'おうふく', meaning: 'khứ hồi' },
      { word: '時刻表', hiragana: 'じこくひょう', meaning: 'bảng giờ tàu' },
    ],
  },
  {
    title: 'Tình huống: Ở nhà hàng',
    level: 'N5',
    order: 3,
    situation: 'restaurant',
    type: 'Tình huống',
    description: 'Gọi món, hỏi món ăn và thanh toán ở nhà hàng.',
    can_do_goals: [
      'Gọi được món mình muốn ăn',
      'Hỏi được món nào ngon hoặc món nào không cay',
      'Xin được hoá đơn khi ăn xong',
    ],
    dialogue: [
      {
        speaker: 'Nhân viên',
        text_ja: 'いらっしゃいませ。何名さまですか。',
        reading: 'いらっしゃいませ。なんめいさまですか。',
        text_vi: 'Kính chào quý khách. Quý khách đi mấy người ạ?',
      },
      {
        speaker: 'Khách',
        text_ja: '２人です。',
        reading: 'ふたりです。',
        text_vi: 'Hai người ạ.',
      },
      {
        speaker: 'Khách',
        text_ja: 'すみません、ちゅうもんをおねがいします。',
        reading: 'すみません、ちゅうもんをおねがいします。',
        text_vi: 'Xin lỗi, cho tôi gọi món ạ.',
      },
      {
        speaker: 'Khách',
        text_ja: 'ラーメンを１つとおちゃをください。',
        reading: 'ラーメンをひとつとおちゃをください。',
        text_vi: 'Cho tôi một tô ramen và trà ạ.',
      },
      {
        speaker: 'Nhân viên',
        text_ja: 'かしこまりました。少々おまちください。',
        reading: 'かしこまりました。しょうしょうおまちください。',
        text_vi: 'Vâng ạ. Quý khách vui lòng đợi một chút.',
      },
      {
        speaker: 'Khách',
        text_ja: 'すみません、おかいけいをおねがいします。',
        reading: 'すみません、おかいけいをおねがいします。',
        text_vi: 'Xin lỗi, cho tôi thanh toán ạ.',
      },
    ],
    vocabularies: [
      { word: '注文', hiragana: 'ちゅうもん', meaning: 'gọi món, đặt hàng' },
      { word: '料理', hiragana: 'りょうり', meaning: 'món ăn' },
      { word: '飲み物', hiragana: 'のみもの', meaning: 'đồ uống' },
      { word: 'お茶', hiragana: 'おちゃ', meaning: 'trà' },
      { word: '水', hiragana: 'みず', meaning: 'nước' },
      { word: '辛い', hiragana: 'からい', meaning: 'cay' },
      { word: '美味しい', hiragana: 'おいしい', meaning: 'ngon' },
      { word: '店', hiragana: 'みせ', meaning: 'quán, cửa hàng' },
      { word: '席', hiragana: 'せき', meaning: 'chỗ ngồi' },
    ],
  },
];

export default SITUATIONAL_LESSONS;

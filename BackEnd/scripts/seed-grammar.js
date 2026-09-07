import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Grammar from '../model/Grammar.js';

dotenv.config();

const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI;
    await mongoose.connect(mongoURI, {
      dbName: process.env.DB_NAME || 'AppHocTiengNhat'
    });
    console.log('✅ Kết nối MongoDB thành công!');
  } catch (error) {
    console.error('❌ Lỗi kết nối MongoDB:', error.message);
    process.exit(1);
  }
};

const grammars = [
  // N5 Grammar
  {
    title: 'です / だ',
    structure: 'Danh từ + です',
    meaning: 'Là... (khẳng định lịch sự)',
    usage: 'Dùng để khẳng định hoặc kết thúc câu một cách lịch sự',
    level: 'N5',
    examples: [
      { sentence: '私は学生です。', meaning: 'Tôi là học sinh.' },
      { sentence: 'これは本です。', meaning: 'Đây là quyển sách.' }
    ]
  },
  {
    title: 'は (wa)',
    structure: 'Danh từ + は + ...',
    meaning: 'Trợ từ chỉ chủ đề',
    usage: 'Đánh dấu chủ đề của câu',
    level: 'N5',
    examples: [
      { sentence: '私は田中です。', meaning: 'Tôi là Tanaka.' },
      { sentence: '日本は美しいです。', meaning: 'Nhật Bản thì đẹp.' }
    ]
  },
  {
    title: 'が (ga)',
    structure: 'Danh từ + が + ...',
    meaning: 'Trợ từ chỉ chủ ngữ',
    usage: 'Đánh dấu chủ ngữ của câu, nhấn mạnh',
    level: 'N5',
    examples: [
      { sentence: '誰が来ましたか。', meaning: 'Ai đã đến?' },
      { sentence: '水が欲しいです。', meaning: 'Tôi muốn nước.' }
    ]
  },
  {
    title: 'を (wo)',
    structure: 'Danh từ + を + Động từ',
    meaning: 'Trợ từ chỉ tân ngữ',
    usage: 'Đánh dấu đối tượng của hành động',
    level: 'N5',
    examples: [
      { sentence: 'りんごを食べます。', meaning: 'Tôi ăn táo.' },
      { sentence: '本を読みます。', meaning: 'Tôi đọc sách.' }
    ]
  },
  {
    title: 'に (ni)',
    structure: 'Danh từ + に',
    meaning: 'Trợ từ chỉ thời gian, địa điểm, đối tượng',
    usage: 'Chỉ thời điểm, địa điểm đến, người nhận',
    level: 'N5',
    examples: [
      { sentence: '7時に起きます。', meaning: 'Tôi dậy lúc 7 giờ.' },
      { sentence: '学校に行きます。', meaning: 'Tôi đi đến trường.' }
    ]
  },
  {
    title: 'で (de)',
    structure: 'Danh từ + で',
    meaning: 'Trợ từ chỉ phương tiện, địa điểm hành động',
    usage: 'Chỉ phương tiện, công cụ hoặc nơi diễn ra hành động',
    level: 'N5',
    examples: [
      { sentence: 'バスで行きます。', meaning: 'Tôi đi bằng xe buýt.' },
      { sentence: '図書館で勉強します。', meaning: 'Tôi học ở thư viện.' }
    ]
  },
  {
    title: 'ます / ません',
    structure: 'Động từ + ます / ません',
    meaning: 'Thể lịch sự khẳng định / phủ định',
    usage: 'Chia động từ ở thể lịch sự',
    level: 'N5',
    examples: [
      { sentence: '食べます。', meaning: 'Tôi ăn.' },
      { sentence: '食べません。', meaning: 'Tôi không ăn.' }
    ]
  },
  {
    title: 'ました / ませんでした',
    structure: 'Động từ + ました / ませんでした',
    meaning: 'Thể quá khứ lịch sự khẳng định / phủ định',
    usage: 'Diễn tả hành động đã xảy ra trong quá khứ',
    level: 'N5',
    examples: [
      { sentence: '昨日、映画を見ました。', meaning: 'Hôm qua tôi đã xem phim.' },
      { sentence: '行きませんでした。', meaning: 'Tôi đã không đi.' }
    ]
  },
  // N4 Grammar
  {
    title: 'てform + ください',
    structure: 'Động từ thể て + ください',
    meaning: 'Hãy... / Xin hãy...',
    usage: 'Yêu cầu ai đó làm gì một cách lịch sự',
    level: 'N4',
    examples: [
      { sentence: '待ってください。', meaning: 'Xin hãy đợi.' },
      { sentence: '見てください。', meaning: 'Hãy nhìn đây.' }
    ]
  },
  {
    title: 'てform + いる',
    structure: 'Động từ thể て + いる',
    meaning: 'Đang... / Trạng thái tiếp diễn',
    usage: 'Diễn tả hành động đang diễn ra hoặc trạng thái',
    level: 'N4',
    examples: [
      { sentence: '本を読んでいます。', meaning: 'Tôi đang đọc sách.' },
      { sentence: '結婚しています。', meaning: 'Tôi đã kết hôn (trạng thái).' }
    ]
  },
  {
    title: 'たい',
    structure: 'Động từ (bỏ ます) + たい',
    meaning: 'Muốn...',
    usage: 'Diễn tả mong muốn của người nói',
    level: 'N4',
    examples: [
      { sentence: '日本に行きたいです。', meaning: 'Tôi muốn đi Nhật.' },
      { sentence: '寿司を食べたい。', meaning: 'Tôi muốn ăn sushi.' }
    ]
  },
  {
    title: 'ないでください',
    structure: 'Động từ thể ない + でください',
    meaning: 'Xin đừng...',
    usage: 'Yêu cầu ai đó không làm gì',
    level: 'N4',
    examples: [
      { sentence: '触らないでください。', meaning: 'Xin đừng chạm vào.' },
      { sentence: '心配しないでください。', meaning: 'Xin đừng lo lắng.' }
    ]
  },
  {
    title: 'ことができる',
    structure: 'Động từ từ điển + ことができる',
    meaning: 'Có thể...',
    usage: 'Diễn tả khả năng',
    level: 'N4',
    examples: [
      { sentence: '日本語を話すことができます。', meaning: 'Tôi có thể nói tiếng Nhật.' },
      { sentence: '泳ぐことができません。', meaning: 'Tôi không biết bơi.' }
    ]
  },
  // N3 Grammar
  {
    title: 'ようにする',
    structure: 'Động từ từ điển + ようにする',
    meaning: 'Cố gắng để...',
    usage: 'Diễn tả nỗ lực để đạt được điều gì',
    level: 'N3',
    examples: [
      { sentence: '毎日運動するようにしています。', meaning: 'Tôi cố gắng tập thể dục mỗi ngày.' },
      { sentence: '早く寝るようにする。', meaning: 'Tôi sẽ cố đi ngủ sớm.' }
    ]
  },
  {
    title: 'ようになる',
    structure: 'Động từ từ điển + ようになる',
    meaning: 'Trở nên có thể...',
    usage: 'Diễn tả sự thay đổi khả năng',
    level: 'N3',
    examples: [
      { sentence: '日本語が話せるようになりました。', meaning: 'Tôi đã có thể nói tiếng Nhật.' },
      { sentence: '泳げるようになりたい。', meaning: 'Tôi muốn biết bơi.' }
    ]
  },
  {
    title: 'という',
    structure: 'A という B',
    meaning: 'B gọi là A / B tên là A',
    usage: 'Giới thiệu tên hoặc giải thích',
    level: 'N3',
    examples: [
      { sentence: 'さくらという名前です。', meaning: 'Tên là Sakura.' },
      { sentence: '東京という都市', meaning: 'Thành phố tên là Tokyo' }
    ]
  }
];

const seedGrammar = async () => {
  try {
    await connectDB();

    // Xóa dữ liệu cũ
    await Grammar.deleteMany({});
    console.log('🗑️ Đã xóa dữ liệu ngữ pháp cũ');

    // Thêm dữ liệu mới
    const result = await Grammar.insertMany(grammars);
    console.log(`✅ Đã thêm ${result.length} mục ngữ pháp!`);

    // Hiển thị thống kê
    const stats = await Grammar.aggregate([
      { $group: { _id: '$level', count: { $sum: 1 } } },
      { $sort: { _id: 1 } }
    ]);
    
    console.log('\n📊 Thống kê theo level:');
    stats.forEach(s => console.log(`   ${s._id}: ${s.count} mục`));

    process.exit(0);
  } catch (error) {
    console.error('❌ Lỗi:', error.message);
    process.exit(1);
  }
};

seedGrammar();

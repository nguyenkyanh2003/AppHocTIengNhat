import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Lesson from '../model/Lesson.js';

dotenv.config();

const sampleLessons = [
  {
    title: 'Bài 1: Chào hỏi cơ bản',
    level: 'N5',
    order: 1,
    description: 'Học cách chào hỏi và giới thiệu bản thân bằng tiếng Nhật',
    content_html: `
      <h2>Chào hỏi trong tiếng Nhật</h2>
      <p>Chào hỏi là phần quan trọng trong giao tiếp hàng ngày.</p>
      <ul>
        <li><strong>おはよう (ohayou)</strong> - Chào buổi sáng</li>
        <li><strong>こんにちは (konnichiwa)</strong> - Chào buổi chiều</li>
        <li><strong>こんばんは (konbanwa)</strong> - Chào buổi tối</li>
        <li><strong>さようなら (sayounara)</strong> - Tạm biệt</li>
      </ul>
    `,
    vocabularies: [],
    grammars: [],
    kanjis: []
  },
  {
    title: 'Bài 2: Số đếm từ 1-100',
    level: 'N5',
    order: 2,
    description: 'Học cách đếm số trong tiếng Nhật từ 1 đến 100',
    content_html: `
      <h2>Số đếm cơ bản</h2>
      <p>Học cách đếm số là nền tảng quan trọng.</p>
      <h3>Từ 1-10:</h3>
      <ul>
        <li>1 - いち (ichi)</li>
        <li>2 - に (ni)</li>
        <li>3 - さん (san)</li>
        <li>4 - し/よん (shi/yon)</li>
        <li>5 - ご (go)</li>
        <li>6 - ろく (roku)</li>
        <li>7 - しち/なな (shichi/nana)</li>
        <li>8 - はち (hachi)</li>
        <li>9 - きゅう (kyuu)</li>
        <li>10 - じゅう (juu)</li>
      </ul>
    `,
    vocabularies: [],
    grammars: [],
    kanjis: []
  },
  {
    title: 'Bài 3: Gia đình',
    level: 'N5',
    order: 3,
    description: 'Từ vựng về các thành viên trong gia đình',
    content_html: `
      <h2>Các thành viên gia đình</h2>
      <p>Học cách gọi các thành viên trong gia đình.</p>
      <ul>
        <li><strong>家族 (かぞく - kazoku)</strong> - Gia đình</li>
        <li><strong>父 (ちち - chichi)</strong> - Bố (của mình)</li>
        <li><strong>母 (はは - haha)</strong> - Mẹ (của mình)</li>
        <li><strong>兄 (あに - ani)</strong> - Anh trai (của mình)</li>
        <li><strong>姉 (あね - ane)</strong> - Chị gái (của mình)</li>
        <li><strong>弟 (おとうと - otouto)</strong> - Em trai</li>
        <li><strong>妹 (いもうと - imouto)</strong> - Em gái</li>
      </ul>
    `,
    vocabularies: [],
    grammars: [],
    kanjis: []
  },
  {
    title: 'Bài 4: Thời gian',
    level: 'N5',
    order: 4,
    description: 'Học cách nói giờ, ngày, tháng trong tiếng Nhật',
    content_html: `
      <h2>Biểu đạt thời gian</h2>
      <p>Cách nói thời gian trong tiếng Nhật.</p>
      <h3>Giờ:</h3>
      <ul>
        <li>〜時 (じ - ji) - Giờ</li>
        <li>〜分 (ふん - fun/pun) - Phút</li>
        <li>今 (いま - ima) - Bây giờ</li>
        <li>今日 (きょう - kyou) - Hôm nay</li>
        <li>昨日 (きのう - kinou) - Hôm qua</li>
        <li>明日 (あした - ashita) - Ngày mai</li>
      </ul>
    `,
    vocabularies: [],
    grammars: [],
    kanjis: []
  },
  {
    title: 'Bài 5: Động từ cơ bản - Nhóm I',
    level: 'N4',
    order: 1,
    description: 'Học các động từ nhóm I thường dùng và cách chia',
    content_html: `
      <h2>Động từ nhóm I (五段動詞)</h2>
      <p>Động từ nhóm I có âm cuối ở hàng う.</p>
      <h3>Một số động từ thường gặp:</h3>
      <ul>
        <li><strong>行く (いく - iku)</strong> - Đi</li>
        <li><strong>書く (かく - kaku)</strong> - Viết</li>
        <li><strong>聞く (きく - kiku)</strong> - Nghe</li>
        <li><strong>話す (はなす - hanasu)</strong> - Nói</li>
        <li><strong>読む (よむ - yomu)</strong> - Đọc</li>
        <li><strong>飲む (のむ - nomu)</strong> - Uống</li>
      </ul>
    `,
    vocabularies: [],
    grammars: [],
    kanjis: []
  },
  {
    title: 'Bài 6: Tính từ đuôi い',
    level: 'N4',
    order: 2,
    description: 'Học cách sử dụng tính từ đuôi い (い形容詞)',
    content_html: `
      <h2>Tính từ đuôi い (い形容詞)</h2>
      <p>Tính từ đuôi い được dùng để miêu tả tính chất, trạng thái.</p>
      <h3>Các tính từ thường dùng:</h3>
      <ul>
        <li><strong>大きい (おおきい - ookii)</strong> - To, lớn</li>
        <li><strong>小さい (ちいさい - chiisai)</strong> - Nhỏ</li>
        <li><strong>高い (たかい - takai)</strong> - Cao, đắt</li>
        <li><strong>安い (やすい - yasui)</strong> - Rẻ</li>
        <li><strong>新しい (あたらしい - atarashii)</strong> - Mới</li>
        <li><strong>古い (ふるい - furui)</strong> - Cũ</li>
      </ul>
    `,
    vocabularies: [],
    grammars: [],
    kanjis: []
  },
  {
    title: 'Bài 7: Thể て của động từ',
    level: 'N3',
    order: 1,
    description: 'Học cách chuyển động từ sang thể て và ứng dụng',
    content_html: `
      <h2>Thể て (て形)</h2>
      <p>Thể て được dùng để nối câu, yêu cầu, và nhiều mẫu ngữ pháp khác.</p>
      <h3>Cách chuyển:</h3>
      <ul>
        <li>う、つ、る → って (ex: 買う → 買って)</li>
        <li>む、ぶ、ぬ → んで (ex: 読む → 読んで)</li>
        <li>く → いて (ex: 書く → 書いて)</li>
        <li>ぐ → いで (ex: 泳ぐ → 泳いで)</li>
        <li>す → して (ex: 話す → 話して)</li>
      </ul>
    `,
    vocabularies: [],
    grammars: [],
    kanjis: []
  },
  {
    title: 'Bài 8: Thể た',
    level: 'N3',
    order: 2,
    description: 'Học cách sử dụng thể た để biểu đạt quá khứ',
    content_html: `
      <h2>Thể た (た形) - Thì quá khứ</h2>
      <p>Thể た được dùng để diễn tả hành động đã hoàn thành.</p>
      <h3>Cách chuyển từ thể て:</h3>
      <ul>
        <li>て → た (ex: 買って → 買った)</li>
        <li>で → だ (ex: 読んで → 読んだ)</li>
      </ul>
      <h3>Ví dụ:</h3>
      <p>昨日、本を読んだ。(Kinou, hon wo yonda) - Hôm qua tôi đã đọc sách.</p>
    `,
    vocabularies: [],
    grammars: [],
    kanjis: []
  },
  {
    title: 'Bài 9: Kính ngữ cơ bản',
    level: 'N2',
    order: 1,
    description: 'Học cách sử dụng kính ngữ trong giao tiếp',
    content_html: `
      <h2>Kính ngữ (敬語 - Keigo)</h2>
      <p>Kính ngữ được sử dụng để thể hiện sự tôn trọng.</p>
      <h3>3 loại kính ngữ:</h3>
      <ul>
        <li><strong>尊敬語 (そんけいご - Sonkeigo)</strong> - Kính ngữ tôn trọng</li>
        <li><strong>謙譲語 (けんじょうご - Kenjougo)</strong> - Kính ngữ khiêm tốn</li>
        <li><strong>丁寧語 (ていねいご - Teneigo)</strong> - Ngôn ngữ lịch sự</li>
      </ul>
    `,
    vocabularies: [],
    grammars: [],
    kanjis: []
  },
  {
    title: 'Bài 10: Câu điều kiện',
    level: 'N2',
    order: 2,
    description: 'Các mẫu câu điều kiện trong tiếng Nhật',
    content_html: `
      <h2>Câu điều kiện</h2>
      <p>Có 4 mẫu câu điều kiện chính trong tiếng Nhật.</p>
      <h3>Các mẫu:</h3>
      <ul>
        <li><strong>〜と</strong> - Điều kiện tự nhiên, luôn xảy ra</li>
        <li><strong>〜ば</strong> - Điều kiện giả định chung</li>
        <li><strong>〜たら</strong> - Điều kiện giả định sau khi hoàn thành</li>
        <li><strong>〜なら</strong> - Điều kiện dựa trên thông tin có sẵn</li>
      </ul>
    `,
    vocabularies: [],
    grammars: [],
    kanjis: []
  }
];

async function seedLessons() {
  try {
    // Kết nối MongoDB
    await mongoose.connect(process.env.MONGODB_URI, {
      dbName: process.env.DB_NAME || 'AppHocTiengNhat'
    });
    console.log('✅ Đã kết nối MongoDB');

    // Xóa dữ liệu cũ (tùy chọn)
    await Lesson.deleteMany({});
    console.log('🗑️  Đã xóa dữ liệu cũ');

    // Thêm dữ liệu mới
    const result = await Lesson.insertMany(sampleLessons);
    console.log(`✅ Đã thêm ${result.length} bài học mẫu`);

    // Hiển thị danh sách
    console.log('\n📚 Danh sách bài học:');
    result.forEach((lesson, index) => {
      console.log(`${index + 1}. ${lesson.title} (${lesson.level})`);
    });

    await mongoose.connection.close();
    console.log('\n✅ Hoàn thành!');
  } catch (error) {
    console.error('❌ Lỗi:', error);
    process.exit(1);
  }
}

seedLessons();

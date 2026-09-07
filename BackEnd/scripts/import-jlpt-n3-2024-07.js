/**
 * Script Import đề thi JLPT N3 tháng 7/2024
 * Chạy: node scripts/import-jlpt-n3-2024-07.js
 */

import mongoose from "mongoose";
import dotenv from "dotenv";
import JLPT from "../model/JLPT.js";

dotenv.config();

const mongoURI = process.env.MONGODB_URI;
if (!mongoURI) {
  console.error("❌ MONGODB_URI không được cấu hình trong .env");
  process.exit(1);
}

async function connectDB() {
  await mongoose.connect(mongoURI, {
    dbName: process.env.DB_NAME || "AppHocTiengNhat",
  });
  console.log("✅ Đã kết nối MongoDB");
}

// Transform dữ liệu moji_goi và bunpou thành format QuestionSchema
function transformSimpleQuestions(questions) {
  return questions
    .filter(q => q.correct_answer !== null)
    .map(q => ({
      mondai: q.mondai,
      question_text: q.question_text,
      choices: q.choices,
      correct_answer: q.correct_answer,
      score: 1,
      explanation: ""
    }));
}

// Transform dữ liệu dokkai và choukai thành format GroupQuestionSchema
function transformGroupQuestions(groups) {
  const groupMap = new Map();
  
  groups.forEach(item => {
    const key = `${item.mondai}-${item.group_content || ''}`;
    
    if (!groupMap.has(key)) {
      groupMap.set(key, {
        mondai: item.mondai,
        group_content: item.group_content || "",
        group_image: item.group_image || "",
        group_audio: item.group_audio || "",
        transcript: item.transcript || "",
        questions: []
      });
    }
    
    if (item.questions) {
      // Nếu có mảng questions (format đúng)
      item.questions.forEach(q => {
        if (q.correct_answer !== null) {
          groupMap.get(key).questions.push({
            mondai: item.mondai,
            question_text: q.question_text,
            choices: q.choices,
            correct_answer: q.correct_answer,
            score: 2,
            explanation: q.explanation || ""
          });
        }
      });
    } else if (item.question_text) {
      // Nếu câu hỏi ở cấp độ ngoài (format cũ)
      if (item.correct_answer !== null) {
        groupMap.get(key).questions.push({
          mondai: item.mondai,
          question_text: item.question_text,
          choices: item.choices,
          correct_answer: item.correct_answer,
          score: 2,
          explanation: item.explanation || ""
        });
      }
    }
  });
  
  return Array.from(groupMap.values()).filter(g => g.questions.length > 0);
}

async function importExam() {
  try {
    await connectDB();
    
    // Xóa đề thi cũ nếu có
    await JLPT.deleteOne({ 
      title: "Kỳ thi JLPT N3 tháng 7.2024 (Đề chính thức)",
      year: 2024,
      month: 7
    });
    
    console.log("📋 Đang transform dữ liệu...");
    
    // Dữ liệu gốc
    const rawData = {
      title: "Kỳ thi JLPT N3 tháng 7.2024 (Đề chính thức)",
      description: "Đề thi JLPT N3 chính thức tháng 7 năm 2024 - Bao gồm đầy đủ các phần Moji/Goi, Bunpou, Dokkai",
      level: "N3",
      year: 2024,
      month: 7,
      time_limit: 105,
      pass_score: 95,
      total_score: 180,
      is_published: true,
      is_active: true,
      sections: {}
    };
    
    // Transform moji_goi
    const mojiGoiData = [
      { mondai: 1, question_text: "すみません、弟がこれを割ってしまいました。", choices: ["けって", "おって", "わって", "さわって"], correct_answer: 2 },
      { mondai: 1, question_text: "ピアノを基本から習いたい", choices: ["ぎほん", "しほん", "きほん", "じほん"], correct_answer: 2 },
      { mondai: 1, question_text: "かばんは横に置いてください。", choices: ["よこ", "そば", "となり", "ゆか"], correct_answer: 0 },
      { mondai: 1, question_text: "この仕事は今日が最初です。", choices: ["さいしょ", "さいしゅう", "さいしょう", "さいしゅ"], correct_answer: 0 },
      { mondai: 1, question_text: "昨日、山田さんに本を返しました。", choices: ["わたしました", "もどしました", "かしました", "かえしました"], correct_answer: 3 },
      { mondai: 1, question_text: "この包丁は使いやすい。", choices: ["ぼうちょう", "ほうちょう", "ほう", "ぼう"], correct_answer: 1 },
      { mondai: 1, question_text: "適当なやり方を考えてください。", choices: ["てきどう", "てきとう", "ていとう", "ていどう"], correct_answer: 1 },
      { mondai: 1, question_text: "部屋が狭いので、大きな家具は置けません。", choices: ["やぐう", "かぐう", "やぐ", "かぐ"], correct_answer: 3 },
      { mondai: 2, question_text: "この問題をといてください。", choices: ["試いて", "答いて", "解いて", "調いて"], correct_answer: 2 },
      { mondai: 2, question_text: "今日は少しこしが痛い。", choices: ["腕", "腹", "脇", "腰"], correct_answer: 3 },
      { mondai: 2, question_text: "入学式のよくしゅうから講義が始まる。", choices: ["翌週", "次週", "明週", "違週"], correct_answer: 0 },
      { mondai: 2, question_text: "今朝は気温がひくかったので水が凍っていた。", choices: ["寒かった", "底かった", "低かった", "塞かった"], correct_answer: 2 },
      { mondai: 2, question_text: "湖はどのほうこうにありますか。", choices: ["方向", "方角", "法向", "法角"], correct_answer: 0 },
      { mondai: 2, question_text: "学校のきそくが少し変わるそうだ。", choices: ["規側", "規則", "期則", "期側"], correct_answer: 1 },
      { mondai: 3, question_text: "野球が好きな友人の（　）で、私も野球に興味を持った。", choices: ["指定", "申請", "影響", "通知"], correct_answer: 2 },
      { mondai: 3, question_text: "私は歌が苦手なので、歌の上手な人が（　）です。", choices: ["残念", "なつかしい", "うらやましい", "不安"], correct_answer: 2 },
      { mondai: 3, question_text: "ゴールまでもう少しだったので、足の痛みを（　）して走った。", choices: ["我慢", "苦労", "遠慮", "努力"], correct_answer: 0 },
      { mondai: 3, question_text: "林さんは会議ではいつも（　）で、あまり自分の意見を言わない。", choices: ["人工的", "消極的", "自動的", "間接的"], correct_answer: 1 },
      { mondai: 3, question_text: "このバスは駅を出発してから、図書館を（　）して美術館へ行きます。", choices: ["移動", "経由", "進行", "不車"], correct_answer: 1 },
      { mondai: 3, question_text: "あの兄弟はとても（　）がよくて、ほとんどけんかをしないそうだ。", choices: ["組", "間", "形", "仲"], correct_answer: 3 },
      { mondai: 3, question_text: "家のドアを開けるために、ポケットの中から鍵を（　）。", choices: ["取り付っけた", "取り出した", "引き受けた", "引き落とした"], correct_answer: 1 },
      { mondai: 3, question_text: "たくさんのことを（　）言われても、覚えられません。", choices: ["一度に", "偶然", "十分に", "平等に"], correct_answer: 0 },
      { mondai: 3, question_text: "このホテルは空港からの（　）がいいので、外国からの客が多い。", choices: ["ストップ", "セット", "テイクアウト", "アクセス"], correct_answer: 3 },
      { mondai: 3, question_text: "大好きな歌手のコンサートに行きたかったが、チケットが高くて買えないので行くのを（　）。", choices: ["きらった", "うたがった", "あきらめた", "うばった"], correct_answer: 2 },
      { mondai: 3, question_text: "タクシーの乗り場が分からなくて、駅の周りを（　）歩き回った。", choices: ["うろうろ", "どきどき", "ざあざあ", "ちかちか"], correct_answer: 0 },
      { mondai: 4, question_text: "この商品は売り切れました。", choices: ["ほとんど売れました", "全部売れました", "あまり売れませんでした", "全然売れませんでした"], correct_answer: 1 },
      { mondai: 4, question_text: "あそこは道がカーブしているので、気をつけてください。", choices: ["狭くなって", "曲がって", "込んで", "暗くなって"], correct_answer: 1 },
      { mondai: 4, question_text: "今夜は家に誰もいないから退屈だ。", choices: ["つまらない", "怖い", "さびしい", "忙しい"], correct_answer: 0 },
      { mondai: 4, question_text: "テレビで紹介された店にさっそく行った。", choices: ["初めて", "やっと", "たまに", "すぐに"], correct_answer: 3 },
      { mondai: 4, question_text: "このズボンはゆるいので、別のズボンが欲しい。", choices: ["古い", "小さい", "大きい", "薄い"], correct_answer: 2 },
      { mondai: 5, question_text: "知識", choices: ["いつ財布を落としたか知識がありません。", "はさみがどこにあるか知識がありますか。", "パーティーには私の知識がない人も大勢に来ていた。", "この仕事は医学の知識がないとできない。"], correct_answer: 3 },
      { mondai: 5, question_text: "ひびく", choices: ["台所からおいしそうなにおいがひびいている。", "この技術は100年くらい前に外国からひびいたものだ。", "この広場で歌を歌うと声がよくひびく。", "社長が代わるといううわさが会社内でひびいている。"], correct_answer: 2 },
      { mondai: 5, question_text: "完成", choices: ["みんなの意見が一つに完成したので、これから発表します。", "娘は子どものころからの夢が完成して医者になった。", "親戚の結婚が完成したので、お祝いを贈ろうと思います。", "今建てている家が完成したら、ぜひ遊びに来てください。"], correct_answer: 3 },
      { mondai: 5, question_text: "あわてる", choices: ["昨日大雨が降ったので、今日は川の水があわてて流れている。", "寝坊をして、あわてて家を出たので、携帯電話を忘れてきてしまった。", "マラソン大会で優勝するため、私はゴールまであわてて走り続けた。", "あのレストランは人気があるので、お店の人はいつもあわてて働いている。"], correct_answer: 1 },
      { mondai: 5, question_text: "実物", choices: ["服はインターネットの写真だけではなく、実物を見てから買いたい。", "そのときは彼女の実物の気持ちが分からなかった。", "デパートで買い物したとき、実物が足りなかったので、クレジットカードで払った。", "緊張したので発表のときは失敗しましたが、実物はもっと上手にできます。"], correct_answer: 0 }
    ];
    
    rawData.sections.moji_goi = transformSimpleQuestions(mojiGoiData);
    
    // Transform bunpou
    const bunpouData = [
      { mondai: 1, question_text: "久しぶりに大学時代の友人と会って、楽しい時間（　）過ごした。", choices: ["で", "に", "が", "を"], correct_answer: 3 },
      { mondai: 1, question_text: "私の家の近くにはスーパーが2軒あって、（　）歩いて行けるので便利だ。", choices: ["どちらから", "どちらへも", "どちらかでも", "どちらかまで"], correct_answer: 1 },
      { mondai: 1, question_text: "子どものころからバスが大好きだった兄は、今、バスの運転手（　）働いている。", choices: ["として", "にとって", "のほうが", "のほかに"], correct_answer: 0 },
      { mondai: 1, question_text: "今朝、寝坊して会議に遅れそうだったので、タクシーに乗ったが、道が込んでいて、（　）遅刻してしまった。", choices: ["つい", "結局", "次第に", "ほとんど"], correct_answer: 1 },
      { mondai: 1, question_text: "この歌を（　）たびに学生時代のことを思い出す。", choices: ["聞き", "聞く", "聞いた", "聞いている"], correct_answer: 1 },
      { mondai: 1, question_text: "（大学で）等未「アンさんは、卒業後はどうするんですか。」アン「国に帰りますが、帰ってからどう（　）まだ決めていません。」", choices: ["するかは", "するかが", "することは", "することが"], correct_answer: 0 },
      { mondai: 1, question_text: "インターネットで買ったセーターが届いた。サイズが少し大きいかもしれないと心配していたが、実際に（　）ぴったりだった。", choices: ["着てみると", "着たのだから", "着るとしたら", "着ていることで"], correct_answer: 0 },
      { mondai: 1, question_text: "大学で A:「今日、お昼、食べに行かない?」 B:「ごめん、その後、図書館へ行くつもりなんだ。あしたレポートを（　）。」", choices: ["出したほうがよくても", "出さないといけないのに", "出してはいけなくても", "出さないといけないから"], correct_answer: 3 },
      { mondai: 1, question_text: "この夏祭りは、100年以上前から、この町に住む人々によって（　）。", choices: ["続けてもらえる", "続けさせられる", "続けられている", "続けてくれている"], correct_answer: 2 },
      { mondai: 1, question_text: "A: 「このクッキー、おいしいね。どこで（　）。」", choices: ["買ったの", "買ったよね", "買ったことある", "買ったんじゃない"], correct_answer: 0 },
      { mondai: 1, question_text: "会議で A:「会議、お疲れさまでした。この会議室あとでまた使うので、エアコンはつけたま まに（　）。」 B:「はい、わかりました。」", choices: ["していませんか", "なっていませんか", "しておいてください", "なっておいてください"], correct_answer: 2 },
      { mondai: 1, question_text: "昨日読んだ雑誌に、「忘れることは、必ずしも（　）」と書いてあった。", choices: ["悪いことなのだ", "悪いことではない", "悪いことのはずだ", "悪いことかもしれない"], correct_answer: 1 },
      { mondai: 1, question_text: "学生「先生は、ふだん何かスポーツを（　）。」 先生「ええ。ゴルフにはときどき行きますよ。」", choices: ["いたしますか", "まいりますか", "なさいますか", "いらっしゃいますか"], correct_answer: 2 }
    ];
    
    rawData.sections.bunpou = transformSimpleQuestions(bunpouData);
    
    // Transform dokkai
    const dokkaiData = [
      {
        mondai: 4,
        group_content: "件名：部長会議にご出席予定の皆様\n\nあさって12日(金)の部長会議について、ご連絡します。\n天気予報では、明日の夜、台風が東京の近くを通ることが予想されています。そのため、あさってまで交通機関に影響が残る可能性があります。明日の予報で台風が東京を通ることになった場合は、来週に会議を延期することにします。\n最終的なご連絡は、明日11日(木)の15時にメールでいたします。\n以上、よろしくお願いします。\n\n第一営業部\n野村マリア",
        questions: [{
          question_text: "野村さんがこのメールで知らせたいことは何か。",
          choices: ["部長会議は、来週に延期する。", "部長会議は、明日の15時から行う。", "部長会議は天気に関係なく、あさって行う。", "部長会議を延期するかどうか、明日の15時に連絡する。"],
          correct_answer: 3
        }]
      },
      {
        mondai: 4,
        group_content: "高校生の孫が「来週、スポーツの大会に出るんだ。」と言った。コンピューターゲームの大会だと説明されて私は不思議な気がした。なぜ、それがスポーツの大会なのだろうか。\n聞いてみると、英語の「スポーツ」には、ルールを守りながら勝ったり負けたりすることを楽しむものという意味があるそうだ。それで、最近ではコンピューターゲームもスポーツと言うらしい。\n体を動かすことをスポーツだと思っていた私は驚いた。",
        questions: [{
          question_text: "不思議な気がしたとあるが、どうしてか。",
          choices: ["高校生なのに、孫が有名なスポーツの大会に出ると言っているから", "コンピューターゲームにも大会があると聞いたから", "体を動かさないのに、コンピューターゲームをスポーツと言っているから", "英語の「スポーツ」という言葉に、知らない意味があったから"],
          correct_answer: 2
        }]
      },
      {
        mondai: 4,
        group_content: "留学生日本語カラオケ大会 参加者募集\n\n5月29日(土)13時から、大教室(A103) 「留学生日本語カラオケ大会」を行います。参加したい人は、歌いたい日本語の歌を決めて、5月7日(金)までに留学生課で申し込んでください。\nなお、当日の集合時間は12時ですが、希望者は午前中に会場のA103で練習することができます。その場合の集合時間は10時になります。希望者は、参加の申し込みのときに、練習も申し込んでください。参加をお待ちしています。",
        questions: [{
          question_text: "カラオケ大会に参加したい人で、当日、会場で練習したい人はどうしなければならないか。",
          choices: ["5月7日までに留学生課で参加と練習の申し込みをして、29日の10時に会場へ行く。", "5月7日までに留学生課で参加と練習の申し込みをして、29日の12時に会場へ行く。", "5月7日までに留学生課で参加の申し込みだけして、29日の10時に会場へ行く。", "5月29日の10時までに留学生課で参加と練習の申し込みをして、12時に会場へ行く。"],
          correct_answer: 0
        }]
      },
      {
        mondai: 4,
        group_content: "コーヒーを飲むと眠れなくなるから、寝る前には飲まないという人が多いだろう。しかし最近、昼寝の前にはコーヒーを飲むといいと言われるようになってきた。\n昼寝をすると起きたあとの集中力が上がるが、長く寝るのはよくない。そこで、飲むと目が覚めるというコーヒーの効果を利用するのだ。この効果は、飲んでから約30分後に出るので、昼寝の前に飲むと、30分ぐらいで自然に目が覚める。ぜひやってみてほしい。",
        questions: [{
          question_text: "この文章を書いた人が言いたいことは何か。",
          choices: ["コーヒーを飲むと眠れなくなるから、昼寝の前には飲まないほうがいい。", "集中力が高くなるから、昼寝のあとで30分以内にコーヒーを飲むといい。", "昼寝で寝すぎないためには、昼寝をする30分前にコーヒーを飲むといい。", "昼寝で、30分ぐらいで自然に起きるためには、昼寝の直前にコーヒーを飲むといい。"],
          correct_answer: 3
        }]
      },
      {
        mondai: 5,
        group_content: "私は、箱から自分で野菜を育てたいと思っていました。私のうちには庭もベランダもないので、諦めていたのですが、先月、友達から部屋の中でホウレンソウを育てているという話を聞きました。室内でできるなら私もやってみたいと思い、準備をしました。\n外に似た環境がいいだろうと考え、窓の近くで育て始めたら、4日で芽が出始めました。少しずつ大きくなるのがうれしかったです。ところが、だんだん葉が黄色くなって、全部枯れてしまったのです! 太陽の光が足りなかったのかもしれないと思いましたがっかりして、友達に電話をして聞いてみると、ホウレンソウは夜になったら光が当たってはいけないということがわかりました。私の場合は、部屋の電気の光がよくなかったようです。友達は、段ボール箱でホウレンソウにカバーをしているのだそうです。\n私も同じようにやってみたら、今度は元気に育ちました。サラダにして食べたら、とてもおいしかったです。",
        questions: [
          { question_text: "①「諦めていた」とあるが、何を諦めていたのか。", choices: ["自分で野菜を育てること", "庭やベランダがある家に住むこと", "友達に野菜の育て方を教えてもらうこと", "部屋の中でホウレンソウを育てること"], correct_answer: 0 },
          { question_text: "②「がっかりして」とあるが、どうしてがっかりしたのか。", choices: ["ホウレンソウの芽が出なかったから", "ホウレンソウが全部枯れてしまったから", "ホウレンソウについての友達の知識が間違っていたから", "うまく育ったホウレンソウが少なかったから"], correct_answer: 1 },
          { question_text: "「今度は元気に育ちました」とあるが、どうして元気に育ったのか。", choices: ["昼、ホウレンソウにもっと光が当たるようにしたから", "昼、ホウレンソウにあまり光が当たらないようにしたから", "夜、ホウレンソウに光が当たるようにしたから", "夜、ホウレンソウに光が当たらないようにしたから"], correct_answer: 3 }
        ]
      },
      {
        mondai: 5,
        group_content: "日本に留学したばかりのころ、文房具店に入って驚いてしまった。私の国では、シャープペンシルはあまり売られていないが、その店には100円の安い物から5,000円以上する高い物まで、すごい数のシャーペンが並んでいたのだ。芯も太さが0.3mmから1.5mm まであって、濃さもいろいろな物が売られていた。\nイギリスで生まれたシャーペンだが、初めは1.5mmや1.0mmの芯しかなかった。だが、約60年前、ある日本の会社が、複雑な漢字でも美しく書けるよう、世界で初めて0.5mmの折れにくい芯を作ることにチャレンジして、成功したのだそうだ。それからシャーペンが日本中で使われるようになったらしい。\n私は、来日してからずっとシャーペンを愛用している。鉛筆のように先が丸くならず、小さい字がきれいに書けるからだ。今、使っているのは安い物だが、来年、就職したら、少しいい物を買おうと思っている。",
        questions: [
          { question_text: "「驚いてしまった」とあるが、文房具店のどんなことに驚いたのか。", choices: ["シャーペンがあまり売られていなかったこと", "たくさんの種類のシャーペンや芯が売られていたこと", "値段の高いシャーペンばかりが売られていたこと", "シャーペンの芯だけを売る専門の店だったこと"], correct_answer: 1 },
          { question_text: "シャーペンが日本中で使われるようになったのは、いつからか。", choices: ["日本の会社が、太くて折れにくい芯を作ってから", "日本の会社が細くて折れにくい芯を作ってから", "日本の会社が、日本でイギリスのシャーペンを売るようになってから", "日本の会社が世界で初めてシャーペンを作ってから"], correct_answer: 1 },
          { question_text: "「私」が今、シャーペンを使っているのはなぜか。", choices: ["日本中で使われているから", "小さい字が書きやすいから", "鉛筆より安く買えるから", "高くていい物を買ったから"], correct_answer: 1 }
        ]
      },
      {
        mondai: 6,
        group_content: "野球やサッカーなどのプロスポーツの経営では、試合会場に来てくれる客を増やすことが重要だ。また見たいと思うようないい試合が続けば、客は自然に増えるだろう。しかし、どんなに選手が努力しても、そのような試合をずっと続けるのは難しい。そこで、(1)経営者のさまざまな工夫が必要になる。\nその一つに、(2)試合会場の工夫がある。例えば、ある会場では、試合がある日に、いろいろな飲食店の食べ物や飲み物を1,000種類も選べるようにしている。また、バーベキューをしながら試合が見られる観客席を作っているところもある。会場を楽しく過ごせる場所にして、また来たいと思ってもらおうという考え方だ。経営という点では、試合を見ること以外にも会場に来る目的を作ることが重要なのだ。\nもちろん、試合を楽しむために来る客を増やす工夫もしている。例えば、新しい客に来てもらうために、無料のチケットを配るという方法がある。一度会場に来て試合を楽しんでくれたら、次はチケットを買って来てくれる可能性が広がるという考えからだ。\nただ、(3)この考え方には反対意見もある。無料のチケットで来た客は、ふだんのチケットを高く感じてしまう。すると、結局チケットを買わなくなるので、収入は増えないと考える経営者もいる。\nプロスポーツの経営者は、客に来てもらうために、いろいろな工夫をしている。手段はさまざまだが、客に満足してもらい、何度も来てもらいたいという気持ちは共通しているのだ。",
        questions: [
          { question_text: "①「経営者のさまざまな工夫が必要になる」とあるが、なぜか。", choices: ["選手が、客を増やすことに関心を持っていないから", "選手がどんなにいい試合を続けても、客の数には影響しないから", "選手がいい試合をし続けて客を増やすことは、難しいから", "選手が努力することがなく、客が減っているから"], correct_answer: 2 },
          { question_text: "②「試合会場の工夫」とあるが、どのような工夫を例として書いているか。", choices: ["会場内の飲食店の案内をわかりやすくする工夫", "会場で食べ物や飲み物を注文しやすくする工夫", "会場で集中して試合を見てもらうための観客席の工夫", "会場で試合以外に飲食も楽しんでもらうための工夫"], correct_answer: 3 },
          { question_text: "③「この考え方」とあるが、どのような考え方か。", choices: ["無料のチケットを配って客が増えれば、選手たちのやる気が出るだろう。", "無料のチケットを配っても、見に来る客はほとんどいないだろう。", "無料のチケットで試合を楽しんだ客は、次はチケットを買って来るだろう。", "無料のチケットで試合を楽しんだ客は、次もチケットを買わないだろう。"], correct_answer: 3 },
          { question_text: "この文章全体のテーマは何か。", choices: ["プロスポーツの経営者が、試合会場に来る客を増やすためにしていること", "プロスポーツの経営者が、選手を強くするためにしていること", "プロスポーツの経営者が、試合会場を客が楽しめる場所にするためにしていること", "プロスポーツの経営者が、客に安く試合を見てもらうためにしていること"], correct_answer: 0 }
        ]
      }
    ];
    
    rawData.sections.dokkai = transformGroupQuestions(dokkaiData);
    
    // Transform choukai - File audio chung: /uploads/DeThi/jlpt72024.mp3
    const choukaiData = [
      // Mondai 1: Kadai Rikai (課題理解) - 6 câu
      {
        mondai: 1,
        group_content: "問題1では、まず質問を聞いてください。それから話を聞いて、問題用紙の1から4の中から、最もよいものを一つ選んでください。",
        group_audio: "/uploads/DeThi/jlpt72024.mp3",
        transcript: "[File audio chứa toàn bộ phần Choukai - Mondai 1: Kadai Rikai]",
        questions: [
          { mondai: 1, question_text: "Câu 1 - Kadai Rikai", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 1, question_text: "Câu 2 - Kadai Rikai", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 1, question_text: "Câu 3 - Kadai Rikai", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 1, question_text: "Câu 4 - Kadai Rikai", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 1, question_text: "Câu 5 - Kadai Rikai", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 1, question_text: "Câu 6 - Kadai Rikai", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 }
        ]
      },
      // Mondai 2: Pointo Rikai (ポイント理解) - 6 câu
      {
        mondai: 2,
        group_content: "問題2では、まず質問を聞いてください。そのあと、問題用紙を見てください。読む時間があります。それから話を聞いて、問題用紙の1から4の中から、最もよいものを一つ選んでください。",
        group_audio: "/uploads/DeThi/jlpt72024.mp3",
        transcript: "[File audio chứa toàn bộ phần Choukai - Mondai 2: Pointo Rikai]",
        questions: [
          { mondai: 2, question_text: "Câu 1 - Pointo Rikai", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 2, question_text: "Câu 2 - Pointo Rikai", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 2, question_text: "Câu 3 - Pointo Rikai", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 2, question_text: "Câu 4 - Pointo Rikai", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 2, question_text: "Câu 5 - Pointo Rikai", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 2, question_text: "Câu 6 - Pointo Rikai", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 }
        ]
      },
      // Mondai 3: Gaiyou Rikai (概要理解) - 3 câu
      {
        mondai: 3,
        group_content: "問題3では、問題用紙に何も印刷されていません。この問題は、全体としてどんな内容かを聞く問題です。話の前に質問はありません。まず話を聞いてください。それから、質問とせんたくしを聞いて、1から4の中から、最もよいものを一つ選んでください。",
        group_audio: "/uploads/DeThi/jlpt72024.mp3",
        transcript: "[File audio chứa toàn bộ phần Choukai - Mondai 3: Gaiyou Rikai]",
        questions: [
          { mondai: 3, question_text: "Câu 1 - Gaiyou Rikai", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 3, question_text: "Câu 2 - Gaiyou Rikai", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 3, question_text: "Câu 3 - Gaiyou Rikai", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 }
        ]
      },
      // Mondai 4: Hatsuwa Hyougen (発話表現) - 4 câu (có 4 lựa chọn)
      {
        mondai: 4,
        group_content: "問題4では、問題用紙に何も印刷されていません。まず文を聞いてください。それから、それに対する返事を聞いて、1から4の中から、最もよいものを一つ選んでください。",
        group_audio: "/uploads/DeThi/jlpt72024.mp3",
        transcript: "[File audio chứa toàn bộ phần Choukai - Mondai 4: Hatsuwa Hyougen]",
        questions: [
          { mondai: 4, question_text: "Câu 1 - Hatsuwa Hyougen", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 4, question_text: "Câu 2 - Hatsuwa Hyougen", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 4, question_text: "Câu 3 - Hatsuwa Hyougen", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 4, question_text: "Câu 4 - Hatsuwa Hyougen", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 }
        ]
      },
      // Mondai 5: Sokuiji Outou (即時応答) - 9 câu (có 4 lựa chọn)
      {
        mondai: 5,
        group_content: "問題5では、問題用紙に何も印刷されていません。まず文を聞いてください。それから、それに対する返事を聞いて、1から4の中から、最もよいものを一つ選んでください。",
        group_audio: "/uploads/DeThi/jlpt72024.mp3",
        transcript: "[File audio chứa toàn bộ phần Choukai - Mondai 5: Sokuiji Outou]",
        questions: [
          { mondai: 5, question_text: "Câu 1 - Sokuiji Outou", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 5, question_text: "Câu 2 - Sokuiji Outou", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 5, question_text: "Câu 3 - Sokuiji Outou", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 5, question_text: "Câu 4 - Sokuiji Outou", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 5, question_text: "Câu 5 - Sokuiji Outou", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 5, question_text: "Câu 6 - Sokuiji Outou", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 5, question_text: "Câu 7 - Sokuiji Outou", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 5, question_text: "Câu 8 - Sokuiji Outou", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 },
          { mondai: 5, question_text: "Câu 9 - Sokuiji Outou", choices: ["1", "2", "3", "4"], correct_answer: 0, score: 2 }
        ]
      }
    ];
    
    rawData.sections.choukai = transformGroupQuestions(choukaiData);
    
    console.log("✅ Transform dữ liệu thành công!");
    console.log(`   - Moji/Goi: ${rawData.sections.moji_goi.length} câu`);
    console.log(`   - Bunpou: ${rawData.sections.bunpou.length} câu`);
    console.log(`   - Dokkai: ${rawData.sections.dokkai.length} nhóm`);
    console.log(`   - Choukai: ${rawData.sections.choukai.length} nhóm (28 câu)`);
    console.log(`   - Audio: /uploads/DeThi/jlpt72024.mp3`);
    
    // Lưu vào database
    const newExam = new JLPT(rawData);
    await newExam.save();
    
    console.log(`\n✅ Đã import thành công đề thi JLPT N3!`);
    console.log(`   ID: ${newExam._id}`);
    console.log(`   Title: ${newExam.title}`);
    
  } catch (error) {
    console.error("❌ Lỗi:", error.message);
    console.error(error);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log("\n✅ Đã đóng kết nối MongoDB");
  }
}

importExam();

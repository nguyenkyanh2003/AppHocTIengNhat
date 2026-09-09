import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'vi': {
      // Chung
      'app_name': 'Học Tiếng Nhật',
      'cancel': 'Hủy',
      'ok': 'OK',
      'save': 'Lưu',
      'delete': 'Xóa',
      'edit': 'Sửa',
      'search': 'Tìm kiếm',
      'loading': 'Đang tải...',
      'error': 'Lỗi',
      'success': 'Thành công',
      'back': 'Quay lại',
      'next': 'Tiếp theo',
      'done': 'Hoàn thành',
      'close': 'Đóng',

      // Home Screen
      'welcome_back': 'Chào mừng trở lại!',
      'continue_learning': 'Hãy tiếp tục hành trình học tiếng Nhật',
      'days': 'ngày',
      'consecutive_days': 'ngày liên tiếp',
      'streak': 'Chuỗi học',
      'current_streak': 'Streak hiện tại',
      'points': 'Điểm',
      'xp': 'XP',
      'total_xp': 'Tổng XP',
      'latest_news': 'Tin Tức Mới',
      'view_all': 'Xem tất cả',
      'lessons': 'Học tập',
      'review': 'Ôn tập',
      'account': 'Tài khoản',
      'home': 'Trang chủ',
      'progress': 'Tiến độ',
      'profile': 'Cá nhân',
      'learning_stats': 'Thống kê học tập',
      'details': 'Chi tiết',
      'progress_details': 'Tiến độ chi tiết',

      // Menu Items
      'menu_lesson': 'Bài học',
      'menu_lesson_subtitle': 'Học từ vựng và ngữ pháp',
      'menu_vocabulary': 'Từ vựng',
      'menu_vocabulary_subtitle': 'Học từ mới mỗi ngày',
      'menu_kanji': 'Kanji',
      'menu_kanji_subtitle': 'Học chữ Hán',
      'menu_exercise': 'Luyện tập',
      'menu_exercise_subtitle': 'Bài tập và kiểm tra',
      'menu_jlpt': 'JLPT',
      'menu_jlpt_subtitle': 'Luyện thi năng lực',
      'menu_news': 'Tin tức',
      'menu_news_subtitle': 'Đọc tin tiếng Nhật',
      'menu_study_group': 'Nhóm học',
      'menu_study_group_subtitle': 'Học cùng bạn bè',
      'menu_notebook': 'Sổ tay',
      'menu_notebook_subtitle': 'Ghi chú của bạn',
      'menu_streak': 'Streak & Thành tích',
      'menu_streak_subtitle': 'Xem tiến độ và XP',

      // Stats
      'level': 'Level',
      'xp_to_next_level': 'XP tới level kế',
      'days_studied': 'Số ngày đã học',
      'longest_streak': 'Streak dài nhất',

      // Settings Screen
      'settings': 'Cài đặt',
      'account_info': 'Thông tin tài khoản',
      'user': 'Người dùng',
      'notifications': 'Thông báo',
      'enable_notifications': 'Bật thông báo',
      'receive_notifications': 'Nhận thông báo từ ứng dụng',
      'sound': 'Âm thanh',
      'play_sound_notification': 'Phát âm thanh khi có thông báo',
      'vibrate': 'Rung',
      'vibrate_notification': 'Rung khi có thông báo',
      'language_interface': 'Ngôn ngữ & Giao diện',
      'language': 'Ngôn ngữ',
      'interface': 'Giao diện',
      'light': 'Sáng',
      'dark': 'Tối',
      'auto': 'Tự động',
      'other': 'Khác',
      'help_feedback': 'Trợ giúp & Phản hồi',
      'privacy_policy': 'Chính sách riêng tư',
      'about_app': 'Về ứng dụng',
      'logout': 'Đăng xuất',
      'save_settings': 'Lưu cài đặt',
      'settings_saved': 'Cài đặt đã được lưu',

      // Change Password Screen
      'change_password': 'Đổi mật khẩu',
      'current_password': 'Mật khẩu hiện tại',
      'new_password': 'Mật khẩu mới',
      'confirm_new_password': 'Xác nhận mật khẩu mới',
      'password_changed': 'Đổi mật khẩu thành công!',
      'password_min_length': 'Mật khẩu phải có ít nhất 6 ký tự',
      'passwords_not_match': 'Mật khẩu xác nhận không khớp',
      'old_password_incorrect': 'Mật khẩu cũ không chính xác',
      'select_language': 'Chọn ngôn ngữ',
      'language_changed': 'Đã đổi ngôn ngữ sang',

      // Profile Screen
      'my_profile': 'Hồ sơ của tôi',
      'edit_profile': 'Chỉnh sửa hồ sơ',
      'full_name': 'Họ và tên',
      'email': 'Email',
      'phone': 'Số điện thoại',
      'address': 'Địa chỉ',
      'gender': 'Giới tính',
      'date_of_birth': 'Ngày sinh',
      'total_points': 'Tổng điểm',
      'study_time': 'Thời gian học',
      'achievements': 'Thành tích',

      // Lesson Screen
      'lesson_list': 'Danh sách bài học',
      'lesson': 'Bài học',
      'start_lesson': 'Bắt đầu học',
      'continue_lesson': 'Tiếp tục học',
      'lesson_completed': 'Hoàn thành bài học',
      'lesson_in_progress': 'Đang học',

      // Vocabulary Screen
      'vocabulary': 'Từ vựng',
      'vocabulary_list': 'Danh sách từ vựng',
      'meaning': 'Nghĩa',
      'pronunciation': 'Phát âm',
      'example': 'Ví dụ',
      'add_to_notebook': 'Thêm vào sổ tay',

      // Kanji Screen
      'kanji': 'Kanji',
      'kanji_list': 'Danh sách Kanji',
      'stroke_count': 'Số nét',
      'onyomi': 'Âm Ôn',
      'kunyomi': 'Âm Huấn',

      // Exercise Screen
      'exercise': 'Bài tập',
      'exercise_list': 'Danh sách bài tập',
      'start_exercise': 'Bắt đầu làm bài',
      'submit': 'Nộp bài',
      'result': 'Kết quả',
      'correct': 'Đúng',
      'incorrect': 'Sai',
      'score': 'Điểm số',

      // News Screen
      'news': 'Tin tức',
      'read_more': 'Đọc thêm',

      // Notebook Screen
      'notebook': 'Sổ tay',
      'my_notes': 'Ghi chú của tôi',
      'add_note': 'Thêm ghi chú',

      // Auth Screen
      'login': 'Đăng nhập',
      'register': 'Đăng ký',
      'username': 'Tên đăng nhập',
      'password': 'Mật khẩu',
      'confirm_password': 'Xác nhận mật khẩu',
      'forgot_password': 'Quên mật khẩu?',

      // Help Screen
      'help': 'Trợ giúp',
      'help_title': 'Chúng tôi có thể giúp gì cho bạn?',
      'help_subtitle': 'Tìm câu trả lời nhanh hoặc liên hệ với chúng tôi',
      'send_email': 'Gửi Email',
      'contact_directly': 'Liên hệ trực tiếp',
      'report_bug': 'Báo lỗi',
      'send_bug_report': 'Gửi báo cáo lỗi',
      'feedback': 'Góp ý',
      'suggest_feature': 'Đề xuất tính năng',
      'about': 'Về ứng dụng',
      'version_info': 'Thông tin & phiên bản',
      'faq': 'Câu hỏi thường gặp',
      'still_need_help': 'Vẫn cần trợ giúp?',
      'support_team_ready': 'Đội ngũ hỗ trợ sẵn sàng giúp đỡ bạn 24/7',
      'contact_support': 'Liên hệ hỗ trợ',

      // Learning History Screen
      'learning_history': 'Lịch sử học tập',
      'overview': 'Tổng quan',
      'activity': 'Hoạt động',
      'statistics': 'Thống kê',
      'consecutive_days_short': 'Ngày liên tiếp',
      'record': 'Kỷ lục',
      'weekly_calendar': 'Lịch học tuần này',
      'recent_achievements': 'Thành tích gần đây',
      'all': 'Tất cả',
      'no_activity': 'Chưa có hoạt động nào',
      'start_learning': 'Bắt đầu học để ghi lại hoạt động!',
      'today': 'Hôm nay',
      'this_week': 'Tuần này',
      'total': 'Tổng cộng',
      'daily_activity': 'Hoạt động theo ngày',
      'learning_distribution': 'Phân bố học tập',
      'grammar': 'Ngữ pháp',

      // Languages
      'vietnamese': 'Tiếng Việt',
      'english': 'English',
      'japanese': '日本語',
    },
    'en': {
      // Common
      'app_name': 'Japanese Learning',
      'cancel': 'Cancel',
      'ok': 'OK',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'back': 'Back',
      'next': 'Next',
      'done': 'Done',
      'close': 'Close',

      // Home Screen
      'welcome_back': 'Welcome back!',
      'continue_learning': 'Continue your Japanese learning journey',
      'days': 'days',
      'consecutive_days': 'consecutive days',
      'streak': 'Streak',
      'current_streak': 'Current Streak',
      'points': 'Points',
      'xp': 'XP',
      'total_xp': 'Total XP',
      'latest_news': 'Latest News',
      'view_all': 'View all',
      'lessons': 'Lessons',
      'review': 'Review',
      'account': 'Account',
      'home': 'Home',
      'progress': 'Progress',
      'profile': 'Profile',
      'learning_stats': 'Learning Statistics',
      'details': 'Details',
      'progress_details': 'Progress Details',

      // Menu Items
      'menu_lesson': 'Lessons',
      'menu_lesson_subtitle': 'Learn vocabulary and grammar',
      'menu_vocabulary': 'Vocabulary',
      'menu_vocabulary_subtitle': 'Learn new words daily',
      'menu_kanji': 'Kanji',
      'menu_kanji_subtitle': 'Learn Chinese characters',
      'menu_exercise': 'Practice',
      'menu_exercise_subtitle': 'Exercises and tests',
      'menu_jlpt': 'JLPT',
      'menu_jlpt_subtitle': 'JLPT preparation',
      'menu_news': 'News',
      'menu_news_subtitle': 'Read Japanese news',
      'menu_study_group': 'Study Groups',
      'menu_study_group_subtitle': 'Learn with friends',
      'menu_notebook': 'Notebook',
      'menu_notebook_subtitle': 'Your notes',
      'menu_streak': 'Streak & Achievements',
      'menu_streak_subtitle': 'View progress and XP',

      // Stats
      'level': 'Level',
      'xp_to_next_level': 'XP to next level',
      'days_studied': 'Days studied',
      'longest_streak': 'Longest streak',

      // Settings Screen
      'settings': 'Settings',
      'account_info': 'Account Information',
      'user': 'User',
      'notifications': 'Notifications',
      'enable_notifications': 'Enable notifications',
      'receive_notifications': 'Receive notifications from app',
      'sound': 'Sound',
      'play_sound_notification': 'Play sound when notification arrives',
      'vibrate': 'Vibrate',
      'vibrate_notification': 'Vibrate when notification arrives',
      'language_interface': 'Language & Interface',
      'language': 'Language',
      'interface': 'Interface',
      'light': 'Light',
      'dark': 'Dark',
      'auto': 'Auto',
      'other': 'Other',
      'help_feedback': 'Help & Feedback',
      'privacy_policy': 'Privacy Policy',
      'about_app': 'About App',
      'logout': 'Logout',
      'save_settings': 'Save Settings',
      'settings_saved': 'Settings saved',

      // Change Password Screen
      'change_password': 'Change Password',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_new_password': 'Confirm New Password',
      'password_changed': 'Password changed successfully!',
      'password_min_length': 'Password must be at least 6 characters',
      'passwords_not_match': 'Passwords do not match',
      'old_password_incorrect': 'Current password is incorrect',
      'select_language': 'Select Language',
      'language_changed': 'Language changed to',

      // Profile Screen
      'my_profile': 'My Profile',
      'edit_profile': 'Edit Profile',
      'full_name': 'Full Name',
      'email': 'Email',
      'phone': 'Phone Number',
      'address': 'Address',
      'gender': 'Gender',
      'date_of_birth': 'Date of Birth',
      'total_points': 'Total Points',
      'study_time': 'Study Time',
      'achievements': 'Achievements',

      // Lesson Screen
      'lesson_list': 'Lesson List',
      'lesson': 'Lesson',
      'start_lesson': 'Start Lesson',
      'continue_lesson': 'Continue',
      'lesson_completed': 'Completed',
      'lesson_in_progress': 'In Progress',

      // Vocabulary Screen
      'vocabulary': 'Vocabulary',
      'vocabulary_list': 'Vocabulary List',
      'meaning': 'Meaning',
      'pronunciation': 'Pronunciation',
      'example': 'Example',
      'add_to_notebook': 'Add to Notebook',

      // Kanji Screen
      'kanji': 'Kanji',
      'kanji_list': 'Kanji List',
      'stroke_count': 'Strokes',
      'onyomi': 'Onyomi',
      'kunyomi': 'Kunyomi',

      // Exercise Screen
      'exercise': 'Exercise',
      'exercise_list': 'Exercise List',
      'start_exercise': 'Start Exercise',
      'submit': 'Submit',
      'result': 'Result',
      'correct': 'Correct',
      'incorrect': 'Incorrect',
      'score': 'Score',

      // News Screen
      'news': 'News',
      'read_more': 'Read more',

      // Notebook Screen
      'notebook': 'Notebook',
      'my_notes': 'My Notes',
      'add_note': 'Add Note',

      // Auth Screen
      'login': 'Login',
      'register': 'Register',
      'username': 'Username',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'forgot_password': 'Forgot Password?',

      // Help Screen
      'help': 'Help',
      'help_title': 'How can we help you?',
      'help_subtitle': 'Find quick answers or contact us',
      'send_email': 'Send Email',
      'contact_directly': 'Contact Directly',
      'report_bug': 'Report Bug',
      'send_bug_report': 'Submit Bug Report',
      'feedback': 'Feedback',
      'suggest_feature': 'Suggest Feature',
      'about': 'About',
      'version_info': 'Info & Version',
      'faq': 'FAQ',
      'still_need_help': 'Still need help?',
      'support_team_ready': 'Our support team is ready to help you 24/7',
      'contact_support': 'Contact Support',

      // Learning History Screen
      'learning_history': 'Learning History',
      'overview': 'Overview',
      'activity': 'Activity',
      'statistics': 'Statistics',
      'consecutive_days_short': 'Consecutive Days',
      'record': 'Record',
      'weekly_calendar': 'Weekly Calendar',
      'recent_achievements': 'Recent Achievements',
      'all': 'All',
      'no_activity': 'No activity yet',
      'start_learning': 'Start learning to record activity!',
      'today': 'Today',
      'this_week': 'This Week',
      'total': 'Total',
      'daily_activity': 'Daily Activity',
      'learning_distribution': 'Learning Distribution',
      'grammar': 'Grammar',

      // Languages
      'vietnamese': 'Tiếng Việt',
      'english': 'English',
      'japanese': '日本語',
    },
    'ja': {
      // Common
      'app_name': '日本語学習',
      'cancel': 'キャンセル',
      'ok': 'OK',
      'save': '保存',
      'delete': '削除',
      'edit': '編集',
      'search': '検索',
      'loading': '読み込み中...',
      'error': 'エラー',
      'success': '成功',
      'back': '戻る',
      'next': '次へ',
      'done': '完了',
      'close': '閉じる',

      // Home Screen
      'welcome_back': 'おかえりなさい！',
      'continue_learning': '日本語学習を続けましょう',
      'days': '日',
      'consecutive_days': '日連続',
      'streak': '連続記録',
      'current_streak': '現在の連続記録',
      'points': 'ポイント',
      'xp': 'XP',
      'total_xp': '総XP',
      'latest_news': '最新ニュース',
      'view_all': 'すべて表示',
      'lessons': 'レッスン',
      'review': '復習',
      'account': 'アカウント',
      'home': 'ホーム',
      'progress': '進捗',
      'profile': 'プロフィール',
      'learning_stats': '学習統計',
      'details': '詳細',
      'progress_details': '進捗詳細',

      // Menu Items
      'menu_lesson': 'レッスン',
      'menu_lesson_subtitle': '語彙と文法を学ぶ',
      'menu_vocabulary': '語彙',
      'menu_vocabulary_subtitle': '毎日新しい単語を学ぶ',
      'menu_kanji': '漢字',
      'menu_kanji_subtitle': '漢字を学ぶ',
      'menu_exercise': '練習',
      'menu_exercise_subtitle': '練習問題とテスト',
      'menu_jlpt': 'JLPT',
      'menu_jlpt_subtitle': 'JLPT対策',
      'menu_news': 'ニュース',
      'menu_news_subtitle': '日本語のニュースを読む',
      'menu_study_group': '学習グループ',
      'menu_study_group_subtitle': '友達と一緒に学ぶ',
      'menu_notebook': 'ノート',
      'menu_notebook_subtitle': 'あなたのノート',
      'menu_streak': '連続記録と実績',
      'menu_streak_subtitle': '進捗とXPを見る',

      // Stats
      'level': 'レベル',
      'xp_to_next_level': '次のレベルまでのXP',
      'days_studied': '学習日数',
      'longest_streak': '最長連続記録',

      // Settings Screen
      'settings': '設定',
      'account_info': 'アカウント情報',
      'user': 'ユーザー',
      'notifications': '通知',
      'enable_notifications': '通知を有効にする',
      'receive_notifications': 'アプリから通知を受け取る',
      'sound': '音',
      'play_sound_notification': '通知音を鳴らす',
      'vibrate': 'バイブレーション',
      'vibrate_notification': '通知時に振動する',
      'language_interface': '言語とインターフェース',
      'language': '言語',
      'interface': 'インターフェース',
      'light': 'ライト',
      'dark': 'ダーク',
      'auto': '自動',
      'other': 'その他',
      'help_feedback': 'ヘルプとフィードバック',
      'privacy_policy': 'プライバシーポリシー',
      'about_app': 'アプリについて',
      'logout': 'ログアウト',
      'save_settings': '設定を保存',
      'settings_saved': '設定が保存されました',

      // Change Password Screen
      'change_password': 'パスワード変更',
      'current_password': '現在のパスワード',
      'new_password': '新しいパスワード',
      'confirm_new_password': '新しいパスワードの確認',
      'password_changed': 'パスワードが変更されました！',
      'password_min_length': 'パスワードは6文字以上必要です',
      'passwords_not_match': 'パスワードが一致しません',
      'old_password_incorrect': '現在のパスワードが正しくありません',
      'select_language': '言語を選択',
      'language_changed': '言語が変更されました：',

      // Profile Screen
      'my_profile': 'マイプロフィール',
      'edit_profile': 'プロフィール編集',
      'full_name': '氏名',
      'email': 'メール',
      'phone': '電話番号',
      'address': '住所',
      'gender': '性別',
      'date_of_birth': '生年月日',
      'total_points': '総ポイント',
      'study_time': '学習時間',
      'achievements': '実績',

      // Lesson Screen
      'lesson_list': 'レッスン一覧',
      'lesson': 'レッスン',
      'start_lesson': 'レッスン開始',
      'continue_lesson': '続ける',
      'lesson_completed': '完了',
      'lesson_in_progress': '進行中',

      // Vocabulary Screen
      'vocabulary': '語彙',
      'vocabulary_list': '語彙リスト',
      'meaning': '意味',
      'pronunciation': '発音',
      'example': '例文',
      'add_to_notebook': 'ノートに追加',

      // Kanji Screen
      'kanji': '漢字',
      'kanji_list': '漢字リスト',
      'stroke_count': '画数',
      'onyomi': '音読み',
      'kunyomi': '訓読み',

      // Exercise Screen
      'exercise': '練習',
      'exercise_list': '練習リスト',
      'start_exercise': '練習開始',
      'submit': '提出',
      'result': '結果',
      'correct': '正解',
      'incorrect': '不正解',
      'score': 'スコア',

      // News Screen
      'news': 'ニュース',
      'read_more': '続きを読む',

      // Notebook Screen
      'notebook': 'ノート',
      'my_notes': 'マイノート',
      'add_note': 'ノート追加',

      // Auth Screen
      'login': 'ログイン',
      'register': '登録',
      'username': 'ユーザー名',
      'password': 'パスワード',
      'confirm_password': 'パスワード確認',
      'forgot_password': 'パスワードを忘れた？',

      // Help Screen
      'help': 'ヘルプ',
      'help_title': '何かお手伝いできますか？',
      'help_subtitle': '回答を見つけるか、お問い合わせください',
      'send_email': 'メールを送る',
      'contact_directly': '直接連絡',
      'report_bug': 'バグを報告',
      'send_bug_report': 'バグレポートを送信',
      'feedback': 'フィードバック',
      'suggest_feature': '機能を提案',
      'about': 'アプリについて',
      'version_info': '情報とバージョン',
      'faq': 'よくある質問',
      'still_need_help': 'まだ助けが必要ですか？',
      'support_team_ready': 'サポートチームが24時間対応しています',
      'contact_support': 'サポートに連絡',

      // Learning History Screen
      'learning_history': '学習履歴',
      'overview': '概要',
      'activity': 'アクティビティ',
      'statistics': '統計',
      'consecutive_days_short': '連続日数',
      'record': '記録',
      'weekly_calendar': '今週のカレンダー',
      'recent_achievements': '最近の実績',
      'all': 'すべて',
      'no_activity': 'アクティビティがありません',
      'start_learning': '学習を開始してアクティビティを記録しましょう！',
      'today': '今日',
      'this_week': '今週',
      'total': '合計',
      'daily_activity': '日別アクティビティ',
      'learning_distribution': '学習分布',
      'grammar': '文法',

      // Languages
      'vietnamese': 'Tiếng Việt',
      'english': 'English',
      'japanese': '日本語',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Common shortcuts
  String get appName => translate('app_name');
  String get cancel => translate('cancel');
  String get ok => translate('ok');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get search => translate('search');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get back => translate('back');
  String get next => translate('next');
  String get done => translate('done');
  String get close => translate('close');

  // Home Screen
  String get welcomeBack => translate('welcome_back');
  String get continueLearning => translate('continue_learning');
  String get days => translate('days');
  String get consecutiveDays => translate('consecutive_days');
  String get streak => translate('streak');
  String get currentStreak => translate('current_streak');
  String get points => translate('points');
  String get xp => translate('xp');
  String get totalXp => translate('total_xp');
  String get latestNews => translate('latest_news');
  String get viewAll => translate('view_all');
  String get lessons => translate('lessons');
  String get home => translate('home');
  String get progress => translate('progress');
  String get review => translate('review');
  String get account => translate('account');
  String get profile => translate('profile');
  String get learningStats => translate('learning_stats');
  String get details => translate('details');
  String get progressDetails => translate('progress_details');

  // Menu Items
  String get menuLesson => translate('menu_lesson');
  String get menuLessonSubtitle => translate('menu_lesson_subtitle');
  String get menuVocabulary => translate('menu_vocabulary');
  String get menuVocabularySubtitle => translate('menu_vocabulary_subtitle');
  String get menuKanji => translate('menu_kanji');
  String get menuKanjiSubtitle => translate('menu_kanji_subtitle');
  String get menuExercise => translate('menu_exercise');
  String get menuExerciseSubtitle => translate('menu_exercise_subtitle');
  String get menuJlpt => translate('menu_jlpt');
  String get menuJlptSubtitle => translate('menu_jlpt_subtitle');
  String get menuNews => translate('menu_news');
  String get menuNewsSubtitle => translate('menu_news_subtitle');
  String get menuStudyGroup => translate('menu_study_group');
  String get menuStudyGroupSubtitle => translate('menu_study_group_subtitle');
  String get menuNotebook => translate('menu_notebook');
  String get menuNotebookSubtitle => translate('menu_notebook_subtitle');
  String get menuStreak => translate('menu_streak');
  String get menuStreakSubtitle => translate('menu_streak_subtitle');

  // Stats
  String get level => translate('level');
  String get xpToNextLevel => translate('xp_to_next_level');
  String get daysStudied => translate('days_studied');
  String get longestStreak => translate('longest_streak');

  // Settings
  String get settings => translate('settings');
  String get accountInfo => translate('account_info');
  String get user => translate('user');
  String get notifications => translate('notifications');
  String get enableNotifications => translate('enable_notifications');
  String get receiveNotifications => translate('receive_notifications');
  String get sound => translate('sound');
  String get playSoundNotification => translate('play_sound_notification');
  String get vibrate => translate('vibrate');
  String get vibrateNotification => translate('vibrate_notification');
  String get languageInterface => translate('language_interface');
  String get language => translate('language');
  String get interface => translate('interface');
  String get light => translate('light');
  String get dark => translate('dark');
  String get auto => translate('auto');
  String get other => translate('other');
  String get helpFeedback => translate('help_feedback');
  String get privacyPolicy => translate('privacy_policy');
  String get aboutApp => translate('about_app');
  String get logout => translate('logout');
  String get saveSettings => translate('save_settings');
  String get settingsSaved => translate('settings_saved');

  // Profile
  String get myProfile => translate('my_profile');
  String get editProfile => translate('edit_profile');
  String get fullName => translate('full_name');
  String get email => translate('email');
  String get phone => translate('phone');
  String get address => translate('address');
  String get gender => translate('gender');
  String get dateOfBirth => translate('date_of_birth');
  String get totalPoints => translate('total_points');
  String get studyTime => translate('study_time');
  String get achievements => translate('achievements');

  // Lesson
  String get lessonList => translate('lesson_list');
  String get lesson => translate('lesson');
  String get startLesson => translate('start_lesson');
  String get continueLesson => translate('continue_lesson');
  String get lessonCompleted => translate('lesson_completed');
  String get lessonInProgress => translate('lesson_in_progress');

  // Vocabulary
  String get vocabulary => translate('vocabulary');
  String get vocabularyList => translate('vocabulary_list');
  String get meaning => translate('meaning');
  String get pronunciation => translate('pronunciation');
  String get example => translate('example');
  String get addToNotebook => translate('add_to_notebook');

  // Kanji
  String get kanji => translate('kanji');
  String get kanjiList => translate('kanji_list');
  String get strokeCount => translate('stroke_count');
  String get onyomi => translate('onyomi');
  String get kunyomi => translate('kunyomi');

  // Exercise
  String get exercise => translate('exercise');
  String get exerciseList => translate('exercise_list');
  String get startExercise => translate('start_exercise');
  String get submit => translate('submit');
  String get result => translate('result');
  String get correct => translate('correct');
  String get incorrect => translate('incorrect');
  String get score => translate('score');

  // News
  String get news => translate('news');
  String get readMore => translate('read_more');

  // Notebook
  String get notebook => translate('notebook');
  String get myNotes => translate('my_notes');
  String get addNote => translate('add_note');

  // Auth
  String get login => translate('login');
  String get register => translate('register');
  String get username => translate('username');
  String get password => translate('password');
  String get confirmPassword => translate('confirm_password');
  String get forgotPassword => translate('forgot_password');

  // Help Screen
  String get help => translate('help');
  String get helpTitle => translate('help_title');
  String get helpSubtitle => translate('help_subtitle');
  String get sendEmail => translate('send_email');
  String get contactDirectly => translate('contact_directly');
  String get reportBug => translate('report_bug');
  String get sendBugReport => translate('send_bug_report');
  String get feedback => translate('feedback');
  String get suggestFeature => translate('suggest_feature');
  String get about => translate('about');
  String get versionInfo => translate('version_info');
  String get faq => translate('faq');
  String get stillNeedHelp => translate('still_need_help');
  String get supportTeamReady => translate('support_team_ready');
  String get contactSupport => translate('contact_support');

  // Learning History Screen
  String get learningHistory => translate('learning_history');
  String get overview => translate('overview');
  String get activity => translate('activity');
  String get statistics => translate('statistics');
  String get consecutiveDaysShort => translate('consecutive_days_short');
  String get record => translate('record');
  String get weeklyCalendar => translate('weekly_calendar');
  String get recentAchievements => translate('recent_achievements');
  String get all => translate('all');
  String get noActivity => translate('no_activity');
  String get startLearning => translate('start_learning');
  String get today => translate('today');
  String get thisWeek => translate('this_week');
  String get total => translate('total');
  String get dailyActivity => translate('daily_activity');
  String get learningDistribution => translate('learning_distribution');
  String get grammar => translate('grammar');

  // Change Password
  String get changePassword => translate('change_password');
  String get currentPassword => translate('current_password');
  String get newPassword => translate('new_password');
  String get confirmNewPassword => translate('confirm_new_password');
  String get passwordChanged => translate('password_changed');
  String get passwordMinLength => translate('password_min_length');
  String get passwordsNotMatch => translate('passwords_not_match');
  String get oldPasswordIncorrect => translate('old_password_incorrect');
  String get selectLanguage => translate('select_language');
  String get languageChanged => translate('language_changed');

  // Languages
  String get vietnamese => translate('vietnamese');
  String get english => translate('english');
  String get japanese => translate('japanese');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['vi', 'en', 'ja'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}

final List<FAQItem> helpFaqItems = [
  FAQItem(
    question: 'Làm thế nào để bắt đầu học tiếng Nhật?',
    answer:
        'Bạn có thể bắt đầu từ mục "Bài học" trên trang chủ. Chúng tôi khuyên bạn nên học từ N5 (cơ bản) trước, sau đó tiến lên các cấp độ cao hơn. Mỗi ngày dành 15-30 phút học sẽ giúp bạn tiến bộ nhanh chóng.',
  ),
  FAQItem(
    question: 'Streak (chuỗi học) hoạt động như thế nào?',
    answer:
        'Streak là số ngày liên tiếp bạn học tập. Mỗi khi bạn hoàn thành ít nhất 1 hoạt động học tập trong ngày (học bài, làm bài tập, ôn tập flashcard...), streak sẽ được duy trì. Nếu bỏ lỡ 1 ngày, streak sẽ reset về 0.',
  ),
  FAQItem(
    question: 'XP là gì và tích lũy XP như thế nào?',
    answer:
        'XP (Experience Points) là điểm kinh nghiệm bạn nhận được khi học tập. Bạn nhận XP khi:\n• Hoàn thành bài học: 10-50 XP\n• Làm bài tập đúng: 5-20 XP/câu\n• Duy trì streak: 10 XP/ngày\n• Đạt thành tích: 50-500 XP\n\nXP giúp bạn lên level và mở khóa các thành tích mới.',
  ),
  FAQItem(
    question: 'Làm sao để ôn tập từ vựng hiệu quả?',
    answer:
        'Sử dụng tính năng Flashcard với hệ thống SRS (Spaced Repetition System). Hệ thống sẽ tự động nhắc bạn ôn tập những từ sắp quên. Ngoài ra, bạn có thể thêm từ vào Sổ tay cá nhân để ôn tập bất cứ lúc nào.',
  ),
  FAQItem(
    question: 'Tôi có thể học offline không?',
    answer:
        'Có! Vào Cài đặt > Chế độ Offline để tải xuống các bài học. Nội dung đã tải sẽ có sẵn khi không có mạng. Lưu ý: Một số tính năng như streak và bảng xếp hạng yêu cầu kết nối internet.',
  ),
  FAQItem(
    question: 'Làm thế nào để chuẩn bị cho kỳ thi JLPT?',
    answer:
        'Vào mục JLPT trên trang chủ để:\n• Làm đề thi thử các năm\n• Ôn tập theo từng phần (Từ vựng, Ngữ pháp, Đọc hiểu, Nghe)\n• Xem thống kê điểm yếu cần cải thiện\n\nChúng tôi khuyên bạn nên bắt đầu luyện thi ít nhất 3-6 tháng trước kỳ thi.',
  ),
  FAQItem(
    question: 'Làm sao để tham gia nhóm học tập?',
    answer:
        'Vào mục "Nhóm học" để tạo hoặc tham gia nhóm. Bạn có thể:\n• Tạo nhóm riêng và mời bạn bè\n• Tìm và tham gia nhóm công khai\n• Chat, chia sẻ tài liệu với thành viên\n• Thi đua với nhau trên bảng xếp hạng nhóm',
  ),
  FAQItem(
    question: 'Tôi gặp lỗi khi sử dụng ứng dụng, phải làm sao?',
    answer:
        'Thử các bước sau:\n1. Đóng và mở lại ứng dụng\n2. Kiểm tra kết nối mạng\n3. Cập nhật ứng dụng lên phiên bản mới nhất\n4. Xóa cache ứng dụng trong Cài đặt thiết bị\n\nNếu vẫn gặp lỗi, hãy liên hệ với chúng tôi qua mục "Liên hệ hỗ trợ" bên dưới.',
  ),
];

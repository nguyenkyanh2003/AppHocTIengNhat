/// Cài đặt của người dùng lưu ở backend (`/settings`).
///
/// Giao diện sáng/tối do máy quyết định (`ThemeProvider`); [theme] ở đây chỉ là
/// bản gửi lên server khi người dùng bấm Lưu, không được đọc ngược để đè lựa chọn
/// trên máy.
class UserSettings {
  const UserSettings({
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrateEnabled = true,
    this.language = 'vi',
    this.theme = 'light',
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        vibrateEnabled: json['vibrateEnabled'] as bool? ?? true,
        language: json['language'] as String? ?? 'vi',
        theme: json['theme'] as String? ?? 'light',
      );

  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrateEnabled;
  final String language;
  final String theme;

  UserSettings copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrateEnabled,
    String? language,
    String? theme,
  }) =>
      UserSettings(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        vibrateEnabled: vibrateEnabled ?? this.vibrateEnabled,
        language: language ?? this.language,
        theme: theme ?? this.theme,
      );

  Map<String, dynamic> toJson() => {
        'notificationsEnabled': notificationsEnabled,
        'soundEnabled': soundEnabled,
        'vibrateEnabled': vibrateEnabled,
        'language': language,
        'theme': theme,
      };
}

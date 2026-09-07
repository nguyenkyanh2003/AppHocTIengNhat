class AppNotification {
  final String id;
  final String nguoiHocId;
  final String tieuDe;
  final String noiDung;
  final String
      loai; // 'achievement', 'lesson', 'exercise', 'group', 'streak', 'message'
  final String trangThai; // 'DaDoc', 'ChuaDoc'
  final String? thamChieuId; // ID của resource liên quan (exercise, kanji, etc)
  final String? thamChieuLoai; // Loại resource liên quan
  final String ngayTao;
  final String? ngayCapNhat;

  AppNotification({
    required this.id,
    required this.nguoiHocId,
    required this.tieuDe,
    required this.noiDung,
    required this.loai,
    required this.trangThai,
    this.thamChieuId,
    this.thamChieuLoai,
    required this.ngayTao,
    this.ngayCapNhat,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? '',
      nguoiHocId: json['NguoiHocID'] ?? '',
      tieuDe: json['TieuDe'] ?? '',
      noiDung: json['NoiDung'] ?? '',
      loai: json['Loai'] ?? 'message',
      trangThai: json['TrangThai'] ?? 'ChuaDoc',
      thamChieuId: json['ThamChieuID'],
      thamChieuLoai: json['ThamChieuLoai'],
      ngayTao: json['NgayTao'] ?? '',
      ngayCapNhat: json['NgayCapNhat'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'NguoiHocID': nguoiHocId,
      'TieuDe': tieuDe,
      'NoiDung': noiDung,
      'Loai': loai,
      'TrangThai': trangThai,
      'ThamChieuID': thamChieuId,
      'ThamChieuLoai': thamChieuLoai,
      'NgayTao': ngayTao,
      'NgayCapNhat': ngayCapNhat,
    };
  }
}

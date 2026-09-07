import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> saveBytes({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Chọn nơi lưu tệp',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: [fileName.split('.').last],
    bytes: Platform.isAndroid || Platform.isIOS ? bytes : null,
  );
  if (path == null) return false;
  if (!Platform.isAndroid && !Platform.isIOS) {
    await File(path).writeAsBytes(bytes, flush: true);
  }
  return true;
}

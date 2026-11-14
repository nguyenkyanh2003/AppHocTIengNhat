import 'package:flutter/material.dart';

/// Hỏi lại khi người học bấm nộp lúc còn câu chưa trả lời.
Future<bool> confirmPartialSubmit(BuildContext context, {required int answered, required int total}) async {
  final submit = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Chưa hoàn thành'),
      content: Text('Bạn mới trả lời $answered/$total câu.\nBạn có muốn nộp bài không?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Tiếp tục')),
        ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Nộp bài')),
      ],
    ),
  );
  return submit ?? false;
}

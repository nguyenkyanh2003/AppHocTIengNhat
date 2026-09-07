import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// Controller to start/stop recording from parent widgets.
class AudioRecorderController {
  _AudioRecorderWidgetState? _state;

  void _attach(_AudioRecorderWidgetState state) => _state = state;
  void _detach() => _state = null;

  Future<void> start() => _state?._startRecordingInternal() ?? Future.value();
  Future<void> stop() => _state?._stopRecording() ?? Future.value();
  Future<void> cancel() => _state?._cancelRecording() ?? Future.value();
}

class AudioRecorderWidget extends StatefulWidget {
  final Function(String audioPath) onAudioRecorded;
  final AudioRecorderController? controller;

  const AudioRecorderWidget({
    Key? key,
    required this.onAudioRecorded,
    this.controller,
  }) : super(key: key);

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  late final AudioRecorder _recorder;
  bool isRecording = false;
  String? recordingPath;
  int recordingDuration = 0;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecordingInternal() async {
    try {
      if (isRecording) return;
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ghi âm chưa hỗ trợ trên web')),
          );
        }
        return;
      }
      if (await _recorder.hasPermission()) {
        final filePath = await _createTempPath();
        if (filePath == null) {
          // Shouldn't happen on supported platforms, but guard to satisfy null-safety.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể tạo file ghi âm tạm')),
            );
          }
          return;
        }
        await _recorder.start(
          const RecordConfig(),
          path: filePath,
        );
        setState(() {
          isRecording = true;
          recordingDuration = 0;
        });

        // Update duration every second
        Future.delayed(const Duration(seconds: 1), _updateDuration);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cần quyền truy cập microphone')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi ghi âm: $e')),
        );
      }
    }
  }

  void _updateDuration() {
    if (mounted && isRecording) {
      setState(() {
        recordingDuration++;
      });
      if (recordingDuration < 300) {
        // Max 5 minutes
        Future.delayed(const Duration(seconds: 1), _updateDuration);
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (path != null && mounted) {
        setState(() {
          isRecording = false;
          recordingPath = path;
        });
        widget.onAudioRecorded(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu ghi âm: $e')),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _recorder.stop();
      if (recordingPath != null) {
        final file = File(recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      if (mounted) {
        setState(() {
          isRecording = false;
          recordingPath = null;
          recordingDuration = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<String?> _createTempPath() async {
    if (kIsWeb) return null;
    final dir = await getTemporaryDirectory();
    return '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!isRecording) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border(
          top: BorderSide(color: Colors.red[200]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Đang ghi âm: ${_formatDuration(recordingDuration)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: _cancelRecording,
            tooltip: 'Hủy ghi âm',
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle, color: Colors.red),
            onPressed: _stopRecording,
            tooltip: 'Kết thúc ghi âm',
          ),
        ],
      ),
    );
  }
}

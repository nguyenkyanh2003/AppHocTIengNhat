import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../core/audio/audio_source_resolver.dart';
import '../providers/jlpt_exam_provider.dart';
import '../models/jlpt_models.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../widgets/jlpt_audio_bar.dart';
import '../widgets/jlpt_exam_sections.dart';
import '../widgets/jlpt_result_sheet.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';

class JLPTExamScreen extends StatefulWidget {
  final String examId;
  final String title;
  const JLPTExamScreen({super.key, required this.examId, required this.title});

  @override
  State<JLPTExamScreen> createState() => _JLPTExamScreenState();
}

class _JLPTExamScreenState extends State<JLPTExamScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Source? _cachedAudioSource;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JLPTExamProvider>().loadExam(widget.examId);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _getFullAudioUrl(String audioPath) {
    final host = ApiClient.baseUrl.replaceFirst('/api', '');
    if (audioPath.startsWith('http')) return audioPath;
    return '$host$audioPath';
  }

  /// Phát audio của câu hỏi.
  ///
  /// Nguồn phát do adapter theo nền tảng quyết định: trình duyệt phát thẳng từ
  /// URL, nền tảng có hệ thống tệp thì tải về thư mục tạm rồi phát từ tệp. Màn
  /// hình này không được biết `File` hay `DeviceFileSource` là gì.
  Future<void> _playAudio(String audioPath, String fileName) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        return;
      }

      setState(() => _isLoading = true);

      final fullUrl = _getFullAudioUrl(audioPath);
      debugPrint('Audio URL: $fullUrl');

      _cachedAudioSource ??= await resolveAudioSource(
        url: fullUrl,
        fileName: fileName,
      );

      await _audioPlayer.stop();
      await _audioPlayer.setSource(_cachedAudioSource!);
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Audio error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Không phát được file nghe: ${userMessageOf(e)}'),
              backgroundColor: AppColors.errorStrong),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.title,
      actions: [
        Consumer<JLPTExamProvider>(
          builder: (context, p, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_formatTime(p.secondsLeft)),
            ),
          ),
        )
      ],
      body: ContentWidthLimit(
        child: Consumer<JLPTExamProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading || provider.exam == null) {
              return AsyncView<JLPTExamDetail>(
                state: ViewState.detail(
                  isLoading: provider.isLoading,
                  error: provider.error,
                  value: provider.exam,
                ),
                onRetry: () => provider.loadExam(widget.examId),
                builder: (context, _) => const SizedBox.shrink(),
              );
            }
            final exam = provider.exam!;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      ...buildJlptSection(context, 'Từ vựng (文字・語彙)',
                          exam.mojiGoi, 'moji', provider,
                          startIndex: 0),
                      ...buildJlptSection(context, 'Ngữ pháp (文法)', exam.bunpou,
                          'bunpou', provider,
                          startIndex: exam.mojiGoi.length),
                      ...buildJlptGroupSection(context, 'Đọc hiểu (読解)',
                          exam.dokkai, 'dokkai', provider,
                          startIndex: exam.mojiGoi.length + exam.bunpou.length,
                          audioBar: _audioBar),
                      ...buildJlptGroupSection(context, 'Nghe hiểu (聴解)',
                          exam.choukai, 'choukai', provider,
                          startIndex: exam.mojiGoi.length +
                              exam.bunpou.length +
                              _countGroupQuestions(exam.dokkai),
                          audioBar: _audioBar),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ElevatedButton(
                      onPressed: provider.isSubmitting || provider.hasSubmitted
                          ? null
                          : () async {
                              await provider.submit(widget.examId);
                              if (!context.mounted) return;
                              if (provider.result != null) {
                                showJlptResultSheet(context, provider);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Nộp bài thất bại, vui lòng thử lại.')),
                                );
                              }
                            },
                      child: provider.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(provider.hasSubmitted ? 'Đã nộp' : 'Nộp bài'),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  int _countGroupQuestions(List<JLPTGroupQuestion> groups) {
    return groups.fold(0, (sum, g) => sum + g.questions.length);
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  Widget _audioBar(String audioPath, String audioName) => JlptAudioBar(
      audioPath: audioPath,
      audioName: audioName,
      audioPlayer: _audioPlayer,
      isPlaying: _isPlaying,
      isLoading: _isLoading,
      duration: _duration,
      position: _position,
      playAudio: _playAudio);
}

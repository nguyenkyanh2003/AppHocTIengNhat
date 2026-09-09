import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../core/audio/audio_source_resolver.dart';
import '../providers/jlpt_exam_provider.dart';
import '../models/jlpt_models.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';

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
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  Widget _buildAudioPlayer(String audioPath, String audioName) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.audiotrack, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  audioName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: _position.inSeconds.toDouble(),
              max: _duration.inSeconds.toDouble().clamp(1, double.infinity),
              onChanged: (value) async {
                await _audioPlayer.seek(Duration(seconds: value.toInt()));
              },
              activeColor: Colors.blue,
              inactiveColor: Colors.blue.shade100,
            ),
          ),
          // Time display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position),
                    style: const TextStyle(fontSize: 12)),
                Text(_formatDuration(_duration),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Play/Pause button
          Center(
            child: GestureDetector(
              onTap: _isLoading ? null : () => _playAudio(audioPath, audioName),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                decoration: BoxDecoration(
                  color: _isLoading
                      ? Colors.grey
                      : (_isPlaying ? Colors.orange : Colors.blue),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    else
                      Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _isLoading
                          ? 'Đang tải...'
                          : (_isPlaying ? 'Tạm dừng' : 'Phát audio'),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
              return const Center(child: CircularProgressIndicator());
            }
            final exam = provider.exam!;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      ..._buildSection(
                          'Từ vựng (文字・語彙)', exam.mojiGoi, 'moji', provider,
                          startIndex: 0),
                      ..._buildSection(
                          'Ngữ pháp (文法)', exam.bunpou, 'bunpou', provider,
                          startIndex: exam.mojiGoi.length),
                      ..._buildGroupSection(
                          'Đọc hiểu (読解)', exam.dokkai, 'dokkai', provider,
                          startIndex: exam.mojiGoi.length + exam.bunpou.length),
                      ..._buildGroupSection(
                          'Nghe hiểu (聴解)', exam.choukai, 'choukai', provider,
                          startIndex: exam.mojiGoi.length +
                              exam.bunpou.length +
                              _countGroupQuestions(exam.dokkai)),
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
                                _showResultSheet(context, provider);
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

  List<Widget> _buildSection(String title, List<JLPTQuestion> questions,
      String keyPrefix, JLPTExamProvider provider,
      {required int startIndex}) {
    if (questions.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      ...questions.asMap().entries.map((entry) {
        final idx = entry.key;
        final q = entry.value;
        final key = '$keyPrefix-$idx';
        final selected = provider.answers[key];
        final solutionIdx = startIndex + idx;
        final hasResult =
            provider.result != null && provider.solutions.length > solutionIdx;
        final solution = hasResult ? provider.solutions[solutionIdx] : null;
        final correctIdx = solution?.correctAnswer;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${idx + 1}. ${q.questionText}'),
                const SizedBox(height: 8),
                ...q.choices.asMap().entries.map((c) {
                  final cid = c.key;
                  final isUserChoice = selected == cid;
                  final isCorrectChoice = hasResult && correctIdx == cid;
                  Color? fill;
                  if (hasResult) {
                    if (isCorrectChoice) {
                      fill = Colors.green.withValues(alpha: 0.12);
                    } else if (isUserChoice) {
                      fill = Colors.red.withValues(alpha: 0.12);
                    }
                  }
                  return RadioListTile<int>(
                    value: cid,
                    groupValue: selected,
                    onChanged: provider.hasSubmitted
                        ? null
                        : (v) => provider.setAnswer(key, v ?? 0),
                    title: Text(c.value),
                    activeColor:
                        hasResult && isCorrectChoice ? Colors.green : null,
                    tileColor: fill,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    secondary: hasResult
                        ? Icon(
                            isCorrectChoice
                                ? Icons.check_circle_outline
                                : (isUserChoice
                                    ? Icons.cancel_outlined
                                    : Icons.radio_button_unchecked),
                            color: isCorrectChoice
                                ? Colors.green
                                : (isUserChoice ? Colors.red : Colors.grey),
                          )
                        : null,
                  );
                }).toList(),
                if (hasResult && solution?.explanation != null) ...[
                  const Divider(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 20, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          solution!.explanation!,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    ];
  }

  List<Widget> _buildGroupSection(String title, List<JLPTGroupQuestion> groups,
      String keyPrefix, JLPTExamProvider provider,
      {required int startIndex}) {
    if (groups.isEmpty) return [];

    final widgets = <Widget>[];

    // Tìm file audio chung cho section (chỉ lấy từ group đầu tiên có audio)
    String? sectionAudio;
    String? sectionAudioName;
    for (var g in groups) {
      if (g.groupAudio != null && g.groupAudio!.isNotEmpty) {
        sectionAudio = g.groupAudio;
        sectionAudioName = g.groupAudio!.split('/').last;
        break;
      }
    }

    // Header với audio player widget (nếu có)
    widgets.add(
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (sectionAudio != null)
              _buildAudioPlayer(sectionAudio, sectionAudioName!),
          ],
        ),
      ),
    );

    int questionCounter = startIndex;

    for (var groupIdx = 0; groupIdx < groups.length; groupIdx++) {
      final group = groups[groupIdx];

      // Hiển thị nội dung nhóm (bài đọc) - KHÔNG hiện audio ở đây
      widgets.add(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mondai ${group.mondai}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (group.groupContent != null &&
                    group.groupContent!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    group.groupContent!,
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ],
              ],
            ),
          ),
        ),
      );

      // Hiển thị các câu hỏi trong nhóm
      for (var qIdx = 0; qIdx < group.questions.length; qIdx++) {
        final q = group.questions[qIdx];
        final key = '$keyPrefix-$groupIdx-$qIdx';
        final selected = provider.answers[key];
        final solutionIdx = questionCounter;
        final hasResult =
            provider.result != null && provider.solutions.length > solutionIdx;
        final solution = hasResult ? provider.solutions[solutionIdx] : null;
        final correctIdx = solution?.correctAnswer;

        widgets.add(
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.questionText.isNotEmpty
                      ? q.questionText
                      : 'Câu ${qIdx + 1}'),
                  const SizedBox(height: 8),
                  ...q.choices.asMap().entries.map((c) {
                    final cid = c.key;
                    final isUserChoice = selected == cid;
                    final isCorrectChoice = hasResult && correctIdx == cid;
                    Color? fill;
                    if (hasResult) {
                      if (isCorrectChoice) {
                        fill = Colors.green.withValues(alpha: 0.12);
                      } else if (isUserChoice) {
                        fill = Colors.red.withValues(alpha: 0.12);
                      }
                    }
                    return RadioListTile<int>(
                      value: cid,
                      groupValue: selected,
                      onChanged: provider.hasSubmitted
                          ? null
                          : (v) => provider.setAnswer(key, v ?? 0),
                      title: Text(c.value),
                      activeColor:
                          hasResult && isCorrectChoice ? Colors.green : null,
                      tileColor: fill,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      secondary: hasResult
                          ? Icon(
                              isCorrectChoice
                                  ? Icons.check_circle_outline
                                  : (isUserChoice
                                      ? Icons.cancel_outlined
                                      : Icons.radio_button_unchecked),
                              color: isCorrectChoice
                                  ? Colors.green
                                  : (isUserChoice ? Colors.red : Colors.grey),
                            )
                          : null,
                    );
                  }).toList(),
                  if (hasResult && solution?.explanation != null) ...[
                    const Divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 20, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            solution!.explanation!,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );

        questionCounter++;
      }
    }

    return widgets;
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  void _showResultSheet(BuildContext context, JLPTExamProvider provider) {
    final result = provider.result!;
    final isPassed = result.passed;
    final color = isPassed ? Colors.green : Colors.red;
    final icon = isPassed ? Icons.check_circle : Icons.cancel;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: 600,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Icon(icon, size: 64, color: color),
                      const SizedBox(height: 8),
                      Text(
                        isPassed ? 'Chúc mừng!' : 'Cố gắng lên',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: color),
                      ),
                      Text(
                        'Điểm: ${result.totalScore} / 100',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildScoreItem('Từ vựng', result.vocabScore),
                _buildScoreItem('Ngữ pháp', result.grammarScore),
                _buildScoreItem('Đọc hiểu', result.readingScore),
                _buildScoreItem('Nghe hiểu', result.listeningScore),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem(String title, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text('$score',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

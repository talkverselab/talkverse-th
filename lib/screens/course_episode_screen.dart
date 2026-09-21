import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/course_service.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';

/// 코스 스크립트 1편(8턴) — 채팅 버블. 화자 성별에 맞는 음성으로 읽는다.
class CourseEpisodeScreen extends StatefulWidget {
  final CourseScript script;
  const CourseEpisodeScreen({super.key, required this.script});

  @override
  State<CourseEpisodeScreen> createState() => _CourseEpisodeScreenState();
}

class _CourseEpisodeScreenState extends State<CourseEpisodeScreen> {
  int _playing = -1;

  CourseScript get s => widget.script;
  String _gender(String speaker) => s.voices[speaker] == 'm' ? 'male' : 'female';

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  void _playAll() {
    if (TtsService.instance.isSequencePlaying) {
      TtsService.instance.stopSequence();
      setState(() => _playing = -1);
      return;
    }
    TtsService.instance.speakSequence(
      [for (final t in s.turns) (text: t.th, gender: _gender(t.speaker))],
      onLine: (i) {
        if (mounted) setState(() => _playing = i);
      },
    );
  }

  Future<void> _finish() async {
    await CourseService.instance.markDone(s);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final seqOn = _playing >= 0;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(s.title, overflow: TextOverflow.ellipsis),
        actions: [
          const KoReadingToggleAction(),
          IconButton(
            tooltip: seqOn ? tr('전체 재생 정지') : tr('전체 재생'),
            icon: Icon(seqOn ? Icons.stop_circle_outlined : Icons.play_circle_outline),
            onPressed: _playAll,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 24 + bottomInset(context)),
        children: [
          if (s.recap.isNotEmpty) _card(tr('지난 이야기'), s.recap, AppColors.creamDeep),
          _card('${s.emoji}  ${'🌶' * s.heat}', s.hook, Colors.white),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
            child: Text('A · ${s.charA}\nB · ${s.charB}',
                style: const TextStyle(fontSize: 11.5, height: 1.5, color: AppColors.khramLight)),
          ),
          for (var i = 0; i < s.turns.length; i++) _bubble(s.turns[i], i == _playing),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _finish,
            icon: const Icon(Icons.check),
            label: Text(s.next != null ? tr('완료 · 다음 편 열기') : tr('완료하고 닫기')),
          ),
        ],
      ),
    );
  }

  Widget _card(String head, String body, Color bg) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, border: Border.all(color: AppColors.thong, width: 0.6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(head,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: AppColors.kluayMaiDeep)),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.khram)),
          ],
        ),
      );

  Widget _bubble(CourseTurn t, bool playing) {
    final isA = t.speaker == 'A';
    final fg = isA ? Colors.white : AppColors.khram;
    return Align(
      alignment: isA ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.84),
        decoration: BoxDecoration(
          color: isA ? AppColors.kluayMaiDeep : Colors.white,
          border: Border.all(
            color: playing ? AppColors.khram : AppColors.thongDeep,
            width: playing ? 2.4 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    t.th,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: fg,
                      height: 1.4,
                      fontFamilyFallback: AppTheme.fontFallback,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => TtsService.instance.speakAs(t.th, gender: _gender(t.speaker)),
                  child: Icon(Icons.volume_up, size: 16, color: fg.withValues(alpha: 0.85)),
                ),
              ],
            ),
            const SizedBox(height: 3),
            KoReadingText(t.roman, th: t.th, style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.85))),
            const SizedBox(height: 4),
            Container(height: 0.5, color: fg.withValues(alpha: 0.3)),
            const SizedBox(height: 4),
            Text(t.ko, style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.95))),
            if (t.note != null && t.note!.isNotEmpty) ...[
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: isA ? 0.18 : 0.55),
                  border: Border.all(color: fg.withValues(alpha: 0.35), width: 0.5),
                ),
                child: Text('💡 ${t.note}',
                    style: TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.9), height: 1.3)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/content_store.dart';
import '../services/dev_notes.dart';
import '../widgets/thai_decor.dart';
import 'grammar_lesson_screen.dart';
import 'grammar_topic_screen.dart';

/// 문법 메뉴 — 초급 문법 코스 16과 목록. 기초 교재들이 공통으로 가르치는 순서.
/// 1~15과는 `lessons.json`, 마지막 「어말조사」는 기존 화면(`sfp.json`).
class GrammarHubScreen extends StatefulWidget {
  const GrammarHubScreen({super.key});

  @override
  State<GrammarHubScreen> createState() => _GrammarHubScreenState();
}

class _GrammarHubScreenState extends State<GrammarHubScreen> {
  List<GrammarLesson> _lessons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await ContentStore.instance.loadString('assets/data/grammar/lessons.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final list = (data['lessons'] as List?) ?? [];
    if (!mounted) return;
    setState(() {
      _lessons = list.whereType<Map>().map((m) => GrammarLesson.fromJson(m.cast<String, dynamic>())).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFAD1457);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('초급 문법 코스'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            const Text('ไวยากรณ์', style: TextStyle(fontSize: 10, letterSpacing: 2)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.kluayMai))
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
              children: [
                Text(tr('기초 교재들이 공통으로 가르치는 순서예요. 위에서부터 차례로 보면 초급이 끝나요.'),
                    style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.khramLight)),
                const LaiThaiDivider(height: 14),
                for (var i = 0; i < _lessons.length; i++) ...[
                  _LessonTile(
                    number: i + 1,
                    emoji: _lessons[i].emoji,
                    title: _lessons[i].title,
                    sub: _lessons[i].sub,
                    count: _lessons[i].items.length,
                    accent: accent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GrammarTopicScreen(lesson: _lessons[i], index: i)),
                    ).then((_) => DevNotes.instance.clearContext('grammar')),
                  ),
                  const SizedBox(height: 8),
                ],
                _LessonTile(
                  number: _lessons.length + 1,
                  emoji: '🗣',
                  title: tr('문장 끝 어조사'),
                  sub: 'นะ · สิ · เถอะ · ล่ะ · หรอก · จัง',
                  count: 14,
                  accent: accent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrammarLessonScreen())),
                ),
              ],
            ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final int number;
  final String emoji;
  final String title;
  final String sub;
  final int count;
  final Color accent;
  final VoidCallback onTap;
  const _LessonTile({
    required this.number,
    required this.emoji,
    required this.title,
    required this.sub,
    required this.count,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ThaiCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent, width: 1),
                ),
                child: Text('$number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$emoji $title',
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.khram)),
                    const SizedBox(height: 2),
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.khramLight, fontFamilyFallback: AppTheme.fontFallback)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(trf('{0}개', [count]), style: const TextStyle(fontSize: 11, color: AppColors.khramLight)),
              const Icon(Icons.chevron_right, color: AppColors.khramLight),
            ],
          ),
        ),
      ),
    );
  }
}

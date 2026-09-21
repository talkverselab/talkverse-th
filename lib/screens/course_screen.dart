import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/course_service.dart';
import 'course_episode_screen.dart';
import 'course_onboarding_screen.dart';

/// 「내 코스」 — 질문 답에 맞춰 늘어놓은 스크립트 목록. 앞 회차를 끝내야 다음 회차가 열린다.
class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final _svc = CourseService.instance;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _svc.ensureLoaded();
    } catch (e) {
      _error = '$e';
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (_error == null && !_svc.hasAnswers) _ask();
  }

  Future<void> _ask() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseOnboardingScreen()));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(tr('내 코스')),
        actions: [
          if (!_loading && _svc.hasAnswers)
            IconButton(tooltip: tr('질문 다시 하기'), icon: const Icon(Icons.tune), onPressed: _ask),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(trf('코스를 불러오지 못했어요\n{0}', [_error]), textAlign: TextAlign.center))
              : !_svc.hasAnswers
                  ? Center(
                      child: FilledButton(onPressed: _ask, child: Text(tr('내 코스 만들기'))),
                    )
                  : _list(),
    );
  }

  Widget _list() {
    final items = _svc.playlist();
    final doneCount = items.where((e) => _svc.isDone(e.$2)).length;
    final drive = _svc.driveLabels[_svc.topDrive()] ?? '';
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(14, 12, 14, 24 + bottomInset(context)),
      itemCount: items.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.creamDeep,
              border: Border.all(color: AppColors.thong, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trf('내 답에 맞춘 {0}편', [items.length]),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.khram)),
                const SizedBox(height: 4),
                Text('${tr('속마음')} · $drive   ${trf('완료 {0} / {1}', [doneCount, items.length])}',
                    style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
              ],
            ),
          );
        }
        final s = items[i - 1].$2;
        final open = _svc.isUnlocked(s);
        final done = _svc.isDone(s);
        return Opacity(
          opacity: open ? 1 : 0.5,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: done ? AppColors.morakot : AppColors.thong, width: done ? 1.4 : 0.6),
            ),
            child: ListTile(
              onTap: () async {
                if (!open) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(tr('앞 편을 먼저 끝내세요'))));
                  return;
                }
                await Navigator.push(
                    context, MaterialPageRoute(builder: (_) => CourseEpisodeScreen(script: s)));
                if (mounted) setState(() {});
              },
              leading: Text(s.emoji, style: const TextStyle(fontSize: 26)),
              title: Text(
                s.seriesLen > 1 ? '${s.title}  ·  ${trf('제{0}편', [s.ep])}' : s.title,
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.khram, fontSize: 14.5),
              ),
              subtitle: Text('${'🌶' * s.heat}  ${s.hook}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.khramLight, height: 1.35)),
              trailing: Icon(
                done ? Icons.check_circle : (open ? Icons.chevron_right : Icons.lock_outline),
                color: done ? AppColors.morakot : AppColors.kluayMaiDeep,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }
}

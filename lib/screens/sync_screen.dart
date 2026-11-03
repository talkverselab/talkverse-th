import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/content_sync.dart';

/// 시작 로딩 화면 — 그림(장면 컷·단어 그림)을 기기에 내려받는 동안 진행률을 보이고, 끝나면 홈으로.
/// 「나중에」 = 앱을 먼저 열고 뒤에서 계속 받는다(사용자 지시 2026-11-04, 일본어앱 sync_screen.dart 이식).
class SyncScreen extends StatefulWidget {
  final Widget next;
  const SyncScreen({super.key, required this.next});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _left = false;

  @override
  void initState() {
    super.initState();
    ContentSync.instance.download().then((_) {
      if (mounted && !_left) _go();
    });
  }

  void _go() {
    _left = true;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, _, _) => widget.next,
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final (n, mb) = ContentSync.instance.estimate;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: ValueListenableBuilder<SyncProgress>(
                valueListenable: ContentSync.instance.progress,
                builder: (context, p, _) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(tr('태국어유니버스'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.kluayMaiDeep)),
                  const SizedBox(height: 28),
                  Text(tr('그림 준비 중'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.khram)),
                  const SizedBox(height: 8),
                  Text(tr('처음 한 번만 그림을 내려받습니다. 다음부터는 바로 열립니다.'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.khramLight, height: 1.5)),
                  const SizedBox(height: 22),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: p.total == 0 ? null : p.ratio, minHeight: 10, backgroundColor: AppColors.creamDeep, color: AppColors.kluayMai),
                  ),
                  const SizedBox(height: 10),
                  Text('${p.done} / ${p.total}   ·   ${trf('그림 {0}장 · 약 {1}MB', [n, mb])}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.thongDeep)),
                  const SizedBox(height: 28),
                  OutlinedButton(
                    onPressed: _go,
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.khram, side: const BorderSide(color: AppColors.thong), shape: const StadiumBorder()),
                    child: Text(tr('나중에 — 앱 먼저 열기(뒤에서 계속 받음)'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

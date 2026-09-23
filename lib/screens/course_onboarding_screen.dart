import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/course_service.dart';
import '../widgets/domain_chips.dart';

/// 코스 질문 — 한 화면에 질문 하나. 답은 저장되고, 같은 답이면 항상 같은 코스가 나온다.
class CourseOnboardingScreen extends StatefulWidget {
  const CourseOnboardingScreen({super.key});

  @override
  State<CourseOnboardingScreen> createState() => _CourseOnboardingScreenState();
}

class _CourseOnboardingScreenState extends State<CourseOnboardingScreen> {
  final _svc = CourseService.instance;
  late final Map<String, dynamic> _ans = {..._svc.answers};
  // 새로 생긴 질문만 비어 있으면 거기서부터(예: 레벨 질문 추가). 다 답했으면 처음부터.
  late int _i = () {
    final k = _svc.questions.indexWhere((q) => !_ans.containsKey(q.id));
    return k < 0 ? 0 : k;
  }();

  CourseQuestion get _q => _svc.questions[_i];

  bool get _answered {
    final a = _ans[_q.id];
    return _q.multi > 0 ? (a is List && a.isNotEmpty) : a is String;
  }

  void _pick(CourseOption o) {
    setState(() {
      if (_q.multi > 0) {
        final cur = [...((_ans[_q.id] as List?)?.cast<String>() ?? const <String>[])];
        if (cur.contains(o.id)) {
          cur.remove(o.id);
        } else {
          if (cur.length >= _q.multi) cur.removeAt(0);
          cur.add(o.id);
        }
        _ans[_q.id] = cur;
      } else {
        _ans[_q.id] = o.id;
      }
    });
    if (_q.multi == 0) _next();
  }

  Future<void> _next() async {
    if (!_answered) return;
    if (_i < _svc.questions.length - 1) {
      setState(() => _i++);
      return;
    }
    await _svc.saveAnswers(_ans);
    if (mounted) Navigator.pop(context);
  }

  bool _selected(CourseOption o) {
    final a = _ans[_q.id];
    return a is List ? a.contains(o.id) : a == o.id;
  }

  @override
  Widget build(BuildContext context) {
    final n = _svc.questions.length;
    final last = _i == n - 1;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(trf('질문 {0} / {1}', [_i + 1, n])),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _i == 0 ? Navigator.pop(context) : setState(() => _i--),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_i + 1) / n,
            minHeight: 3,
            backgroundColor: AppColors.creamDeep,
            color: AppColors.thong,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(18, 22, 18, 24 + bottomInset(context)),
        children: [
          Text(_q.section,
              style: const TextStyle(fontSize: 12, letterSpacing: 2, color: AppColors.kluayMaiDeep, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(_q.ask,
              style: const TextStyle(fontSize: 21, height: 1.35, fontWeight: FontWeight.w900, color: AppColors.khram)),
          if (_q.multi > 0) ...[
            const SizedBox(height: 6),
            Text(trf('{0}개까지 고를 수 있어요', [_q.multi]),
                style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
          ],
          const SizedBox(height: 18),
          if (_q.multi > 0)
            DomainChips(
              question: _q,
              selected: {...((_ans[_q.id] as List?)?.cast<String>() ?? const <String>[])},
              onToggle: (id) => _pick(_q.options.firstWhere((o) => o.id == id)),
            )
          else
          for (final o in _q.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _pick(o),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: _selected(o) ? AppColors.kluayMai.withValues(alpha: 0.12) : Colors.white,
                    border: Border.all(
                      color: _selected(o) ? AppColors.kluayMaiDeep : AppColors.thong,
                      width: _selected(o) ? 1.6 : 0.6,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (o.emoji != null) ...[
                        Text(o.emoji!, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.label,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.khram)),
                            if (o.sub != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(o.sub!,
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.khramLight)),
                              ),
                          ],
                        ),
                      ),
                      if (_selected(o)) const Icon(Icons.check, size: 18, color: AppColors.kluayMaiDeep),
                    ],
                  ),
                ),
              ),
            ),
          if (_q.multi > 0 || _answered) ...[
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _answered ? _next : null,
              child: Text(last ? tr('코스 만들기') : tr('다음')),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/course_service.dart';
import '../widgets/domain_chips.dart';

/// 학습 목적(도메인)만 다시 고르는 화면 — 코스 목록 머리와 프로필에서 언제든 연다.
/// 나머지 답(속마음·관계·말투)은 그대로 두고 도메인만 바꾼다.
class CourseDomainScreen extends StatefulWidget {
  const CourseDomainScreen({super.key});

  @override
  State<CourseDomainScreen> createState() => _CourseDomainScreenState();
}

class _CourseDomainScreenState extends State<CourseDomainScreen> {
  final _svc = CourseService.instance;
  late final CourseQuestion _q = _svc.domainQuestion;
  late final Set<String> _sel = {..._svc.domains};

  void _toggle(String id) {
    setState(() {
      if (_sel.contains(id)) {
        _sel.remove(id);
      } else {
        if (_sel.length >= _q.multi) _sel.remove(_sel.first);
        _sel.add(id);
      }
    });
  }

  Future<void> _save() async {
    await _svc.setDomains(_sel.toList());
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(tr('학습 목적'))),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              children: [
                Text(tr('무엇을 위해 배우나요?'),
                    style: const TextStyle(fontSize: 22, height: 1.3, fontWeight: FontWeight.w900, color: AppColors.khram)),
                const SizedBox(height: 8),
                Text(trf('{0}개까지 고르면 그 상황의 스크립트만 코스에 들어와요. 언제든 바꿀 수 있어요.', [_q.multi]),
                    style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.khramLight)),
                const SizedBox(height: 22),
                DomainChips(question: _q, selected: _sel, onToggle: _toggle),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(22, 8, 22, 18 + bottomInset(context)),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _sel.isEmpty ? null : _save,
                child: Text(tr('저장')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
  late String? _level = _svc.level;

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
    await _svc.saveAnswers({..._svc.answers, 'q3_domain': _sel.toList(), if (_level != null) 'q3b_level': _level});
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(tr('무대 · 레벨'))),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              children: [
                Text(tr('지금 태국어는?'),
                    style: const TextStyle(fontSize: 22, height: 1.3, fontWeight: FontWeight.w900, color: AppColors.khram)),
                const SizedBox(height: 12),
                for (final o in _svc.levelQuestion.options)
                  _LevelRow(option: o, selected: _level == o.id, onTap: () => setState(() => _level = o.id)),
                const SizedBox(height: 26),
                Text(tr('어디서 태국어를 쓰고 싶나요?'),
                    style: const TextStyle(fontSize: 22, height: 1.3, fontWeight: FontWeight.w900, color: AppColors.khram)),
                const SizedBox(height: 8),
                Text(trf('{0}개까지 고르면 그 무대의 스크립트만 코스에 들어와요. 언제든 바꿀 수 있어요.', [_q.multi]),
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
                onPressed: _sel.isEmpty || _level == null ? null : _save,
                child: Text(tr('저장')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  final CourseOption option;
  final bool selected;
  final VoidCallback onTap;
  const _LevelRow({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.kluayMaiDeep;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? accent : AppColors.thong, width: selected ? 1.5 : 0.8),
          ),
          child: Row(
            children: [
              Text(option.emoji ?? '', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.label,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: selected ? accent : AppColors.khram)),
                    if (option.sub != null)
                      Text(option.sub!, style: const TextStyle(fontSize: 11, color: AppColors.khramLight)),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

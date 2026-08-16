import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/memo_service.dart';

/// 문장별 메모 토글. 작은 아이콘 → 탭하면 입력 영역 펼침.
class MemoToggle extends StatefulWidget {
  final String patternId;
  final int idx;
  final String sentence;

  const MemoToggle({
    super.key,
    required this.patternId,
    required this.idx,
    required this.sentence,
  });

  @override
  State<MemoToggle> createState() => _MemoToggleState();
}

class _MemoToggleState extends State<MemoToggle> {
  bool _open = false;
  bool _loaded = false;
  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final v = await MemoService.instance.get(widget.patternId, widget.idx);
    if (mounted) {
      setState(() {
        _ctrl.text = v ?? '';
        _loaded = true;
      });
    }
  }

  Future<void> _save() async {
    await MemoService.instance.set(widget.patternId, widget.idx, _ctrl.text);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasMemo = _ctrl.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: GestureDetector(
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: [
                Icon(
                  _open
                      ? Icons.edit_note
                      : (hasMemo ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined),
                  size: 14,
                  color: hasMemo ? AppColors.kluayMai : AppColors.khramLight,
                ),
                const SizedBox(width: 4),
                Text(
                  hasMemo ? '메모 있음' : '메모',
                  style: TextStyle(
                    fontSize: 10,
                    color: hasMemo ? AppColors.kluayMai : AppColors.khramLight,
                    fontWeight: hasMemo ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                if (hasMemo) ...[
                  const SizedBox(width: 4),
                  Container(width: 4, height: 4, decoration: const BoxDecoration(
                    color: AppColors.kluayMai, shape: BoxShape.circle)),
                ],
                const Spacer(),
                Text(
                  _open ? '닫기 ▴' : '▾',
                  style: const TextStyle(fontSize: 10, color: AppColors.khramLight),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          child: _open
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    decoration: BoxDecoration(
                      color: AppColors.creamDeep,
                      border: Border.all(color: AppColors.thong.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _ctrl,
                          enabled: _loaded,
                          maxLines: null,
                          minLines: 2,
                          style: const TextStyle(fontSize: 12, color: AppColors.khram, height: 1.4),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            border: InputBorder.none,
                            hintText: '예: 이 문장 진짜야? 너무 짧음. 발음 더 듣고 싶음.',
                            hintStyle: TextStyle(
                              fontSize: 11,
                              color: AppColors.khramLight,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (_) => _save(),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

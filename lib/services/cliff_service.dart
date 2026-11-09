import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/embed_env.dart';

/// 절벽 기준(2026-11-07, 모든 언어앱 공통): 누적 55/60/70/80% 첫 순위 → R1~R4 끝, 80% 밖 R5, R5 는 2,000위에서 끊는다.
/// 숫자는 태국 드라마 50편 대사(26만 토큰)에서 산출(docs/CONTENT_STATUS.md). 경계는 여기 한 곳에만 둔다.
const int kWordCap = 2000;
const List<int> kWordCliffs = [109, 149, 295, 642];
const double kWordCapPct = 91.6;

/// 단어 → 절벽구간(R1~R5) 조회. 데이터 = assets/data/wordsets/th_cliff_words.json(`tools/vocab_pipeline/build_cliff_words.py`).
/// 2,000위 밖이면서 회화·단어장에 있는 단어는 'C'(회화) 로 본다. 절벽 단어·루트 단어·단어장이 같은 구간 표시를 쓴다.
class CliffService {
  CliffService._();
  static final CliffService instance = CliffService._();

  final Map<String, int> _rank = {};
  final Set<String> _conv = {};
  Future<void>? _loading;

  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final j = json.decode(await tvBundle.loadString('assets/data/wordsets/th_cliff_words.json')) as Map<String, dynamic>;
      for (final m in (j['words'] as List).cast<Map<String, dynamic>>()) {
        _rank[m['w'] as String] = m['r'] as int;
      }
      for (final m in (j['conv'] as List).cast<Map<String, dynamic>>()) {
        _conv.add(m['w'] as String);
      }
    } catch (_) {}
  }

  int? rankOf(String word) => _rank[word.trim()];

  /// 'R1'~'R5' · 'C'(2,000위 밖 회화 단어) · null(모름).
  String? regionOf(String word) {
    final r = _rank[word.trim()];
    if (r != null) return regionOfRank(r);
    return _conv.contains(word.trim()) ? 'C' : null;
  }

  static String regionOfRank(int rank) {
    for (var i = 0; i < kWordCliffs.length; i++) {
      if (rank <= kWordCliffs[i]) return 'R${i + 1}';
    }
    return 'R5';
  }

  static const regions = ['R1', 'R2', 'R3', 'R4', 'R5', 'C'];

  static Color colorOf(String region) => switch (region) {
        'R1' => AppColors.badges[8],
        'R2' => AppColors.badges[1],
        'R3' => AppColors.badges[4],
        'R4' => AppColors.morakot,
        'R5' => AppColors.thongDeep,
        _ => AppColors.thai,
      };

  static String labelOf(String region) => region == 'C' ? tr('회화') : region;

  /// 「R1 · 1-109」 식 구간 이름.
  static String rangeLabel(String region) {
    if (region == 'C') return tr('회화');
    final i = int.parse(region.substring(1)) - 1;
    final start = i == 0 ? 1 : kWordCliffs[i - 1] + 1;
    final end = i < kWordCliffs.length ? kWordCliffs[i] : kWordCap;
    return '$region · $start-$end';
  }
}

/// 구간 배지(R1~R5·회화) — 단어 타일·루트 카드 공용.
class RegionBadge extends StatelessWidget {
  final String region;
  final double fontSize;
  const RegionBadge(this.region, {super.key, this.fontSize = 9});

  @override
  Widget build(BuildContext context) {
    final c = CliffService.colorOf(region);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
      child: Text(CliffService.labelOf(region), style: TextStyle(color: AppColors.onFill(c), fontSize: fontSize, fontWeight: FontWeight.w800)),
    );
  }
}

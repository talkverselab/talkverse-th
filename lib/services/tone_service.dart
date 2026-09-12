import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import '../core/l10n.dart';

/// 음절 하나의 성조 정보.
class ToneSyllable {
  final String th;
  final String tone; // mid | low | falling | high | rising | '' (미분석)
  final String ko; // 한글 + 성조 기호
  final String ro; // 우리 로마자 ({..} = 장음, 악센트 = 성조)
  const ToneSyllable(this.th, this.tone, this.ko, this.ro);
}

/// 태국어 문자열 하나의 성조 독음.
class ToneReading {
  final String ko;
  final String ro;
  final List<ToneSyllable> syllables;
  const ToneReading(this.ko, this.ro, this.syllables);
}

/// 성조 DB — `assets/data/vocab/th_tones.json` (철자 규칙으로 자동 계산된 음절별 성조).
/// 단어·대화·바로 문장·영어유래·루트 등 앱의 태국어 문자열이 키.
class ToneService {
  ToneService._();
  static final ToneService instance = ToneService._();

  final Map<String, ToneReading> _map = {};
  bool _loaded = false;
  Future<void>? _loading;

  bool get isLoaded => _loaded;
  int get count => _map.length;

  static Map<String, String> toneKoMark = {
    'mid': '',
    'low': 'ˋ',
    'falling': 'ˆ',
    'high': 'ˊ',
    'rising': 'ˇ',
  };
  static Map<String, String> get toneNameKo => {
    'mid': tr('평성'),
    'low': tr('저성'),
    'falling': tr('하성'),
    'high': tr('고성'),
    'rising': tr('상성'),
  };

  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/vocab/th_tones.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final entries = data['entries'] as Map<String, dynamic>;
      entries.forEach((k, v) {
        final m = v as Map<String, dynamic>;
        final syl = <ToneSyllable>[
          for (final s in (m['syl'] as List? ?? []).whereType<Map>())
            ToneSyllable('${s['s'] ?? ''}', '${s['t'] ?? ''}',
                '${s['ko'] ?? ''}', '${s['ro'] ?? ''}'),
        ];
        _map[k] = ToneReading('${m['ko'] ?? ''}', '${m['ro'] ?? ''}', syl);
      });
    } catch (_) {
      // 에셋 없이도 동작
    }
    _loaded = true;
  }

  /// 완전일치 조회 (공백·슬래시 변형은 첫 변형으로).
  ToneReading? lookup(String th) {
    final t = th.trim();
    return _map[t] ?? _map[t.split('/').first.trim()];
  }

  /// 성조 기호가 붙은 한글 독음 (없으면 null).
  String? koWithTones(String th) => lookup(th)?.ko;

  /// 우리 로마자 (없으면 null).
  String? roman(String th) => lookup(th)?.ro;
}

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/tone.dart';

/// 성조 JSON을 에셋에서 한 번 로드해 캐싱.
class ToneRepository {
  static final ToneRepository instance = ToneRepository._();
  ToneRepository._();

  static const _assetPath = 'assets/data/tones/th_tones.json';

  ToneData? _cache;
  Future<ToneData>? _inflight;

  Future<ToneData> load() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    return _inflight ??= _load();
  }

  Future<ToneData> _load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final map = json.decode(raw) as Map<String, dynamic>;

    final tones = (map['tones'] as List<dynamic>)
        .map((e) => ThaiTone.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final marks = (map['marks'] as List<dynamic>)
        .map((e) => ToneMark.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final rules = (map['rules'] as List<dynamic>)
        .map((e) => ToneRule.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    final data = ToneData(tones: tones, marks: marks, rules: rules);
    _cache = data;
    return data;
  }
}

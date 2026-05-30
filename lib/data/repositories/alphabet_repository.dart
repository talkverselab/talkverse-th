import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/alphabet.dart';

/// 자음·모음 JSON을 에셋에서 한 번 로드해 캐싱.
class AlphabetRepository {
  static final AlphabetRepository instance = AlphabetRepository._();
  AlphabetRepository._();

  static const _assetPath = 'assets/data/alphabet/th_alphabet.json';

  AlphabetData? _cache;
  Future<AlphabetData>? _inflight;

  Future<AlphabetData> load() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    return _inflight ??= _load();
  }

  Future<AlphabetData> _load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final map = json.decode(raw) as Map<String, dynamic>;

    final consonants = (map['consonants'] as List<dynamic>)
        .map((e) => ThaiConsonant.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final vowels = (map['vowels'] as List<dynamic>)
        .map((e) => ThaiVowel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    final data = AlphabetData(consonants: consonants, vowels: vowels);
    _cache = data;
    return data;
  }
}

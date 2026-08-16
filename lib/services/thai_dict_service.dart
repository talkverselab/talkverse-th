import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 단어 정보 (Netflix 원어 코퍼스 빈도 기반).
class ThaiWordInfo {
  final int rank;
  final String word;
  final double freq;
  final String tier; // R1..R4
  final String domain;

  const ThaiWordInfo({
    required this.rank,
    required this.word,
    required this.freq,
    required this.tier,
    required this.domain,
  });
}

/// 상위 빈도 단어 사전 + 최장일치 분절.
///
/// 태국어는 띄어쓰기가 없으므로, 빈도 상위 단어 사전을 기준으로
/// 최장일치(longest-match) 분절을 수행한다.
class ThaiDictService {
  ThaiDictService._();
  static final ThaiDictService instance = ThaiDictService._();

  final Map<String, ThaiWordInfo> _words = {};
  int _maxLen = 1;
  bool _loaded = false;

  int get wordCount => _words.length;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw =
          await rootBundle.loadString('assets/data/wordsets/th_top1000.csv');
      final rows = const CsvToListConverter(eol: '\n').convert(raw);
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 5) continue;
        final word = '${row[1]}'.trim();
        if (word.isEmpty) continue;
        _words[word] = ThaiWordInfo(
          rank: int.tryParse('${row[0]}') ?? 0,
          word: word,
          freq: double.tryParse('${row[2]}') ?? 0,
          tier: '${row[3]}',
          domain: '${row[4]}',
        );
        if (word.length > _maxLen) _maxLen = word.length;
      }
    } catch (_) {
      // 사전 없이도 동작 (분절 없이 통짜 토큰)
    }
    _loaded = true;
  }

  ThaiWordInfo? lookup(String word) => _words[word];

  static bool isThaiCode(int code) => code >= 0x0E00 && code <= 0x0E7F;
  static bool isThai(String s) =>
      s.isNotEmpty && s.runes.every(isThaiCode);

  /// 최장일치 분절. [{text, compound}] 반환.
  /// compound=true 는 사전에 있는 단어(탭 가능 청크).
  List<Map<String, dynamic>> segment(String text) {
    final tokens = <Map<String, dynamic>>[];
    final chars = text.split('');
    var i = 0;
    final pending = StringBuffer(); // 미등재 태국 문자 누적

    void flushPending() {
      if (pending.isNotEmpty) {
        tokens.add({'text': pending.toString(), 'compound': false});
        pending.clear();
      }
    }

    while (i < chars.length) {
      final code = chars[i].codeUnitAt(0);
      if (!isThaiCode(code)) {
        flushPending();
        // 비태국 문자 연속 구간을 하나의 토큰으로
        final start = i;
        while (i < chars.length && !isThaiCode(chars[i].codeUnitAt(0))) {
          i++;
        }
        tokens.add({'text': chars.sublist(start, i).join(), 'compound': false});
        continue;
      }
      var matched = false;
      final maxLen = _maxLen.clamp(1, chars.length - i);
      for (var len = maxLen; len >= 2; len--) {
        final cand = chars.sublist(i, i + len).join();
        if (_words.containsKey(cand)) {
          flushPending();
          tokens.add({'text': cand, 'compound': true});
          i += len;
          matched = true;
          break;
        }
      }
      if (!matched) {
        pending.write(chars[i]);
        i++;
      }
    }
    flushPending();
    return tokens;
  }
}

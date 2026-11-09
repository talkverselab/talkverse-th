import 'dart:convert';
import '../core/embed_env.dart';


/// 문자·발음 기초 데이터(자음 44·모음 25·성조 5) — assets/data/alphabet/th_phonetics.json(tools/build_phonetics.py).
/// 일본어앱 kana_phonetics.dart 와 같은 역할(2026-11-08, 모든 언어앱 「문자와 발음」).
class ThaiSound {
  final String ipa, ipaFinal, roman, romanFinal, place, korSim, korDiff, finalNote, note, say;
  final List<double>? pos; // 모음 위치 x(앞0~뒤1), y(높0~낮1)
  const ThaiSound({
    required this.ipa,
    this.ipaFinal = '',
    required this.roman,
    this.romanFinal = '',
    required this.place,
    required this.korSim,
    required this.korDiff,
    this.finalNote = '',
    this.note = '',
    this.say = '',
    this.pos,
  });
}

class ThaiTone {
  final String id, name, th, sample, ko, gloss, ipa, mark, how, kor;
  final List<int> contour; // 1(낮음)~5(높음)
  const ThaiTone(this.id, this.name, this.th, this.sample, this.ko, this.gloss, this.ipa, this.mark, this.how, this.kor, this.contour);
}

class ThaiPhonetics {
  ThaiPhonetics._();
  static final ThaiPhonetics instance = ThaiPhonetics._();

  final Map<String, ThaiSound> consonants = {};
  final Map<String, ThaiSound> vowels = {};
  final List<ThaiTone> tones = [];
  final Map<String, List<double>> thaiVowelPos = {};
  final List<(String, double, double)> korVowels = [];
  Future<void>? _loading;

  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    final j = json.decode(await tvBundle.loadString('assets/data/alphabet/th_phonetics.json')) as Map<String, dynamic>;
    String s(Map m, String k) => (m[k] as String?) ?? '';
    (j['consonants'] as Map<String, dynamic>).forEach((k, v) {
      final m = v as Map<String, dynamic>;
      consonants[k] = ThaiSound(ipa: s(m, 'ipa'), ipaFinal: s(m, 'ipaFinal'), roman: s(m, 'roman'), romanFinal: s(m, 'romanFinal'), place: s(m, 'place'),
          korSim: s(m, 'korSim'), korDiff: s(m, 'korDiff'), finalNote: s(m, 'final'), note: s(m, 'note'));
    });
    (j['vowels'] as Map<String, dynamic>).forEach((k, v) {
      final m = v as Map<String, dynamic>;
      final p = m['pos'] as List?;
      vowels[k] = ThaiSound(ipa: s(m, 'ipa'), roman: s(m, 'roman'), place: s(m, 'place'), korSim: s(m, 'korSim'), korDiff: s(m, 'korDiff'), say: s(m, 'say'),
          pos: p == null ? null : [for (final x in p) (x as num).toDouble()]);
    });
    for (final t in (j['tones'] as List).cast<Map<String, dynamic>>()) {
      tones.add(ThaiTone(s(t, 'id'), s(t, 'name'), s(t, 'th'), s(t, 'sample'), s(t, 'ko'), s(t, 'gloss'), s(t, 'ipa'), s(t, 'mark'), s(t, 'how'), s(t, 'kor'),
          [for (final x in t['contour'] as List) (x as num).toInt()]));
    }
    (j['thaiVowelPos'] as Map<String, dynamic>).forEach((k, v) => thaiVowelPos[k] = [for (final x in v as List) (x as num).toDouble()]);
    for (final k in (j['korVowels'] as List)) {
      final l = k as List;
      korVowels.add((l[0] as String, (l[1] as num).toDouble(), (l[2] as num).toDouble()));
    }
  }
}

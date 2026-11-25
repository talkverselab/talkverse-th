import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:talkverse_pitch/talkverse_pitch.dart';

import '../core/embed_env.dart';
import '../core/prefs.dart';
import 'tone_recorder.dart';

/// 태국어 5성 — 성조 DB(th_tones.json)의 id 그대로.
const thaiTones = ['mid', 'low', 'falling', 'high', 'rising'];

/// 목표 성조의 대표 모양(평소 음높이 기준 반음, [points]점) — 방콕 표준어. 그림과 참고 점수에 같이 쓴다.
/// 평성 = 가운데서 평평 · 저성 = 낮게 깔림 · 하성 = 높이 올랐다 뚝 떨어짐 · 고성 = 높게, 끝이 더 올라감 · 상성 = 낮게 내렸다 올림.
List<double> thaiIdeal(String tone, {int points = 20}) {
  final k = switch (tone) {
    'low' => [-1.5, -3.0, -4.0],
    'falling' => [3.0, 4.5, 3.0, -3.5],
    'high' => [1.0, 1.5, 3.0, 4.5],
    'rising' => [-2.0, -4.0, -4.0, 0.0, 3.0],
    _ => [0.5, 0.0, -0.5],
  };
  double lerp(double x) {
    final p = x * (k.length - 1), i = p.floor().clamp(0, k.length - 2);
    return k[i] + (k[i + 1] - k[i]) * (p - i);
  }

  return [for (var i = 0; i < points; i++) lerp(i / (points - 1))];
}

/// 성조연습 자료 한 낱말(tools/build_tone_drill.py → assets/data/tone_drill.json).
class DrillWord {
  DrillWord(this.th, this.syl, this.tones, this.rd, this.ko);
  final String th, rd, ko;

  /// 음절 조각(글자)과 그 음절의 **소리 나는** 성조.
  final List<String> syl, tones;
  String get cell => tones.join('-');
  factory DrillWord.fromJson(Map<String, dynamic> j) =>
      DrillWord(j['th'], [for (final s in j['syl']) s as String], [for (final t in j['t']) t as String], j['rd'] ?? '', j['ko'] ?? '');
}

class DrillSentence {
  DrillSentence(this.ep, this.turn, this.th, this.rd, this.ko, this.ref);
  final String ep, th, rd, ko;
  final int turn;

  /// 기준 음성 곡선(가운뎃값 기준 반음 50점).
  final Contour ref;
  factory DrillSentence.fromJson(Map<String, dynamic> j) => DrillSentence(j['ep'], j['turn'], j['th'], j['rd'] ?? '', j['ko'] ?? '',
      Contour([for (final v in j['ref']['st']) (v as num).toDouble()], (j['ref']['dur'] as num).toDouble()));
}

/// 묶음 = 낱말 4개(처음 2개 → 3개 → 4개) + 문장.
class DrillRound {
  DrillRound(this.words, this.sentence);
  final List<DrillWord> words;
  final DrillSentence sentence;
}

/// 메뉴 한 줄 = 성조 조합(평성 평성, 평성 저성 …) — 묶음 3개(낱말 12개).
class DrillCombo {
  DrillCombo(this.cell, this.rounds);
  final String cell;
  final List<DrillRound> rounds;
  List<String> get tones => cell.split('-');
  List<DrillWord> get words => [for (final r in rounds) ...r.words];
}

class ToneDrillData {
  ToneDrillData(this.combos);
  final List<DrillCombo> combos;
}

/// 낱말 한 번 말한 결과 — 성조 이름을 판정하지 않고, 목표 모양과 얼마나 닮았는지만(참고 점수).
class WordResult {
  const WordResult(this.syllables, this.score);

  /// 음절별 내 곡선(평소 음높이 기준 반음 20점). 음절을 못 나누면 빈 목록.
  final List<Contour?> syllables;

  /// 0~1. 소리를 못 들었으면 null.
  final double? score;
  bool get valid => score != null;
}

class SentenceResult {
  SentenceResult(this.mine, this.match);
  final Contour? mine;
  final ContourMatch? match;
}

/// 마이크 녹음 → talkverse_pitch(음높이 추적·곡선·모양 비교). 녹음은 기기 안에서만 처리한다(서버 전송 없음).
/// 모듈의 낱말 채점(성조 이름 판정)은 중국어 전용이라 쓰지 않는다 — 태국어는 목표 모양과의 비교만 한다.
class PitchCoach {
  PitchCoach._();
  static final PitchCoach instance = PitchCoach._();

  // 저장은 Prefs(th_ 접두) — 통합 앱에서 다른 언어와 섞이지 않는다.
  static const _kHz = 'pitch_coach_hz_v1'; // 그 사람 평소 음높이 — 최근 유성 칸 Hz(최대 3000개)
  static const _kDays = 'pitch_coach_days_v1'; // {낱말: [yyyy-mm-dd …]}
  /// 진도 = 통과가 아니라 연습한 날. 낱말마다 하루 한 번만 세고 5일이면 완료.
  static const daysToFinish = 5;

  ToneDrillData? _data;
  List<double> _hz = [];
  Map<String, List<String>> _days = {};
  bool _loaded = false;

  Future<ToneDrillData> data() async {
    if (_data != null) return _data!;
    final j = jsonDecode(await rootBundle.loadString(assetPath('assets/data/tone_drill.json'))) as Map<String, dynamic>;
    List<DrillWord> ws(List l) => [for (final w in l) DrillWord.fromJson(w)];
    return _data = ToneDrillData([
      for (final c in j['combos'])
        DrillCombo(c['cell'], [for (final r in c['rounds']) DrillRound(ws(r['words']), DrillSentence.fromJson(r['sentence']))]),
    ]);
  }

  Future<void> _load() async {
    if (_loaded) return;
    final p = await Prefs.getInstance();
    _hz = [for (final v in p.getStringList(_kHz) ?? const <String>[]) double.tryParse(v) ?? 0]..removeWhere((v) => v <= 0);
    try {
      final j = jsonDecode(p.getString(_kDays) ?? '{}') as Map<String, dynamic>;
      _days = {for (final e in j.entries) e.key: [for (final d in e.value) d as String]};
    } catch (_) {
      _days = {};
    }
    _loaded = true;
  }

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// 연습한 날 수(최대 5).
  Future<int> days(String word) async {
    await _load();
    return (_days[word]?.length ?? 0).clamp(0, daysToFinish);
  }

  /// 한 번 말해 보면(점수와 무관하게) 오늘 연습으로 센다 — 하루 한 번만.
  Future<void> countPractice(String word) async {
    await _load();
    final l = _days.putIfAbsent(word, () => []);
    if (l.contains(_today())) return;
    l.add(_today());
    (await Prefs.getInstance()).setString(_kDays, jsonEncode(_days));
  }

  /// 기기에 모인 평소 음높이. 처음 몇 번은 없다(그때는 발화 가운뎃값으로 대신).
  double? get medianHz => _hz.length < 60 ? null : SpeakerRange.fromHz(_hz).medianHz;

  Future<void> _remember(PitchTrack t) async {
    final v = t.voicedHz;
    if (v.length < 10) return;
    _hz = [..._hz, ...v];
    if (_hz.length > 3000) _hz = _hz.sublist(_hz.length - 3000);
    (await Prefs.getInstance()).setStringList(_kHz, [for (final x in _hz) x.toStringAsFixed(1)]);
  }

  Future<PitchTrack> _record(double seconds, void Function(double)? onLevel) async {
    final Uint8List b = await ToneRecorder.instance.recordPcm(seconds: seconds, onLevel: onLevel);
    return const PitchTracker().track(pcm16ToFloat(b));
  }

  /// 낱말 녹음 길이 = 0.8초 + 음절당 0.5초.
  static double wordSeconds(int syllables) => 0.8 + 0.5 * syllables;

  /// 낱말의 목표 곡선(음절마다 20점을 이어 붙임).
  static List<double> targetOf(List<String> tones) => [for (final t in tones) ...thaiIdeal(t)];

  /// 음높이 기록 → 낱말 결과. 음절로 나눠 목표 모양(높낮이 관계 포함, 목소리 높이는 뺌)과 견준다.
  /// 음절이 안 나뉘면 통째로 견준다(빠르기 맞춤).
  static WordResult scoreTrack(PitchTrack t, List<String> tones, {double? speakerMedianHz}) {
    final hz = t.voicedHz;
    if (hz.length < 10) return const WordResult([], null);
    final ref = speakerMedianHz ?? (([...hz]..sort())[hz.length ~/ 2]);
    final target = Contour(targetOf(tones), 0.3 * tones.length);
    final parts = splitSyllables(t, tones.length);
    final cs = [for (final p in parts) Contour.fromTrack(p, refHz: ref, points: 20, minVoicedFrames: 4)];
    if (cs.length == tones.length && cs.every((c) => c != null)) {
      final mine = Contour([for (final c in cs) ...c!.st], target.duration);
      return WordResult(cs, compareContours(mine, target).score);
    }
    final whole = Contour.fromTrack(t, refHz: ref, points: target.st.length);
    if (whole == null) return const WordResult([], null);
    return WordResult(const [], compareContoursWarped(whole, target).score);
  }

  Future<WordResult> scoreWord(DrillWord w, {void Function(double)? onLevel}) async {
    await _load();
    final t = await _record(wordSeconds(w.tones.length), onLevel);
    final r = scoreTrack(t, w.tones, speakerMedianHz: medianHz);
    await _remember(t);
    return r;
  }

  /// 문장: 음절별로 보지 않고 기준 음성 곡선과 모양만 견준다(참고 점수).
  Future<SentenceResult> scoreSentence(DrillSentence s, {void Function(double)? onLevel}) async {
    await _load();
    final t = await _record(s.ref.duration + 1.5, onLevel);
    final hz = t.voicedHz;
    if (hz.length < 10) return SentenceResult(null, null);
    final med = ([...hz]..sort())[hz.length ~/ 2];
    final mine = Contour.fromTrack(t, refHz: med, points: s.ref.st.length);
    await _remember(t);
    return SentenceResult(mine, mine == null ? null : compareContoursWarped(mine, s.ref));
  }
}

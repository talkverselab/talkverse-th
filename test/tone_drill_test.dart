import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkverse_pitch/talkverse_pitch.dart';

import 'package:thai_universe/screens/tone_drill_screen.dart';
import 'package:thai_universe/services/dialogue_service.dart';
import 'package:thai_universe/services/pitch_coach.dart';
import 'package:thai_universe/services/tone_service.dart';

/// 목표 모양대로 소리 낸 것 같은 음높이 기록(음절 사이 60ms 무성).
PitchTrack fake(List<String> tones, {double baseHz = 180}) {
  final f = <PitchFrame>[];
  var t = 0.0;
  for (final tone in tones) {
    for (final st in thaiIdeal(tone, points: 28)) {
      f.add(PitchFrame(t, baseHz * math.pow(2, st / 12).toDouble(), 0.95, 0.2));
      t += 0.01;
    }
    for (var i = 0; i < 6; i++) {
      f.add(PitchFrame(t, null, 0, 0.001));
      t += 0.01;
    }
  }
  return PitchTrack(f, 0.01);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('연습 기록: th_ 접두 키에 하루 한 번만 센다', () async {
    SharedPreferences.setMockInitialValues({'th__migrated_v1': true});
    expect(await PitchCoach.instance.days('วันนี้'), 0);
    await PitchCoach.instance.countPractice('วันนี้');
    await PitchCoach.instance.countPractice('วันนี้');
    expect(await PitchCoach.instance.days('วันนี้'), 1);
    final p = await SharedPreferences.getInstance();
    expect(p.containsKey('pitch_coach_days_v1'), isFalse);
    expect((jsonDecode(p.getString('th_pitch_coach_days_v1')!) as Map)['วันนี้'], hasLength(1));
  });

  test('자료: 조합 25 × 묶음 3 × 낱말 4, 낱말 성조는 성조 DB 그대로, 문장은 지금 회화 대사와 같고 기준 곡선이 있다', () async {
    SharedPreferences.setMockInitialValues({});
    final d = await PitchCoach.instance.data();
    await DialogueService.instance.ensureLoaded();
    await ToneService.instance.ensureLoaded();
    expect(d.combos.length, 25);
    expect({for (final c in d.combos) c.cell}, {for (final a in thaiTones) for (final b in thaiTones) '$a-$b'});
    final seen = <String>{}, sents = <String>{};
    for (final c in d.combos) {
      expect(c.rounds.length, 3, reason: c.cell);
      for (final r in c.rounds) {
        expect(r.words.length, 4);
        for (final w in r.words) {
          expect(w.cell, c.cell, reason: w.th);
          expect(w.syl.join(), w.th);
          final db = ToneService.instance.lookup(w.th)!;
          expect([for (final s in db.syllables) s.tone], w.tones, reason: w.th);
          expect(seen.add(w.th), isTrue, reason: '겹침 ${w.th}');
        }
        final s = r.sentence;
        final t = DialogueService.instance.byId(s.ep)!.turns.firstWhere((t) => t.num == s.turn);
        expect(s.th, t.th, reason: '${s.ep}#${s.turn} 옛 대사');
        expect(s.th.contains(RegExp('[가-힣]')), isFalse);
        expect(s.ref.st.length, 50);
        expect(sents.add('${s.ep}#${s.turn}'), isTrue);
      }
    }
    // 겉보기 2음절이지만 실제로는 3음절이거나 쓰는 성조와 말하는 성조가 다른 낱말은 두지 않는다
    for (final z in ['ผลไม้', 'เอกสาร', 'ปกติ', 'ก็ได้', 'เหรอ', 'ประตู']) {
      expect(seen.contains(z), isFalse, reason: z);
    }
  });

  test('참고 점수: 목표 모양대로 낸 소리는 높고, 다른 조합으로 낸 소리는 낮다(목소리 높이와 무관)', () {
    for (final base in [110.0, 220.0]) {
      for (final a in thaiTones) {
        for (final b in thaiTones) {
          final r = PitchCoach.scoreTrack(fake([a, b], baseHz: base), [a, b]);
          expect(r.syllables.length, 2, reason: '$a-$b');
          expect(r.score!, greaterThan(0.85), reason: '$a-$b @$base');
        }
      }
    }
    expect(PitchCoach.scoreTrack(fake(['rising', 'falling']), ['falling', 'rising']).score!, lessThan(0.3));
    expect(PitchCoach.scoreTrack(fake(['low', 'low']), ['high', 'falling']).score!, lessThan(0.5));
    expect(PitchCoach.scoreTrack(PitchTrack(const [], 0.01), ['mid', 'mid']).valid, isFalse);
  });

  testWidgets('화면: 조합 25칸이 뜨고, 묶음 화면이 채운 그래프로 그려진다', (t) async {
    SharedPreferences.setMockInitialValues({});
    // 테스트 환경에는 기기 TTS 가 없다 — 채널만 받아 준다
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => c.method == 'getVoices' ? [] : 1);
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() => PitchCoach.instance.data());
    await t.pumpWidget(const MaterialApp(home: ToneDrillHubScreen()));
    for (var i = 0; i < 10; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await t.pump();
    }
    expect(find.text('준비: 성조 5개 듣기'), findsOneWidget);
    expect(find.text('평성 + 평성'), findsOneWidget);
    final d = await t.runAsync(() => PitchCoach.instance.data());
    final key = GlobalKey();
    await t.pumpWidget(MaterialApp(
      home: RepaintBoundary(key: key, child: ToneRoundScreen(title: comboName('falling-rising'), round: d!.combos[14].rounds[0], onNext: () {})),
    ));
    await t.pump(const Duration(milliseconds: 300));
    expect(t.takeException(), isNull);
    expect(d.combos[14].cell, 'falling-rising');
    expect(find.byKey(const ValueKey('target-graph')), findsOneWidget); // 말하기 전에도 목표 곡선이 보인다
    final out = Platform.environment['TONE_SHOT'];
    if (out != null) {
      await t.runAsync(() async {
        final img = await (key.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio: 2);
        final b = await img.toByteData(format: ui.ImageByteFormat.png);
        File(out).writeAsBytesSync(b!.buffer.asUint8List());
      });
    }
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 15)); // 기기 음성 쪽 대기 타이머를 흘려보낸다
  });
}

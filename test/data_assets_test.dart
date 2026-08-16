import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:thai_universe/services/thai_dict_service.dart';

/// 에셋 데이터 무결성 + 분절 서비스 스모크 테스트.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('단어 사전 로드 + 최장일치 분절', () async {
    final dict = ThaiDictService.instance;
    await dict.ensureLoaded();
    expect(dict.wordCount, greaterThanOrEqualTo(900));

    // 최빈 단어들이 사전에 존재
    expect(dict.lookup('ที่'), isNotNull);
    expect(dict.lookup('ไม่'), isNotNull);

    // 분절: 토큰을 이어붙이면 원문 복원
    const sentence = 'ผมมาจากเกาหลีครับ';
    final tokens = dict.segment(sentence);
    expect(tokens.map((t) => t['text']).join(), sentence);
    expect(tokens.any((t) => t['compound'] == true), isTrue);
  });

  test('다이얼로그 JSON 스키마 (L1 episodes / L2 dialogues)', () async {
    for (final (level, key) in [('L1', 'episodes'), ('L2', 'dialogues')]) {
      final raw =
          await rootBundle.loadString('assets/data/dialogues/$level.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final units = data[key] as List;
      expect(units, isNotEmpty, reason: '$level $key 비어 있음');
      for (final ep in units.cast<Map<String, dynamic>>()) {
        expect(ep['id'], isA<String>());
        final turns = ep['turns'] as List;
        expect(turns, isNotEmpty);
        for (final t in turns.cast<Map<String, dynamic>>()) {
          expect(t['num'], isA<int>());
          expect(t['speaker'], anyOf('A', 'B'));
          expect(t['th'], isA<String>());
        }
      }
    }
  });

  test('알파벳 JSON — 자음 44자·분류 유효', () async {
    final raw =
        await rootBundle.loadString('assets/data/alphabet/th_alphabet.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final consonants = data['consonants'] as List;
    expect(consonants.length, 44);
    for (final c in consonants.cast<Map<String, dynamic>>()) {
      expect(c['cls'], anyOf('high', 'mid', 'low'));
    }
  });

  test('어말조사 JSON — 12종 + 예문', () async {
    final raw = await rootBundle.loadString('assets/data/grammar/sfp.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final items = data['items'] as List;
    expect(items.length, 12);
    for (final i in items.cast<Map<String, dynamic>>()) {
      expect((i['examples'] as List), isNotEmpty,
          reason: '${i['sfp']} 예문 없음');
    }
  });

  test('청크 JSON — 2200문장', () async {
    final raw =
        await rootBundle.loadString('assets/data/chunks/th_chunks.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    expect((data['chunks'] as List).length, 2200);
  });
}

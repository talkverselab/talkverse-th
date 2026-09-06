import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:thai_universe/services/root_service.dart';
import 'package:thai_universe/screens/sentence_flashcard_screen.dart';
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

  _HintTest.run();

  test('청크 JSON — 2200문장', () async {
    final raw =
        await rootBundle.loadString('assets/data/chunks/th_chunks.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    expect((data['chunks'] as List).length, 2200);
  });

  test('통합 단어장 에셋 스키마', () async {
    final raw = await rootBundle.loadString('assets/data/vocab/th_vocab.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final entries = data['entries'] as List;
    expect(entries.length, greaterThan(3000));
    for (final e in entries.take(200)) {
      final m = e as Map<String, dynamic>;
      expect(m['th'], isNotEmpty);
      expect(m['ko'], isNotNull);
      expect(RegExp(r'[A-Za-z]').hasMatch(m['reading'] as String), isFalse,
          reason: '독음에 로마자 없음: ${m['reading']}');
    }
    // 표제어 중복 없음 · 예문(원서 문장) 없음 · 빈도 단계 1~5
    final ths = entries.map((e) => (e as Map)['th'] as String).toList();
    expect(ths.toSet().length, ths.length, reason: '표제어 중복');
    expect(entries.any((e) => (e as Map).containsKey('ex')), isFalse);
    expect(entries.any((e) => ((e as Map)['level'] ?? 0) == 5), isTrue);
    expect(entries.every((e) => !(e as Map).containsKey('pages')), isTrue);
  });

  test('대화 JSON — 모든 대화 8턴 · 한글 독음 · 출처 언급 없음', () async {
    for (final (level, key) in [('L1', 'episodes'), ('L2', 'dialogues'), ('L3', 'dialogues')]) {
      final raw = await rootBundle.loadString('assets/data/dialogues/$level.json');
      expect(raw.toLowerCase().contains('netflix'), isFalse);
      final data = json.decode(raw) as Map<String, dynamic>;
      for (final ep in (data[key] as List).cast<Map<String, dynamic>>()) {
        final turns = ep['turns'] as List;
        expect(turns.length, 8, reason: '$level ${ep['id']}');
        for (final t in turns.cast<Map<String, dynamic>>()) {
          expect(t['roman'], isNotNull, reason: '$level ${ep['id']} #${t['num']}');
          expect(RegExp(r'[A-Za-z]').hasMatch(t['roman'] as String), isFalse);
        }
      }
    }
  });

  test('루트 단어 에셋 + 경계 규칙', () async {
    final raw = await rootBundle.loadString('assets/data/vocab/th_roots.json');
    final roots = (json.decode(raw) as Map<String, dynamic>)['roots'] as List;
    expect(roots.length, greaterThan(100));
    expect(roots.any((r) => (r as Map)['th'] == 'น้ำ'), isTrue);
    expect(RootService.containsAtBoundary('น้ำแข็ง', 'น้ำ'), isTrue);
    expect(RootService.containsAtBoundary('แม่น้ำ', 'น้ำ'), isTrue);
    expect(RootService.containsAtBoundary('น้ำ', 'น้ำ'), isFalse);
    // ตา 뒤에 결합 부호(ตาย 의 ย 는 자음이라 허용되지만, ตำ 은 불가)
    expect(RootService.containsAtBoundary('ตำรวจ', 'ตา'), isFalse);
    expect(RootService.containsAtBoundary('เตา', 'ตา'), isFalse);
    expect(RootService.containsAtBoundary('ตารางราคา', 'ตา'), isTrue);
  });
}

// ── 플래시카드 힌트: 전체 문장이 아닌 첫 어절만 ──
class _HintTest {
  static void run() {
    test('플래시카드 힌트는 첫 어절만 노출', () {
      expect(SentenceFlashcardHint.hintOf('싸왓디 크랍, 폼 츠 민호 크랍'), '싸왓디 …');
      expect(SentenceFlashcardHint.hintOf('내넌'), '내넌');
      expect(SentenceFlashcardHint.hintOf(''), '');
    });
  }

}

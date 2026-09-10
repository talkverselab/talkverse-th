import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:thai_universe/services/update_service.dart';
import 'package:thai_universe/services/root_service.dart';
import 'package:thai_universe/screens/sentence_flashcard_screen.dart';
import 'package:thai_universe/services/thai_dict_service.dart';

/// 에셋 데이터 무결성 + 분절 서비스 스모크 테스트.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _updateTests();

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

  test('문법 JSON — 어말조사 12종 + การ·ที่ + 예문', () async {
    final raw = await rootBundle.loadString('assets/data/grammar/sfp.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final items = data['items'] as List;
    expect(items.length, 14);
    expect(items.any((i) => (i as Map)['sfp'] == 'การ'), isTrue);
    expect(items.any((i) => (i as Map)['sfp'] == 'ที่'), isTrue);
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

  test('영어 유래 단어 에셋 — 8줄기 · 200단어 · 한글 독음', () async {
    final raw =
        await rootBundle.loadString('assets/data/wordsets/th_loanwords.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final groups = (data['groups'] as List).cast<Map>();
    expect(groups.length, 8);
    final ids = groups.map((g) => g['id']).toSet();
    final words = (data['words'] as List).cast<Map>();
    expect(words.length, 200);
    expect(words.map((w) => w['th']).toSet().length, 200, reason: '중복 없음');
    for (final w in words) {
      expect(ids.contains(w['group']), isTrue, reason: '${w['th']}');
      expect(RegExp(r'[A-Za-z]').hasMatch(w['reading'] as String), isFalse,
          reason: '독음에 로마자 없음: ${w['th']}');
      expect((w['en'] as String).isNotEmpty && (w['ko'] as String).isNotEmpty,
          isTrue);
    }
    expect(words.where((w) => w['exception'] == true).length,
        greaterThanOrEqualTo(15));
  });

  test('성조 DB 에셋 — 대화·단어 전부 포함, 성조 기호', () async {
    final raw = await rootBundle.loadString('assets/data/vocab/th_tones.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final entries = data['entries'] as Map<String, dynamic>;
    expect(entries.length, greaterThan(5000));
    final kai = entries['ไก่'] as Map<String, dynamic>;
    expect((kai['syl'] as List).first['t'], 'low');
    expect(kai['ko'], '까이ˋ');
    final khao = entries['ข้าว'] as Map<String, dynamic>;
    expect((khao['syl'] as List).first['t'], 'falling');
    // 대화 문장이 모두 들어 있어야 한다
    for (final (level, key) in [('L1', 'episodes'), ('L2', 'dialogues'), ('L3', 'dialogues')]) {
      final d = json.decode(await rootBundle.loadString('assets/data/dialogues/$level.json')) as Map;
      for (final ep in (d[key] as List).cast<Map>()) {
        for (final turn in (ep['turns'] as List).cast<Map>()) {
          expect(entries.containsKey(turn['th']), isTrue, reason: '${turn['th']}');
        }
      }
    }
  });

  test('단어 그림 — 중요 1000단어 1·2단계는 표제어별 그림 지정', () async {
    final raw = await rootBundle.loadString('assets/data/vocab/th_emoji_map.json');
    final words = (json.decode(raw) as Map<String, dynamic>)['words'] as Map;
    final vocab = json.decode(
      await rootBundle.loadString('assets/data/vocab/th_vocab.json'),
    ) as Map<String, dynamic>;
    final tiers = (vocab['entries'] as List).whereType<Map>().where(
      (e) => (e['level'] as num? ?? 0) >= 1 && (e['level'] as num) <= 5,
    );
    final missing = [
      for (final e in tiers)
        if (!words.containsKey(e['th'])) e['th'],
    ];
    expect(missing, isEmpty, reason: '그림 미지정: $missing');
    expect(words['ไม่'], '❌');
    expect(words['เลือด'], '🩸'); // 2단계(501~1000위)
    expect(words['ประมาณ'], isNot('💊')); // '약, 대략' → 약 오매칭 방지
  });

  test('교육부 표준 단어(OBEC) 에셋 — ป.1~3 표준 2,600+', () async {
    final raw =
        await rootBundle.loadString('assets/data/wordsets/th_obec_basic.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final std = (data['standard'] as List).cast<Map>();
    expect(std.length, greaterThan(2500));
    expect(std.map((w) => w['th']).toSet().length, std.length);
    expect(std.every((w) => [1, 2, 3].contains(w['grade'])), isTrue);
    final withKo = std.where((w) => (w['ko'] as String).isNotEmpty).length;
    expect(withKo, greaterThan(900));
    for (final w in std) {
      expect(RegExp(r'[A-Za-z]').hasMatch(w['reading'] as String), isFalse,
          reason: '${w['th']}');
    }
    expect((data['upper'] as Map).keys.toSet(), {'4', '5', '6'});
  });

  test('주제별 단어 — th_topics.json 과 entries[].topic 일치', () async {
    final raw = await rootBundle.loadString('assets/data/vocab/th_topics.json');
    final topics = ((json.decode(raw) as Map)['topics'] as List).cast<Map>();
    expect(topics.length, greaterThanOrEqualTo(12));
    final ids = topics.map((t) => t['id']).toSet();
    final vraw = await rootBundle.loadString('assets/data/vocab/th_vocab.json');
    final entries = ((json.decode(vraw) as Map)['entries'] as List).cast<Map>();
    for (final e in entries) {
      expect(ids.contains(e['topic']), isTrue, reason: '${e['th']} topic=${e['topic']}');
      expect((e['part'] as String).isNotEmpty, isTrue, reason: '${e['th']}');
    }
    final total = topics.fold<int>(0, (s, t) => s + (t['count'] as int));
    expect(total, entries.length);
  });

  test('표현학습 에셋 — 단어장과 분리, 문장만', () async {
    final raw = await rootBundle.loadString('assets/data/vocab/th_expressions.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final entries = (data['entries'] as List).cast<Map>();
    expect(entries.length, greaterThan(50));
    final vraw = await rootBundle.loadString('assets/data/vocab/th_vocab.json');
    final vths = ((json.decode(vraw) as Map)['entries'] as List).cast<Map>().map((e) => e['th']).toSet();
    for (final e in entries) {
      expect(vths.contains(e['th']), isFalse, reason: '단어장과 중복: ${e['th']}');
    }
  });

  test('루트 단어 에셋 + 경계 규칙', () async {
    final raw = await rootBundle.loadString('assets/data/vocab/th_roots.json');
    final roots = (json.decode(raw) as Map<String, dynamic>)['roots'] as List;
    expect(roots.length, greaterThan(100));
    expect(roots.any((r) => (r as Map)['th'] == 'น้ำ'), isTrue);
    final doc = json.decode(raw) as Map<String, dynamic>;
    expect((doc['pieces'] as Map).length, greaterThan(150));
    expect((doc['reject'] as List).contains('ยา|ยาว'), isTrue);
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

void _updateTests() {
  group('앱 업데이트', () {
    test('latest.json 파싱', () {
      final info = UpdateInfo.parse(
        '{"version":"0.2.0","build":26,"sha":"34958c0",'
        '"date":"2026-09-10T10:20:00Z","notes":"단어 그림 2단계","size":52428800}',
      );
      expect(info.version, '0.2.0');
      expect(info.build, 26);
      expect(info.sha, '34958c0');
      expect(info.notes, '단어 그림 2단계');
      expect(info.builtAt, isNotNull);
      expect(info.sizeText, '50.0 MB');
    });

    test('필드가 빠져도 견딘다', () {
      final info = UpdateInfo.parse('{"version":"0.2.0"}');
      expect(info.build, 0);
      expect(info.sizeText, '');
      expect(info.builtAt, isNull);
    });

    test('빌드 번호가 클 때만 새 버전', () {
      expect(UpdateService.isNewer(current: 2, latest: 26), isTrue);
      expect(UpdateService.isNewer(current: 26, latest: 26), isFalse);
      expect(UpdateService.isNewer(current: 27, latest: 26), isFalse);
    });
  });
}

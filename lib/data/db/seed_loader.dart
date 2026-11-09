import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';
import '../../core/embed_env.dart';
import '../../core/prefs.dart';

class SeedLoader {
  final AppDatabase db;
  SeedLoader(this.db);

  /// 번들 `assets/data/version.json` 의 `db`(업데이트 번호)와 저장된 번호가 다르면 DB 를 전부 다시 채운다(사용자 지시 2026-11-04, 모든 언어앱 공통).
  /// 옛 키(`db_seeded_th_v5`)는 더 쓰지 않는다 — 번호는 version.json 한 곳에서만 올린다.
  static const _kDbVersion = 'db_version';
  Future<void> seedIfNeeded() async {
    final prefs = await Prefs.getInstance();
    final bundled = await bundledVersion();
    if (prefs.getInt(_kDbVersion) == bundled) return;

    await db.delete(db.words).go();
    await _seedWords();
    await _seedTurns();

    await prefs.setInt(_kDbVersion, bundled);
  }

  static Future<int> bundledVersion() async {
    try {
      final j = json.decode(await tvBundle.loadString('assets/data/version.json')) as Map<String, dynamic>;
      return (j['db'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  Future<void> _seedWords() async {
    final raw =
        await tvBundle.loadString('assets/data/wordsets/th_top1000.csv');
    final rows = const CsvToListConverter(eol: '\n').convert(raw);
    final batch = <Insertable<WordRow>>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 5) continue;
      batch.add(WordsCompanion.insert(
        rank: Value(int.tryParse('${row[0]}') ?? 0),
        word: '${row[1]}',
        freq: Value(double.tryParse('${row[2]}')),
        tier: Value('${row[3]}'),
        domain: Value('${row[4]}'),
      ));
    }
    await db.batch((b) => b.insertAllOnConflictUpdate(db.words, batch));
  }

  /// L1~L3 전체 턴 시딩. L1은 'episodes', L2/L3은 'dialogues' 키 사용.
  Future<void> _seedTurns() async {
    final batch = <Insertable<TurnRow>>[];
    for (final level in ['L1', 'L2', 'L3']) {
      final Map<String, dynamic> data;
      try {
        final raw =
            await tvBundle.loadString('assets/data/dialogues/$level.json');
        data = json.decode(raw) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      final units =
          (data['episodes'] as List?) ?? (data['dialogues'] as List?) ?? [];
      for (final ep in units) {
        final epMap = ep as Map<String, dynamic>;
        final epId = epMap['id'] as String?;
        final turns = (epMap['turns'] as List?) ?? [];
        for (final t in turns) {
          final m = t as Map<String, dynamic>;
          batch.add(TurnsCompanion.insert(
            level: level,
            episodeId: Value(epId),
            num: m['num'] as int,
            speaker: m['speaker'] as String,
            th: m['th'] as String,
            roman: Value(m['roman'] as String?),
            ko: Value(m['ko'] as String?),
            note: Value(m['note'] as String?),
            tagsJson: Value(m['tags'] != null ? json.encode(m['tags']) : null),
          ));
        }
      }
    }
    if (batch.isNotEmpty) {
      // 재시딩: 이전 버전 턴·진행 기록 제거 후 삽입 (turnId 재발급)
      await db.delete(db.userProgress).go();
      await db.delete(db.turns).go();
      await db.batch((b) => b.insertAll(db.turns, batch));
    }
  }

  Future<int> turnCount() => db.turns.count().getSingle();
  Future<int> wordCount() => db.words.count().getSingle();
}

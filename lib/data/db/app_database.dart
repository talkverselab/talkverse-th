import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ─── Tables ─────────────────────────────────────────────────────────────────

@DataClassName('TurnRow')
class Turns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get level => text()(); // 'L1' | 'L2' | 'L3'
  TextColumn get episodeId => text().nullable()(); // 'ep1' .. / 'd1' ..
  IntColumn get num => integer()();
  TextColumn get speaker => text()(); // 'A' | 'B'
  TextColumn get th => text()();
  TextColumn get roman => text().nullable()(); // 성조 부호 포함 로마자
  TextColumn get ko => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get tagsJson => text().nullable()();
}

@DataClassName('WordRow')
class Words extends Table {
  IntColumn get rank => integer()();
  TextColumn get word => text()();
  RealColumn get freq => real().nullable()();
  TextColumn get tier => text().nullable()(); // R1, R2, R3, R4
  TextColumn get domain => text().nullable()();

  @override
  Set<Column> get primaryKey => {rank};
}

@DataClassName('UserProgressRow')
class UserProgress extends Table {
  IntColumn get turnId => integer().references(Turns, #id)();
  BoolColumn get learned => boolean().withDefault(const Constant(false))();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastReviewed => dateTime().nullable()();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {turnId};
}

/// 태국 문자(자음·모음) 학습 진행.
@DataClassName('LetterProgressRow')
class LetterProgress extends Table {
  TextColumn get char => text()();
  BoolColumn get known => boolean().withDefault(const Constant(false))();
  IntColumn get exposureCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReviewed => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {char};
}

@DataClassName('UserMemoRow')
class UserMemos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get context => text()(); // screen+turn or 'global'
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─── Database ───────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Turns,
  Words,
  UserProgress,
  LetterProgress,
  UserMemos,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'thai_universe');
  }
}

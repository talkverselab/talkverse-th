// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TurnsTable extends Turns with TableInfo<$TurnsTable, TurnRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TurnsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeIdMeta = const VerificationMeta(
    'episodeId',
  );
  @override
  late final GeneratedColumn<String> episodeId = GeneratedColumn<String>(
    'episode_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numMeta = const VerificationMeta('num');
  @override
  late final GeneratedColumn<int> num = GeneratedColumn<int>(
    'num',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speakerMeta = const VerificationMeta(
    'speaker',
  );
  @override
  late final GeneratedColumn<String> speaker = GeneratedColumn<String>(
    'speaker',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thMeta = const VerificationMeta('th');
  @override
  late final GeneratedColumn<String> th = GeneratedColumn<String>(
    'th',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _romanMeta = const VerificationMeta('roman');
  @override
  late final GeneratedColumn<String> roman = GeneratedColumn<String>(
    'roman',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _koMeta = const VerificationMeta('ko');
  @override
  late final GeneratedColumn<String> ko = GeneratedColumn<String>(
    'ko',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    level,
    episodeId,
    num,
    speaker,
    th,
    roman,
    ko,
    note,
    tagsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'turns';
  @override
  VerificationContext validateIntegrity(
    Insertable<TurnRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('episode_id')) {
      context.handle(
        _episodeIdMeta,
        episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta),
      );
    }
    if (data.containsKey('num')) {
      context.handle(
        _numMeta,
        num.isAcceptableOrUnknown(data['num']!, _numMeta),
      );
    } else if (isInserting) {
      context.missing(_numMeta);
    }
    if (data.containsKey('speaker')) {
      context.handle(
        _speakerMeta,
        speaker.isAcceptableOrUnknown(data['speaker']!, _speakerMeta),
      );
    } else if (isInserting) {
      context.missing(_speakerMeta);
    }
    if (data.containsKey('th')) {
      context.handle(_thMeta, th.isAcceptableOrUnknown(data['th']!, _thMeta));
    } else if (isInserting) {
      context.missing(_thMeta);
    }
    if (data.containsKey('roman')) {
      context.handle(
        _romanMeta,
        roman.isAcceptableOrUnknown(data['roman']!, _romanMeta),
      );
    }
    if (data.containsKey('ko')) {
      context.handle(_koMeta, ko.isAcceptableOrUnknown(data['ko']!, _koMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TurnRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TurnRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      episodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_id'],
      ),
      num: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}num'],
      )!,
      speaker: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}speaker'],
      )!,
      th: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}th'],
      )!,
      roman: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roman'],
      ),
      ko: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ko'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      ),
    );
  }

  @override
  $TurnsTable createAlias(String alias) {
    return $TurnsTable(attachedDatabase, alias);
  }
}

class TurnRow extends DataClass implements Insertable<TurnRow> {
  final int id;
  final String level;
  final String? episodeId;
  final int num;
  final String speaker;
  final String th;
  final String? roman;
  final String? ko;
  final String? note;
  final String? tagsJson;
  const TurnRow({
    required this.id,
    required this.level,
    this.episodeId,
    required this.num,
    required this.speaker,
    required this.th,
    this.roman,
    this.ko,
    this.note,
    this.tagsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['level'] = Variable<String>(level);
    if (!nullToAbsent || episodeId != null) {
      map['episode_id'] = Variable<String>(episodeId);
    }
    map['num'] = Variable<int>(num);
    map['speaker'] = Variable<String>(speaker);
    map['th'] = Variable<String>(th);
    if (!nullToAbsent || roman != null) {
      map['roman'] = Variable<String>(roman);
    }
    if (!nullToAbsent || ko != null) {
      map['ko'] = Variable<String>(ko);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || tagsJson != null) {
      map['tags_json'] = Variable<String>(tagsJson);
    }
    return map;
  }

  TurnsCompanion toCompanion(bool nullToAbsent) {
    return TurnsCompanion(
      id: Value(id),
      level: Value(level),
      episodeId: episodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeId),
      num: Value(num),
      speaker: Value(speaker),
      th: Value(th),
      roman: roman == null && nullToAbsent
          ? const Value.absent()
          : Value(roman),
      ko: ko == null && nullToAbsent ? const Value.absent() : Value(ko),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      tagsJson: tagsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(tagsJson),
    );
  }

  factory TurnRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TurnRow(
      id: serializer.fromJson<int>(json['id']),
      level: serializer.fromJson<String>(json['level']),
      episodeId: serializer.fromJson<String?>(json['episodeId']),
      num: serializer.fromJson<int>(json['num']),
      speaker: serializer.fromJson<String>(json['speaker']),
      th: serializer.fromJson<String>(json['th']),
      roman: serializer.fromJson<String?>(json['roman']),
      ko: serializer.fromJson<String?>(json['ko']),
      note: serializer.fromJson<String?>(json['note']),
      tagsJson: serializer.fromJson<String?>(json['tagsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'level': serializer.toJson<String>(level),
      'episodeId': serializer.toJson<String?>(episodeId),
      'num': serializer.toJson<int>(num),
      'speaker': serializer.toJson<String>(speaker),
      'th': serializer.toJson<String>(th),
      'roman': serializer.toJson<String?>(roman),
      'ko': serializer.toJson<String?>(ko),
      'note': serializer.toJson<String?>(note),
      'tagsJson': serializer.toJson<String?>(tagsJson),
    };
  }

  TurnRow copyWith({
    int? id,
    String? level,
    Value<String?> episodeId = const Value.absent(),
    int? num,
    String? speaker,
    String? th,
    Value<String?> roman = const Value.absent(),
    Value<String?> ko = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> tagsJson = const Value.absent(),
  }) => TurnRow(
    id: id ?? this.id,
    level: level ?? this.level,
    episodeId: episodeId.present ? episodeId.value : this.episodeId,
    num: num ?? this.num,
    speaker: speaker ?? this.speaker,
    th: th ?? this.th,
    roman: roman.present ? roman.value : this.roman,
    ko: ko.present ? ko.value : this.ko,
    note: note.present ? note.value : this.note,
    tagsJson: tagsJson.present ? tagsJson.value : this.tagsJson,
  );
  TurnRow copyWithCompanion(TurnsCompanion data) {
    return TurnRow(
      id: data.id.present ? data.id.value : this.id,
      level: data.level.present ? data.level.value : this.level,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      num: data.num.present ? data.num.value : this.num,
      speaker: data.speaker.present ? data.speaker.value : this.speaker,
      th: data.th.present ? data.th.value : this.th,
      roman: data.roman.present ? data.roman.value : this.roman,
      ko: data.ko.present ? data.ko.value : this.ko,
      note: data.note.present ? data.note.value : this.note,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TurnRow(')
          ..write('id: $id, ')
          ..write('level: $level, ')
          ..write('episodeId: $episodeId, ')
          ..write('num: $num, ')
          ..write('speaker: $speaker, ')
          ..write('th: $th, ')
          ..write('roman: $roman, ')
          ..write('ko: $ko, ')
          ..write('note: $note, ')
          ..write('tagsJson: $tagsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    level,
    episodeId,
    num,
    speaker,
    th,
    roman,
    ko,
    note,
    tagsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TurnRow &&
          other.id == this.id &&
          other.level == this.level &&
          other.episodeId == this.episodeId &&
          other.num == this.num &&
          other.speaker == this.speaker &&
          other.th == this.th &&
          other.roman == this.roman &&
          other.ko == this.ko &&
          other.note == this.note &&
          other.tagsJson == this.tagsJson);
}

class TurnsCompanion extends UpdateCompanion<TurnRow> {
  final Value<int> id;
  final Value<String> level;
  final Value<String?> episodeId;
  final Value<int> num;
  final Value<String> speaker;
  final Value<String> th;
  final Value<String?> roman;
  final Value<String?> ko;
  final Value<String?> note;
  final Value<String?> tagsJson;
  const TurnsCompanion({
    this.id = const Value.absent(),
    this.level = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.num = const Value.absent(),
    this.speaker = const Value.absent(),
    this.th = const Value.absent(),
    this.roman = const Value.absent(),
    this.ko = const Value.absent(),
    this.note = const Value.absent(),
    this.tagsJson = const Value.absent(),
  });
  TurnsCompanion.insert({
    this.id = const Value.absent(),
    required String level,
    this.episodeId = const Value.absent(),
    required int num,
    required String speaker,
    required String th,
    this.roman = const Value.absent(),
    this.ko = const Value.absent(),
    this.note = const Value.absent(),
    this.tagsJson = const Value.absent(),
  }) : level = Value(level),
       num = Value(num),
       speaker = Value(speaker),
       th = Value(th);
  static Insertable<TurnRow> custom({
    Expression<int>? id,
    Expression<String>? level,
    Expression<String>? episodeId,
    Expression<int>? num,
    Expression<String>? speaker,
    Expression<String>? th,
    Expression<String>? roman,
    Expression<String>? ko,
    Expression<String>? note,
    Expression<String>? tagsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (level != null) 'level': level,
      if (episodeId != null) 'episode_id': episodeId,
      if (num != null) 'num': num,
      if (speaker != null) 'speaker': speaker,
      if (th != null) 'th': th,
      if (roman != null) 'roman': roman,
      if (ko != null) 'ko': ko,
      if (note != null) 'note': note,
      if (tagsJson != null) 'tags_json': tagsJson,
    });
  }

  TurnsCompanion copyWith({
    Value<int>? id,
    Value<String>? level,
    Value<String?>? episodeId,
    Value<int>? num,
    Value<String>? speaker,
    Value<String>? th,
    Value<String?>? roman,
    Value<String?>? ko,
    Value<String?>? note,
    Value<String?>? tagsJson,
  }) {
    return TurnsCompanion(
      id: id ?? this.id,
      level: level ?? this.level,
      episodeId: episodeId ?? this.episodeId,
      num: num ?? this.num,
      speaker: speaker ?? this.speaker,
      th: th ?? this.th,
      roman: roman ?? this.roman,
      ko: ko ?? this.ko,
      note: note ?? this.note,
      tagsJson: tagsJson ?? this.tagsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<String>(episodeId.value);
    }
    if (num.present) {
      map['num'] = Variable<int>(num.value);
    }
    if (speaker.present) {
      map['speaker'] = Variable<String>(speaker.value);
    }
    if (th.present) {
      map['th'] = Variable<String>(th.value);
    }
    if (roman.present) {
      map['roman'] = Variable<String>(roman.value);
    }
    if (ko.present) {
      map['ko'] = Variable<String>(ko.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TurnsCompanion(')
          ..write('id: $id, ')
          ..write('level: $level, ')
          ..write('episodeId: $episodeId, ')
          ..write('num: $num, ')
          ..write('speaker: $speaker, ')
          ..write('th: $th, ')
          ..write('roman: $roman, ')
          ..write('ko: $ko, ')
          ..write('note: $note, ')
          ..write('tagsJson: $tagsJson')
          ..write(')'))
        .toString();
  }
}

class $WordsTable extends Words with TableInfo<$WordsTable, WordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<int> rank = GeneratedColumn<int>(
    'rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _freqMeta = const VerificationMeta('freq');
  @override
  late final GeneratedColumn<double> freq = GeneratedColumn<double>(
    'freq',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  @override
  late final GeneratedColumn<String> tier = GeneratedColumn<String>(
    'tier',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [rank, word, freq, tier, domain];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('rank')) {
      context.handle(
        _rankMeta,
        rank.isAcceptableOrUnknown(data['rank']!, _rankMeta),
      );
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('freq')) {
      context.handle(
        _freqMeta,
        freq.isAcceptableOrUnknown(data['freq']!, _freqMeta),
      );
    }
    if (data.containsKey('tier')) {
      context.handle(
        _tierMeta,
        tier.isAcceptableOrUnknown(data['tier']!, _tierMeta),
      );
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rank};
  @override
  WordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordRow(
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      freq: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}freq'],
      ),
      tier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tier'],
      ),
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      ),
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class WordRow extends DataClass implements Insertable<WordRow> {
  final int rank;
  final String word;
  final double? freq;
  final String? tier;
  final String? domain;
  const WordRow({
    required this.rank,
    required this.word,
    this.freq,
    this.tier,
    this.domain,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['rank'] = Variable<int>(rank);
    map['word'] = Variable<String>(word);
    if (!nullToAbsent || freq != null) {
      map['freq'] = Variable<double>(freq);
    }
    if (!nullToAbsent || tier != null) {
      map['tier'] = Variable<String>(tier);
    }
    if (!nullToAbsent || domain != null) {
      map['domain'] = Variable<String>(domain);
    }
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      rank: Value(rank),
      word: Value(word),
      freq: freq == null && nullToAbsent ? const Value.absent() : Value(freq),
      tier: tier == null && nullToAbsent ? const Value.absent() : Value(tier),
      domain: domain == null && nullToAbsent
          ? const Value.absent()
          : Value(domain),
    );
  }

  factory WordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordRow(
      rank: serializer.fromJson<int>(json['rank']),
      word: serializer.fromJson<String>(json['word']),
      freq: serializer.fromJson<double?>(json['freq']),
      tier: serializer.fromJson<String?>(json['tier']),
      domain: serializer.fromJson<String?>(json['domain']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rank': serializer.toJson<int>(rank),
      'word': serializer.toJson<String>(word),
      'freq': serializer.toJson<double?>(freq),
      'tier': serializer.toJson<String?>(tier),
      'domain': serializer.toJson<String?>(domain),
    };
  }

  WordRow copyWith({
    int? rank,
    String? word,
    Value<double?> freq = const Value.absent(),
    Value<String?> tier = const Value.absent(),
    Value<String?> domain = const Value.absent(),
  }) => WordRow(
    rank: rank ?? this.rank,
    word: word ?? this.word,
    freq: freq.present ? freq.value : this.freq,
    tier: tier.present ? tier.value : this.tier,
    domain: domain.present ? domain.value : this.domain,
  );
  WordRow copyWithCompanion(WordsCompanion data) {
    return WordRow(
      rank: data.rank.present ? data.rank.value : this.rank,
      word: data.word.present ? data.word.value : this.word,
      freq: data.freq.present ? data.freq.value : this.freq,
      tier: data.tier.present ? data.tier.value : this.tier,
      domain: data.domain.present ? data.domain.value : this.domain,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordRow(')
          ..write('rank: $rank, ')
          ..write('word: $word, ')
          ..write('freq: $freq, ')
          ..write('tier: $tier, ')
          ..write('domain: $domain')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rank, word, freq, tier, domain);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordRow &&
          other.rank == this.rank &&
          other.word == this.word &&
          other.freq == this.freq &&
          other.tier == this.tier &&
          other.domain == this.domain);
}

class WordsCompanion extends UpdateCompanion<WordRow> {
  final Value<int> rank;
  final Value<String> word;
  final Value<double?> freq;
  final Value<String?> tier;
  final Value<String?> domain;
  const WordsCompanion({
    this.rank = const Value.absent(),
    this.word = const Value.absent(),
    this.freq = const Value.absent(),
    this.tier = const Value.absent(),
    this.domain = const Value.absent(),
  });
  WordsCompanion.insert({
    this.rank = const Value.absent(),
    required String word,
    this.freq = const Value.absent(),
    this.tier = const Value.absent(),
    this.domain = const Value.absent(),
  }) : word = Value(word);
  static Insertable<WordRow> custom({
    Expression<int>? rank,
    Expression<String>? word,
    Expression<double>? freq,
    Expression<String>? tier,
    Expression<String>? domain,
  }) {
    return RawValuesInsertable({
      if (rank != null) 'rank': rank,
      if (word != null) 'word': word,
      if (freq != null) 'freq': freq,
      if (tier != null) 'tier': tier,
      if (domain != null) 'domain': domain,
    });
  }

  WordsCompanion copyWith({
    Value<int>? rank,
    Value<String>? word,
    Value<double?>? freq,
    Value<String?>? tier,
    Value<String?>? domain,
  }) {
    return WordsCompanion(
      rank: rank ?? this.rank,
      word: word ?? this.word,
      freq: freq ?? this.freq,
      tier: tier ?? this.tier,
      domain: domain ?? this.domain,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rank.present) {
      map['rank'] = Variable<int>(rank.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (freq.present) {
      map['freq'] = Variable<double>(freq.value);
    }
    if (tier.present) {
      map['tier'] = Variable<String>(tier.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('rank: $rank, ')
          ..write('word: $word, ')
          ..write('freq: $freq, ')
          ..write('tier: $tier, ')
          ..write('domain: $domain')
          ..write(')'))
        .toString();
  }
}

class $UserProgressTable extends UserProgress
    with TableInfo<$UserProgressTable, UserProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _turnIdMeta = const VerificationMeta('turnId');
  @override
  late final GeneratedColumn<int> turnId = GeneratedColumn<int>(
    'turn_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES turns (id)',
    ),
  );
  static const VerificationMeta _learnedMeta = const VerificationMeta(
    'learned',
  );
  @override
  late final GeneratedColumn<bool> learned = GeneratedColumn<bool>(
    'learned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("learned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastReviewedMeta = const VerificationMeta(
    'lastReviewed',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewed = GeneratedColumn<DateTime>(
    'last_reviewed',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta(
    'reviewCount',
  );
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    turnId,
    learned,
    favorite,
    lastReviewed,
    reviewCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('turn_id')) {
      context.handle(
        _turnIdMeta,
        turnId.isAcceptableOrUnknown(data['turn_id']!, _turnIdMeta),
      );
    }
    if (data.containsKey('learned')) {
      context.handle(
        _learnedMeta,
        learned.isAcceptableOrUnknown(data['learned']!, _learnedMeta),
      );
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
    }
    if (data.containsKey('last_reviewed')) {
      context.handle(
        _lastReviewedMeta,
        lastReviewed.isAcceptableOrUnknown(
          data['last_reviewed']!,
          _lastReviewedMeta,
        ),
      );
    }
    if (data.containsKey('review_count')) {
      context.handle(
        _reviewCountMeta,
        reviewCount.isAcceptableOrUnknown(
          data['review_count']!,
          _reviewCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {turnId};
  @override
  UserProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProgressRow(
      turnId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}turn_id'],
      )!,
      learned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}learned'],
      )!,
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
      lastReviewed: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed'],
      ),
      reviewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_count'],
      )!,
    );
  }

  @override
  $UserProgressTable createAlias(String alias) {
    return $UserProgressTable(attachedDatabase, alias);
  }
}

class UserProgressRow extends DataClass implements Insertable<UserProgressRow> {
  final int turnId;
  final bool learned;
  final bool favorite;
  final DateTime? lastReviewed;
  final int reviewCount;
  const UserProgressRow({
    required this.turnId,
    required this.learned,
    required this.favorite,
    this.lastReviewed,
    required this.reviewCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['turn_id'] = Variable<int>(turnId);
    map['learned'] = Variable<bool>(learned);
    map['favorite'] = Variable<bool>(favorite);
    if (!nullToAbsent || lastReviewed != null) {
      map['last_reviewed'] = Variable<DateTime>(lastReviewed);
    }
    map['review_count'] = Variable<int>(reviewCount);
    return map;
  }

  UserProgressCompanion toCompanion(bool nullToAbsent) {
    return UserProgressCompanion(
      turnId: Value(turnId),
      learned: Value(learned),
      favorite: Value(favorite),
      lastReviewed: lastReviewed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewed),
      reviewCount: Value(reviewCount),
    );
  }

  factory UserProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProgressRow(
      turnId: serializer.fromJson<int>(json['turnId']),
      learned: serializer.fromJson<bool>(json['learned']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      lastReviewed: serializer.fromJson<DateTime?>(json['lastReviewed']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'turnId': serializer.toJson<int>(turnId),
      'learned': serializer.toJson<bool>(learned),
      'favorite': serializer.toJson<bool>(favorite),
      'lastReviewed': serializer.toJson<DateTime?>(lastReviewed),
      'reviewCount': serializer.toJson<int>(reviewCount),
    };
  }

  UserProgressRow copyWith({
    int? turnId,
    bool? learned,
    bool? favorite,
    Value<DateTime?> lastReviewed = const Value.absent(),
    int? reviewCount,
  }) => UserProgressRow(
    turnId: turnId ?? this.turnId,
    learned: learned ?? this.learned,
    favorite: favorite ?? this.favorite,
    lastReviewed: lastReviewed.present ? lastReviewed.value : this.lastReviewed,
    reviewCount: reviewCount ?? this.reviewCount,
  );
  UserProgressRow copyWithCompanion(UserProgressCompanion data) {
    return UserProgressRow(
      turnId: data.turnId.present ? data.turnId.value : this.turnId,
      learned: data.learned.present ? data.learned.value : this.learned,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      lastReviewed: data.lastReviewed.present
          ? data.lastReviewed.value
          : this.lastReviewed,
      reviewCount: data.reviewCount.present
          ? data.reviewCount.value
          : this.reviewCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProgressRow(')
          ..write('turnId: $turnId, ')
          ..write('learned: $learned, ')
          ..write('favorite: $favorite, ')
          ..write('lastReviewed: $lastReviewed, ')
          ..write('reviewCount: $reviewCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(turnId, learned, favorite, lastReviewed, reviewCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProgressRow &&
          other.turnId == this.turnId &&
          other.learned == this.learned &&
          other.favorite == this.favorite &&
          other.lastReviewed == this.lastReviewed &&
          other.reviewCount == this.reviewCount);
}

class UserProgressCompanion extends UpdateCompanion<UserProgressRow> {
  final Value<int> turnId;
  final Value<bool> learned;
  final Value<bool> favorite;
  final Value<DateTime?> lastReviewed;
  final Value<int> reviewCount;
  const UserProgressCompanion({
    this.turnId = const Value.absent(),
    this.learned = const Value.absent(),
    this.favorite = const Value.absent(),
    this.lastReviewed = const Value.absent(),
    this.reviewCount = const Value.absent(),
  });
  UserProgressCompanion.insert({
    this.turnId = const Value.absent(),
    this.learned = const Value.absent(),
    this.favorite = const Value.absent(),
    this.lastReviewed = const Value.absent(),
    this.reviewCount = const Value.absent(),
  });
  static Insertable<UserProgressRow> custom({
    Expression<int>? turnId,
    Expression<bool>? learned,
    Expression<bool>? favorite,
    Expression<DateTime>? lastReviewed,
    Expression<int>? reviewCount,
  }) {
    return RawValuesInsertable({
      if (turnId != null) 'turn_id': turnId,
      if (learned != null) 'learned': learned,
      if (favorite != null) 'favorite': favorite,
      if (lastReviewed != null) 'last_reviewed': lastReviewed,
      if (reviewCount != null) 'review_count': reviewCount,
    });
  }

  UserProgressCompanion copyWith({
    Value<int>? turnId,
    Value<bool>? learned,
    Value<bool>? favorite,
    Value<DateTime?>? lastReviewed,
    Value<int>? reviewCount,
  }) {
    return UserProgressCompanion(
      turnId: turnId ?? this.turnId,
      learned: learned ?? this.learned,
      favorite: favorite ?? this.favorite,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (turnId.present) {
      map['turn_id'] = Variable<int>(turnId.value);
    }
    if (learned.present) {
      map['learned'] = Variable<bool>(learned.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (lastReviewed.present) {
      map['last_reviewed'] = Variable<DateTime>(lastReviewed.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProgressCompanion(')
          ..write('turnId: $turnId, ')
          ..write('learned: $learned, ')
          ..write('favorite: $favorite, ')
          ..write('lastReviewed: $lastReviewed, ')
          ..write('reviewCount: $reviewCount')
          ..write(')'))
        .toString();
  }
}

class $LetterProgressTable extends LetterProgress
    with TableInfo<$LetterProgressTable, LetterProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LetterProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _charMeta = const VerificationMeta('char');
  @override
  late final GeneratedColumn<String> char = GeneratedColumn<String>(
    'char',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _knownMeta = const VerificationMeta('known');
  @override
  late final GeneratedColumn<bool> known = GeneratedColumn<bool>(
    'known',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("known" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _exposureCountMeta = const VerificationMeta(
    'exposureCount',
  );
  @override
  late final GeneratedColumn<int> exposureCount = GeneratedColumn<int>(
    'exposure_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReviewedMeta = const VerificationMeta(
    'lastReviewed',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewed = GeneratedColumn<DateTime>(
    'last_reviewed',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    char,
    known,
    exposureCount,
    lastReviewed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'letter_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<LetterProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('char')) {
      context.handle(
        _charMeta,
        char.isAcceptableOrUnknown(data['char']!, _charMeta),
      );
    } else if (isInserting) {
      context.missing(_charMeta);
    }
    if (data.containsKey('known')) {
      context.handle(
        _knownMeta,
        known.isAcceptableOrUnknown(data['known']!, _knownMeta),
      );
    }
    if (data.containsKey('exposure_count')) {
      context.handle(
        _exposureCountMeta,
        exposureCount.isAcceptableOrUnknown(
          data['exposure_count']!,
          _exposureCountMeta,
        ),
      );
    }
    if (data.containsKey('last_reviewed')) {
      context.handle(
        _lastReviewedMeta,
        lastReviewed.isAcceptableOrUnknown(
          data['last_reviewed']!,
          _lastReviewedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {char};
  @override
  LetterProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LetterProgressRow(
      char: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}char'],
      )!,
      known: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}known'],
      )!,
      exposureCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exposure_count'],
      )!,
      lastReviewed: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed'],
      ),
    );
  }

  @override
  $LetterProgressTable createAlias(String alias) {
    return $LetterProgressTable(attachedDatabase, alias);
  }
}

class LetterProgressRow extends DataClass
    implements Insertable<LetterProgressRow> {
  final String char;
  final bool known;
  final int exposureCount;
  final DateTime? lastReviewed;
  const LetterProgressRow({
    required this.char,
    required this.known,
    required this.exposureCount,
    this.lastReviewed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['char'] = Variable<String>(char);
    map['known'] = Variable<bool>(known);
    map['exposure_count'] = Variable<int>(exposureCount);
    if (!nullToAbsent || lastReviewed != null) {
      map['last_reviewed'] = Variable<DateTime>(lastReviewed);
    }
    return map;
  }

  LetterProgressCompanion toCompanion(bool nullToAbsent) {
    return LetterProgressCompanion(
      char: Value(char),
      known: Value(known),
      exposureCount: Value(exposureCount),
      lastReviewed: lastReviewed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewed),
    );
  }

  factory LetterProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LetterProgressRow(
      char: serializer.fromJson<String>(json['char']),
      known: serializer.fromJson<bool>(json['known']),
      exposureCount: serializer.fromJson<int>(json['exposureCount']),
      lastReviewed: serializer.fromJson<DateTime?>(json['lastReviewed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'char': serializer.toJson<String>(char),
      'known': serializer.toJson<bool>(known),
      'exposureCount': serializer.toJson<int>(exposureCount),
      'lastReviewed': serializer.toJson<DateTime?>(lastReviewed),
    };
  }

  LetterProgressRow copyWith({
    String? char,
    bool? known,
    int? exposureCount,
    Value<DateTime?> lastReviewed = const Value.absent(),
  }) => LetterProgressRow(
    char: char ?? this.char,
    known: known ?? this.known,
    exposureCount: exposureCount ?? this.exposureCount,
    lastReviewed: lastReviewed.present ? lastReviewed.value : this.lastReviewed,
  );
  LetterProgressRow copyWithCompanion(LetterProgressCompanion data) {
    return LetterProgressRow(
      char: data.char.present ? data.char.value : this.char,
      known: data.known.present ? data.known.value : this.known,
      exposureCount: data.exposureCount.present
          ? data.exposureCount.value
          : this.exposureCount,
      lastReviewed: data.lastReviewed.present
          ? data.lastReviewed.value
          : this.lastReviewed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LetterProgressRow(')
          ..write('char: $char, ')
          ..write('known: $known, ')
          ..write('exposureCount: $exposureCount, ')
          ..write('lastReviewed: $lastReviewed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(char, known, exposureCount, lastReviewed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LetterProgressRow &&
          other.char == this.char &&
          other.known == this.known &&
          other.exposureCount == this.exposureCount &&
          other.lastReviewed == this.lastReviewed);
}

class LetterProgressCompanion extends UpdateCompanion<LetterProgressRow> {
  final Value<String> char;
  final Value<bool> known;
  final Value<int> exposureCount;
  final Value<DateTime?> lastReviewed;
  final Value<int> rowid;
  const LetterProgressCompanion({
    this.char = const Value.absent(),
    this.known = const Value.absent(),
    this.exposureCount = const Value.absent(),
    this.lastReviewed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LetterProgressCompanion.insert({
    required String char,
    this.known = const Value.absent(),
    this.exposureCount = const Value.absent(),
    this.lastReviewed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : char = Value(char);
  static Insertable<LetterProgressRow> custom({
    Expression<String>? char,
    Expression<bool>? known,
    Expression<int>? exposureCount,
    Expression<DateTime>? lastReviewed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (char != null) 'char': char,
      if (known != null) 'known': known,
      if (exposureCount != null) 'exposure_count': exposureCount,
      if (lastReviewed != null) 'last_reviewed': lastReviewed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LetterProgressCompanion copyWith({
    Value<String>? char,
    Value<bool>? known,
    Value<int>? exposureCount,
    Value<DateTime?>? lastReviewed,
    Value<int>? rowid,
  }) {
    return LetterProgressCompanion(
      char: char ?? this.char,
      known: known ?? this.known,
      exposureCount: exposureCount ?? this.exposureCount,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (char.present) {
      map['char'] = Variable<String>(char.value);
    }
    if (known.present) {
      map['known'] = Variable<bool>(known.value);
    }
    if (exposureCount.present) {
      map['exposure_count'] = Variable<int>(exposureCount.value);
    }
    if (lastReviewed.present) {
      map['last_reviewed'] = Variable<DateTime>(lastReviewed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LetterProgressCompanion(')
          ..write('char: $char, ')
          ..write('known: $known, ')
          ..write('exposureCount: $exposureCount, ')
          ..write('lastReviewed: $lastReviewed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserMemosTable extends UserMemos
    with TableInfo<$UserMemosTable, UserMemoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserMemosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contextMeta = const VerificationMeta(
    'context',
  );
  @override
  late final GeneratedColumn<String> context = GeneratedColumn<String>(
    'context',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, context, body, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_memos';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserMemoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('context')) {
      context.handle(
        _contextMeta,
        this.context.isAcceptableOrUnknown(data['context']!, _contextMeta),
      );
    } else if (isInserting) {
      context.missing(_contextMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserMemoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserMemoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      context: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserMemosTable createAlias(String alias) {
    return $UserMemosTable(attachedDatabase, alias);
  }
}

class UserMemoRow extends DataClass implements Insertable<UserMemoRow> {
  final int id;
  final String context;
  final String body;
  final DateTime createdAt;
  const UserMemoRow({
    required this.id,
    required this.context,
    required this.body,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['context'] = Variable<String>(context);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserMemosCompanion toCompanion(bool nullToAbsent) {
    return UserMemosCompanion(
      id: Value(id),
      context: Value(context),
      body: Value(body),
      createdAt: Value(createdAt),
    );
  }

  factory UserMemoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserMemoRow(
      id: serializer.fromJson<int>(json['id']),
      context: serializer.fromJson<String>(json['context']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'context': serializer.toJson<String>(context),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserMemoRow copyWith({
    int? id,
    String? context,
    String? body,
    DateTime? createdAt,
  }) => UserMemoRow(
    id: id ?? this.id,
    context: context ?? this.context,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
  );
  UserMemoRow copyWithCompanion(UserMemosCompanion data) {
    return UserMemoRow(
      id: data.id.present ? data.id.value : this.id,
      context: data.context.present ? data.context.value : this.context,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserMemoRow(')
          ..write('id: $id, ')
          ..write('context: $context, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, context, body, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserMemoRow &&
          other.id == this.id &&
          other.context == this.context &&
          other.body == this.body &&
          other.createdAt == this.createdAt);
}

class UserMemosCompanion extends UpdateCompanion<UserMemoRow> {
  final Value<int> id;
  final Value<String> context;
  final Value<String> body;
  final Value<DateTime> createdAt;
  const UserMemosCompanion({
    this.id = const Value.absent(),
    this.context = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UserMemosCompanion.insert({
    this.id = const Value.absent(),
    required String context,
    required String body,
    this.createdAt = const Value.absent(),
  }) : context = Value(context),
       body = Value(body);
  static Insertable<UserMemoRow> custom({
    Expression<int>? id,
    Expression<String>? context,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (context != null) 'context': context,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UserMemosCompanion copyWith({
    Value<int>? id,
    Value<String>? context,
    Value<String>? body,
    Value<DateTime>? createdAt,
  }) {
    return UserMemosCompanion(
      id: id ?? this.id,
      context: context ?? this.context,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (context.present) {
      map['context'] = Variable<String>(context.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserMemosCompanion(')
          ..write('id: $id, ')
          ..write('context: $context, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TurnsTable turns = $TurnsTable(this);
  late final $WordsTable words = $WordsTable(this);
  late final $UserProgressTable userProgress = $UserProgressTable(this);
  late final $LetterProgressTable letterProgress = $LetterProgressTable(this);
  late final $UserMemosTable userMemos = $UserMemosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    turns,
    words,
    userProgress,
    letterProgress,
    userMemos,
  ];
}

typedef $$TurnsTableCreateCompanionBuilder =
    TurnsCompanion Function({
      Value<int> id,
      required String level,
      Value<String?> episodeId,
      required int num,
      required String speaker,
      required String th,
      Value<String?> roman,
      Value<String?> ko,
      Value<String?> note,
      Value<String?> tagsJson,
    });
typedef $$TurnsTableUpdateCompanionBuilder =
    TurnsCompanion Function({
      Value<int> id,
      Value<String> level,
      Value<String?> episodeId,
      Value<int> num,
      Value<String> speaker,
      Value<String> th,
      Value<String?> roman,
      Value<String?> ko,
      Value<String?> note,
      Value<String?> tagsJson,
    });

final class $$TurnsTableReferences
    extends BaseReferences<_$AppDatabase, $TurnsTable, TurnRow> {
  $$TurnsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$UserProgressTable, List<UserProgressRow>>
  _userProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.userProgress,
    aliasName: $_aliasNameGenerator(db.turns.id, db.userProgress.turnId),
  );

  $$UserProgressTableProcessedTableManager get userProgressRefs {
    final manager = $$UserProgressTableTableManager(
      $_db,
      $_db.userProgress,
    ).filter((f) => f.turnId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userProgressRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TurnsTableFilterComposer extends Composer<_$AppDatabase, $TurnsTable> {
  $$TurnsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get num => $composableBuilder(
    column: $table.num,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get speaker => $composableBuilder(
    column: $table.speaker,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get th => $composableBuilder(
    column: $table.th,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roman => $composableBuilder(
    column: $table.roman,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ko => $composableBuilder(
    column: $table.ko,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> userProgressRefs(
    Expression<bool> Function($$UserProgressTableFilterComposer f) f,
  ) {
    final $$UserProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userProgress,
      getReferencedColumn: (t) => t.turnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserProgressTableFilterComposer(
            $db: $db,
            $table: $db.userProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TurnsTableOrderingComposer
    extends Composer<_$AppDatabase, $TurnsTable> {
  $$TurnsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get num => $composableBuilder(
    column: $table.num,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get speaker => $composableBuilder(
    column: $table.speaker,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get th => $composableBuilder(
    column: $table.th,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roman => $composableBuilder(
    column: $table.roman,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ko => $composableBuilder(
    column: $table.ko,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TurnsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TurnsTable> {
  $$TurnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => column);

  GeneratedColumn<int> get num =>
      $composableBuilder(column: $table.num, builder: (column) => column);

  GeneratedColumn<String> get speaker =>
      $composableBuilder(column: $table.speaker, builder: (column) => column);

  GeneratedColumn<String> get th =>
      $composableBuilder(column: $table.th, builder: (column) => column);

  GeneratedColumn<String> get roman =>
      $composableBuilder(column: $table.roman, builder: (column) => column);

  GeneratedColumn<String> get ko =>
      $composableBuilder(column: $table.ko, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  Expression<T> userProgressRefs<T extends Object>(
    Expression<T> Function($$UserProgressTableAnnotationComposer a) f,
  ) {
    final $$UserProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userProgress,
      getReferencedColumn: (t) => t.turnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.userProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TurnsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TurnsTable,
          TurnRow,
          $$TurnsTableFilterComposer,
          $$TurnsTableOrderingComposer,
          $$TurnsTableAnnotationComposer,
          $$TurnsTableCreateCompanionBuilder,
          $$TurnsTableUpdateCompanionBuilder,
          (TurnRow, $$TurnsTableReferences),
          TurnRow,
          PrefetchHooks Function({bool userProgressRefs})
        > {
  $$TurnsTableTableManager(_$AppDatabase db, $TurnsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TurnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TurnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TurnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<String?> episodeId = const Value.absent(),
                Value<int> num = const Value.absent(),
                Value<String> speaker = const Value.absent(),
                Value<String> th = const Value.absent(),
                Value<String?> roman = const Value.absent(),
                Value<String?> ko = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> tagsJson = const Value.absent(),
              }) => TurnsCompanion(
                id: id,
                level: level,
                episodeId: episodeId,
                num: num,
                speaker: speaker,
                th: th,
                roman: roman,
                ko: ko,
                note: note,
                tagsJson: tagsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String level,
                Value<String?> episodeId = const Value.absent(),
                required int num,
                required String speaker,
                required String th,
                Value<String?> roman = const Value.absent(),
                Value<String?> ko = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> tagsJson = const Value.absent(),
              }) => TurnsCompanion.insert(
                id: id,
                level: level,
                episodeId: episodeId,
                num: num,
                speaker: speaker,
                th: th,
                roman: roman,
                ko: ko,
                note: note,
                tagsJson: tagsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TurnsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({userProgressRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (userProgressRefs) db.userProgress],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (userProgressRefs)
                    await $_getPrefetchedData<
                      TurnRow,
                      $TurnsTable,
                      UserProgressRow
                    >(
                      currentTable: table,
                      referencedTable: $$TurnsTableReferences
                          ._userProgressRefsTable(db),
                      managerFromTypedResult: (p0) => $$TurnsTableReferences(
                        db,
                        table,
                        p0,
                      ).userProgressRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.turnId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TurnsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TurnsTable,
      TurnRow,
      $$TurnsTableFilterComposer,
      $$TurnsTableOrderingComposer,
      $$TurnsTableAnnotationComposer,
      $$TurnsTableCreateCompanionBuilder,
      $$TurnsTableUpdateCompanionBuilder,
      (TurnRow, $$TurnsTableReferences),
      TurnRow,
      PrefetchHooks Function({bool userProgressRefs})
    >;
typedef $$WordsTableCreateCompanionBuilder =
    WordsCompanion Function({
      Value<int> rank,
      required String word,
      Value<double?> freq,
      Value<String?> tier,
      Value<String?> domain,
    });
typedef $$WordsTableUpdateCompanionBuilder =
    WordsCompanion Function({
      Value<int> rank,
      Value<String> word,
      Value<double?> freq,
      Value<String?> tier,
      Value<String?> domain,
    });

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get freq => $composableBuilder(
    column: $table.freq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get freq => $composableBuilder(
    column: $table.freq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<double> get freq =>
      $composableBuilder(column: $table.freq, builder: (column) => column);

  GeneratedColumn<String> get tier =>
      $composableBuilder(column: $table.tier, builder: (column) => column);

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTable,
          WordRow,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (WordRow, BaseReferences<_$AppDatabase, $WordsTable, WordRow>),
          WordRow,
          PrefetchHooks Function()
        > {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rank = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<double?> freq = const Value.absent(),
                Value<String?> tier = const Value.absent(),
                Value<String?> domain = const Value.absent(),
              }) => WordsCompanion(
                rank: rank,
                word: word,
                freq: freq,
                tier: tier,
                domain: domain,
              ),
          createCompanionCallback:
              ({
                Value<int> rank = const Value.absent(),
                required String word,
                Value<double?> freq = const Value.absent(),
                Value<String?> tier = const Value.absent(),
                Value<String?> domain = const Value.absent(),
              }) => WordsCompanion.insert(
                rank: rank,
                word: word,
                freq: freq,
                tier: tier,
                domain: domain,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTable,
      WordRow,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (WordRow, BaseReferences<_$AppDatabase, $WordsTable, WordRow>),
      WordRow,
      PrefetchHooks Function()
    >;
typedef $$UserProgressTableCreateCompanionBuilder =
    UserProgressCompanion Function({
      Value<int> turnId,
      Value<bool> learned,
      Value<bool> favorite,
      Value<DateTime?> lastReviewed,
      Value<int> reviewCount,
    });
typedef $$UserProgressTableUpdateCompanionBuilder =
    UserProgressCompanion Function({
      Value<int> turnId,
      Value<bool> learned,
      Value<bool> favorite,
      Value<DateTime?> lastReviewed,
      Value<int> reviewCount,
    });

final class $$UserProgressTableReferences
    extends BaseReferences<_$AppDatabase, $UserProgressTable, UserProgressRow> {
  $$UserProgressTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TurnsTable _turnIdTable(_$AppDatabase db) => db.turns.createAlias(
    $_aliasNameGenerator(db.userProgress.turnId, db.turns.id),
  );

  $$TurnsTableProcessedTableManager get turnId {
    final $_column = $_itemColumn<int>('turn_id')!;

    final manager = $$TurnsTableTableManager(
      $_db,
      $_db.turns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_turnIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserProgressTableFilterComposer
    extends Composer<_$AppDatabase, $UserProgressTable> {
  $$UserProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get learned => $composableBuilder(
    column: $table.learned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnFilters(column),
  );

  $$TurnsTableFilterComposer get turnId {
    final $$TurnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.turnId,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableFilterComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProgressTable> {
  $$UserProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get learned => $composableBuilder(
    column: $table.learned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$TurnsTableOrderingComposer get turnId {
    final $$TurnsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.turnId,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableOrderingComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProgressTable> {
  $$UserProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get learned =>
      $composableBuilder(column: $table.learned, builder: (column) => column);

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => column,
  );

  $$TurnsTableAnnotationComposer get turnId {
    final $$TurnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.turnId,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableAnnotationComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProgressTable,
          UserProgressRow,
          $$UserProgressTableFilterComposer,
          $$UserProgressTableOrderingComposer,
          $$UserProgressTableAnnotationComposer,
          $$UserProgressTableCreateCompanionBuilder,
          $$UserProgressTableUpdateCompanionBuilder,
          (UserProgressRow, $$UserProgressTableReferences),
          UserProgressRow,
          PrefetchHooks Function({bool turnId})
        > {
  $$UserProgressTableTableManager(_$AppDatabase db, $UserProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> turnId = const Value.absent(),
                Value<bool> learned = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<DateTime?> lastReviewed = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
              }) => UserProgressCompanion(
                turnId: turnId,
                learned: learned,
                favorite: favorite,
                lastReviewed: lastReviewed,
                reviewCount: reviewCount,
              ),
          createCompanionCallback:
              ({
                Value<int> turnId = const Value.absent(),
                Value<bool> learned = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<DateTime?> lastReviewed = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
              }) => UserProgressCompanion.insert(
                turnId: turnId,
                learned: learned,
                favorite: favorite,
                lastReviewed: lastReviewed,
                reviewCount: reviewCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({turnId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (turnId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.turnId,
                                referencedTable: $$UserProgressTableReferences
                                    ._turnIdTable(db),
                                referencedColumn: $$UserProgressTableReferences
                                    ._turnIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UserProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProgressTable,
      UserProgressRow,
      $$UserProgressTableFilterComposer,
      $$UserProgressTableOrderingComposer,
      $$UserProgressTableAnnotationComposer,
      $$UserProgressTableCreateCompanionBuilder,
      $$UserProgressTableUpdateCompanionBuilder,
      (UserProgressRow, $$UserProgressTableReferences),
      UserProgressRow,
      PrefetchHooks Function({bool turnId})
    >;
typedef $$LetterProgressTableCreateCompanionBuilder =
    LetterProgressCompanion Function({
      required String char,
      Value<bool> known,
      Value<int> exposureCount,
      Value<DateTime?> lastReviewed,
      Value<int> rowid,
    });
typedef $$LetterProgressTableUpdateCompanionBuilder =
    LetterProgressCompanion Function({
      Value<String> char,
      Value<bool> known,
      Value<int> exposureCount,
      Value<DateTime?> lastReviewed,
      Value<int> rowid,
    });

class $$LetterProgressTableFilterComposer
    extends Composer<_$AppDatabase, $LetterProgressTable> {
  $$LetterProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get char => $composableBuilder(
    column: $table.char,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get known => $composableBuilder(
    column: $table.known,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exposureCount => $composableBuilder(
    column: $table.exposureCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LetterProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $LetterProgressTable> {
  $$LetterProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get char => $composableBuilder(
    column: $table.char,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get known => $composableBuilder(
    column: $table.known,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exposureCount => $composableBuilder(
    column: $table.exposureCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LetterProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $LetterProgressTable> {
  $$LetterProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get char =>
      $composableBuilder(column: $table.char, builder: (column) => column);

  GeneratedColumn<bool> get known =>
      $composableBuilder(column: $table.known, builder: (column) => column);

  GeneratedColumn<int> get exposureCount => $composableBuilder(
    column: $table.exposureCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => column,
  );
}

class $$LetterProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LetterProgressTable,
          LetterProgressRow,
          $$LetterProgressTableFilterComposer,
          $$LetterProgressTableOrderingComposer,
          $$LetterProgressTableAnnotationComposer,
          $$LetterProgressTableCreateCompanionBuilder,
          $$LetterProgressTableUpdateCompanionBuilder,
          (
            LetterProgressRow,
            BaseReferences<
              _$AppDatabase,
              $LetterProgressTable,
              LetterProgressRow
            >,
          ),
          LetterProgressRow,
          PrefetchHooks Function()
        > {
  $$LetterProgressTableTableManager(
    _$AppDatabase db,
    $LetterProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LetterProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LetterProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LetterProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> char = const Value.absent(),
                Value<bool> known = const Value.absent(),
                Value<int> exposureCount = const Value.absent(),
                Value<DateTime?> lastReviewed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LetterProgressCompanion(
                char: char,
                known: known,
                exposureCount: exposureCount,
                lastReviewed: lastReviewed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String char,
                Value<bool> known = const Value.absent(),
                Value<int> exposureCount = const Value.absent(),
                Value<DateTime?> lastReviewed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LetterProgressCompanion.insert(
                char: char,
                known: known,
                exposureCount: exposureCount,
                lastReviewed: lastReviewed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LetterProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LetterProgressTable,
      LetterProgressRow,
      $$LetterProgressTableFilterComposer,
      $$LetterProgressTableOrderingComposer,
      $$LetterProgressTableAnnotationComposer,
      $$LetterProgressTableCreateCompanionBuilder,
      $$LetterProgressTableUpdateCompanionBuilder,
      (
        LetterProgressRow,
        BaseReferences<_$AppDatabase, $LetterProgressTable, LetterProgressRow>,
      ),
      LetterProgressRow,
      PrefetchHooks Function()
    >;
typedef $$UserMemosTableCreateCompanionBuilder =
    UserMemosCompanion Function({
      Value<int> id,
      required String context,
      required String body,
      Value<DateTime> createdAt,
    });
typedef $$UserMemosTableUpdateCompanionBuilder =
    UserMemosCompanion Function({
      Value<int> id,
      Value<String> context,
      Value<String> body,
      Value<DateTime> createdAt,
    });

class $$UserMemosTableFilterComposer
    extends Composer<_$AppDatabase, $UserMemosTable> {
  $$UserMemosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserMemosTableOrderingComposer
    extends Composer<_$AppDatabase, $UserMemosTable> {
  $$UserMemosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserMemosTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserMemosTable> {
  $$UserMemosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UserMemosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserMemosTable,
          UserMemoRow,
          $$UserMemosTableFilterComposer,
          $$UserMemosTableOrderingComposer,
          $$UserMemosTableAnnotationComposer,
          $$UserMemosTableCreateCompanionBuilder,
          $$UserMemosTableUpdateCompanionBuilder,
          (
            UserMemoRow,
            BaseReferences<_$AppDatabase, $UserMemosTable, UserMemoRow>,
          ),
          UserMemoRow,
          PrefetchHooks Function()
        > {
  $$UserMemosTableTableManager(_$AppDatabase db, $UserMemosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserMemosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserMemosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserMemosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> context = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UserMemosCompanion(
                id: id,
                context: context,
                body: body,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String context,
                required String body,
                Value<DateTime> createdAt = const Value.absent(),
              }) => UserMemosCompanion.insert(
                id: id,
                context: context,
                body: body,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserMemosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserMemosTable,
      UserMemoRow,
      $$UserMemosTableFilterComposer,
      $$UserMemosTableOrderingComposer,
      $$UserMemosTableAnnotationComposer,
      $$UserMemosTableCreateCompanionBuilder,
      $$UserMemosTableUpdateCompanionBuilder,
      (
        UserMemoRow,
        BaseReferences<_$AppDatabase, $UserMemosTable, UserMemoRow>,
      ),
      UserMemoRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TurnsTableTableManager get turns =>
      $$TurnsTableTableManager(_db, _db.turns);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$UserProgressTableTableManager get userProgress =>
      $$UserProgressTableTableManager(_db, _db.userProgress);
  $$LetterProgressTableTableManager get letterProgress =>
      $$LetterProgressTableTableManager(_db, _db.letterProgress);
  $$UserMemosTableTableManager get userMemos =>
      $$UserMemosTableTableManager(_db, _db.userMemos);
}

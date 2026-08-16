import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'thai_dict_service.dart';

/// 인덱싱된 문장 하나. 앱의 모든 문장 소스(대화·문법·코퍼스 청크)를 통합한 단위.
class IndexedSentence {
  final String th;
  final String? roman;
  final String? ko;
  final String source; // 예: '대화 L1', '어말조사', '코퍼스'
  final List<Map<String, dynamic>> tokens; // [{text, compound}]

  IndexedSentence({
    required this.th,
    this.roman,
    this.ko,
    required this.source,
    required this.tokens,
  });
}

/// 검색 결과의 청크(단어) 하나 + 그 청크가 등장하는 문장들.
class ChunkHit {
  final String chunk;
  final ThaiWordInfo? info;
  final List<IndexedSentence> sentences;

  ChunkHit({
    required this.chunk,
    this.info,
    required this.sentences,
  });
}

/// 앱의 모든 문장을 청크(단어) 기준으로 역인덱싱해 검색 제공.
///
/// - 분절은 빈도 상위 단어 사전 최장일치 (ThaiDictService).
/// - 검색: 태국어 / 로마자 / 한국어 뜻 자동 판별.
class ChunkIndexService {
  ChunkIndexService._();
  static final ChunkIndexService instance = ChunkIndexService._();

  final List<IndexedSentence> _sentences = [];
  final Map<String, List<int>> _byChunk = {}; // chunk → sentence indices
  bool _loaded = false;
  bool _loading = false;

  int get sentenceCount => _sentences.length;
  int get chunkCount => _byChunk.length;

  Future<void> ensureLoaded() async {
    if (_loaded || _loading) return;
    _loading = true;
    await ThaiDictService.instance.ensureLoaded();

    await _loadDialogues();
    await _loadGrammar();
    await _loadCorpusChunks();

    _buildIndex();
    _loaded = true;
    _loading = false;
  }

  Future<void> _loadDialogues() async {
    for (final level in ['L1', 'L2', 'L3']) {
      final Map<String, dynamic> data;
      try {
        final raw =
            await rootBundle.loadString('assets/data/dialogues/$level.json');
        data = json.decode(raw) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      final units =
          (data['episodes'] as List?) ?? (data['dialogues'] as List?) ?? [];
      for (final ep in units) {
        final turns = ((ep as Map)['turns'] as List?) ?? [];
        for (final t in turns) {
          final m = t as Map<String, dynamic>;
          final th = m['th'] as String?;
          if (th == null || th.isEmpty) continue;
          _sentences.add(IndexedSentence(
            th: th,
            roman: m['roman'] as String?,
            ko: m['ko'] as String?,
            source: '대화 $level',
            tokens: _segment(th),
          ));
        }
      }
    }
  }

  Future<void> _loadGrammar() async {
    final Map<String, dynamic> data;
    try {
      final raw = await rootBundle.loadString('assets/data/grammar/sfp.json');
      data = json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final items = (data['items'] as List?) ?? [];
    for (final item in items) {
      final examples = ((item as Map)['examples'] as List?) ?? [];
      for (final ex in examples) {
        final m = ex as Map<String, dynamic>;
        final th = m['th'] as String?;
        if (th == null || th.isEmpty) continue;
        _sentences.add(IndexedSentence(
          th: th,
          ko: m['ko'] as String?,
          source: '어말조사 ${item['sfp']}',
          tokens: _segment(th),
        ));
      }
    }
  }

  Future<void> _loadCorpusChunks() async {
    final Map<String, dynamic> data;
    try {
      final raw =
          await rootBundle.loadString('assets/data/chunks/th_chunks.json');
      data = json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final chunks = (data['chunks'] as List?) ?? [];
    for (final c in chunks) {
      final m = c as Map<String, dynamic>;
      final th = m['th'] as String?;
      if (th == null || th.isEmpty) continue;
      _sentences.add(IndexedSentence(
        th: th,
        ko: m['ko'] as String?,
        source: '코퍼스 ${m['level'] ?? ''}'.trim(),
        tokens: _segment(th),
      ));
    }
  }

  /// 외부용: 문장을 청크 토큰으로 분절. ensureLoaded 이후 사용.
  List<Map<String, dynamic>> tokensFor(String th) => _segment(th);

  List<Map<String, dynamic>> _segment(String th) =>
      ThaiDictService.instance.segment(th);

  void _buildIndex() {
    for (var si = 0; si < _sentences.length; si++) {
      final seen = <String>{};
      for (final t in _sentences[si].tokens) {
        final txt = t['text'] as String? ?? '';
        if (txt.isEmpty || t['compound'] != true) continue;
        if (seen.contains(txt)) continue;
        seen.add(txt);
        _byChunk.putIfAbsent(txt, () => []).add(si);
      }
    }
  }

  ChunkHit _hitFor(String chunk) {
    return ChunkHit(
      chunk: chunk,
      info: ThaiDictService.instance.lookup(chunk),
      sentences: (_byChunk[chunk] ?? []).map((i) => _sentences[i]).toList(),
    );
  }

  static final _hangul = RegExp(r'[가-힣]');
  static final _thai = RegExp(r'[฀-๿]');

  /// 청크 검색. 태국어·로마자·한국어 자동 판별.
  List<ChunkHit> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return [];

    final matches = <String>{};
    if (_thai.hasMatch(q)) {
      // 태국어: 청크에 부분일치
      for (final chunk in _byChunk.keys) {
        if (chunk.contains(q) || (q.contains(chunk) && chunk.length >= 2)) {
          matches.add(chunk);
        }
      }
    } else if (_hangul.hasMatch(q)) {
      // 한국어: 문장 뜻(ko)에 부분일치하는 문장들의 청크
      for (var si = 0; si < _sentences.length; si++) {
        final s = _sentences[si];
        if (s.ko == null || !s.ko!.contains(q)) continue;
        for (final t in s.tokens) {
          if (t['compound'] == true) matches.add(t['text'] as String);
        }
      }
    } else {
      // 로마자: 문장 roman 부분일치
      final nq = q.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (nq.isEmpty) return [];
      for (var si = 0; si < _sentences.length; si++) {
        final s = _sentences[si];
        final roman = s.roman?.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
        if (roman == null || !roman.contains(nq)) continue;
        for (final t in s.tokens) {
          if (t['compound'] == true) matches.add(t['text'] as String);
        }
      }
    }

    final hits = matches.map(_hitFor).toList()
      // 다(多)문장 청크 우선, 그다음 짧은 청크 우선
      ..sort((a, b) {
        final c = b.sentences.length.compareTo(a.sentences.length);
        if (c != 0) return c;
        return a.chunk.length.compareTo(b.chunk.length);
      });
    return hits;
  }

  /// 한국어 질의가 청크에 없을 때 문장 번역(ko) 직접 검색 폴백.
  List<IndexedSentence> searchSentencesByKo(String query) {
    final q = query.trim();
    if (q.isEmpty) return [];
    return _sentences
        .where((s) => s.ko != null && s.ko!.contains(q))
        .toList(growable: false);
  }
}

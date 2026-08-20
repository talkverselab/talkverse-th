import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/chunk_index_service.dart';
import '../services/tts_service.dart';
import '../widgets/selectable_thai.dart';
import '../widgets/thai_decor.dart';

/// 청크(단어) 기준 문장 검색.
/// 예: 'อร่อย' / '아러이' / '맛있' → 청크 목록 → 청크별 문장 → 문장 안 청크 탐색.
class ChunkSearchScreen extends StatefulWidget {
  const ChunkSearchScreen({super.key});

  @override
  State<ChunkSearchScreen> createState() => _ChunkSearchScreenState();
}

class _ChunkSearchScreenState extends State<ChunkSearchScreen> {
  final _controller = TextEditingController();
  bool _ready = false;
  List<ChunkHit> _hits = [];
  List<IndexedSentence> _koFallback = [];
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    ChunkIndexService.instance.ensureLoaded().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String q) {
    final svc = ChunkIndexService.instance;
    final hits = svc.search(q);
    setState(() {
      _lastQuery = q.trim();
      _hits = hits;
      // 한국어 질의인데 청크 매치가 빈약하면 문장 번역 직접 검색도 함께
      _koFallback =
          RegExp(r'[가-힣]').hasMatch(q) ? svc.searchSentencesByKo(q) : [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.khram,
        elevation: 0,
        title: const Text('청크 검색', style: TextStyle(color: AppColors.khram)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _search,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.khram,
                fontFamilyFallback: AppTheme.fontFallback,
              ),
              decoration: InputDecoration(
                hintText: 'อร่อย · 아러이 · 맛있다',
                hintStyle: const TextStyle(
                    color: AppColors.khramLight, fontSize: 15),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.kluayMai),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.khramLight),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      ),
                filled: true,
                fillColor: AppColors.creamDeep,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.thong),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.kluayMai, width: 1.5),
                ),
              ),
            ),
          ),
          const LaiThaiDivider(height: 10),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_ready) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.kluayMai),
            SizedBox(height: 12),
            Text('사전·문장 인덱스 준비 중…',
                style: TextStyle(color: AppColors.khramLight, fontSize: 13)),
          ],
        ),
      );
    }
    if (_lastQuery.isEmpty) {
      final svc = ChunkIndexService.instance;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GoldEmblem(text: 'หา', size: 56),
            const SizedBox(height: 16),
            Text(
              '문장 ${svc.sentenceCount}개 · 청크 ${svc.chunkCount}개 인덱스',
              style: const TextStyle(
                  color: AppColors.khramLight, fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              '태국어·한글 독음·한국어로 검색하세요',
              style: TextStyle(
                color: AppColors.khram,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    if (_hits.isEmpty && _koFallback.isEmpty) {
      return const Center(
        child: Text('일치하는 청크가 없어요',
            style: TextStyle(color: AppColors.khramLight, fontSize: 14)),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ..._hits
            .take(50)
            .map((h) => _ChunkCard(hit: h, key: ValueKey('c:${h.chunk}'))),
        if (_koFallback.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            '문장 번역 일치',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.kluayMai,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          ..._koFallback.take(30).map((s) => _SentenceTile(sentence: s)),
        ],
      ],
    );
  }
}

class _ChunkCard extends StatefulWidget {
  final ChunkHit hit;
  const _ChunkCard({required this.hit, super.key});

  @override
  State<_ChunkCard> createState() => _ChunkCardState();
}

class _ChunkCardState extends State<_ChunkCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.hit;
    final info = h.info;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.creamDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _expanded
              ? AppColors.kluayMai
              : AppColors.thong.withValues(alpha: 0.6),
          width: _expanded ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // 청크 자체 — 탭하면 청크 정보 시트
                  InkWell(
                    onTap: () => showChunkSheet(context, h.chunk),
                    child: Text(
                      h.chunk,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.khram,
                        height: 1.3,
                        fontFamilyFallback: AppTheme.fontFallback,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (info != null)
                          Text(
                            '빈도 #${info.rank} · ${info.tier}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kluayMai,
                            ),
                          ),
                        if (info != null && info.domain.isNotEmpty)
                          Text(
                            info.domain,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.khramLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up,
                        size: 20, color: AppColors.kluayMai),
                    onPressed: () => TtsService.instance.speak(h.chunk),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.thong.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.thong),
                    ),
                    child: Text(
                      '문장 ${h.sentences.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.khram,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.khramLight,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.thong),
            ...h.sentences.take(30).map(
                  (s) => _SentenceTile(sentence: s, highlight: h.chunk),
                ),
          ],
        ],
      ),
    );
  }
}

class _SentenceTile extends StatelessWidget {
  final IndexedSentence sentence;
  final String? highlight;
  const _SentenceTile({required this.sentence, this.highlight});

  @override
  Widget build(BuildContext context) {
    final s = sentence;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.thong.withValues(alpha: 0.25)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SelectableThaiText(
                  text: s.th,
                  tokens: s.tokens,
                  highlightText: highlight,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.khram,
                    height: 1.4,
                    fontFamilyFallback: AppTheme.fontFallback,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up,
                    size: 18, color: AppColors.kluayMai),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => TtsService.instance.speak(s.th),
              ),
            ],
          ),
          if (s.roman != null)
            Text(
              s.roman!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.khramLight,
              ),
            ),
          if (s.ko != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                s.ko!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.khram,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              s.source,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.khramLight,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

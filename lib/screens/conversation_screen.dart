import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/chunk_index_service.dart';
import '../widgets/thai_decor.dart';
import 'chunk_search_screen.dart';
import 'episode_screen.dart';
import 'grammar_lesson_screen.dart';
import 'sentence_flashcard_screen.dart';

/// 회화(다이얼로그) 허브 — 스토리 에피소드 + 자체 콘텐츠 + 코퍼스.
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await EpisodeCatalog.instance.ensureLoaded();
    await ChunkIndexService.instance.ensureLoaded();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('회화',
                style: TextStyle(
                    color: AppColors.khram,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('บทสนทนา',
                style: TextStyle(
                    color: AppColors.khramLight,
                    fontSize: 10,
                    letterSpacing: 2)),
          ],
        ),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.khram,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kluayMai))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _storyHub()),
        SliverToBoxAdapter(child: _contentHub()),
        SliverToBoxAdapter(child: _corpusHub()),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _storyHub() {
    final catalog = EpisodeCatalog.instance;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final level in ['L1', 'L2', 'L3'])
            if (catalog.forLevel(level).isNotEmpty) ...[
              Row(
                children: [
                  GoldEmblem(text: level, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${EpisodeCatalog.levelLabels[level]} · ${catalog.forLevel(level).length}편',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.khram,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: catalog.forLevel(level).length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final meta = catalog.forLevel(level)[i];
                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EpisodeScreen(meta: meta)),
                      ),
                      child: Container(
                        width: 96,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: AppColors.kluayMai, width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(meta.emoji,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(
                              '${i + 1}. ${meta.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.khram,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _contentHub() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              GoldEmblem(text: 'เรียน', size: 22),
              SizedBox(width: 8),
              Text(
                '우리 콘텐츠 (자체 제작)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.khram,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _HubCard(
            title: '어말조사 (คำลงท้าย)',
            sub: 'นะ·ครับ·ค่ะ·ไหม… 말맛의 핵심 12개',
            emblem: 'นะ',
            color: const Color(0xFFAD1457),
            builder: (_) => const GrammarLessonScreen(),
          ),
          const SizedBox(height: 8),
          _HubCard(
            title: '문장 플래시카드',
            sub: '전 레벨 랜덤 20문장 · 뜻 뒤집기 · 남/녀 음성',
            emblem: 'ทวน',
            color: AppColors.morakot,
            builder: (_) => const SentenceFlashcardScreen(),
          ),
        ],
      ),
    );
  }

  Widget _corpusHub() {
    final count = ChunkIndexService.instance.sentenceCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const GoldEmblem(text: 'คุย', size: 22),
              const SizedBox(width: 8),
              const Text(
                'Netflix 원어 코퍼스',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.khram,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.morakot.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '문장 $count',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.morakot,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _HubCard(
            title: '청크 검색',
            sub: '태국어·로마자·한국어로 실전 문장 검색',
            emblem: 'หา',
            color: AppColors.kluayMai,
            builder: (_) => const ChunkSearchScreen(),
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final String title;
  final String sub;
  final String emblem;
  final Color color;
  final WidgetBuilder builder;

  const _HubCard({
    required this.title,
    required this.sub,
    required this.emblem,
    required this.color,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: builder)),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.2),
        ),
        child: Row(
          children: [
            GoldEmblem(text: emblem, size: 40, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.khram,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.khramLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

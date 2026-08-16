import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../main.dart';
import '../services/tts_service.dart';
import '../widgets/thai_decor.dart';
import 'episode_screen.dart';

/// 카드 학습 상태: 몰라요 / 공부중 / 알아요.
/// DB 매핑: 알아요=learned true · 공부중=learned false+reviewCount>0 ·
/// 몰라요=learned false+reviewCount 0.
enum CardState { unknown, studying, known }

/// 회화 문장 플래시카드.
/// - 기본: 한국어 앞면 → 뒤집으면 태국어 (방향 토글 가능, 설정 저장)
/// - 한국어 앞면에는 로마자 힌트 표시 (힌트 토글 가능, 설정 저장)
/// - [meta] 있으면 해당 에피소드 전체 턴, 없으면 전 레벨 랜덤 20문장
/// - [initialIndex]로 특정 턴부터 시작 (에피소드 버블 탭 진입)
class SentenceFlashcardScreen extends StatefulWidget {
  final EpisodeMeta? meta;
  final int initialIndex;
  const SentenceFlashcardScreen({super.key, this.meta, this.initialIndex = 0});

  @override
  State<SentenceFlashcardScreen> createState() =>
      _SentenceFlashcardScreenState();
}

class _SentenceFlashcardScreenState extends State<SentenceFlashcardScreen> {
  static const _kKoFirst = 'flash_ko_first';
  static const _kShowHint = 'flash_show_hint';

  List<TurnRow> _cards = [];
  final Map<int, CardState> _states = {}; // turnId → 상태
  bool _loading = true;
  int _index = 0;
  bool _flipped = false;
  bool _koFirst = true;
  bool _showHint = true;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    _koFirst = _prefs!.getBool(_kKoFirst) ?? true;
    _showHint = _prefs!.getBool(_kShowHint) ?? true;

    List<TurnRow> turns;
    final meta = widget.meta;
    if (meta != null) {
      turns = await (appDb.select(appDb.turns)
            ..where((t) =>
                t.level.equals(meta.level) & t.episodeId.equals(meta.id))
            ..orderBy([(t) => OrderingTerm.asc(t.num)]))
          .get();
    } else {
      turns = await appDb.select(appDb.turns).get();
      turns.shuffle();
      turns = turns.take(20).toList();
    }
    final progress = await appDb.select(appDb.userProgress).get();
    final byId = {for (final p in progress) p.turnId: p};
    if (!mounted) return;
    setState(() {
      _cards = turns;
      for (final t in turns) {
        final p = byId[t.id];
        _states[t.id] = p == null
            ? CardState.unknown
            : p.learned
                ? CardState.known
                : (p.reviewCount > 0 ? CardState.studying : CardState.unknown);
      }
      _index =
          turns.isEmpty ? 0 : widget.initialIndex.clamp(0, turns.length - 1);
      _loading = false;
    });
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= _cards.length) return;
    setState(() {
      _index = next;
      _flipped = false;
    });
  }

  Future<void> _mark(CardState state) async {
    final turn = _cards[_index];
    setState(() => _states[turn.id] = state);
    await appDb.into(appDb.userProgress).insertOnConflictUpdate(
          UserProgressCompanion(
            turnId: Value(turn.id),
            learned: Value(state == CardState.known),
            reviewCount: Value(state == CardState.unknown ? 0 : 1),
            lastReviewed: Value(DateTime.now()),
          ),
        );
    if (!mounted) return;
    if (_index < _cards.length - 1) {
      _go(1);
    } else {
      final known = _states.values.where((s) => s == CardState.known).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 마지막 카드! ${_cards.length}장 중 알아요 $known장'),
          backgroundColor: AppColors.morakot,
        ),
      );
    }
  }

  Future<void> _toggleDirection() async {
    setState(() {
      _koFirst = !_koFirst;
      _flipped = false;
    });
    await _prefs?.setBool(_kKoFirst, _koFirst);
  }

  Future<void> _toggleHint() async {
    setState(() => _showHint = !_showHint);
    await _prefs?.setBool(_kShowHint, _showHint);
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.meta;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.khram,
        elevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              meta == null ? '문장 플래시카드' : '${meta.emoji} ${meta.title} 카드',
              style: const TextStyle(
                  color: AppColors.khram,
                  fontSize: 16,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              meta == null ? '전 레벨 랜덤 20' : '${meta.level} 회화',
              style: const TextStyle(
                  color: AppColors.khramLight, fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _koFirst ? '한국어 먼저 (탭: 태국어 먼저)' : '태국어 먼저 (탭: 한국어 먼저)',
            onPressed: _toggleDirection,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.kluayMai),
                borderRadius: BorderRadius.circular(6),
                color: AppColors.kluayMai.withValues(alpha: 0.08),
              ),
              child: Text(
                _koFirst ? '한→태' : '태→한',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.kluayMai,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: _showHint ? '힌트 켜짐' : '힌트 꺼짐',
            onPressed: _toggleHint,
            icon: Icon(
              _showHint ? Icons.lightbulb : Icons.lightbulb_outline,
              color: _showHint ? AppColors.thongDeep : AppColors.khramLight,
              size: 22,
            ),
          ),
          if (_cards.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${_index + 1}/${_cards.length}',
                  style: const TextStyle(
                    color: AppColors.kluayMai,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kluayMai))
          : _cards.isEmpty
              ? const Center(
                  child: Text('카드가 없어요',
                      style: TextStyle(color: AppColors.khramLight)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final turn = _cards[_index];
    final isA = turn.speaker == 'A';
    final state = _states[turn.id] ?? CardState.unknown;
    // 앞면/뒷면 내용 결정
    final showThSide = _koFirst ? _flipped : !_flipped;

    return Column(
      children: [
        const LaiThaiDivider(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: showThSide ? AppColors.creamDeep : AppColors.cream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: switch (state) {
                      CardState.known => AppColors.morakot,
                      CardState.studying => AppColors.thongDeep,
                      CardState.unknown => AppColors.kluayMai,
                    },
                    width: 1.6,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  isA ? AppColors.kluayMai : AppColors.thong,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              isA ? 'M' : 'ฟ',
                              style: const TextStyle(
                                color: AppColors.cream,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                fontFamilyFallback: AppTheme.fontFallback,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StateChip(state: state),
                          if (showThSide)
                            IconButton(
                              icon: const Icon(Icons.volume_up,
                                  color: AppColors.kluayMai),
                              onPressed: () => TtsService.instance.speakAs(
                                turn.th,
                                gender: isA ? 'male' : 'female',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (showThSide) ...[
                        // ── 태국어 면 ──
                        Text(
                          turn.th,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.khram,
                            height: 1.5,
                            fontFamilyFallback: AppTheme.fontFallback,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (turn.roman != null)
                          Text(
                            turn.roman!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kluayMai,
                            ),
                          ),
                        if (_flipped && turn.ko != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            turn.ko!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.khramLight,
                            ),
                          ),
                        ],
                      ] else ...[
                        // ── 한국어 면 ──
                        Text(
                          turn.ko ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.khram,
                            height: 1.4,
                          ),
                        ),
                        if (_koFirst && _showHint && turn.roman != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.thong.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      AppColors.thong.withValues(alpha: 0.7)),
                            ),
                            child: Text(
                              '💡 ${turn.roman}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.thongDeep,
                              ),
                            ),
                          ),
                        ],
                      ],
                      if (_flipped &&
                          turn.note != null &&
                          turn.note!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.thong.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.thong),
                          ),
                          child: Text(
                            '💡 ${turn.note}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.khram,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        _flipped ? '탭해서 앞면 보기' : '탭해서 뒤집기',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.khramLight,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // ── 이전/다음 이동 ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _NavButton(
                icon: Icons.arrow_back,
                label: '이전',
                enabled: _index > 0,
                onTap: () => _go(-1),
              ),
              const Spacer(),
              _NavButton(
                icon: Icons.arrow_forward,
                label: '다음',
                trailingIcon: true,
                enabled: _index < _cards.length - 1,
                onTap: () => _go(1),
              ),
            ],
          ),
        ),
        // ── 3단계 평가 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
          child: Row(
            children: [
              Expanded(
                child: _AnswerButton(
                  label: '몰라요',
                  color: AppColors.kluayMai,
                  selected: state == CardState.unknown,
                  onTap: () => _mark(CardState.unknown),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AnswerButton(
                  label: '공부중',
                  color: AppColors.thongDeep,
                  selected: state == CardState.studying,
                  onTap: () => _mark(CardState.studying),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AnswerButton(
                  label: '알아요 ✓',
                  color: AppColors.morakot,
                  selected: state == CardState.known,
                  onTap: () => _mark(CardState.known),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StateChip extends StatelessWidget {
  final CardState state;
  const _StateChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      CardState.known => ('알아요', AppColors.morakot),
      CardState.studying => ('공부중', AppColors.thongDeep),
      CardState.unknown => ('몰라요', AppColors.khramLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool trailingIcon;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.trailingIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        enabled ? AppColors.khram : AppColors.khramLight.withValues(alpha: 0.5);
    final children = [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: color)),
    ];
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(
            color: enabled
                ? AppColors.thong
                : AppColors.khramLight.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: const Size(0, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: enabled ? onTap : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: trailingIcon ? children.reversed.toList() : children,
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    return selected
        ? FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: AppColors.cream,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: shape,
            ),
            onPressed: onTap,
            child:
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: shape,
            ),
            onPressed: onTap,
            child:
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          );
  }
}

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/alphabet.dart';
import '../data/repositories/alphabet_repository.dart';
import '../services/tts_service.dart';
import '../services/vocab_service.dart';
import '../widgets/vocab_sheet.dart';
import 'consonant_class_screen.dart';
import '../core/l10n.dart';
import '../core/platform.dart';

class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  late final Future<AlphabetData> _future;

  @override
  void initState() {
    super.initState();
    _future = AlphabetRepository.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.creamDeep,
        appBar: AppBar(
          title: Text(
            tr('문자 44 · อักษรไทย'),
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.brand,
            labelColor: AppColors.brand,
            unselectedLabelColor: Colors.black45,
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: tr('자음 44')),
              Tab(text: tr('3분류')),
              Tab(text: tr('모음')),
            ],
          ),
        ),
        body: FutureBuilder<AlphabetData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || !snap.hasData) {
              return Center(child: Text(trf('데이터를 불러오지 못했어요\n{0}', [snap.error ?? ''])));
            }
            final data = snap.data!;
            return TabBarView(
              children: [
                _ConsonantTab(data: data),
                ConsonantClassBody(data: data),
                _VowelTab(vowels: data.vowels),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────── 자음 탭 ─────────────────────────

class _ConsonantTab extends StatelessWidget {
  final AlphabetData data;
  const _ConsonantTab({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 28 + bottomInset(context)),
      children: [
        const _ClassExplainerCard(),
        const SizedBox(height: 16),
        _ClassSection(
          title: tr('중자음 · อักษรกลาง'),
          ko: tr('9자'),
          color: AppColors.classMid,
          consonants: data.mid,
        ),
        const SizedBox(height: 20),
        _ClassSection(
          title: tr('고자음 · อักษรสูง'),
          ko: tr('11자'),
          color: AppColors.classHigh,
          consonants: data.high,
        ),
        const SizedBox(height: 20),
        _ClassSection(
          title: tr('저자음 · อักษรต่ำ'),
          ko: tr('24자'),
          color: AppColors.classLow,
          consonants: data.low,
        ),
        const SizedBox(height: 16),
        Text(
          tr('※ ฃ·ฅ 두 글자는 현재 쓰이지 않는 폐자(廢字)지만 전통적으로 44자에 포함합니다.'),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.black45),
        ),
      ],
    );
  }
}

class _ClassExplainerCard extends StatelessWidget {
  const _ClassExplainerCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.khram,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => DefaultTabController.of(context).animateTo(1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('🔑', style: TextStyle(fontSize: 26)),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('왜 자음을 3그룹으로 나눌까?'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      tr('자음 분류가 음절의 성조를 결정합니다. 자세히 보기 →'),
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassSection extends StatelessWidget {
  final String title;
  final String ko;
  final Color color;
  final List<ThaiConsonant> consonants;
  const _ClassSection({
    required this.title,
    required this.ko,
    required this.color,
    required this.consonants,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ko,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.78,
          children: [
            for (final c in consonants) _ConsonantCard(c: c, color: color),
          ],
        ),
      ],
    );
  }
}

class _ConsonantCard extends StatelessWidget {
  final ThaiConsonant c;
  final Color color;
  const _ConsonantCard({required this.c, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showConsonantDetail(context, c, color),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                c.char,
                style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                c.roman,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showConsonantDetail(BuildContext context, ThaiConsonant c, Color color) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.88,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 18, 24, 32 + bottomInset(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    c.char,
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.acrophonic,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${c.roman} · ${c.meaning}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      _ClassBadge(c: c, color: color),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(tr('초성(앞소리)'), c.initial),
            _DetailRow(tr('종성(받침)'), c.finalSound == '-' ? tr('받침 없음') : c.finalSound),
            _DetailRow(tr('한국어 근사'), c.ko),
            const SizedBox(height: 12),
            _ExampleWords(char: c.char, color: color),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: color),
                onPressed: () => TtsService.instance.speak(
                  c.acrophonic.split(' ').length > 1
                      ? c.acrophonic.split(' ').sublist(1).join(' ')
                      : c.char,
                ),
                icon: const Icon(Icons.volume_up_rounded),
                label: Text(tr('발음 듣기 (예시 단어)')),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 이 자음으로 시작하는 단어 — 빈도순 최대 5개 (탭하면 단어 상세).
class _ExampleWords extends StatelessWidget {
  final String char;
  final Color color;
  const _ExampleWords({required this.char, required this.color});

  static const _leadingVowels = 'เแโใไ';

  static String _firstConsonant(String w) {
    var i = 0;
    while (i < w.length && _leadingVowels.contains(w[i])) {
      i++;
    }
    return i < w.length ? w[i] : '';
  }

  Future<List<VocabEntry>> _load() async {
    await VocabService.instance.ensureLoaded();
    final hits =
        VocabService.instance.entries
            .where((e) => !e.th.contains(' ') && !e.th.contains('/'))
            .where((e) => _firstConsonant(e.th) == char)
            .toList()
          ..sort((a, b) {
            final ra = a.rank == 0 ? 1 << 20 : a.rank;
            final rb = b.rank == 0 ? 1 << 20 : b.rank;
            if (ra != rb) return ra.compareTo(rb);
            return a.th.length.compareTo(b.th.length);
          });
    return hits.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VocabEntry>>(
      future: _load(),
      builder: (context, snap) {
        final words = snap.data ?? const <VocabEntry>[];
        if (words.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('예시 단어 · 빈도순'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            for (final e in words)
              InkWell(
                onTap: () => showVocabSheet(context, e),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        e.th,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.khram,
                          fontFamilyFallback: AppTheme.fontFallback,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${e.reading}  ·  ${e.ko}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.khramLight,
                          ),
                        ),
                      ),
                      if (e.level > 0)
                        Text(
                          e.levelStars,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.thongDeep,
                          ),
                        ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.volume_up, size: 18, color: color),
                        onPressed: () => TtsService.instance.speak(e.speakable),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ClassBadge extends StatelessWidget {
  final ThaiConsonant c;
  final Color color;
  const _ClassBadge({required this.c, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = c.isMid
        ? tr('중자음 · กลาง')
        : c.isHigh
        ? tr('고자음 · สูง')
        : tr('저자음 · ต่ำ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

// ───────────────────────── 모음 탭 ─────────────────────────

class _VowelTab extends StatelessWidget {
  final List<ThaiVowel> vowels;
  const _VowelTab({required this.vowels});

  @override
  Widget build(BuildContext context) {
    final shortV = vowels.where((v) => !v.isLong).toList(growable: false);
    final longV = vowels.where((v) => v.isLong).toList(growable: false);
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 28 + bottomInset(context)),
      children: [
        _VowelGroup(title: tr('단모음 · สระเสียงสั้น'), vowels: shortV),
        const SizedBox(height: 20),
        _VowelGroup(title: tr('장모음 · สระเสียงยาว'), vowels: longV),
        const SizedBox(height: 14),
        Text(
          tr('※ – 자리에 자음이 들어갑니다. 모음 길이(단·장)는 성조 결정에도 영향을 줍니다.'),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.black45),
        ),
      ],
    );
  }
}

class _VowelGroup extends StatelessWidget {
  final String title;
  final List<ThaiVowel> vowels;
  const _VowelGroup({required this.title, required this.vowels});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 18, color: AppColors.morakot),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.25,
          children: [for (final v in vowels) _VowelCard(v: v)],
        ),
      ],
    );
  }
}

class _VowelCard extends StatelessWidget {
  final ThaiVowel v;
  const _VowelCard({required this.v});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showVowelDetail(context, v),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              v.form,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.morakot,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              trf('독음 {0}', [v.ko]),
              style: const TextStyle(fontSize: 11.5, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

void _showVowelDetail(BuildContext context, ThaiVowel v) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 32 + bottomInset(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              v.form,
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: AppColors.morakot,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DetailRow(tr('독음'), v.ko),
          _DetailRow(tr('길이'), v.isLong ? tr('장모음 (길게)') : tr('단모음 (짧게)')),
          _DetailRow(tr('예시'), '${v.example}  ·  ${v.exampleKo}'),
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black45, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

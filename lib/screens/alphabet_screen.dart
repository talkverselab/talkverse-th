import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/alphabet.dart';
import '../data/repositories/alphabet_repository.dart';
import 'consonant_class_screen.dart';

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
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.bgBottom,
        appBar: AppBar(
          title: const Text('알파벳 · พยัญชนะ',
              style: TextStyle(fontWeight: FontWeight.w800)),
          bottom: const TabBar(
            indicatorColor: AppTheme.brand,
            labelColor: AppTheme.brand,
            unselectedLabelColor: Colors.black45,
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: '자음 44'),
              Tab(text: '모음'),
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
              return Center(
                  child: Text('데이터를 불러오지 못했어요\n${snap.error ?? ''}'));
            }
            final data = snap.data!;
            return TabBarView(
              children: [
                _ConsonantTab(data: data),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        const _ClassExplainerCard(),
        const SizedBox(height: 16),
        _ClassSection(
          title: '중자음 · อักษรกลาง',
          ko: '9자',
          color: AppTheme.classMid,
          consonants: data.mid,
        ),
        const SizedBox(height: 20),
        _ClassSection(
          title: '고자음 · อักษรสูง',
          ko: '11자',
          color: AppTheme.classHigh,
          consonants: data.high,
        ),
        const SizedBox(height: 20),
        _ClassSection(
          title: '저자음 · อักษรต่ำ',
          ko: '24자',
          color: AppTheme.classLow,
          consonants: data.low,
        ),
        const SizedBox(height: 16),
        Text(
          '※ ฃ·ฅ 두 글자는 현재 쓰이지 않는 폐자(廢字)지만 전통적으로 44자에 포함합니다.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.black45),
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
      color: AppTheme.indigo,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ConsonantClassScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('🔑', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '왜 자음을 3그룹으로 나눌까?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '자음 분류가 음절의 성조를 결정합니다. 자세히 보기 →',
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
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(ko,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
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
                child: Text(c.char,
                    style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.acrophonic,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${c.roman} · ${c.meaning}',
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    _ClassBadge(c: c, color: color),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DetailRow('초성(앞소리)', c.initial),
          _DetailRow('종성(받침)', c.finalSound == '-' ? '받침 없음' : c.finalSound),
          _DetailRow('한국어 근사', c.ko),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: color),
              onPressed: () {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('발음 오디오 — 준비 중 (합성 예정)'),
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              },
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('발음 듣기'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ClassBadge extends StatelessWidget {
  final ThaiConsonant c;
  final Color color;
  const _ClassBadge({required this.c, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = c.isMid
        ? '중자음 · กลาง'
        : c.isHigh
            ? '고자음 · สูง'
            : '저자음 · ต่ำ';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        _VowelGroup(title: '단모음 · สระเสียงสั้น', vowels: shortV),
        const SizedBox(height: 20),
        _VowelGroup(title: '장모음 · สระเสียงยาว', vowels: longV),
        const SizedBox(height: 14),
        Text(
          '※ – 자리에 자음이 들어갑니다. 모음 길이(단·장)는 성조 결정에도 영향을 줍니다.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.black45),
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
            Container(width: 4, height: 18, color: AppTheme.teal),
            const SizedBox(width: 8),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
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
            Text(v.form,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.teal)),
            const SizedBox(height: 4),
            Text('${v.roman}  ·  ${v.ko}',
                style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(v.form,
                style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.teal)),
          ),
          const SizedBox(height: 12),
          _DetailRow('로마자', v.roman),
          _DetailRow('한국어 근사', v.ko),
          _DetailRow('길이', v.isLong ? '장모음 (길게)' : '단모음 (짧게)'),
          _DetailRow('예시', '${v.example}  ·  ${v.exampleKo}'),
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
            child: Text(label,
                style: const TextStyle(color: Colors.black45, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

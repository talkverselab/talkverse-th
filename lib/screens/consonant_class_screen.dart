import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/alphabet.dart';
import '../data/repositories/alphabet_repository.dart';

/// 고/중/저 자음 분류 심화 화면.
/// 각 그룹의 글자 구성과, 그 분류가 성조에 어떤 영향을 주는지 설명한다.
class ConsonantClassScreen extends StatefulWidget {
  const ConsonantClassScreen({super.key});

  @override
  State<ConsonantClassScreen> createState() => _ConsonantClassScreenState();
}

class _ConsonantClassScreenState extends State<ConsonantClassScreen> {
  late final Future<AlphabetData> _future;

  @override
  void initState() {
    super.initState();
    _future = AlphabetRepository.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBottom,
      appBar: AppBar(
        title: const Text('자음 3분류 · ไตรยางศ์',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: FutureBuilder<AlphabetData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(child: Text('데이터를 불러오지 못했어요\n${snap.error ?? ''}'));
          }
          final data = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              const _IntroCard(),
              const SizedBox(height: 20),
              _ClassBlock(
                title: '중자음',
                thai: 'อักษรกลาง',
                color: AppTheme.classMid,
                count: data.mid.length,
                tagline: '소리가 막히지 않는 안정된 자음. 5성조를 모두 만들 수 있는 기준.',
                consonants: data.mid,
                mnemonic: '“ไก่ จิก เด็ก ตาย บน ปาก โอ่ง” 같은 암기 문장으로 9자를 외웁니다.',
              ),
              const SizedBox(height: 18),
              _ClassBlock(
                title: '고자음',
                thai: 'อักษรสูง',
                color: AppTheme.classHigh,
                count: data.high.length,
                tagline: '높은 곳에서 시작하는 무성·기식음. 무표시일 때 상승성이 된다.',
                consonants: data.high,
                mnemonic: '대부분 ㅋ·ㅊ·ㅌ·ㅍ·ㅅ·ㅎ 계열의 거센소리/마찰음입니다.',
              ),
              const SizedBox(height: 18),
              _ClassBlock(
                title: '저자음',
                thai: 'อักษรต่ำ',
                color: AppTheme.classLow,
                count: data.low.length,
                tagline: '가장 많은 24자. 무표시일 때 평성, 비음·유음이 다수.',
                consonants: data.low,
                mnemonic: '고자음과 짝(같은 음가)을 이루는 글자가 많아 함께 외우면 효율적입니다.',
              ),
              const SizedBox(height: 22),
              const _ToneHintCard(),
            ],
          );
        },
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppTheme.indigo, AppTheme.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ไตรยางศ์ (뜨라이양)',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            '태국어 44개 자음은 고(สูง)·중(กลาง)·저(ต่ำ) 세 그룹으로 나뉩니다. '
            '같은 모음·받침이라도 어느 그룹 자음으로 시작하느냐에 따라 음절의 성조가 달라지므로, '
            '이 분류는 태국어 읽기의 출발점입니다.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                height: 1.5,
                fontSize: 13.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              _CountPill('중 9'),
              SizedBox(width: 8),
              _CountPill('고 11'),
              SizedBox(width: 8),
              _CountPill('저 24'),
              SizedBox(width: 8),
              _CountPill('합 44'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final String text;
  const _CountPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
    );
  }
}

class _ClassBlock extends StatelessWidget {
  final String title;
  final String thai;
  final Color color;
  final int count;
  final String tagline;
  final List<ThaiConsonant> consonants;
  final String mnemonic;

  const _ClassBlock({
    required this.title,
    required this.thai,
    required this.color,
    required this.count,
    required this.tagline,
    required this.consonants,
    required this.mnemonic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.4),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text('$count',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                  Text(thai,
                      style: const TextStyle(
                          color: Colors.black45, fontSize: 12.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(tagline,
              style: const TextStyle(
                  fontSize: 13.5, height: 1.45, color: Colors.black87)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in consonants)
                Container(
                  width: 40,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  alignment: Alignment.center,
                  child: Text(c.char,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(mnemonic,
                      style: const TextStyle(
                          fontSize: 12.5, height: 1.4, color: Colors.black87)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToneHintCard extends StatelessWidget {
  const _ToneHintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text('🎵', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('다음 단계: 성조',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14.5)),
                SizedBox(height: 3),
                Text(
                  '자음 분류를 익혔다면, 하단 “성조” 탭에서 분류별 성조 규칙표로 넘어가세요.',
                  style: TextStyle(color: Colors.black54, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

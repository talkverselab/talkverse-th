import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'alphabet_screen.dart';
import 'consonant_class_screen.dart';
import 'tones_screen.dart';

class HomeScreen extends StatelessWidget {
  /// 하단 탭 전환 콜백 (알파벳=1, 성조=2 …). 홈 그리드에서 사용.
  final ValueChanged<int>? onNavigate;
  const HomeScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.bgTop, AppTheme.bgBottom],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const _Header(),
            const SizedBox(height: 18),
            const _BangkokBanner(),
            const SizedBox(height: 22),
            const _SectionTitle('태국어 입문'),
            const SizedBox(height: 12),
            _ClassPromoCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ConsonantClassScreen(),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const _SectionTitle('학습 시작하기'),
            const SizedBox(height: 12),
            _FeatureGrid(onNavigate: onNavigate),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สวัสดีครับ 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.brand,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                '오늘도 태국어(방콕) 한 걸음',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.brand, AppTheme.gold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.brand.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text('🐘', style: TextStyle(fontSize: 22)),
        ),
      ],
    );
  }
}

/// 방콕 야경 무드의 히어로 배너 (왓 아룬 / 차오프라야강 느낌).
class _BangkokBanner extends StatelessWidget {
  const _BangkokBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.indigo, AppTheme.brand, AppTheme.gold],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brand.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -6,
            child: Text(
              '🛕',
              style: TextStyle(
                fontSize: 96,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
          const Positioned(
            left: 22,
            top: 22,
            child: Text(
              'BANGKOK',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            left: 22,
            top: 52,
            child: Text(
              'กรุงเทพมหานคร',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
          Positioned(
            left: 22,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '자음 44 · 모음 32 · 성조 5',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 고/중/저 자음 분류로 바로 가는 프로모 카드.
class _ClassPromoCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ClassPromoCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _ClassChip('กลาง', '중', AppTheme.classMid),
              const SizedBox(width: 6),
              _ClassChip('สูง', '고', AppTheme.classHigh),
              const SizedBox(width: 6),
              _ClassChip('ต่ำ', '저', AppTheme.classLow),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '자음 3분류 (고·중·저)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '성조를 푸는 열쇠',
                      style: TextStyle(color: Colors.black54, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassChip extends StatelessWidget {
  final String thai;
  final String ko;
  final Color color;
  const _ClassChip(this.thai, this.ko, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 54,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(thai,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  height: 1.1)),
          Text(ko,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  height: 1.1)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final ValueChanged<int>? onNavigate;
  const _FeatureGrid({this.onNavigate});

  static const _features = <_Feature>[
    _Feature('알파벳', Icons.abc_rounded, AppTheme.brand, tab: 1),
    _Feature('자음 3분류', Icons.category_rounded, AppTheme.teal, route: 'class'),
    _Feature('성조 연습', Icons.graphic_eq_rounded, AppTheme.gold, tab: 2),
    _Feature('회화', Icons.forum_rounded, Color(0xFF7B61FF)),
    _Feature('단어장', Icons.style_rounded, Color(0xFFEF6C5A)),
    _Feature('내 학습', Icons.insights_rounded, Color(0xFF3AA0FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        for (final f in _features)
          _FeatureCard(feature: f, onNavigate: onNavigate),
      ],
    );
  }
}

class _Feature {
  final String label;
  final IconData icon;
  final Color color;
  final int? tab; // 하단 탭 인덱스로 전환
  final String? route; // 별도 화면 push
  const _Feature(this.label, this.icon, this.color, {this.tab, this.route});
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  final ValueChanged<int>? onNavigate;
  const _FeatureCard({required this.feature, this.onNavigate});

  void _onTap(BuildContext context) {
    if (feature.route == 'class') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ConsonantClassScreen()),
      );
      return;
    }
    if (feature.tab != null) {
      // 알파벳·성조는 전용 화면을 직접 push (탭 전환 콜백이 없을 때 대비).
      final tab = feature.tab!;
      if (onNavigate != null) {
        onNavigate!(tab);
        return;
      }
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => tab == 1 ? const AlphabetScreen() : const TonesScreen(),
      ));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${feature.label} — 준비 중'),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _onTap(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: feature.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(feature.icon, color: feature.color, size: 26),
              ),
              Text(
                feature.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/thai_decor.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('프로필 · 설정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.kluayMaiDeep, AppColors.kluayMai],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.thong, width: 1.5),
            ),
            child: const Row(
              children: [
                GoldEmblem(text: 'เรียน', size: 60),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '학습자',
                        style: TextStyle(
                          color: AppColors.cream,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Day 1 · 입문',
                        style: TextStyle(
                          color: AppColors.thongBright,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('설정',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.khram,
                letterSpacing: 2,
              )),
          const SizedBox(height: 8),
          _SettingsGroup(items: [
            _SettingItem(
                icon: Icons.volume_up,
                title: 'TTS 음성',
                subtitle: '시스템 th-TH 보이스'),
            _SettingItem(
                icon: Icons.palette,
                title: '테마',
                subtitle: '낮 · 방콕 모던 #E6007E'),
          ]),
          const SizedBox(height: 16),
          const Text('정보',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.khram,
                letterSpacing: 2,
              )),
          const SizedBox(height: 8),
          _SettingsGroup(items: [
            _SettingItem(
                icon: Icons.info_outline,
                title: '앱 버전',
                subtitle: '0.2.0 · alpha 방콕 모던'),
            _SettingItem(
                icon: Icons.code,
                title: 'Stack',
                subtitle: 'Flutter · Material 3 · SQLite'),
            _SettingItem(
                icon: Icons.copyright,
                title: '저작권',
                subtitle: '태국어유니버스 · 2026'),
          ]),
          const SizedBox(height: 20),
          const SilkDivider(),
          const SizedBox(height: 12),
          const Center(child: Lotus(size: 30)),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'ค่อยๆ ไป · 천천히 꾸준히',
              style: TextStyle(
                color: AppColors.khramLight,
                fontSize: 11,
                letterSpacing: 4,
                fontFamilyFallback: AppTheme.fontFallback,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.thong.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.kluayMai.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.kluayMai, width: 0.8),
                ),
                child:
                    Icon(items[i].icon, color: AppColors.kluayMai, size: 18),
              ),
              title: Text(items[i].title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.khram)),
              subtitle: Text(items[i].subtitle,
                  style: const TextStyle(
                      color: AppColors.khramLight, fontSize: 11)),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.kluayMai, size: 18),
            ),
            if (i < items.length - 1)
              Container(
                  height: 0.5,
                  color: AppColors.thong.withValues(alpha: 0.3)),
          ],
        ],
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  _SettingItem(
      {required this.icon, required this.title, required this.subtitle});
}

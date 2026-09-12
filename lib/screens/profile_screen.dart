import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/update_service.dart';
import '../widgets/thai_decor.dart';
import 'update_screen.dart';
import '../core/l10n.dart';
import '../core/platform.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    await UpdateService.instance.loadCurrent();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(tr('프로필 · 설정'))),
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
            child: Row(
              children: [
                GoldEmblem(text: 'เรียน', size: 60),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('학습자'),
                        style: TextStyle(
                          color: AppColors.cream,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        tr('Day 1 · 입문'),
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
          Text(tr('설정'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.khram,
                letterSpacing: 2,
              )),
          const SizedBox(height: 8),
          _SettingsGroup(items: [
            _SettingItem(
                icon: Icons.language,
                title: tr('언어 / Language'),
                subtitle:
                    '${AppLangPrefs.lang.value.label}  →  ${AppLangPrefs.peekNext().label}',
                onTap: AppLangPrefs.next),
            if (isIOS)
              _SettingItem(
                  icon: Icons.flight_takeoff,
                  title: tr('앱 업데이트'),
                  subtitle: tr('아이폰은 TestFlight 앱에서 새 빌드를 받습니다'))
            else
              _SettingItem(
                  icon: Icons.system_update,
                  title: tr('앱 업데이트'),
                  subtitle: tr('GitHub 최신 빌드 확인 · 내려받아 설치'),
                  onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UpdateScreen()),
                      )),
            _SettingItem(
                icon: Icons.volume_up,
                title: tr('TTS 음성'),
                subtitle: tr('시스템 th-TH 보이스')),
            _SettingItem(
                icon: Icons.palette,
                title: tr('테마'),
                subtitle: tr('낮 · 태국어 하늘색 #3F9FD6')),
          ]),
          const SizedBox(height: 16),
          Text(tr('정보'),
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
                title: tr('앱 버전'),
                subtitle: UpdateService.instance.currentText),
            _SettingItem(
                icon: Icons.code,
                title: 'Stack',
                subtitle: 'Flutter · Material 3 · SQLite'),
            _SettingItem(
                icon: Icons.copyright,
                title: tr('저작권'),
                subtitle: tr('태국어유니버스 · 2026')),
          ]),
          const SizedBox(height: 20),
          const SilkDivider(),
          const SizedBox(height: 12),
          const Center(child: Lotus(size: 30)),
          const SizedBox(height: 6),
          Center(
            child: Text(
              tr('ค่อยๆ ไป · 천천히 꾸준히'),
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
              onTap: items[i].onTap,
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
  final VoidCallback? onTap;
  _SettingItem(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.onTap});
}

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/update_service.dart';
import '../widgets/thai_decor.dart';
import 'about_screen.dart';
import '../embed.dart' show switchLanguage;
import '../widgets/legal_links.dart';
import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../services/auth_service.dart';
import 'account_screen.dart';
import 'course_domain_screen.dart';
import '../services/course_service.dart';
import '../services/dev_notes.dart';
import '../services/ko_reading.dart';
import '../services/learner_prefs.dart';
import '../core/thai_font.dart';
import 'dev_notes_screen.dart';
import '../core/embed_env.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _versionTaps = 0;

  Future<void> _tapVersion() async {
    if (DevNotes.instance.unlocked.value) return;
    if (++_versionTaps < 7) return;
    await DevNotes.instance.unlock();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('개발자 메모가 열렸어요'))));
  }

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    await UpdateService.instance.loadCurrent();
    await CourseService.instance.ensureLoaded();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(tr('프로필'))),
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
            // 통합 앱(Talkverse)에서만: 다른 언어 앱으로(2026-11-09)
            if (switchLanguage != null)
              _SettingItem(icon: Icons.swap_horiz, title: tr('다른 언어 배우기'), subtitle: tr('Talkverse 의 다른 언어로 이동'), onTap: switchLanguage!),
            _SettingItem(
                icon: Icons.badge_outlined,
                title: tr('나 · 이름과 성별'),
                subtitle: LearnerPrefs.name.value.isEmpty
                    ? tr('이름을 정하면 회화와 홈 인사에 나와요')
                    : '${LearnerPrefs.name.value} · ${LearnerPrefs.isFemale ? tr('여성') : tr('남성')}',
                onTap: () async {
                  await _editLearner(context);
                  if (mounted) setState(() {});
                }),
            _SettingItem(
                icon: Icons.person_outline,
                title: tr('계정'),
                subtitle: AuthService.instance.user.value?['email'] as String? ?? tr('로그인 · Google · Kakao'),
                onTap: () async {
                  await openPane(context, (_) => const AccountScreen());
                  if (mounted) setState(() {});
                }),
            _SettingItem(
                icon: Icons.flag_outlined,
                title: tr('무대 · 레벨'),
                subtitle: CourseService.instance.hasAnswers
                    ? CourseService.instance.domainLabels.join(' · ')
                    : tr('내 코스에서 먼저 질문에 답해 주세요'),
                onTap: () async {
                  await CourseService.instance.ensureLoaded();
                  if (!context.mounted || !CourseService.instance.hasAnswers) return;
                  await openPane(context, (_) => const CourseDomainScreen());
                  if (mounted) setState(() {});
                }),
            _SettingItem(
                icon: Icons.translate,
                title: tr('독음 표시'),
                subtitle: KoReadingPrefs.show.value ? tr('켜짐') : tr('꺼짐 · 태국 글자만 보기'),
                onTap: () async {
                  await KoReadingPrefs.switchShown(context);
                  if (mounted) setState(() {});
                }),
            _SettingItem(
                icon: Icons.font_download_outlined,
                title: tr('태국어 글꼴'),
                subtitle: tr(ThaiFontPrefs.current.label),
                onTap: () async {
                  await _pickThaiFont(context);
                  if (mounted) setState(() {});
                }),
            _SettingItem(
                icon: Icons.language,
                title: tr('언어 / Language'),
                subtitle:
                    '${AppLangPrefs.lang.value.label}  →  ${AppLangPrefs.peekNext().label}',
                onTap: AppLangPrefs.next),
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
                icon: Icons.landscape_outlined,
                title: tr('앱 소개'),
                subtitle: tr('절벽구간 — 이 앱이 단어를 나누는 기준'),
                onTap: () => openPane(context, (_) => const AboutScreen())),
            _SettingItem(
                icon: Icons.info_outline,
                title: tr('앱 버전'),
                subtitle: UpdateService.instance.currentText,
                onTap: _tapVersion),
            if (DevNotes.instance.unlocked.value)
              _SettingItem(
                  icon: Icons.edit_note,
                  title: tr('개발자 메모'),
                  subtitle: DevNotes.instance.enabled.value ? tr('켜짐 · 보낸 메모와 처리 결과') : tr('꺼짐 · 눌러서 설정'),
                  onTap: () async {
                    await openPane(context, (_) => const DevNotesScreen());
                    if (mounted) setState(() {});
                  }),
            _SettingItem(
                icon: Icons.description_outlined,
                title: tr('이용약관'),
                subtitle: 'talkverse.uk/terms',
                onTap: () => Legal.open(Legal.terms)),
            _SettingItem(
                icon: Icons.privacy_tip_outlined,
                title: tr('개인정보처리방침'),
                subtitle: 'talkverse.uk/talkverse/th/privacy',
                onTap: () => Legal.open(Legal.privacy)),
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
      // ListTile 잉크가 바탕색 위에 보이도록 투명 Material 을 한 겹 둔다(넓은 화면 확인 때 경고).
      child: Material(
        type: MaterialType.transparency,
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

/// 학습자 이름·성별 — 회화의 화자 A(나)와 홈 인사에 쓰인다. 글로벌 버전이라 이름을 고정하지 않는다.
Future<void> _editLearner(BuildContext context) async {
  final ctl = TextEditingController(text: LearnerPrefs.name.value);
  var female = LearnerPrefs.isFemale;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => AlertDialog(
        title: Text(tr('나 · 이름과 성별')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: ctl, decoration: InputDecoration(hintText: tr('이름')), textInputAction: TextInputAction.done),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(tr('남성'))),
              ButtonSegment(value: true, label: Text(tr('여성'))),
            ],
            selected: {female},
            onSelectionChanged: (s) => set(() => female = s.first),
          ),
          const SizedBox(height: 8),
          Text(tr('성별에 따라 태국어 1인칭·어미(ผม/ฉัน · ครับ/ค่ะ)가 달라져요'),
              style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('취소'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('저장'))),
        ],
      ),
    ),
  );
  if (ok == true) {
    await LearnerPrefs.setName(ctl.text);
    await LearnerPrefs.setGender(female ? 'female' : 'male');
  }
}

/// 태국어 글꼴 고르기 — 글꼴마다 같은 문장을 그 글꼴로 보여 준다(고리형·고리 없는 현대형 비교).
Future<void> _pickThaiFont(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.cream,
      builder: (c) => SafeArea(
        top: false,
        child: ValueListenableBuilder<String>(
          valueListenable: ThaiFontPrefs.id,
          builder: (c, cur, _) => ListView(
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset(c)),
            children: [
              Text(tr('태국어 글꼴'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.khram)),
              const SizedBox(height: 4),
              Text(tr('같은 글자도 글꼴에 따라 느낌이 많이 달라요. 처음엔 고리형을, 간판·광고에 익숙해지려면 현대형을 써 보세요.'),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.khramLight, height: 1.4)),
              const SizedBox(height: 12),
              for (final f in ThaiFontPrefs.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => ThaiFontPrefs.set(f.id),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cur == f.id ? AppColors.kluayMai : AppColors.thong, width: cur == f.id ? 2 : 1),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('สวัสดีครับ ภาษาไทย กขค',
                                style: TextStyle(fontFamily: fontFamilyOf(f.family), fontSize: 24, color: AppColors.khram, height: 1.5)),
                            Text('${tr(f.label)} · ${tr(f.desc)}', style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
                          ]),
                        ),
                        if (cur == f.id) const Icon(Icons.check_circle, color: AppColors.kluayMai),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

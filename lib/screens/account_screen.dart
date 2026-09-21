import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';

/// 계정 — 로그인(Google · Kakao · Naver) · 내 정보 · 이용권.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _auth = AuthService.instance;
  bool _busy = false;

  Future<void> _run(Future<void> Function() f, {String? fail}) async {
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${fail ?? tr('로그인에 실패했어요')}\n$e')));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(tr('계정'))),
      body: ValueListenableBuilder<User?>(
        valueListenable: _auth.user,
        builder: (context, user, _) => ListView(
          padding: EdgeInsets.fromLTRB(18, 20, 18, 24 + bottomInset(context)),
          children: user == null ? _signedOut() : _signedIn(user),
        ),
      ),
    );
  }

  List<Widget> _signedOut() => [
        Text(tr('로그인하면 학습 기록과 코스가 기기와 상관없이 이어져요.'),
            style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.khram)),
        const SizedBox(height: 18),
        _btn('G', tr('Google로 계속하기'), const Color(0xFF4285F4), () => _run(_auth.signInWithGoogle)),
        _btn('K', tr('카카오로 계속하기'), const Color(0xFFFEE500), () => _run(_auth.signInWithKakao), fg: Colors.black87),
        _btn('N', tr('네이버로 계속하기'), const Color(0xFF03C75A), null, note: tr('준비 중')),
        if (!_auth.ready)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(tr('네트워크에 연결하지 못했습니다. 와이파이·데이터를 확인해 주세요.'),
                style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
          ),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
      ];

  List<Widget> _signedIn(User user) {
    final name = _auth.profile?['display_name'] as String? ?? user.userMetadata?['full_name'] as String? ?? '';
    final provider = user.appMetadata['provider'] as String? ?? '';
    final ends = _auth.entitlements.where((e) => e['lang'] == 'th').map((e) => e['ends_at'] as String).firstOrNull;
    return [
      _card([
        Text(name.isEmpty ? (user.email ?? '') : name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.khram)),
        const SizedBox(height: 3),
        Text('${user.email ?? ''}  ·  $provider', style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
      ]),
      _card([
        Text(tr('이용권'), style: const TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w700, color: AppColors.kluayMaiDeep)),
        const SizedBox(height: 6),
        ValueListenableBuilder<bool?>(
          valueListenable: _auth.hasAccess,
          builder: (_, ok, _) => Text(
            ok == true
                ? trf('태국어 · {0}까지', [ends == null ? '' : ends.substring(0, 10)])
                : ok == false
                    ? tr('이용권이 없어요')
                    : tr('확인 중'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.khram),
          ),
        ),
        const SizedBox(height: 4),
        Text(tr('구매는 talkverse.uk 또는 앱 스토어에서 · 준비 중'),
            style: const TextStyle(fontSize: 11.5, color: AppColors.khramLight)),
      ]),
      const SizedBox(height: 4),
      OutlinedButton.icon(
        onPressed: _busy ? null : () => _run(() async {
              await _auth.refreshAccess();
              await _auth.syncCourse();
            }, fail: tr('동기화에 실패했어요')),
        icon: const Icon(Icons.sync, size: 18),
        label: Text(tr('지금 동기화')),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _busy ? null : () => _run(_auth.signOut),
        child: Text(tr('로그아웃'), style: const TextStyle(color: AppColors.khramLight)),
      ),
    ];
  }

  Widget _card(List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.thong, width: 0.8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _btn(String mark, String label, Color bg, VoidCallback? onTap, {Color fg = Colors.white, String? note}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Opacity(
          opacity: onTap == null ? 0.45 : 1,
          child: InkWell(
            onTap: _busy ? null : onTap,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: bg, border: Border.all(color: AppColors.thong.withValues(alpha: 0.4), width: 0.6)),
              child: Row(
                children: [
                  Text(mark, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: fg)),
                  const SizedBox(width: 14),
                  Expanded(child: Text(label, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: fg))),
                  if (note != null) Text(note, style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.9))),
                ],
              ),
            ),
          ),
        ),
      );
}

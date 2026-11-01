import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';

/// 계정 — Talkverse ID 로그인(Apple · Google · Kakao · Naver) · 내 정보 · 이용권 · 로그아웃 · 탈퇴.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _auth = AuthService.instance;
  bool _busy = false;
  List<String> _providers = isIOS ? const ['apple', 'google', 'kakao'] : const ['google', 'kakao'];

  @override
  void initState() {
    super.initState();
    _auth.providers().then((p) {
      if (mounted && p.isNotEmpty) setState(() => _providers = p);
    });
  }

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
      body: ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: _auth.user,
        builder: (context, user, _) => ListView(
          padding: EdgeInsets.fromLTRB(18, 20, 18, 24 + bottomInset(context)),
          children: user == null ? _signedOut() : _signedIn(user),
        ),
      ),
    );
  }

  static const _look = <String, (String, String, Color, Color)>{
    'apple': ('', 'Apple로 계속하기', Colors.black, Colors.white),
    'google': ('G', 'Google로 계속하기', Color(0xFF4285F4), Colors.white),
    'kakao': ('K', '카카오로 계속하기', Color(0xFFFEE500), Colors.black87),
    'naver': ('N', '네이버로 계속하기', Color(0xFF03C75A), Colors.white),
  };

  List<Widget> _signedOut() => [
        Text(tr('Talkverse 계정 하나로 모든 언어앱과 talkverse.uk 에 로그인해요.'),
            style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.khram)),
        const SizedBox(height: 18),
        for (final p in _providers)
          if (_look[p] != null)
            _btn(_look[p]!.$1, tr(_look[p]!.$2), _look[p]!.$3, () => _run(() => _auth.signIn(p)), fg: _look[p]!.$4),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
      ];

  List<Widget> _signedIn(Map<String, dynamic> user) {
    final email = user['email'] as String? ?? '';
    final name = user['display_name'] as String? ?? '';
    return [
      _card([
        Text(name.isEmpty ? email : name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.khram)),
        if (email.isNotEmpty && name.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(email, style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
        ],
      ]),
      _card([
        Text(tr('이용권'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kluayMai)),
        const SizedBox(height: 6),
        ValueListenableBuilder<bool?>(
          valueListenable: _auth.hasAccess,
          builder: (_, ok, _) => Text(
            ok == true ? tr('태국어 이용 중') : tr('이용권이 없어요'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.khram),
          ),
        ),
        const SizedBox(height: 4),
        Text(tr('구매는 talkverse.uk 또는 앱 스토어에서 · 준비 중'),
            style: const TextStyle(fontSize: 11.5, color: AppColors.khramLight)),
      ]),
      const SizedBox(height: 4),
      OutlinedButton.icon(
        onPressed: _busy ? null : () => _run(_auth.refreshAccess, fail: tr('동기화에 실패했어요')),
        icon: const Icon(Icons.sync, size: 18),
        label: Text(tr('지금 동기화')),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _busy ? null : () => _run(_auth.signOut),
        child: Text(tr('로그아웃'), style: const TextStyle(color: AppColors.khramLight)),
      ),
      TextButton(
        onPressed: _busy ? null : _confirmDelete,
        child: Text(tr('계정 삭제'), style: const TextStyle(color: Color(0xFFB00020))),
      ),
    ];
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('계정 삭제')),
        content: Text(tr('Talkverse 계정과 개인정보를 지우고 모든 기기에서 로그아웃해요. 되돌릴 수 없어요. 이 폰의 학습 기록은 남아요.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('취소'))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('삭제'), style: const TextStyle(color: Color(0xFFB00020)))),
        ],
      ),
    );
    if (ok == true) await _run(_auth.deleteAccount, fail: tr('계정을 지우지 못했어요'));
  }

  Widget _card(List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.thong),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _btn(String mark, String label, Color bg, VoidCallback? onTap, {Color fg = Colors.white}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: bg,
          shape: StadiumBorder(side: BorderSide(color: AppColors.thong.withValues(alpha: 0.6))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _busy ? null : onTap,
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  SizedBox(
                    width: 22,
                    child: mark.isEmpty
                        ? Icon(Icons.apple, color: fg, size: 22)
                        : Text(mark, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(label, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: fg))),
                ],
              ),
            ),
          ),
        ),
      );
}

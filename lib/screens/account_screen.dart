import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/entitlement.dart';
import '../data/purchase.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

/// 계정 — Talkverse ID 로그인(LoginScreen: Google · Naver · Kakao · Apple + 심사용 이메일) · 내 정보 · 평생 이용권(구매·복원) · 로그아웃 · 탈퇴.
/// 로그인·결제는 선택 — 안 해도 모든 기능. 한자 앱 me_screen 계정 칸과 같은 구성.
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
      body: ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: _auth.user,
        builder: (context, user, _) => ListView(
          padding: EdgeInsets.fromLTRB(18, 20, 18, 24 + bottomInset(context)),
          children: user == null ? _signedOut() : _signedIn(user),
        ),
      ),
    );
  }

  List<Widget> _signedOut() => [
        Text(tr('Talkverse 계정 하나로 모든 언어앱과 talkverse.uk 에 로그인해요.'),
            style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.khram)),
        const SizedBox(height: 18),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: () => LoginScreen.open(context),
          icon: const Icon(Icons.login, size: 20),
          label: Text(tr('로그인')),
        ),
        const SizedBox(height: 18),
        ..._passTiles(),
      ];

  /// 평생 이용권 — 로그인 없이도 사고 복원한다(스토어).
  List<Widget> _passTiles() => [
        ValueListenableBuilder<Set<String>>(
          valueListenable: Purchase.owned,
          builder: (_, _, _) => _card([
            Text(tr('평생 이용권'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kluayMai)),
            const SizedBox(height: 6),
            Text(Entitlement.premium ? tr('태국어 이용 중') : tr('이용권이 없어요'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.khram)),
            const SizedBox(height: 10),
            Row(children: [
              if (!Entitlement.premium)
                Expanded(child: FilledButton(onPressed: () => Entitlement.showPaywall(context), child: Text(tr('평생 이용권 보기')))),
              if (!Entitlement.premium) const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: _busy ? null : () => Purchase.restore(), child: Text(tr('이전 구매 복원')))),
            ]),
          ]),
        ),
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
      ..._passTiles(),
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
}

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/account.dart';
import '../data/purchase.dart';
import 'login_screen.dart';

/// 평생 이용권 시트 — 가격 + 인앱 결제 + 복원(한자 앱 paywall_screen.dart 이식, 2026-11-02).
/// 태국어앱은 아직 잠근 콘텐츠가 없다 — 무료/유료 구간이 정해지면 혜택 문구를 맞춘다.
/// 아래에서 올라오는 시트. 사거나 복원되면 닫힌다. 로그인은 선택(기기 간 공유용).
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static Future<void> show(BuildContext context) {
    Purchase.status.value = null;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.cream,
      builder: (_) => const PaywallScreen(),
    );
  }

  /// 스토어 가격을 못 받았을 때 보여 줄 참고가(원). 실제 가격은 스토어 등록값.
  static const lifetimePriceKrw = 14900;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: Purchase.status,
      builder: (c, st, _) {
        if (st == 'done' || st == 'restored') {
          WidgetsBinding.instance.addPostFrameCallback((_) { if (Navigator.canPop(c)) Navigator.pop(c); });
        }
        final busy = st == 'pending';
        return ValueListenableBuilder<Map<String, dynamic>>(
          valueListenable: Purchase.products,
          builder: (c, _, _) {
            final storePrice = Purchase.price('th');
            final price = storePrice ?? '₩${lifetimePriceKrw.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 4, 24, 20 + bottomInset(context)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.kluayMai.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.lock_outline, color: AppColors.kluayMai)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tr('태국어유니버스'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.kluayMai)),
                        Text(tr('평생 이용권'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.khram)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  // 가격
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    decoration: BoxDecoration(color: AppColors.khram, borderRadius: BorderRadius.circular(18)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(price, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(tr('한 번 결제 · 구독 아님 · 평생'), style: const TextStyle(fontSize: 12.5, color: Colors.white70, fontWeight: FontWeight.w700))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  _row(Icons.check_circle, tr('태국어유니버스 전체 과정 — 회화·단어·문법·말하기')),
                  _row(Icons.check_circle, tr('앞으로 추가되는 과정도 추가 결제 없이')),
                  _row(Icons.check_circle_outline, tr('구독이 아니라 한 번 결제'), muted: true),
                  const SizedBox(height: 14),
                  if (st == 'error') Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(tr('결제를 마치지 못했습니다. 다시 시도해 주세요.'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700))),
                  if (st == 'nothing') Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(tr('복원할 구매가 없습니다.'), style: const TextStyle(color: AppColors.khramLight, fontWeight: FontWeight.w700))),
                  // 인앱 결제 버튼
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.kluayMai, minimumSize: const Size.fromHeight(54), textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    onPressed: busy || storePrice == null ? null : () => Purchase.buy('th'),
                    child: busy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(storePrice == null ? tr('스토어에 연결하는 중…') : trf('평생 이용권 구매 · {0}', [price])),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: busy ? null : () => Purchase.restore(), child: Text(tr('이전 구매 복원'))),
                  const SizedBox(height: 12),
                  ValueListenableBuilder(
                    valueListenable: Account.user,
                    builder: (c, u, _) => u == null
                        ? TextButton(
                            onPressed: () => LoginScreen.open(context),
                            child: Text(tr('로그인하면 다른 기기에서도 이용권이 열립니다 (선택)'), style: const TextStyle(fontSize: 12.5)),
                          )
                        : Text(tr('로그인됨 — 구매는 Talkverse 계정에 기록되어 다른 기기에서도 열립니다.'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppColors.khramLight)),
                  ),
                  Text(
                    tr('결제는 App Store / Google Play 에서 처리됩니다. 표시 가격은 스토어 가격을 따르며 세금이 포함될 수 있습니다.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: AppColors.khramLight, height: 1.4),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _row(IconData icon, String text, {bool muted = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: muted ? AppColors.khramLight : AppColors.morakot),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, height: 1.35, color: muted ? AppColors.khramLight : AppColors.khram, fontWeight: FontWeight.w600))),
        ]),
      );
}

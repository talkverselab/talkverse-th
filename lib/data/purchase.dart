import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account.dart';

/// 판매 상품 하나(가격은 스토어가 정한다 — [krw] 는 스토어 가격을 못 받았을 때의 참고가).
/// 가격·상품 ID 규칙 = Talkverse 공통(2026-11-09 사용자 최종 확정, ~/talkverse/PRICING.md 앱 정가/할인가): 언어 1개 `lang_<코드>_1m`·`_3m`·`_1y`(자동 갱신 구독)·`_life`(비소모성),
/// 종합 패키지(모든 언어) `all_1y`·`all_life`. 앱 안에서는 사이트 가격을 안내·유도하지 않는다(스토어 규정).
class Plan {
  final String id;
  final int months; // 0 = 평생
  final bool bundle;
  final int krw; // 앱 할인가(스토어 판매가) — 스토어 가격을 못 받았을 때 표시
  final int listKrw; // 앱 정가(취소선 표기용, ~/talkverse/PRICING.md)
  const Plan(this.id, this.months, this.krw, {this.listKrw = 0, this.bundle = false});
  bool get lifetime => months == 0;
  bool get discounted => listKrw > krw;
  int get discountPct => discounted ? ((1 - krw / listKrw) * 100).round() : 0;
}

/// 앱 안 결제 — Talkverse 공용 클라이언트(한자앱 방식). 결제는 스토어(iOS StoreKit 2 · Android Play Billing),
/// 이용권 기록은 Talkverse ID(auth.talkverse.uk POST /me/purchases).
/// - 로그인 없이도 사고 복원할 수 있다(스토어가 기억 → 이 기기에 저장).
/// - 로그인돼 있으면 서버가 스토어에 확인해 계정 이용권으로 기록 → 다른 기기·다른 플랫폼에서도 열림. 로그인 전에 산 것은 로그인할 때 서버로 보낸다.
/// - 구독은 기기에 「구매 시각 + 기간 + 3일」까지만 열어 둔다. 자동 갱신되면 스토어가 새 거래를 보내 기한이 늘어난다(해지하면 그 기한에 닫힘).
///   기간의 최종 판단은 서버(계정 이용권)가 한다.
class Purchase {
  Purchase._();

  static String lang = 'th';
  static List<Plan> plans = const [];
  /// 상품 ID → 만료 시각(ms, 평생이면 0)
  static final owned = ValueNotifier<Map<String, int>>(const {});
  static final products = ValueNotifier<Map<String, ProductDetails>>(const {});
  /// 구매 진행 상태 알림(화면이 듣고 안내): null = 없음, 'pending' · 'error' · 'done' · 'restored' · 'nothing'
  static final status = ValueNotifier<String?>(null);
  static StreamSubscription<List<PurchaseDetails>>? _sub;
  static bool _restoring = false, _restoredAny = false;
  /// 옛 평생 상품 ID(2026-11-02 첫 판) — 복원·영수증에 오면 `lang_<코드>_life` 로 친다.
  static const _legacy = {'com.talkverse.thaiUniverse.lifetime': 'lang_th_life', 'lang_th': 'lang_th_life'};

  static Plan? plan(String id) => plans.where((p) => p.id == id).firstOrNull;

  /// 이 언어를 열 수 있는가 — 언어 상품(lang_<코드>_*) 또는 종합(all_*) 중 기한이 남은 것이 있으면.
  static bool owns(String code) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return owned.value.entries.any((e) => (e.key.startsWith('lang_${code}_') || e.key.startsWith('all_')) && (e.value == 0 || e.value > now));
  }

  static Future<void> configure(String code, List<Plan> list) async {
    lang = code;
    plans = list;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('iap_owned2');
    final m = <String, int>{if (raw != null) ...(jsonDecode(raw) as Map).map((k, v) => MapEntry('$k', (v as num).toInt()))};
    if ((p.getStringList('iap_owned') ?? const []).contains(code)) m['lang_${code}_life'] = 0; // 옛 저장 방식(평생 하나)
    owned.value = m;
    Account.user.addListener(_onAccount);
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return;
    _sub ??= InAppPurchase.instance.purchaseStream.listen(_onUpdates, onError: (_) => status.value = 'error');
    try {
      if (!await InAppPurchase.instance.isAvailable()) return;
      final r = await InAppPurchase.instance.queryProductDetails({for (final x in list) x.id});
      products.value = {for (final d in r.productDetails) d.id: d};
    } catch (_) {}
  }

  /// 스토어 표시 가격(예 ₩3,900). 상품을 못 받았으면 null.
  static String? price(String id) => products.value[id]?.price;

  static Future<bool> buy(String id) async {
    final d = products.value[id];
    if (d == null) {
      status.value = 'error';
      return false;
    }
    status.value = 'pending';
    // 자동 갱신 구독도 이 호출로 산다(in_app_purchase 는 구독·비소모성을 같은 경로로 처리).
    return InAppPurchase.instance.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: d));
  }

  /// 구매 복원(스토어 심사 요구). 결과는 [status] 로: 'restored' 또는 'nothing'.
  static Future<void> restore() async {
    _restoring = true;
    _restoredAny = false;
    status.value = 'pending';
    await InAppPurchase.instance.restorePurchases();
    // 복원할 것이 없으면 스트림에 아무것도 안 오는 플랫폼이 있다 — 잠시 뒤 결과를 정한다
    Future.delayed(const Duration(seconds: 4), () {
      if (_restoring) {
        _restoring = false;
        status.value = _restoredAny ? 'restored' : 'nothing';
      }
    });
  }

  static String? _known(String productId) {
    final id = _legacy[productId] ?? productId;
    return plan(id) != null || id.startsWith('lang_') || id.startsWith('all_') ? id : null;
  }

  static Future<void> _onUpdates(List<PurchaseDetails> list) async {
    for (final pd in list) {
      final id = _known(pd.productID);
      switch (pd.status) {
        case PurchaseStatus.pending:
          status.value = 'pending';
        case PurchaseStatus.error:
          status.value = 'error';
        case PurchaseStatus.canceled:
          status.value = null;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (id != null) {
            await _grant(id, pd);
            _restoredAny = true;
            status.value = pd.status == PurchaseStatus.restored ? 'restored' : 'done';
            if (_restoring) _restoring = false;
          }
      }
      if (pd.pendingCompletePurchase) await InAppPurchase.instance.completePurchase(pd);
    }
  }

  static int _expiry(String id, PurchaseDetails pd) {
    final months = plan(id)?.months ?? (id.endsWith('_1m') ? 1 : id.endsWith('_3m') ? 3 : id.endsWith('_1y') ? 12 : 0);
    if (months == 0) return 0;
    final t = DateTime.fromMillisecondsSinceEpoch(int.tryParse(pd.transactionDate ?? '') ?? DateTime.now().millisecondsSinceEpoch);
    return DateTime(t.year, t.month + months, t.day + 3, t.hour, t.minute).millisecondsSinceEpoch;
  }

  static Future<void> _grant(String id, PurchaseDetails pd) async {
    final exp = _expiry(id, pd);
    final cur = owned.value[id];
    final keep = cur != null && (cur == 0 || (exp != 0 && cur > exp)); // 더 긴 기한이 있으면 유지
    if (!keep) owned.value = {...owned.value, id: exp};
    final p = await SharedPreferences.getInstance();
    await p.setString('iap_owned2', jsonEncode(owned.value));
    // 서버로 보낼 영수증 — 로그인 전이면 쌓아 두었다가 로그인 때 보낸다
    final rec = {
      'platform': Platform.isIOS ? 'ios' : 'android',
      'product_id': pd.productID,
      if (Platform.isIOS) 'transaction_id': pd.purchaseID,
      if (Platform.isAndroid) 'purchase_token': pd.verificationData.serverVerificationData,
    };
    await p.setStringList('iap_pending', {...?p.getStringList('iap_pending'), jsonEncode(rec)}.toList());
    await _flush();
  }

  static void _onAccount() {
    if (Account.signedIn) _flush();
  }

  /// 쌓인 영수증을 계정에 붙인다. 실패한 것은 남겨 두고 다음에 다시.
  static Future<void> _flush() async {
    final at = Account.signedIn ? await Account.accessToken() : null;
    if (at == null) return;
    final p = await SharedPreferences.getInstance();
    final left = <String>[];
    var sent = false;
    for (final s in [...?p.getStringList('iap_pending')]) {
      try {
        final r = await http.post(Uri.parse('${Account.base}/me/purchases'),
            headers: {'Authorization': 'Bearer $at', 'Content-Type': 'application/json'},
            body: jsonEncode({...jsonDecode(s) as Map<String, dynamic>, 'client_id': Account.clientId})).timeout(const Duration(seconds: 15));
        if (r.statusCode == 200) {
          sent = true;
        } else if (r.statusCode >= 500 || r.statusCode == 401) {
          left.add(s); // 서버 준비 전·일시 오류 → 다시
        } // 400(잘못된 영수증)은 버린다
      } catch (_) {
        left.add(s);
      }
    }
    await p.setStringList('iap_pending', left);
    if (sent) await Account.refresh(); // 이용권 다시 받기
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account.dart';

/// 앱 안 결제 — Talkverse 공용 클라이언트(2026-11-02). 결제는 스토어(iOS StoreKit 2 · Android Play Billing),
/// 이용권 기록은 Talkverse ID(auth.talkverse.uk POST /me/purchases).
/// - 로그인 없이도 사고 복원할 수 있다(스토어가 기억 → 이 기기에 저장).
/// - 로그인돼 있으면 서버가 스토어에 확인해 계정 이용권으로 기록 → 다른 기기·다른 플랫폼에서도 열림.
///   로그인 전에 산 것은 로그인할 때 서버로 보낸다.
/// 앱은 [configure] 한 번, 그 뒤 [buy] · [restore] · [owns] 만 쓴다.
class Purchase {
  Purchase._();

  /// 이용권 언어 키 → 스토어 상품 번호. 예: {'hanja': ('com.talkverse.hanjaUniverse.lifetime', 'lang_hanja')}
  static Map<String, (String ios, String android)> _items = const {};
  static final owned = ValueNotifier<Set<String>>(const {});
  static final products = ValueNotifier<Map<String, ProductDetails>>(const {});
  /// 구매 진행 상태 알림(화면이 듣고 안내): null = 없음, 'pending' · 'error' · 'done' · 'restored' · 'nothing'
  static final status = ValueNotifier<String?>(null);
  static StreamSubscription<List<PurchaseDetails>>? _sub;
  static bool _restoring = false, _restoredAny = false;

  static bool owns(String lang) => owned.value.contains(lang);
  static String _pid(String lang) => !kIsWeb && Platform.isIOS ? _items[lang]!.$1 : _items[lang]!.$2;
  static String? _langOf(String productId) {
    for (final e in _items.entries) {
      if (e.value.$1 == productId || e.value.$2 == productId) return e.key;
    }
    return null;
  }

  static Future<void> configure(Map<String, (String, String)> items) async {
    _items = items;
    final p = await SharedPreferences.getInstance();
    owned.value = {...?p.getStringList('iap_owned')};
    Account.user.addListener(_onAccount);
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return;
    _sub ??= InAppPurchase.instance.purchaseStream.listen(_onUpdates, onError: (_) => status.value = 'error');
    try {
      if (!await InAppPurchase.instance.isAvailable()) return;
      final r = await InAppPurchase.instance.queryProductDetails({for (final l in items.keys) _pid(l)});
      products.value = {for (final d in r.productDetails) if (_langOf(d.id) != null) _langOf(d.id)!: d};
    } catch (_) {}
  }

  /// 스토어 표시 가격(예 ₩14,900). 상품을 못 받았으면 null.
  static String? price(String lang) => products.value[lang]?.price;

  static Future<bool> buy(String lang) async {
    final d = products.value[lang];
    if (d == null) {
      status.value = 'error';
      return false;
    }
    status.value = 'pending';
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

  static Future<void> _onUpdates(List<PurchaseDetails> list) async {
    for (final pd in list) {
      final lang = _langOf(pd.productID);
      switch (pd.status) {
        case PurchaseStatus.pending:
          status.value = 'pending';
        case PurchaseStatus.error:
          status.value = 'error';
        case PurchaseStatus.canceled:
          status.value = null;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (lang != null) {
            await _grant(lang, pd);
            _restoredAny = true;
            status.value = pd.status == PurchaseStatus.restored ? 'restored' : 'done';
            if (_restoring) _restoring = false;
          }
      }
      if (pd.pendingCompletePurchase) await InAppPurchase.instance.completePurchase(pd);
    }
  }

  static Future<void> _grant(String lang, PurchaseDetails pd) async {
    owned.value = {...owned.value, lang};
    final p = await SharedPreferences.getInstance();
    await p.setStringList('iap_owned', owned.value.toList());
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

import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Talkverse ID — 언어앱·talkverse.uk 와 같은 공용 계정(auth.talkverse.uk, 2026-11-02).
/// 로그인은 선택: 안 해도 앱 전체가 동작한다. 로그인하면 이용권(lang = 'th')을 서버에서 받는다.
/// 앱: 브라우저(ASWebAuthenticationSession/Custom Tabs)로 /oauth/<p>/start(PKCE) → talkverse.th://auth?code= → POST /token.
/// iOS 의 Apple 로그인은 네이티브(심사 지침 4.8) → identityToken 을 POST /token grant apple_native.
class Account {
  Account._();
  static const base = 'https://auth.talkverse.uk';
  static const clientId = 'th';
  static const scheme = 'talkverse.th';
  static const _redirect = '$scheme://auth';

  static const _store = FlutterSecureStorage();
  static final user = ValueNotifier<Map<String, dynamic>?>(null);
  static final entitlements = ValueNotifier<List<String>>(const []);
  static String? _access;
  static DateTime _accessExp = DateTime.fromMillisecondsSinceEpoch(0);

  static bool get signedIn => user.value != null;
  static bool has(String lang) => entitlements.value.contains(lang);

  /// 앱 시작 때: 저장된 사용자를 바로 보여 주고, 뒤에서 토큰을 갱신한다(오프라인이면 저장값 유지).
  static Future<void> load() async {
    try {
      final u = await _store.read(key: 'tv_user');
      final e = await _store.read(key: 'tv_ent');
      if (u != null) user.value = jsonDecode(u) as Map<String, dynamic>;
      if (e != null) entitlements.value = (jsonDecode(e) as List).cast<String>();
    } catch (_) {}
    if (user.value != null) refresh();
  }

  /// 서버에 설정된 제공자. 실패하면 플랫폼 기본값.
  static Future<List<String>> providers() async {
    final out = <String>[];
    try {
      final r = await http.get(Uri.parse('$base/providers')).timeout(const Duration(seconds: 6));
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      out.addAll((j['web'] as List).cast<String>());
    } catch (_) {}
    if (_iosNativeApple && !out.contains('apple')) out.add('apple');
    const order = ['apple', 'google', 'kakao', 'naver'];
    out.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    return out;
  }

  static bool get _iosNativeApple => !kIsWeb && Platform.isIOS;

  /// 로그인. 취소하면 false, 실패하면 예외.
  static Future<bool> signIn(String provider) async {
    if (provider == 'apple' && _iosNativeApple) return _appleNative();
    final verifier = _random(48);
    final challenge = base64Url.encode(sha256.convert(utf8.encode(verifier)).bytes).replaceAll('=', '');
    final url = Uri.parse('$base/oauth/$provider/start').replace(queryParameters: {
      'client_id': clientId, 'redirect_uri': _redirect, 'code_challenge': challenge,
    });
    String result;
    try {
      result = await FlutterWebAuth2.authenticate(url: url.toString(), callbackUrlScheme: scheme);
    } on Exception catch (e) {
      if (e.toString().contains('CANCELED')) return false;
      rethrow;
    }
    final q = Uri.parse(result).queryParameters;
    if (q['error'] == 'cancelled') return false;
    if (q['code'] == null) throw AccountError(q['error'] ?? 'no_code');
    await _token({'grant_type': 'authorization_code', 'code': q['code'], 'code_verifier': verifier});
    return true;
  }

  static Future<bool> _appleNative() async {
    final nonce = _random(32);
    AuthorizationCredentialAppleID c;
    try {
      c = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: sha256.convert(utf8.encode(nonce)).toString(),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return false;
      rethrow;
    }
    await _token({
      'grant_type': 'apple_native', 'identity_token': c.identityToken, 'nonce': nonce,
      'given_name': c.givenName, 'family_name': c.familyName,
    });
    return true;
  }

  /// 이메일·비밀번호 로그인 — 서버가 demo 플래그를 준 계정(App Store 심사자용 데모 계정 등)만 통과한다(사용자 지시 2026-11-02).
  /// 서버 계약: POST /token {grant_type:'password', email, password, client_id} → 일반 토큰 응답, 실패 401.
  static Future<bool> signInPassword(String email, String password) async {
    await _token({'grant_type': 'password', 'email': email.trim(), 'password': password});
    return true;
  }

  static Future<void> _token(Map<String, dynamic> body) async {
    final r = await http.post(Uri.parse('$base/token'),
        headers: {'Content-Type': 'application/json', 'X-Device': _device},
        body: jsonEncode({...body, 'client_id': clientId}));
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode != 200) throw AccountError(j['error']?.toString() ?? 'http_${r.statusCode}');
    await _save(j);
  }

  static Future<void> _save(Map<String, dynamic> j) async {
    _access = j['access_token'] as String;
    _accessExp = DateTime.now().add(Duration(seconds: (j['expires_in'] as num).toInt() - 60));
    await _store.write(key: 'tv_refresh', value: j['refresh_token'] as String);
    user.value = j['user'] as Map<String, dynamic>;
    entitlements.value = [for (final e in (j['entitlements'] as List)) (e as Map)['lang'] as String];
    await _store.write(key: 'tv_user', value: jsonEncode(user.value));
    await _store.write(key: 'tv_ent', value: jsonEncode(entitlements.value));
  }

  /// refresh 토큰으로 새 access. 서버가 거부하면(만료·회수) 로그아웃 상태로.
  static Future<bool> refresh() async {
    final rt = await _store.read(key: 'tv_refresh');
    if (rt == null) return false;
    try {
      final r = await http.post(Uri.parse('$base/token'),
          headers: {'Content-Type': 'application/json', 'X-Device': _device},
          body: jsonEncode({'grant_type': 'refresh_token', 'refresh_token': rt, 'client_id': clientId}))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        await _save(jsonDecode(r.body) as Map<String, dynamic>);
        return true;
      }
      if (r.statusCode == 400) await _clear();
    } catch (_) {} // 오프라인: 저장값 유지
    return false;
  }

  /// 로그인이 필요한 호출용 access 토큰(만료 1분 전이면 갱신).
  static Future<String?> accessToken() async {
    if (_access != null && DateTime.now().isBefore(_accessExp)) return _access;
    return await refresh() ? _access : null;
  }

  static Future<void> signOut() async {
    final rt = await _store.read(key: 'tv_refresh');
    if (rt != null) {
      try {
        await http.post(Uri.parse('$base/logout'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh_token': rt}))
            .timeout(const Duration(seconds: 6));
      } catch (_) {}
    }
    await _clear();
  }

  /// 탈퇴 — 서버에서 개인정보를 지우고 모든 기기에서 로그아웃(스토어 심사 요구).
  static Future<void> deleteAccount() async {
    final at = await accessToken();
    if (at == null) throw AccountError('no_session');
    final r = await http.delete(Uri.parse('$base/me'), headers: {'Authorization': 'Bearer $at'});
    if (r.statusCode != 200 && r.statusCode != 204) throw AccountError('http_${r.statusCode}'); // 서버는 200 {ok:true}, 204 도 허용
    await _clear();
  }

  static Future<void> _clear() async {
    _access = null;
    user.value = null;
    entitlements.value = const [];
    await _store.deleteAll();
  }

  static String get _device => 'th ${kIsWeb ? 'web' : Platform.operatingSystem}';
  static String _random(int n) {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(n, (_) => r.nextInt(256))).replaceAll('=', '');
  }
}

class AccountError implements Exception {
  final String code;
  AccountError(this.code);
  @override
  String toString() => 'AccountError($code)';
}

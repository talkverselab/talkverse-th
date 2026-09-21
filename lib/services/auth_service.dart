import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/backend.dart';
import 'course_service.dart';

/// 로그인 · 프로필 · 이용권 · 코스 동기화. Supabase 는 여기서만 만진다.
///
/// - 로그인 수단: Google · Kakao 는 Supabase 내장 OAuth(브라우저 → 딥링크 복귀). Naver 는 talkverse.uk Worker 경유(준비 중).
/// - 이용권: `tv_has_access(appLang)` 결과를 폰에 저장해 두고 하루에 한 번 다시 묻는다(오프라인 유예).
/// - 코스: 로그인하면 질문 답·완료 회차를 서버와 맞춘다. 설계: docs/accounts-billing-design.md
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kAccess = 'tv_access_v1'; // {"ok":bool,"at":ms}
  static const accessTtl = Duration(hours: 24);

  bool _ready = false;
  final ValueNotifier<User?> user = ValueNotifier<User?>(null);
  final ValueNotifier<bool?> hasAccess = ValueNotifier<bool?>(null);
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> entitlements = const [];
  StreamSubscription<AuthState>? _sub;

  SupabaseClient get _sb => Supabase.instance.client;
  bool get ready => _ready;
  bool get signedIn => user.value != null;

  /// 앱 시작 때 한 번. 네트워크가 없어도 실패하지 않는다(세션은 폰에 저장돼 있음).
  Future<void> init() async {
    if (_ready) return;
    try {
      await Supabase.initialize(
        url: Backend.supabaseUrl,
        publishableKey: Backend.supabaseKey,
        authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
      );
      _ready = true;
    } catch (e) {
      debugPrint('supabase init 실패: $e');
      return;
    }
    user.value = _sb.auth.currentUser;
    await _loadCachedAccess();
    CourseService.instance.onAnswersChanged = () => unawaited(pushAnswers());
    CourseService.instance.onDone = (k) => unawaited(pushDone(k));
    _sub = _sb.auth.onAuthStateChange.listen((s) {
      user.value = s.session?.user;
      if (s.event == AuthChangeEvent.signedIn || s.event == AuthChangeEvent.initialSession) {
        unawaited(afterSignIn());
      }
      if (s.event == AuthChangeEvent.signedOut) {
        profile = null;
        entitlements = const [];
        hasAccess.value = null;
        unawaited(_saveCachedAccess(null));
      }
    });
    if (signedIn) unawaited(afterSignIn());
  }

  Future<void> signInWithGoogle() => _oauth(OAuthProvider.google);
  Future<void> signInWithKakao() => _oauth(OAuthProvider.kakao);

  Future<void> _oauth(OAuthProvider p) async {
    if (!_ready) throw StateError('backend not ready');
    await _sb.auth.signInWithOAuth(
      p,
      redirectTo: Backend.authRedirect,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() async {
    if (!_ready) return;
    await _sb.auth.signOut();
  }

  /// 로그인 직후·앱 시작 때: 프로필 → 이용권 → 코스 동기화. 어느 하나가 실패해도 나머지는 진행.
  Future<void> afterSignIn() async {
    final u = user.value;
    if (u == null) return;
    await _guard(() async {
      profile = await _sb.from('tv_profiles').select().eq('user_id', u.id).maybeSingle();
    });
    await refreshAccess();
    await _guard(syncCourse);
  }

  Future<void> updateProfile(Map<String, dynamic> patch) async {
    final u = user.value;
    if (u == null) return;
    await _sb.from('tv_profiles').update(patch).eq('user_id', u.id);
    profile = {...?profile, ...patch};
  }

  /// 이용권 — 서버에 물어서 폰에 저장. 실패하면 저장된 값 유지(24시간 유예는 화면에서 판단).
  Future<void> refreshAccess() async {
    if (!signedIn) return;
    await _guard(() async {
      final ok = await _sb.rpc('tv_has_access', params: {'p_lang': Backend.appLang}) as bool;
      final rows = await _sb.rpc('tv_my_entitlements') as List;
      entitlements = rows.cast<Map<String, dynamic>>();
      hasAccess.value = ok;
      await _saveCachedAccess(ok);
    });
  }

  Future<void> _loadCachedAccess() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kAccess);
    if (raw == null) return;
    final m = json.decode(raw) as Map<String, dynamic>;
    final at = DateTime.fromMillisecondsSinceEpoch(m['at'] as int);
    if (DateTime.now().difference(at) < accessTtl * 7) hasAccess.value = m['ok'] as bool;
  }

  Future<void> _saveCachedAccess(bool? ok) async {
    final p = await SharedPreferences.getInstance();
    if (ok == null) {
      await p.remove(_kAccess);
    } else {
      await p.setString(_kAccess, json.encode({'ok': ok, 'at': DateTime.now().millisecondsSinceEpoch}));
    }
  }

  /// 코스 동기화 — 답은 최신 것이 이기고, 완료 회차는 양쪽 합집합.
  Future<void> syncCourse() async {
    final u = user.value;
    if (u == null) return;
    final course = CourseService.instance;
    await course.ensureLoaded();

    final row = await _sb
        .from('tv_course_answers')
        .select('answers, updated_at')
        .eq('user_id', u.id)
        .eq('app_lang', Backend.appLang)
        .maybeSingle();
    final serverAt = row == null ? null : DateTime.parse(row['updated_at'] as String);
    final localAt = course.answersUpdatedAt;
    if (row != null && (localAt == null || serverAt!.isAfter(localAt))) {
      await course.saveAnswers((row['answers'] as Map).cast<String, dynamic>(), touch: false);
    } else if (course.hasAnswers && (row == null || localAt!.isAfter(serverAt!))) {
      await _sb.from('tv_course_answers').upsert({
        'user_id': u.id,
        'app_lang': Backend.appLang,
        'answers': course.answers,
        'updated_at': (localAt ?? DateTime.now()).toUtc().toIso8601String(),
      });
    }

    final rows = await _sb
        .from('tv_course_progress')
        .select('script_key')
        .eq('user_id', u.id)
        .eq('app_lang', Backend.appLang) as List;
    final server = {for (final r in rows) r['script_key'] as String};
    final local = course.done;
    final missingOnServer = local.difference(server);
    if (missingOnServer.isNotEmpty) {
      await _sb.from('tv_course_progress').upsert([
        for (final k in missingOnServer) {'user_id': u.id, 'app_lang': Backend.appLang, 'script_key': k},
      ]);
    }
    final missingLocally = server.difference(local);
    if (missingLocally.isNotEmpty) await course.mergeDone(missingLocally);
  }

  /// 완료 1건을 바로 올린다(로그인 상태일 때만, 실패는 무시 — 다음 동기화 때 합쳐진다).
  Future<void> pushDone(String scriptKey) async {
    final u = user.value;
    if (u == null || !_ready) return;
    await _guard(() => _sb.from('tv_course_progress').upsert(
        {'user_id': u.id, 'app_lang': Backend.appLang, 'script_key': scriptKey}));
  }

  Future<void> pushAnswers() async {
    final u = user.value;
    if (u == null || !_ready) return;
    final course = CourseService.instance;
    await _guard(() => _sb.from('tv_course_answers').upsert({
          'user_id': u.id,
          'app_lang': Backend.appLang,
          'answers': course.answers,
          'updated_at': (course.answersUpdatedAt ?? DateTime.now()).toUtc().toIso8601String(),
        }));
  }

  Future<void> _guard(Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      debugPrint('auth/sync: $e');
    }
  }

  void dispose() => _sub?.cancel();
}

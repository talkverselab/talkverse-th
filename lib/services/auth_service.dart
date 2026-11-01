import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/backend.dart';
import '../data/account.dart';
import '../data/learn_api.dart';
import 'course_service.dart';

/// 로그인 · 프로필 · 이용권 · 코스 동기화 — 화면은 여기만 본다.
///
/// - 계정은 Talkverse ID(auth.talkverse.uk, `lib/data/account.dart` — 한자 앱과 같은 공용 클라이언트). 2026-11-02 Supabase 에서 이전.
/// - 로그인 수단: Google · Kakao · Naver(브라우저 → 딥링크 `talkverse.th://auth` 복귀), iOS 는 Apple 네이티브.
/// - 이용권: 토큰 응답의 entitlements 에 'th' 가 있으면 사용 가능. 폰에 저장돼 오프라인에서도 유지.
/// - 코스 동기화(답·완료 회차): 공용 학습 API(`lib/data/learn_api.dart`, /v1/th/course/…). 로그인 전에는 이 폰에만 저장.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  bool _ready = false;
  final ValueNotifier<bool?> hasAccess = ValueNotifier<bool?>(null);

  /// 로그인한 사용자 {id, email, display_name, …}. 로그아웃이면 null.
  ValueNotifier<Map<String, dynamic>?> get user => Account.user;
  Map<String, dynamic>? get profile => Account.user.value;
  bool get ready => _ready;
  bool get signedIn => Account.signedIn;

  /// 앱 시작 때 한 번. 네트워크가 없어도 실패하지 않는다(로그인 상태는 폰에 저장돼 있음).
  Future<void> init() async {
    if (_ready) return;
    Account.entitlements.addListener(_syncAccess);
    Account.user.addListener(_syncAccess);
    try {
      await Account.load();
    } catch (e) {
      debugPrint('Account.load: $e');
    }
    _syncAccess();
    _ready = true;
    CourseService.instance.onAnswersChanged = () => unawaited(_guard(pushAnswers));
    CourseService.instance.onDone = (k) => unawaited(_guard(() => pushDone(k)));
    Account.user.addListener(() {
      if (Account.signedIn) unawaited(_guard(syncCourse));
    });
    if (signedIn) unawaited(_guard(syncCourse));
  }

  void _syncAccess() {
    hasAccess.value = Account.signedIn ? Account.has(Backend.appLang) : null;
  }

  /// 서버에 설정된 로그인 수단(apple·google·kakao·naver 순). 실패하면 플랫폼 기본값.
  Future<List<String>> providers() => Account.providers();

  /// 로그인. 사용자가 취소하면 false.
  Future<bool> signIn(String provider) => Account.signIn(provider);

  Future<void> signOut() => Account.signOut();

  /// 탈퇴 — 서버에서 개인정보를 지우고 모든 기기에서 로그아웃(스토어 심사 요구).
  Future<void> deleteAccount() => Account.deleteAccount();

  /// 이용권 다시 확인(refresh 토큰 → 새 토큰 응답의 entitlements).
  Future<void> refreshAccess() async {
    if (!signedIn) return;
    await Account.refresh();
  }

  /// 코스 동기화 — 답은 최신 updated_at 이 이기고, 완료 회차는 양쪽 합집합.
  Future<void> syncCourse() async {
    if (!signedIn) return;
    final course = CourseService.instance;
    await course.ensureLoaded();

    final a = await LearnApi.call('GET', '/course/answers');
    if (a == null) return;
    final serverAns = a.$2['answers'];
    final serverAt = a.$2['updated_at'] == null ? null : DateTime.tryParse(a.$2['updated_at'] as String);
    final localAt = course.answersUpdatedAt;
    if (serverAns is Map && serverAt != null && (localAt == null || serverAt.isAfter(localAt))) {
      await course.saveAnswers(serverAns.cast<String, dynamic>(), touch: false);
    } else if (course.hasAnswers && (serverAt == null || (localAt != null && localAt.isAfter(serverAt)))) {
      await pushAnswers();
    }

    final p = await LearnApi.call('GET', '/course/progress');
    if (p == null || p.$1 != 200) return;
    final server = {for (final r in (p.$2['items'] as List? ?? const [])) (r as Map)['script_key'] as String};
    final missingOnServer = course.done.difference(server).toList();
    for (var i = 0; i < missingOnServer.length; i += 500) {
      final part = missingOnServer.skip(i).take(500);
      await LearnApi.call('POST', '/course/progress', {
        'items': [for (final k in part) {'script_key': k}],
      });
    }
    final missingLocally = server.difference(course.done);
    if (missingLocally.isNotEmpty) await course.mergeDone(missingLocally);
  }

  /// 답 올리기. 서버 값이 더 새면(409) 서버 값을 받는다.
  Future<void> pushAnswers() async {
    if (!signedIn) return;
    final course = CourseService.instance;
    final r = await LearnApi.call('PUT', '/course/answers', {
      'answers': course.answers,
      'updated_at': (course.answersUpdatedAt ?? DateTime.now()).toUtc().toIso8601String(),
    });
    if (r != null && r.$1 == 409 && r.$2['answers'] is Map) {
      await course.saveAnswers((r.$2['answers'] as Map).cast<String, dynamic>(), touch: false);
    }
  }

  /// 완료 1건을 바로 올린다(실패는 무시 — 다음 동기화 때 합쳐진다).
  Future<void> pushDone(String scriptKey) async {
    if (!signedIn) return;
    await LearnApi.call('POST', '/course/progress', {
      'items': [
        {'script_key': scriptKey},
      ],
    });
  }

  Future<void> _guard(Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      debugPrint('auth/sync: $e');
    }
  }
}

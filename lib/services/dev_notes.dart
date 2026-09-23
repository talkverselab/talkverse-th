import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/backend.dart';
import '../core/platform.dart';
import 'content_store.dart';
import 'update_service.dart';

/// 검수용 개발자 메모 — 어느 화면에서든 메모 + 화면 캡처 + 맥락을 Supabase `tv_dev_notes` 에 남긴다.
///
/// 켜는 법: 프로필 → 「앱 버전」을 7번 탭 → 「개발자 메모」 스위치. 켜면 모든 화면 오른쪽 아래에 버튼이 뜬다.
/// 로그인이 안 됐거나 오프라인이면 폰에 모아 두었다가 다음에 보낸다.
/// 화면이 맥락(스크립트 id·턴 등)을 알리려면 `DevNotes.instance.setContext('course', {...})`.
class DevNotes {
  DevNotes._();
  static final DevNotes instance = DevNotes._();

  static const _kEnabled = 'dev_notes_enabled_v1';
  static const _kUnlocked = 'dev_notes_unlocked_v1';
  static const _kQueue = 'dev_notes_queue_v1';

  final ValueNotifier<bool> enabled = ValueNotifier(false);
  final ValueNotifier<bool> unlocked = ValueNotifier(false);
  final GlobalKey boundaryKey = GlobalKey();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final DevRouteObserver observer = DevRouteObserver();

  /// 화면들이 올리는 맥락 — 키별로 쌓고 화면을 떠나면 지운다.
  final Map<String, Map<String, dynamic>> _context = {};

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    unlocked.value = p.getBool(_kUnlocked) ?? false;
    enabled.value = unlocked.value && (p.getBool(_kEnabled) ?? false);
  }

  Future<void> unlock() async {
    unlocked.value = true;
    (await SharedPreferences.getInstance()).setBool(_kUnlocked, true);
  }

  Future<void> setEnabled(bool v) async {
    enabled.value = v;
    (await SharedPreferences.getInstance()).setBool(_kEnabled, v);
    if (v) flushQueue();
  }

  void setContext(String key, Map<String, dynamic> data) => _context[key] = data;
  void clearContext(String key) => _context.remove(key);

  String get currentScreen => observer.topName;

  Future<Uint8List?> capture() async {
    try {
      final b = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (b == null) return null;
      final img = await b.toImage(pixelRatio: 1.2);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (e) {
      debugPrint('DevNotes.capture: $e');
      return null;
    }
  }

  Map<String, dynamic> snapshot(String note) => {
        'app_lang': Backend.appLang,
        'app_build': UpdateService.instance.currentBuild,
        'platform': isIOS ? 'ios' : (isAndroid ? 'android' : 'other'),
        'screen': currentScreen,
        'context': {
          ..._context.map((k, v) => MapEntry(k, v)),
          'content_version': ContentStore.instance.activeVersion,
          'at': DateTime.now().toIso8601String(),
        },
        'note': note,
      };

  /// 보내기. 실패하면 폰에 모아 둔다. 반환: 바로 보냈으면 true.
  Future<bool> submit(String note, Uint8List? shot) async {
    final row = snapshot(note);
    String? shotFile;
    if (shot != null) {
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/dev_notes');
      await dir.create(recursive: true);
      shotFile = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
      await File(shotFile).writeAsBytes(shot);
    }
    final item = {'row': row, 'shot': shotFile};
    final ok = await _send(item);
    if (!ok) {
      final p = await SharedPreferences.getInstance();
      final q = p.getStringList(_kQueue) ?? [];
      q.add(json.encode(item));
      await p.setStringList(_kQueue, q);
    }
    return ok;
  }

  Future<int> queued() async => ((await SharedPreferences.getInstance()).getStringList(_kQueue) ?? const []).length;

  Future<void> flushQueue() async {
    final p = await SharedPreferences.getInstance();
    final q = p.getStringList(_kQueue) ?? [];
    if (q.isEmpty) return;
    final left = <String>[];
    for (final s in q) {
      if (!await _send(json.decode(s) as Map<String, dynamic>)) left.add(s);
    }
    await p.setStringList(_kQueue, left);
  }

  Future<bool> _send(Map<String, dynamic> item) async {
    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;
      if (uid == null) return false;
      final row = Map<String, dynamic>.from(item['row'] as Map);
      final shotFile = item['shot'] as String?;
      if (shotFile != null && await File(shotFile).exists()) {
        final path = '$uid/${shotFile.split(RegExp(r'[\\/]')).last}';
        await sb.storage.from('dev-notes').uploadBinary(path, await File(shotFile).readAsBytes(),
            fileOptions: const FileOptions(contentType: 'image/png', upsert: true));
        row['shot_path'] = path;
      }
      await sb.from('tv_dev_notes').insert(row);
      if (shotFile != null) {
        try {
          await File(shotFile).delete();
        } catch (_) {}
      }
      return true;
    } catch (e) {
      debugPrint('DevNotes._send: $e');
      return false;
    }
  }

  /// 내가 남긴 메모 목록(처리 결과 포함).
  Future<List<Map<String, dynamic>>> mine() async {
    final rows = await Supabase.instance.client
        .from('tv_dev_notes')
        .select('id, created_at, screen, note, status, resolution, resolved_at')
        .order('created_at', ascending: false)
        .limit(100);
    return (rows as List).cast<Map<String, dynamic>>();
  }
}

/// 맨 위 화면의 이름을 기억한다. MaterialPageRoute 는 builder 로 위젯 종류를 알아낸다.
class DevRouteObserver extends NavigatorObserver {
  final List<String> _stack = [];
  String get topName => _stack.isEmpty ? 'MainScreen' : _stack.last;

  String _name(Route<dynamic> r) {
    if (r.settings.name != null && r.settings.name != '/') return r.settings.name!;
    if (r is MaterialPageRoute) {
      final ctx = navigator?.context;
      if (ctx != null) {
        try {
          return r.builder(ctx).runtimeType.toString();
        } catch (_) {}
      }
    }
    if (r is PopupRoute) return 'popup:${r.runtimeType}';
    return r.runtimeType.toString();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _stack.add(_name(route));
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_stack.isNotEmpty) _stack.removeLast();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_stack.isNotEmpty) _stack.removeLast();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (_stack.isNotEmpty) _stack.removeLast();
    if (newRoute != null) _stack.add(_name(newRoute));
  }
}

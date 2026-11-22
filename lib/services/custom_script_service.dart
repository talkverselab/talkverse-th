import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint;
import '../core/prefs.dart';

import '../data/account.dart';
import 'dialogue_service.dart';

/// 맞춤 회화(고유 스크립트) — 2026-11-02. 계약: `docs/CUSTOM_SCRIPT_API.md`.
///
/// 도메인·상황·레벨을 고르면 Cloudflare 에 요청이 ID 로 저장되고, 맥미니 코드 서버(Claude)가 편을 만들어
/// 같은 ID 에 넣는다. 앱은 ID 목록을 들고 상태를 확인하고, ready 편은 로컬에 보관해 오프라인에서도 연다.
/// 첫 1편 무료, 유료는 한 달 5편(종합 10편)·하루 1편(서버가 device 기준으로 센다). 외부 LLM API 는 쓰지 않는다.
class CustomScriptItem {
  final String id;
  String status; // queued · writing · ready · failed · local(서버에 못 보냄)
  final String domain;
  final String situation;
  final String level;
  final String name;
  final String createdAt;
  Dialogue? dialogue;
  String? error;
  CustomScriptItem({
    required this.id,
    required this.status,
    required this.domain,
    required this.situation,
    required this.level,
    required this.name,
    required this.createdAt,
    this.dialogue,
    this.error,
  });

  bool get isReady => status == 'ready' && dialogue != null;
  bool get isWorking => status == 'queued' || status == 'writing';

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'domain': domain,
        'situation': situation,
        'level': level,
        'name': name,
        'created_at': createdAt,
        if (dialogue != null) 'dialogue': _rawDialogue,
        if (error != null) 'error': error,
      };
  Map<String, dynamic>? _rawDialogue;

  factory CustomScriptItem.fromJson(Map<String, dynamic> j) {
    final it = CustomScriptItem(
      id: j['id'] as String,
      status: j['status'] as String? ?? 'queued',
      domain: j['domain'] as String? ?? 'life',
      situation: j['situation'] as String? ?? '',
      level: j['level'] as String? ?? 'R1',
      name: j['name'] as String? ?? '',
      createdAt: j['created_at'] as String? ?? '',
      error: j['error'] as String?,
    );
    final d = j['dialogue'];
    if (d is Map<String, dynamic>) it.setDialogue(d);
    if (d is String && d.isNotEmpty) {
      try {
        it.setDialogue(json.decode(d) as Map<String, dynamic>);
      } catch (_) {}
    }
    return it;
  }

  void setDialogue(Map<String, dynamic> raw) {
    try {
      final m = Map<String, dynamic>.from(raw);
      m['id'] ??= id;
      m['region'] ??= level;
      m['island'] ??= domain;
      m['kind'] = 'custom';
      final d = Dialogue.fromJson(m);
      if (d.turns.isNotEmpty) {
        dialogue = d;
        _rawDialogue = m;
        status = 'ready';
      }
    } catch (e) {
      debugPrint('CustomScript: 편 파싱 실패 $e');
    }
  }
}

class CustomScriptService {
  CustomScriptService._();
  static final CustomScriptService instance = CustomScriptService._();

  static const baseUrl = 'https://talkverse.uk/api/script/th';
  static const _prefItems = 'custom_scripts_v1';
  static const _prefDevice = 'device_id';
  static const levels = ['R0', 'R1', 'R2', 'R3'];

  /// 추천 상황(도메인별, 칩으로 보임). 자유 입력이 우선.
  static const suggestions = {
    'survival': ['길을 잃어서 역을 물어봄', '지갑을 잃어버림', '약국에서 두통약 사기', '전철을 잘못 탐'],
    'friends': ['친구 생일 깜짝 파티 준비', '늦게 온 친구 놀리기', '같이 볼 영화 고르기', '첫 룸메이트와 규칙 정하기'],
    'love': ['첫 데이트 장소 정하기', '고백할까 말까 상담', '기념일을 깜빡함', '비 오는 날 우산 하나'],
    'life': ['이웃에게 이사 인사', '세탁기가 고장 남', '편의점 알바 첫날', '병원 예약 전화'],
    'travel': ['온천 여관 체크인', '길거리 음식 추천받기', '막차를 놓침', '렌터카 반납'],
    'culture': ['축제에서 유카타 입기', '신사 참배 예절 배우기', '노래방에서 선곡', '벚꽃놀이 자리 잡기'],
    'work': ['회의에 지각해서 사과', '상사에게 휴가 신청', '거래처 첫 전화', '회식에서 자기소개'],
    'study': ['시험 전날 밤샘 공부', '교수님께 과제 연장 부탁', '동아리 신입 환영회', '유학생 친구와 과제 분담'],
  };

  final List<CustomScriptItem> _items = [];
  List<CustomScriptItem> get items => List.unmodifiable(_items);
  bool _loaded = false;
  String _device = '';
  String get deviceId => _device;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await Prefs.getInstance();
    _device = prefs.getString(_prefDevice) ?? '';
    if (_device.isEmpty) {
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
      final r = Random.secure();
      _device = 'd${List.generate(23, (_) => chars[r.nextInt(chars.length)]).join()}';
      await prefs.setString(_prefDevice, _device);
    }
    final raw = prefs.getString(_prefItems);
    if (raw != null) {
      try {
        for (final j in json.decode(raw) as List) {
          _items.add(CustomScriptItem.fromJson(j as Map<String, dynamic>));
        }
      } catch (e) {
        debugPrint('CustomScript: 보관 목록 파싱 실패 $e');
      }
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await Prefs.getInstance();
    await prefs.setString(_prefItems, json.encode(_items.map((e) => e.toJson()).toList()));
  }

  /// 만들기 요청. 성공하면 서랍 맨 앞에 queued 로 들어간다.
  /// 실패: 'paid_required'(무료 1회 소진) · 'offline'(서버 응답 없음) · 그 밖의 서버 오류 문구.
  Future<({CustomScriptItem? item, String? error})> create({required String domain, required String situation, required String level, String name = ''}) async {
    await ensureLoaded();
    final body = {'device': _device, 'domain': domain, 'situation': situation.trim(), 'level': level, if (name.trim().isNotEmpty) 'name': name.trim()};
    final res = await _http('POST', baseUrl, body);
    if (res == null) return (item: null, error: 'offline');
    final (code, j) = res;
    if (code == 402) return (item: null, error: 'paid_required');
    // 한도(2026-11-09): 유료 한 달 5편·종합 10편, 하루 1편(한국 시간). 서버가 429 로 알린다.
    if (code == 429) {
      final e = (j['error'] ?? '').toString();
      if (e == 'monthly_limit') {
        lastLimit = (j['limit'] as num?)?.toInt() ?? lastLimit;
        return (item: null, error: 'monthly_limit');
      }
      if (e == 'daily_limit') return (item: null, error: 'daily_limit');
    }
    if (code != 200 && code != 201 || j['id'] == null) return (item: null, error: (j['error'] ?? 'HTTP $code').toString());
    final it = CustomScriptItem(
      id: j['id'] as String,
      status: j['status'] as String? ?? 'queued',
      domain: domain,
      situation: situation.trim(),
      level: level,
      name: name.trim(),
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    _items.insert(0, it);
    await _save();
    return (item: it, error: null);
  }

  /// 만드는 중인 편들의 상태를 서버에서 받아 온다(열 때·새로고침). 바뀐 게 있으면 true.
  Future<bool> refresh({String? onlyId}) async {
    await ensureLoaded();
    var changed = false;
    for (final it in _items) {
      if (onlyId != null && it.id != onlyId) continue;
      if (it.isReady && onlyId == null) continue;
      final res = await _http('GET', '$baseUrl/${it.id}', null);
      if (res == null) continue;
      final (code, j) = res;
      if (code != 200) continue;
      final st = j['status'] as String? ?? it.status;
      if (st == 'ready' && j['dialogue'] != null) {
        final d = j['dialogue'];
        it.setDialogue(d is String ? json.decode(d) as Map<String, dynamic> : d as Map<String, dynamic>);
        changed = true;
      } else if (st != it.status) {
        it.status = st;
        it.error = j['error'] as String?;
        changed = true;
      }
    }
    if (changed) await _save();
    return changed;
  }

  /// 서버가 마지막으로 알려 준 한 달 한도(없으면 null — 화면이 이용권으로 추정).
  int? lastLimit;

  /// 이번 달(한국 시간) 이 기기에서 만든 편 수 — 서버와 같은 기준(실패 제외).
  int usedThisMonth() {
    final kst = DateTime.now().toUtc().add(const Duration(hours: 9));
    final start = DateTime.utc(kst.year, kst.month).subtract(const Duration(hours: 9));
    return _items.where((e) => e.status != 'failed' && (DateTime.tryParse(e.createdAt)?.isAfter(start) ?? false)).length;
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _save();
  }

  Future<(int, Map<String, dynamic>)?> _http(String method, String url, Map<String, dynamic>? body) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.openUrl(method, Uri.parse(url));
      req.headers.contentType = ContentType.json;
      req.headers.set('User-Agent', 'talkverse-th-app/1.0');
      // 로그인돼 있으면 Talkverse ID 토큰 — Worker 가 이용권(lang th)을 확인해 2편째부터의 402 를 풀 수 있다(uk 세션에 요청, 2026-11-02)
      final at = Account.signedIn ? await Account.accessToken() : null;
      if (at != null) req.headers.set('Authorization', 'Bearer $at');
      if (body != null) req.write(json.encode(body));
      final res = await req.close().timeout(const Duration(seconds: 15));
      final text = await res.transform(utf8.decoder).join();
      Map<String, dynamic> j = {};
      try {
        final parsed = json.decode(text);
        if (parsed is Map<String, dynamic>) j = parsed;
      } catch (_) {}
      return (res.statusCode, j);
    } catch (e) {
      debugPrint('CustomScript: $method $url 실패 $e');
      return null;
    } finally {
      client.close();
    }
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/backend.dart';
import 'account.dart';

/// 공용 학습 데이터 API(talkverse-api, D1 talkverse-db) — `https://auth.talkverse.uk/v1/<lang>/…`
/// 모든 호출은 Talkverse ID access 토큰(Bearer). 로그인 안 했거나 토큰을 못 받으면 null.
class LearnApi {
  LearnApi._();
  static String get _base => '${Account.base}/v1/${Backend.appLang}';

  /// 반환: (상태 코드, 본문 JSON). 로그인 안 됨 = null.
  static Future<(int, Map<String, dynamic>)?> call(String method, String path, [Map<String, dynamic>? body]) async {
    final at = await Account.accessToken();
    if (at == null) return null;
    final req = http.Request(method, Uri.parse('$_base$path'))
      ..headers['Authorization'] = 'Bearer $at'
      ..headers['Content-Type'] = 'application/json';
    if (body != null) req.body = jsonEncode(body);
    final r = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 15)));
    final j = r.body.isEmpty ? <String, dynamic>{} : jsonDecode(r.body) as Map<String, dynamic>;
    return (r.statusCode, j);
  }
}

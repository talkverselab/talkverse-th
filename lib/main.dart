import 'package:flutter/material.dart';

import 'embed.dart';

export 'embed.dart' show appDb;

/// 단독 앱(태국어유니버스) 진입점 — 초기화와 앱 위젯은 embed.dart(통합 앱과 같은 코드).
void main() async {
  await embedInit(standalone: true);
  runApp(embedApp());
}

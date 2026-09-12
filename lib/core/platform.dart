import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 갤럭시(Android) / 아이폰(iOS) 분기 — 한 곳에서만 판단한다.
bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// 화면 아래 시스템 영역(아이폰 홈 인디케이터, 갤럭시 제스처 바) 높이.
/// 하단 고정 버튼·목록 바닥 여백에 더해 가려지지 않게 한다.
double bottomInset(BuildContext context) => MediaQuery.paddingOf(context).bottom;

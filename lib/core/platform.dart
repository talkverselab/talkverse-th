import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 갤럭시(Android) / 아이폰(iOS) 분기 — 한 곳에서만 판단한다.
bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// 화면 아래 시스템 영역(아이폰 홈 인디케이터, 갤럭시 제스처 바) 높이.
/// 하단 고정 버튼·목록 바닥 여백에 더해 가려지지 않게 한다.
double bottomInset(BuildContext context) => MediaQuery.paddingOf(context).bottom;

/// 두 화면 기준 — 가로 720 논리픽셀 이상(아이패드 세로·가로, 안드로이드 태블릿, 폴드 펼침). 일본어앱·한자앱과 같다.
const double wideMin = 720;
bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= wideMin;

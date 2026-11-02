import 'package:flutter/material.dart';

/// 두 화면(넓은 화면)의 오른쪽 칸 — 왼쪽 탭 목록·메뉴에서 연 화면이 여기에 열린다.
/// 폰(한 화면)에는 이 위젯이 없어서 openPane 이 보통 push 로 동작한다. 일본어앱·한자앱 lib/core/pane.dart 와 같은 구조.
class Pane extends InheritedWidget {
  final GlobalKey<NavigatorState> navKey;
  const Pane({super.key, required this.navKey, required super.child});

  static Pane? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<Pane>();

  @override
  bool updateShouldNotify(Pane oldWidget) => oldWidget.navKey != navKey;
}

/// 화면 열기. 넓은 화면이면 오른쪽 칸에 — 왼쪽(메뉴·목록)에서 열면 오른쪽 칸을 통째로 바꾸고,
/// 오른쪽 칸 안에서 열면 그 위에 쌓는다. 한 화면이면 그냥 push.
Future<T?> openPane<T>(BuildContext context, WidgetBuilder builder) {
  final nav = Pane.maybeOf(context)?.navKey.currentState;
  if (nav == null) return Navigator.push<T>(context, MaterialPageRoute(builder: builder));
  if (Navigator.of(context) == nav) return nav.push<T>(MaterialPageRoute(builder: builder));
  return nav.pushAndRemoveUntil<T>(MaterialPageRoute(builder: builder), (r) => false);
}

/// 학습(에피소드·플래시카드 세션·퀴즈)은 넓은 화면에서도 왼쪽 목록을 감추고 **전체 화면**으로 연다.
Future<T?> openFull<T>(BuildContext context, WidgetBuilder builder) =>
    Navigator.of(context, rootNavigator: true).push<T>(MaterialPageRoute(builder: builder));

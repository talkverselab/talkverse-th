import 'package:integration_test/integration_test_driver.dart';

/// 두 화면 확인 스크린샷용 드라이버. 실제 캡처는 호스트 스크립트(tools/pane_shots.py)가
/// 기기 로그의 `SHOT:<이름>` 줄을 보고 `xcrun simctl io screenshot` 으로 찍는다.
Future<void> main() => integrationDriver();

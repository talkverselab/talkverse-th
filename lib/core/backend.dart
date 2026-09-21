/// Supabase 프로젝트 `Talkverse` — 모든 언어 앱과 talkverse.uk 가 같은 프로젝트를 쓴다.
/// 여기 있는 값은 공개 가능한 값이다(RLS 가 지킨다). 서비스 키는 절대 앱에 넣지 않는다.
class Backend {
  Backend._();

  static const supabaseUrl = 'https://jqtwqzxozfryjlzulxzl.supabase.co';
  static const supabaseKey = 'sb_publishable_Cdsd5x-NehefC6aITsBFcw_y-VCXO3Q';

  /// 이 앱의 언어 코드 — 이용권·코스 동기화의 키.
  static const appLang = 'th';

  /// OAuth 로그인 뒤 브라우저가 앱으로 돌아오는 딥링크. **앱마다 다르게** (스킴 끝의 언어 코드).
  /// Supabase Auth → URL Configuration → Redirect URLs 에 등록돼 있어야 한다.
  static const authRedirect = 'io.supabase.talkverse.th://login-callback/';
}

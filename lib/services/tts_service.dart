import 'package:flutter_tts/flutter_tts.dart';

/// flutter_tts 기반 — 시스템 th-TH voice 사용.
///
/// 화자별 음성: 기기에 남/여 th 보이스가 있으면 voice 전환,
/// 없으면 피치(남 0.72 / 여 1.12)로 구분한다.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  String? _speaking;

  Map<String, String>? _maleVoice;
  Map<String, String>? _femaleVoice;
  bool _voicesScanned = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.setLanguage('th-TH');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() => _speaking = null);
    _tts.setCancelHandler(() => _speaking = null);
    _tts.setErrorHandler((msg) => _speaking = null);
    _initialized = true;
  }

  /// th 보이스 중 이름에 male/female 힌트가 있는 것을 1회 스캔.
  Future<void> _scanVoices() async {
    if (_voicesScanned) return;
    _voicesScanned = true;
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return;
      for (final v in voices) {
        if (v is! Map) continue;
        final name = (v['name'] ?? '').toString();
        final locale = (v['locale'] ?? '').toString();
        if (!locale.toLowerCase().startsWith('th')) continue;
        final lower = name.toLowerCase();
        final voice = {'name': name, 'locale': locale};
        if (_maleVoice == null &&
            (lower.contains('male') && !lower.contains('female'))) {
          _maleVoice = voice;
        }
        if (_femaleVoice == null && lower.contains('female')) {
          _femaleVoice = voice;
        }
      }
    } catch (_) {
      // 보이스 목록 실패 시 피치 폴백만 사용
    }
  }

  bool isSpeaking(String text) => _speaking == text;

  Future<void> speak(String text) => _speakWith(text, null, 1.0);

  /// 화자 성별에 맞춰 읽기. gender: 'male' | 'female'
  Future<void> speakAs(String text, {required String gender}) async {
    await _scanVoices();
    final male = gender == 'male';
    final voice = male ? _maleVoice : _femaleVoice;
    // 전용 보이스가 있으면 피치는 1.0, 없으면 피치로 성별 구분
    final pitch = voice != null ? 1.0 : (male ? 0.72 : 1.12);
    await _speakWith(text, voice, pitch);
  }

  Future<void> _speakWith(
      String text, Map<String, String>? voice, double pitch) async {
    await _ensureInit();
    await _tts.stop();
    if (voice != null) {
      await _tts.setVoice(voice);
    } else {
      // 이전 speakAs 가 남긴 voice 를 초기화하기 위해 언어 재설정
      await _tts.setLanguage('th-TH');
    }
    await _tts.setPitch(pitch);
    _speaking = text;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _speaking = null;
  }
}

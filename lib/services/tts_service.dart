import 'package:flutter_tts/flutter_tts.dart';

import '../core/platform.dart';

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
    if (isIOS) {
      // 무음 스위치가 켜져 있어도 재생되게, 다른 앱 소리는 잠시 줄이게
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.duckOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ],
        IosTextToSpeechAudioMode.spokenAudio,
      );
    }
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
        // 안드로이드는 이름에 male/female 이 들어 있고, iOS 는 사람 이름(Kanya 등)이다.
        final gender = (v['gender'] ?? '').toString().toLowerCase();
        final isFemale = gender == 'female' ||
            lower.contains('female') ||
            lower.contains('kanya') ||
            lower.contains('narisa');
        final isMale = gender == 'male' ||
            (lower.contains('male') && !lower.contains('female'));
        if (_maleVoice == null && isMale) _maleVoice = voice;
        if (_femaleVoice == null && isFemale) _femaleVoice = voice;
      }
    } catch (_) {
      // 보이스 목록 실패 시 피치 폴백만 사용
    }
  }

  bool isSpeaking(String text) => _speaking == text;

  /// 재생 전 지연 — 탭 직후 바로 나오지 않고 1초 뒤에 나온다.
  static const Duration playDelay = Duration(seconds: 1);
  int _requestSeq = 0;

  /// 기본 음성 = 여성. 남/여 화자 대화 외의 단어·표현은 모두 여성 음성.
  Future<void> speak(String text) => speakAs(text, gender: 'female');

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
    _speaking = null;
    final seq = ++_requestSeq;
    await Future.delayed(playDelay);
    if (seq != _requestSeq) return; // 지연 중 새 요청이 오면 이전 요청은 버린다
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

  int _seqToken = 0;
  bool get isSequencePlaying => _seqPlaying;
  bool _seqPlaying = false;

  /// 여러 문장을 화자 성별에 맞춰 순서대로 끝까지 재생. onLine(i) 로 현재 줄을 알리고
  /// 끝나면 onLine(-1). stopSequence()/stop() 으로 중단.
  Future<void> speakSequence(
    List<({String text, String gender})> lines, {
    void Function(int index)? onLine,
    Duration gap = const Duration(milliseconds: 500),
  }) async {
    await _ensureInit();
    await _scanVoices();
    final token = ++_seqToken;
    _seqPlaying = true;
    await _tts.awaitSpeakCompletion(true);
    try {
      for (var i = 0; i < lines.length; i++) {
        if (token != _seqToken) break;
        onLine?.call(i);
        await speakAs(lines[i].text, gender: lines[i].gender);
        if (token != _seqToken) break;
        await Future.delayed(gap);
      }
    } finally {
      if (token == _seqToken) {
        _seqPlaying = false;
        await _tts.awaitSpeakCompletion(false);
        onLine?.call(-1);
      }
    }
  }

  void stopSequence() {
    _seqToken++;
    _seqPlaying = false;
    _requestSeq++;
    _tts.stop();
    _speaking = null;
  }

  Future<void> stop() async {
    _seqToken++;
    _seqPlaying = false;
    _requestSeq++; // 대기 중인 지연 재생 취소
    await _tts.stop();
    _speaking = null;
  }
}

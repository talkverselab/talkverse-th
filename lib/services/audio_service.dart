import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 합성 mp3 재생. manifest(letters/turns)가 있으면 에셋 경로를 찾아 재생한다.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  Map<String, String> _letterMap = const {};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw =
          await rootBundle.loadString('assets/data/audio_manifest.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final letters = (data['letters'] as Map<String, dynamic>?) ?? {};
      _letterMap = letters.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      _letterMap = const {};
    }
    _loaded = true;
  }

  bool hasLetter(String char) => _letterMap.containsKey(char);

  Future<bool> playLetter(String char) async {
    await ensureLoaded();
    final path = _letterMap[char];
    if (path == null) return false;
    final assetPath =
        path.startsWith('assets/') ? path.substring('assets/'.length) : path;
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> stop() => _player.stop();

  Future<void> dispose() async {
    await _player.dispose();
  }
}

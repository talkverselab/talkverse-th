import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

/// 성조연습용 마이크 녹음 — 16kHz 모노 PCM16. 녹음은 기기 안에서만 쓰고 저장·전송하지 않는다.
class ToneRecorder {
  ToneRecorder._();
  static final ToneRecorder instance = ToneRecorder._();
  static const int sampleRate = 16000;

  AudioRecorder? _recorder;
  AudioRecorder get _rec => _recorder ??= AudioRecorder();

  Future<bool> hasPermission() => _rec.hasPermission();

  /// [seconds] 동안 녹음해 PCM16(little endian) 바이트를 돌려준다. [onLevel] 은 소리 세기 0~1.
  Future<Uint8List> recordPcm({required double seconds, void Function(double level)? onLevel}) async {
    final stream = await _rec.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1,
      autoGain: true,
      echoCancel: false,
      noiseSuppress: true,
    ));
    final out = BytesBuilder(copy: true);
    late final StreamSubscription sub;
    sub = stream.listen((bytes) {
      out.add(bytes);
      if (onLevel != null && bytes.length > 2) {
        final bd = ByteData.sublistView(bytes);
        double sum = 0;
        for (var i = 0; i + 1 < bytes.length; i += 2) {
          final v = bd.getInt16(i, Endian.little);
          sum += v * v;
        }
        onLevel(math.sqrt(sum / (bytes.length / 2)) / 32768);
      }
    });
    await Future.delayed(Duration(milliseconds: (seconds * 1000).round()));
    await _rec.stop();
    await sub.cancel();
    return out.takeBytes();
  }

  Future<void> cancel() async {
    final r = _recorder;
    if (r != null && await r.isRecording()) await r.cancel();
  }
}

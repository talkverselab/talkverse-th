// 기준 음성의 음높이 곡선을 뽑는다(문장 겹쳐 보기용 자료 만들기).
//   ffmpeg -v error -i line.mp3 -f s16le -ar 16000 -ac 1 - | dart run talkverse_pitch:contour [점 개수]
// 출력: {"dur": 유성 구간 길이(초), "medianHz": 가운뎃값, "st": [가운뎃값 기준 반음 …]}
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:talkverse_pitch/talkverse_pitch.dart';

Future<void> main(List<String> args) async {
  final points = args.isEmpty ? 50 : int.parse(args[0]);
  final b = BytesBuilder(copy: false);
  await for (final chunk in stdin) {
    b.add(chunk);
  }
  final track = const PitchTracker().track(pcm16ToFloat(b.takeBytes()));
  final hz = track.voicedHz..sort();
  if (hz.length < 5) {
    stdout.writeln('null');
    return;
  }
  final median = hz[hz.length ~/ 2];
  final c = Contour.fromTrack(track, refHz: median, points: points)!;
  stdout.writeln(jsonEncode({
    'dur': double.parse(c.duration.toStringAsFixed(3)),
    'medianHz': double.parse(median.toStringAsFixed(1)),
    'st': [for (final v in c.st) double.parse(v.toStringAsFixed(2))],
  }));
}

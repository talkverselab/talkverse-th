import 'dart:math' as math;
import 'dart:typed_data';

/// 10ms 단위 한 칸의 음높이.
class PitchFrame {
  const PitchFrame(this.time, this.hz, this.clarity, this.rms);

  /// 칸 가운데 시각(초).
  final double time;

  /// 음높이(Hz). 무음·무성음이면 null.
  final double? hz;

  /// 주기성 0~1(1 에 가까울수록 또렷한 유성음).
  final double clarity;
  final double rms;
  bool get voiced => hz != null;
}

class PitchTrack {
  PitchTrack(this.frames, this.hopSeconds);
  final List<PitchFrame> frames;
  final double hopSeconds;

  List<double> get voicedHz => [
        for (final f in frames)
          if (f.hz != null) f.hz!
      ];

  /// 음절 구간만 잘라 낼 때(구간 시각은 앱이 준다).
  PitchTrack slice(double from, double to) => PitchTrack(
        [
          for (final f in frames)
            if (f.time >= from && f.time <= to) f
        ],
        hopSeconds,
      );
}

/// 16비트 리틀엔디언 PCM(마이크 스트림) → -1~1 실수.
Float64List pcm16ToFloat(Uint8List bytes) {
  final bd = ByteData.sublistView(bytes);
  final n = bytes.length ~/ 2;
  final out = Float64List(n);
  for (var i = 0; i < n; i++) {
    out[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
  }
  return out;
}

/// 음높이 추적: YIN 의 차이 함수(누적 평균 정규화)로 칸마다 후보 주기를 여럿 뽑고,
/// 칸 사이가 매끄럽게 이어지는 길을 골라 잇는다(유성·무성 가름도 그 길에서 정한다).
///
/// 칸마다 가장 깊은 골짜기 하나만 믿으면, 갈라지는 3성 바닥·숨 섞인 음절 끝·낮은 남자
/// 목소리처럼 주기성이 흐린 칸에서 배음이나 무성으로 튄다. 후보를 남겨 두고 앞뒤 칸과
/// 가장 자연스럽게 이어지는 것을 고르면 그런 칸도 이웃의 음높이를 따라 이어진다.
class PitchTracker {
  const PitchTracker({
    this.sampleRate = 16000,
    this.minHz = 70,
    this.maxHz = 500,
    this.hopSeconds = 0.01,
    this.voicingCutoff = 0.5,
    this.switchCost = 0.15,
    this.jumpCost = 0.08,
    this.candidates = 5,
    this.relativeSilence = 0.1,
    this.absoluteSilence = 0.003,
    this.minRunFrames = 3,
  });

  final int sampleRate;
  final double minHz;
  final double maxHz;
  final double hopSeconds;

  /// 소리가 있는 칸을 무성으로 두는 값. 골짜기 깊이(0 = 완전한 주기)가 이보다 얕은 칸은
  /// 이웃과 잘 이어질 때만 유성이 된다.
  final double voicingCutoff;

  /// 유성↔무성으로 바뀔 때마다 드는 값(한두 칸짜리 깜빡임을 막는다).
  final double switchCost;

  /// 이웃 칸과 음높이가 벌어질 때 반음마다 드는 값(1반음까지는 없음 — 성조가 움직이는 폭).
  final double jumpCost;

  /// 칸마다 남겨 두는 후보 수.
  final int candidates;

  /// 가장 큰 칸의 세기 대비 이 비율 밑은 무음.
  final double relativeSilence;
  final double absoluteSilence;

  /// 이보다 짧은 유성 구간은 버린다(튀는 값).
  final int minRunFrames;

  PitchTrack track(Float64List x) {
    final tauMin = math.max(2, (sampleRate / maxHz).floor());
    final tauMax = (sampleRate / minHz).ceil();
    final w = math.max(tauMax, (0.025 * sampleRate).round());
    final hop = math.max(1, (hopSeconds * sampleRate).round());
    final need = w + tauMax;
    final d = Float64List(tauMax + 2);

    final times = <double>[];
    final rmss = <double>[];
    // 칸마다 후보: 음높이(반음, 임의 기준)와 골짜기 깊이.
    final candSt = <List<double>>[];
    final candDepth = <List<double>>[];
    var maxRms = 0.0;

    for (var s = 0; s + need <= x.length; s += hop) {
      var e = 0.0;
      for (var j = 0; j < w; j++) {
        e += x[s + j] * x[s + j];
      }
      final rms = math.sqrt(e / w);
      if (rms > maxRms) maxRms = rms;

      for (var tau = 1; tau <= tauMax; tau++) {
        var sum = 0.0;
        for (var j = 0; j < w; j++) {
          final v = x[s + j] - x[s + j + tau];
          sum += v * v;
        }
        d[tau] = sum;
      }
      var running = 0.0;
      d[0] = 1;
      for (var tau = 1; tau <= tauMax; tau++) {
        running += d[tau];
        d[tau] = running > 0 ? d[tau] * tau / running : 1.0;
      }
      d[tauMax + 1] = d[tauMax];

      // 골짜기(둘레보다 낮은 곳)를 깊은 순으로 [candidates] 개.
      final taus = <int>[];
      for (var tau = tauMin; tau <= tauMax; tau++) {
        if (d[tau] < 0.9 && d[tau] <= d[tau - 1] && d[tau] < d[tau + 1]) taus.add(tau);
      }
      taus.sort((a, b) => d[a].compareTo(d[b]));
      final st = <double>[], depth = <double>[];
      for (final tau in taus.take(candidates)) {
        var tauF = tau.toDouble();
        final a = d[tau - 1], b = d[tau], c = d[tau + 1];
        final den = a - 2 * b + c;
        if (den.abs() > 1e-12) tauF += (0.5 * (a - c) / den).clamp(-1.0, 1.0);
        st.add(12 * math.log(sampleRate / tauF) / math.ln2);
        depth.add(math.max(0.0, b));
      }
      times.add((s + need / 2) / sampleRate);
      rmss.add(rms);
      candSt.add(st);
      candDepth.add(depth);
    }

    final n = times.length;
    final gate = math.max(absoluteSilence, relativeSilence * maxRms);

    // 가장 싼 길 찾기. 상태 0 = 무성, 1.. = 그 칸의 후보.
    // 같은 깊이면 높은 쪽(짧은 주기)을 고른다 — 주기의 배수에도 똑같은 골짜기가 생기므로.
    const inf = 1e18;
    const octaveBias = 0.03;
    final top = 12 * math.log(maxHz) / math.ln2;
    final back = <Int32List>[];
    var prevCost = Float64List(0);
    var prevSt = const <double>[];
    for (var i = 0; i < n; i++) {
      final st = candSt[i], depth = candDepth[i];
      final loud = rmss[i] >= gate;
      final cost = Float64List(st.length + 1);
      final from = Int32List(st.length + 1);
      for (var k = 0; k <= st.length; k++) {
        final own = k == 0
            ? (loud ? voicingCutoff : 0.0)
            : (loud ? depth[k - 1] + octaveBias * (top - st[k - 1]) / 12 : inf);
        if (i == 0) {
          cost[k] = own;
          continue;
        }
        var best = inf;
        var arg = 0;
        for (var p = 0; p < prevCost.length; p++) {
          double move;
          if (k == 0 || p == 0) {
            move = k == p ? 0.0 : switchCost;
          } else {
            final gap = (st[k - 1] - prevSt[p - 1]).abs();
            move = math.min(1.2, jumpCost * math.max(0.0, gap - 1.0));
          }
          final c = prevCost[p] + move;
          if (c < best) {
            best = c;
            arg = p;
          }
        }
        cost[k] = best + own;
        from[k] = arg;
      }
      back.add(from);
      prevCost = cost;
      prevSt = st;
    }
    final state = Int32List(n);
    if (n > 0) {
      var k = 0;
      for (var p = 1; p < prevCost.length; p++) {
        if (prevCost[p] < prevCost[k]) k = p;
      }
      for (var i = n - 1; i >= 0; i--) {
        state[i] = k;
        k = back[i][k];
      }
    }

    final hz = List<double?>.generate(
      n,
      (i) => state[i] == 0 ? null : math.pow(2, candSt[i][state[i] - 1] / 12).toDouble(),
    );

    // 너무 짧은 유성 구간 버리기.
    var i = 0;
    while (i < n) {
      if (hz[i] == null) {
        i++;
        continue;
      }
      var j = i;
      while (j < n && hz[j] != null) {
        j++;
      }
      if (j - i < minRunFrames) {
        for (var k = i; k < j; k++) {
          hz[k] = null;
        }
      }
      i = j;
    }

    double depthAt(int k) => state[k] > 0
        ? candDepth[k][state[k] - 1]
        : (candDepth[k].isEmpty ? 1.0 : candDepth[k].first);
    return PitchTrack(
      [
        for (var k = 0; k < n; k++)
          PitchFrame(times[k], hz[k], (1 - depthAt(k)).clamp(0.0, 1.0), rmss[k])
      ],
      hop / sampleRate,
    );
  }
}

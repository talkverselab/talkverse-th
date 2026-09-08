import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../main.dart';
import '../services/ko_reading.dart';
import '../services/speech_judge.dart';
import '../services/thai_dict_service.dart';
import '../services/tts_service.dart';
import '../widgets/thai_decor.dart';
import 'episode_screen.dart';

// ─────────────────────────────────────────────────────────────
// 문장 말하기 — 한국어를 보고 제한 시간 안에 태국어로 말하기
//   1) 선택: 회화 + 단계(7초/4초/2초) + 판정 기준
//   2) 연습: 8문장 자동 진행 · 문장마다 음성 인식
//   3) 결과: 통과/미통과 · 인식 텍스트 · 빠진 단어 · 원어민 듣기
// ─────────────────────────────────────────────────────────────

/// 단계별 문장당 제한 시간(초).
const List<int> _kStageSeconds = [7, 4, 2];
const String _kPrefStage = 'speak_stage';
const String _kPrefThreshold = 'speak_threshold';
const String _kPrefHint = 'speak_hint';
const Duration _kGap = Duration(milliseconds: 600);
const String _kPassRule = '시간 안에 빠진 단어 없이 말하면 통과';

int _secondsOf(int stage) => _kStageSeconds[(stage - 1).clamp(0, 2)];

String _stageHint(int stage) => switch (stage) {
      1 => '천천히 떠올리며 말하기',
      2 => '익숙하게 말하기',
      _ => '반사적으로 말하기',
    };

/// 힌트: 태국어 첫 어절 + 독음 첫 어절만 (그 이상은 절대 노출하지 않음).
/// 예) "ขอบคุณครับ แต่ยัง…" / "컵쿤 크랍, 때…" → "ขอบคุณครับ … (컵쿤 …)"
String _hintOf(String th, String? roman) {
  final sep = RegExp(r'[\s,，]+');
  String first(String s) {
    final parts = s.split(sep).where((w) => w.isNotEmpty);
    if (parts.isEmpty) return '';
    return parts.length > 1 ? '${parts.first} …' : parts.first;
  }

  final t = first(th);
  final r = roman == null ? '' : first(roman);
  if (t.isEmpty) return '';
  return r.isEmpty ? t : '$t ($r)';
}

/// 사전 최장일치 분절 → 텍스트 토큰 목록.
List<String> _segmentThai(String s) => [
      for (final t in ThaiDictService.instance.segment(s)) t['text'] as String,
    ];

/// 문장 말하기 — 진입 화면(회화·단계·판정 기준 선택).
class SpeakingPracticeScreen extends StatefulWidget {
  const SpeakingPracticeScreen({super.key});

  @override
  State<SpeakingPracticeScreen> createState() =>
      _SpeakingPracticeScreenState();
}

class _SpeakingPracticeScreenState extends State<SpeakingPracticeScreen> {
  bool _loading = true;
  int _stage = 1;
  double _threshold = SpeechJudge.defaultThreshold;
  bool _hint = false;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    await EpisodeCatalog.instance.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _stage = (_prefs!.getInt(_kPrefStage) ?? 1).clamp(1, 3);
      _hint = _prefs!.getBool(_kPrefHint) ?? false;
      _threshold = (_prefs!.getDouble(_kPrefThreshold) ??
              SpeechJudge.defaultThreshold)
          .clamp(0.3, 0.9);
      _loading = false;
    });
  }

  Future<void> _setStage(int stage) async {
    setState(() => _stage = stage);
    await _prefs?.setInt(_kPrefStage, stage);
  }

  Future<void> _setThreshold(double v) async {
    setState(() => _threshold = v);
    await _prefs?.setDouble(_kPrefThreshold, v);
  }

  Future<void> _setHint(bool v) async {
    setState(() => _hint = v);
    await _prefs?.setBool(_kPrefHint, v);
  }

  Future<void> _start(EpisodeMeta meta) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PracticeScreen(
          meta: meta,
          stage: _stage,
          threshold: _threshold,
          hint: _hint,
        ),
      ),
    );
    // 결과 화면에서 '다음 단계로'를 눌렀거나 연습 중 힌트를 바꿨으면 반영
    if (!mounted) return;
    final saved = _prefs?.getInt(_kPrefStage);
    final hint = _prefs?.getBool(_kPrefHint) ?? _hint;
    if ((saved != null && saved != _stage) || hint != _hint) {
      setState(() {
        if (saved != null) _stage = saved.clamp(1, 3);
        _hint = hint;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.khram,
        elevation: 0,
        centerTitle: true,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '문장 말하기',
              style: TextStyle(
                  color: AppColors.khram,
                  fontSize: 16,
                  fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 2),
            Text(
              '한국어 보고 태국어로 말하기',
              style: TextStyle(
                  color: AppColors.khramLight, fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kluayMai))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final catalog = EpisodeCatalog.instance;
    final levels = ['L1', 'L2', 'L3']
        .where((l) => catalog.forLevel(l).isNotEmpty)
        .toList(growable: false);
    final pct = (_threshold * 100).round();

    return Column(
      children: [
        const LaiThaiDivider(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            children: [
              const _SectionLabel('단계'),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var s = 1; s <= 3; s++) ...[
                    if (s > 1) const SizedBox(width: 8),
                    Expanded(
                      child: _StageChip(
                        stage: s,
                        selected: _stage == s,
                        onTap: () => _setStage(s),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$_stage단계 · 문장당 ${_secondsOf(_stage)}초 — ${_stageHint(_stage)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.khramLight, height: 1.4),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const _SectionLabel('판정 기준 (낮을수록 관대)'),
                  const Spacer(),
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.kluayMai,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.kluayMai,
                  inactiveTrackColor: AppColors.creamDeep,
                  thumbColor: AppColors.kluayMai,
                  overlayColor: AppColors.kluayMai.withValues(alpha: 0.12),
                  tickMarkShape: SliderTickMarkShape.noTickMark,
                ),
                child: Slider(
                  value: _threshold,
                  min: 0.3,
                  max: 0.9,
                  divisions: 12,
                  label: '$pct%',
                  onChanged: _setThreshold,
                ),
              ),
              const Text(
                '$_kPassRule · 인식된 단어 비율이 기준 이상이면 통과 · 발음 품질은 보지 않아요',
                style: TextStyle(
                    fontSize: 12, color: AppColors.khramLight, height: 1.4),
              ),
              const SizedBox(height: 22),
              InkWell(
                onTap: () => _setHint(!_hint),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _hint
                        ? AppColors.thong.withValues(alpha: 0.12)
                        : AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _hint ? AppColors.thong : AppColors.creamDeep),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _hint ? Icons.lightbulb : Icons.lightbulb_outline,
                        size: 20,
                        color: _hint
                            ? AppColors.thongDeep
                            : AppColors.khramLight,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('힌트 표시'),
                            SizedBox(height: 2),
                            Text(
                              '태국어 첫 어절과 독음만 살짝 보여줘요',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.khramLight),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _hint,
                        activeTrackColor: AppColors.thong,
                        onChanged: _setHint,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const _SectionLabel('회화 선택'),
              if (levels.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text('회화 데이터가 없어요',
                        style: TextStyle(color: AppColors.khramLight)),
                  ),
                ),
              for (final level in levels) ...[
                const SizedBox(height: 12),
                Text(
                  EpisodeCatalog.levelLabels[level] ?? level,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.kluayMai,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                for (final meta in catalog.forLevel(level))
                  _EpisodeTile(meta: meta, onTap: () => _start(meta)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: AppColors.khram,
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  final int stage;
  final bool selected;
  final VoidCallback onTap;
  const _StageChip({
    required this.stage,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.kluayMai : AppColors.khramLight;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.kluayMai : AppColors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.kluayMai : AppColors.thong,
            width: 1.4,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$stage단계',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: selected ? AppColors.cream : AppColors.khram,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_secondsOf(stage)}초',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.cream : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final EpisodeMeta meta;
  final VoidCallback onTap;
  const _EpisodeTile({required this.meta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.thong, width: 0.8),
          ),
          child: Row(
            children: [
              GoldEmblem(text: meta.emoji, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  meta.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.khram,
                  ),
                ),
              ),
              const Icon(Icons.mic, size: 18, color: AppColors.kluayMai),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 20, color: AppColors.khramLight),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 2) 연습 화면
// ─────────────────────────────────────────────────────────────

enum _Phase { loading, ready, recording, gap, paused, finishing }

class _PracticeScreen extends StatefulWidget {
  final EpisodeMeta meta;
  final int stage;
  final double threshold;
  final bool hint;
  const _PracticeScreen({
    required this.meta,
    required this.stage,
    required this.threshold,
    required this.hint,
  });

  @override
  State<_PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<_PracticeScreen>
    with SingleTickerProviderStateMixin {
  List<TurnRow> _turns = [];

  /// turn.num → 인식 텍스트. null = 판정 불가(인식 불가/권한 없음).
  final Map<int, String?> _recognized = {};
  int _index = 0;
  _Phase _phase = _Phase.loading;
  late bool _hint = widget.hint;

  late final AnimationController _timer;
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _speechChecked = false;
  String _localeId = 'th-TH';
  int _generation = 0; // 정지/일시정지 후 늦게 도착하는 콜백 무시용

  // 현재 문장의 인식 누적 (세션이 중간에 끊겨도 이어붙임)
  final List<String> _finalChunks = [];
  String _partial = '';
  bool _listenActive = false;

  int get _seconds => _secondsOf(widget.stage);
  Duration get _window => Duration(seconds: _seconds);

  String get _currentText =>
      [..._finalChunks, if (_partial.isNotEmpty) _partial].join(' ').trim();

  @override
  void initState() {
    super.initState();
    _timer = AnimationController(vsync: this, duration: _window)
      ..addStatusListener(_onTimerStatus);
    _load();
  }

  @override
  void dispose() {
    _generation++;
    _timer.dispose();
    if (_speechReady) _speech.cancel();
    super.dispose();
  }

  Future<void> _toggleHint() async {
    setState(() => _hint = !_hint);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefHint, _hint);
  }

  Future<void> _load() async {
    await ThaiDictService.instance.ensureLoaded();
    final turns = await (appDb.select(appDb.turns)
          ..where((t) =>
              t.level.equals(widget.meta.level) &
              t.episodeId.equals(widget.meta.id))
          ..orderBy([(t) => OrderingTerm.asc(t.num)]))
        .get();
    if (!mounted) return;
    setState(() {
      _turns = turns;
      _phase = _Phase.ready;
    });
  }

  // ── 음성 인식 ──

  Future<void> _ensureSpeech() async {
    if (_speechChecked) return;
    _speechChecked = true;
    try {
      _speechReady = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      if (_speechReady) {
        final locales = await _speech.locales();
        final th = locales.where(
          (l) => l.localeId.toLowerCase().startsWith('th'),
        );
        if (th.isNotEmpty) {
          // th_TH / th-TH 정확 일치 우선
          _localeId = th
              .firstWhere(
                (l) => l.localeId.toLowerCase().replaceAll('-', '_') == 'th_th',
                orElse: () => th.first,
              )
              .localeId;
        }
      }
    } catch (_) {
      _speechReady = false;
    }
    if (!_speechReady && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('음성 인식을 쓸 수 없어요 (권한/기기 미지원) — 판정 없이 진행해요'),
          backgroundColor: AppColors.thongDeep,
        ),
      );
    }
  }

  void _onSpeechStatus(String status) {
    // 기기 인식기가 침묵 등으로 먼저 끝나면 남은 시간 동안 다시 듣기
    if (status == 'done' || status == 'notListening') {
      _listenActive = false;
      _maybeRelisten();
    }
  }

  void _onSpeechError(SpeechRecognitionError e) {
    _listenActive = false;
    _maybeRelisten();
  }

  void _maybeRelisten() {
    if (!mounted || _phase != _Phase.recording || _listenActive) return;
    final remainMs = ((1 - _timer.value) * _window.inMilliseconds).round();
    if (remainMs < 800) return;
    final gen = _generation;
    // 인식기 정리 시간 살짝 두고 재시작
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (!mounted || gen != _generation || _phase != _Phase.recording) return;
      final left = ((1 - _timer.value) * _window.inMilliseconds).round();
      if (left < 500) return;
      _startListening(Duration(milliseconds: left));
    });
  }

  void _onResult(SpeechRecognitionResult r) {
    if (!mounted || _phase != _Phase.recording) return;
    if (r.finalResult) {
      if (r.recognizedWords.trim().isNotEmpty) {
        _finalChunks.add(r.recognizedWords.trim());
      }
      _partial = '';
    } else {
      _partial = r.recognizedWords;
    }
    setState(() {});
  }

  Future<void> _startListening(Duration span) async {
    if (!_speechReady || _listenActive) return;
    _listenActive = true;
    try {
      await _speech.listen(
        onResult: _onResult,
        listenOptions: SpeechListenOptions(
          localeId: _localeId,
          listenFor: span,
          pauseFor: span,
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: false,
        ),
      );
    } catch (_) {
      _listenActive = false;
    }
  }

  Future<void> _stopListening({bool cancel = false}) async {
    if (!_speechReady) return;
    try {
      if (cancel) {
        await _speech.cancel();
      } else {
        await _speech.stop();
      }
    } catch (_) {}
    _listenActive = false;
  }

  // ── 진행 ──

  /// 현재 문장 시작: 인식 시작 + 타이머 0부터.
  Future<void> _beginSentence() async {
    final gen = ++_generation;
    await _ensureSpeech();
    if (!mounted || gen != _generation) return;

    _finalChunks.clear();
    _partial = '';
    setState(() => _phase = _Phase.recording);
    _timer
      ..reset()
      ..forward();
    await _startListening(_window);
  }

  void _onTimerStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _endSentence();
  }

  /// 시간 종료: 인식 종료 → 0.6초(마지막 결과 수신) → 다음 문장 or 결과.
  Future<void> _endSentence() async {
    final gen = _generation;
    final num = _turns[_index].num;
    final last = _index >= _turns.length - 1;
    setState(() => _phase = last ? _Phase.finishing : _Phase.gap);

    await _stopListening();
    await Future<void>.delayed(_kGap);
    if (!mounted || gen != _generation) return;

    _recognized[num] = _speechReady ? _currentText : null;

    if (last) {
      _goResult();
    } else {
      setState(() => _index++);
      await _beginSentence();
    }
  }

  Future<void> _pause() async {
    if (_phase != _Phase.recording) return;
    _generation++;
    _timer.stop();
    setState(() => _phase = _Phase.paused);
    // 일시정지한 문장은 재개 시 처음부터 다시
    await _stopListening(cancel: true);
  }

  Future<void> _resume() async {
    if (_phase != _Phase.paused) return;
    await _beginSentence();
  }

  Future<void> _stop() async {
    _generation++;
    _timer.stop();
    await _stopListening(cancel: true);
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _goResult() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _ResultScreen(
          meta: widget.meta,
          stage: widget.stage,
          threshold: widget.threshold,
          hint: _hint,
          turns: _turns,
          recognized: Map.of(_recognized),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.meta;
    return PopScope(
      canPop: _phase == _Phase.ready || _phase == _Phase.loading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stop();
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.khram,
          elevation: 0,
          centerTitle: true,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${meta.emoji} ${meta.title}',
                style: const TextStyle(
                    color: AppColors.khram,
                    fontSize: 16,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${meta.level} · ${widget.stage}단계 · 문장당 $_seconds초',
                style: const TextStyle(
                    color: AppColors.khramLight,
                    fontSize: 10,
                    letterSpacing: 2),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: _hint ? '힌트 켜짐' : '힌트 꺼짐',
              onPressed: _toggleHint,
              icon: Icon(
                _hint ? Icons.lightbulb : Icons.lightbulb_outline,
                color: _hint ? AppColors.thongDeep : AppColors.khramLight,
                size: 22,
              ),
            ),
            if (_turns.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Text(
                    '${_index + 1} / ${_turns.length}',
                    style: const TextStyle(
                      color: AppColors.kluayMai,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: switch (_phase) {
          _Phase.loading => const Center(
              child: CircularProgressIndicator(color: AppColors.kluayMai)),
          _ when _turns.isEmpty => const Center(
              child: Text('문장이 없어요',
                  style: TextStyle(color: AppColors.khramLight))),
          _Phase.ready => _buildReady(),
          _ => _buildPractice(),
        },
      ),
    );
  }

  Widget _buildReady() {
    return Column(
      children: [
        const LaiThaiDivider(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GoldEmblem(text: '🎤', size: 72),
                const SizedBox(height: 24),
                Text(
                  '한국어 문장이 나오면\n$_seconds초 안에 태국어로 말해요',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.khram,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$_kPassRule · 총 ${_turns.length}문장',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.khramLight),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.kluayMai,
                      foregroundColor: AppColors.cream,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _beginSentence,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('시작',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPractice() {
    final turn = _turns[_index];
    final isA = turn.speaker == 'A';
    final recording = _phase == _Phase.recording;
    final paused = _phase == _Phase.paused;
    final waiting = _phase == _Phase.gap || _phase == _Phase.finishing;
    final heard = _currentText;

    return Column(
      children: [
        const LaiThaiDivider(height: 8),
        // ── 카운트다운 바 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: AnimatedBuilder(
            animation: _timer,
            builder: (context, _) {
              final remain = waiting ? 0.0 : (1 - _timer.value) * _seconds;
              return Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        recording && _speechReady
                            ? Icons.mic
                            : paused
                                ? Icons.pause_circle
                                : Icons.mic_off,
                        size: 18,
                        color: recording && _speechReady
                            ? AppColors.kluayMai
                            : AppColors.khramLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        paused
                            ? '일시정지'
                            : waiting
                                ? '다음 문장…'
                                : _speechReady
                                    ? '듣는 중'
                                    : '말하기',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.khramLight,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${remain.ceil()}초',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.kluayMai,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: waiting ? 0 : 1 - _timer.value,
                      minHeight: 16,
                      backgroundColor: AppColors.creamDeep,
                      color: paused ? AppColors.thong : AppColors.kluayMai,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        // ── 한국어 문장 ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: waiting ? 0.35 : 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: paused ? AppColors.thong : AppColors.kluayMai,
                    width: 1.6,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SpeakerBadge(isA: isA, size: 36),
                    const SizedBox(height: 20),
                    Text(
                      turn.ko ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.khram,
                        height: 1.4,
                      ),
                    ),
                    if (_hint && _hintOf(turn.th, turn.roman).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.thong.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.thong.withValues(alpha: 0.7)),
                        ),
                        child: Text(
                          '💡 ${_hintOf(turn.th, turn.roman)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.thongDeep,
                            fontFamilyFallback: AppTheme.fontFallback,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Text(
                      paused ? '재개하면 이 문장을 처음부터 다시' : '태국어로 말해 보세요',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.khramLight,
                        letterSpacing: 2,
                      ),
                    ),
                    // 인식 중인 텍스트 (태국어 정답은 절대 표시하지 않음)
                    if (_speechReady && !paused) ...[
                      const SizedBox(height: 14),
                      Text(
                        heard.isEmpty ? '…' : heard,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.khramLight,
                          fontFamilyFallback: AppTheme.fontFallback,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        // ── 일시정지 / 정지 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.khram,
                    side: const BorderSide(color: AppColors.thong),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _stop,
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('정지',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        paused ? AppColors.morakot : AppColors.kluayMai,
                    foregroundColor: AppColors.cream,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: paused
                      ? _resume
                      : recording
                          ? _pause
                          : null,
                  icon: Icon(paused ? Icons.play_arrow : Icons.pause,
                      size: 18),
                  label: Text(paused ? '재개' : '일시정지',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpeakerBadge extends StatelessWidget {
  final bool isA;
  final double size;
  const _SpeakerBadge({required this.isA, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isA ? AppColors.kluayMai : AppColors.thong,
        shape: BoxShape.circle,
      ),
      child: Text(
        isA ? 'A' : 'B',
        style: TextStyle(
          color: AppColors.cream,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 3) 결과 화면
// ─────────────────────────────────────────────────────────────

class _ResultScreen extends StatefulWidget {
  final EpisodeMeta meta;
  final int stage;
  final double threshold;
  final bool hint;
  final List<TurnRow> turns;

  /// turn.num → 인식 텍스트 (null = 판정 불가)
  final Map<int, String?> recognized;
  const _ResultScreen({
    required this.meta,
    required this.stage,
    required this.threshold,
    required this.hint,
    required this.turns,
    required this.recognized,
  });

  @override
  State<_ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<_ResultScreen> {
  late final Map<int, SpeechJudgeResult?> _judged;

  @override
  void initState() {
    super.initState();
    _judged = {
      for (final t in widget.turns)
        t.num: widget.recognized.containsKey(t.num) &&
                widget.recognized[t.num] != null
            ? SpeechJudge.evaluate(
                t.th,
                widget.recognized[t.num]!,
                _segmentThai,
                threshold: widget.threshold,
              )
            : null,
    };
  }

  int get _passCount =>
      _judged.values.where((r) => r != null && r.passed).length;

  Future<void> _playReference(TurnRow turn) async {
    await TtsService.instance.speakAs(
      turn.th,
      gender: turn.speaker == 'A' ? 'male' : 'female',
    );
  }

  void _retry() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _PracticeScreen(
          meta: widget.meta,
          stage: widget.stage,
          threshold: widget.threshold,
          hint: widget.hint,
        ),
      ),
    );
  }

  Future<void> _nextStage() async {
    final next = widget.stage + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrefStage, next);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _PracticeScreen(
          meta: widget.meta,
          stage: next,
          threshold: widget.threshold,
          hint: widget.hint,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.meta;
    final hasNext = widget.stage < 3;
    final total = widget.turns.length;
    final pass = _passCount;
    final allPassed = total > 0 && pass == total;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.khram,
        elevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${meta.emoji} ${meta.title} 결과',
              style: const TextStyle(
                  color: AppColors.khram,
                  fontSize: 16,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              '${meta.level} · ${widget.stage}단계 · 기준 ${(widget.threshold * 100).round()}%',
              style: const TextStyle(
                  color: AppColors.khramLight, fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
        actions: const [KoReadingToggleAction()],
      ),
      body: Column(
        children: [
          const LaiThaiDivider(height: 8),
          // ── 헤더: 통과 N / 8 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (allPassed ? AppColors.morakot : AppColors.kluayMai)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: allPassed ? AppColors.morakot : AppColors.kluayMai,
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '통과 $pass / $total',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: allPassed ? AppColors.morakot : AppColors.kluayMai,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    _kPassRule,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.khramLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              itemCount: widget.turns.length,
              itemBuilder: (context, i) {
                final turn = widget.turns[i];
                return _ResultCard(
                  turn: turn,
                  recognized: widget.recognized[turn.num],
                  judge: _judged[turn.num],
                  onPlayReference: () => _playReference(turn),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.khram,
                      side: const BorderSide(color: AppColors.thong),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _retry,
                    icon: const Icon(Icons.replay, size: 18),
                    label: const Text('다시 하기',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          hasNext ? AppColors.kluayMai : AppColors.morakot,
                      foregroundColor: AppColors.cream,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed:
                        hasNext ? _nextStage : () => Navigator.pop(context),
                    icon: Icon(hasNext ? Icons.arrow_forward : Icons.done,
                        size: 18),
                    label: Text(
                      hasNext ? '다음 단계로 (${widget.stage + 1}단계)' : '완료',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final TurnRow turn;
  final String? recognized; // null = 판정 불가
  final SpeechJudgeResult? judge;
  final VoidCallback onPlayReference;

  const _ResultCard({
    required this.turn,
    required this.recognized,
    required this.judge,
    required this.onPlayReference,
  });

  @override
  Widget build(BuildContext context) {
    final isA = turn.speaker == 'A';
    final j = judge;
    final (badge, badgeColor) = j == null
        ? ('판정 불가', AppColors.khramLight)
        : j.passed
            ? ('통과', AppColors.morakot)
            : ('미통과', AppColors.kluayMai);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SpeakerBadge(isA: isA),
              const SizedBox(width: 8),
              Text(
                '${turn.num}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.khramLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  turn.ko ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.khramLight,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _Badge(label: badge, color: badgeColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            turn.th,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.khram,
              height: 1.5,
              fontFamilyFallback: AppTheme.fontFallback,
            ),
          ),
          if (turn.roman != null) ...[
            const SizedBox(height: 4),
            KoReadingText(
              turn.roman!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.kluayMai,
              ),
            ),
          ],
          if (j != null && j.words.isNotEmpty) ...[
            const SizedBox(height: 8),
            _WordCoverage(judge: j),
          ],
          const SizedBox(height: 6),
          Text(
            j == null
                ? '인식: (음성 인식 불가)'
                : '인식: ${(recognized ?? '').trim().isEmpty ? '(없음)' : recognized}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.khramLight,
              height: 1.4,
              fontFamilyFallback: AppTheme.fontFallback,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.thongDeep,
                side: const BorderSide(color: AppColors.thong),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: const Size(0, 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onPlayReference,
              icon: const Icon(Icons.volume_up, size: 16),
              label: const Text(
                '원어민',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 목표 단어들 — 빠진 단어는 빨강 밑줄.
class _WordCoverage extends StatelessWidget {
  final SpeechJudgeResult judge;
  const _WordCoverage({required this.judge});

  @override
  Widget build(BuildContext context) {
    final missed = judge.missedCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (var i = 0; i < judge.words.length; i++)
              Text(
                judge.words[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: judge.said[i] ? AppColors.morakot : Colors.red,
                  decoration: judge.said[i]
                      ? TextDecoration.none
                      : TextDecoration.underline,
                  decorationColor: Colors.red,
                  decorationThickness: 2,
                  fontFamilyFallback: AppTheme.fontFallback,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          missed == 0
              ? '빠진 단어 없음 · 인식 ${(judge.coverage * 100).round()}%'
              : '빠진 단어 $missed개 · 인식 ${(judge.coverage * 100).round()}%',
          style: TextStyle(
            fontSize: 11,
            color: missed == 0 ? AppColors.morakot : Colors.red,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
